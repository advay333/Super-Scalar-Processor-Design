library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

package store_buffer_types is

    type store_buf_entry_t is record
        busy     : std_logic;
        ip_addr  : std_logic_vector(15 downto 0);
        
        -- Address 
        addr     : std_logic_vector(15 downto 0);
        v1       : std_logic;
        
        -- Data 
        data     : std_logic_vector(15 downto 0);
        data_tag : std_logic_vector(5 downto 0);
        v2       : std_logic;
        

    end record;

    constant EMPTY_STORE_ENTRY : store_buf_entry_t := (
        busy => '0', ip_addr => x"0000",
        addr => x"0000", v1 => '0',
        data => x"0000", data_tag => "000000", v2 => '0'
    );

end package;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;
use work.store_buffer_types.all;

entity store_buffer is
    generic (
        SB_DEPTH : integer := 8
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        
        cdb_buses       : in  cdb_array_t;

        
        disp_en_0       : in  std_logic;
        disp_data_0     : in  store_buf_entry_t;
        disp_en_1       : in  std_logic;
        disp_data_1     : in  store_buf_entry_t;
        queue_full      : out std_logic;

        exec_addr_en    : in  std_logic;
        exec_addr       : in  std_logic_vector(15 downto 0);
        commit_en       : in  std_logic; 
        
        
        head_ip         : out std_logic_vector(15 downto 0);
        head_addr       : out std_logic_vector(15 downto 0);
        head_data       : out std_logic_vector(15 downto 0);
        head_done       : out std_logic; 
        is_empty        : out std_logic;

        load_addr_valid : in  std_logic;
        load_addr       : in  std_logic_vector(15 downto 0);
		  
		  
        br_addr_valid : in  std_logic;
        br_addr       : in  std_logic_vector(15 downto 0);
        
        fwd_valid       : out std_logic; -- '1' if match found AND data ready
        fwd_data        : out std_logic_vector(15 downto 0);
        fwd_pending     : out std_logic;  -- '1' if match found BUT data missing (LSU must stall)
		  
		  fwd_valid_br       : out std_logic; -- '1' if match found AND data ready
        fwd_data_br        : out std_logic_vector(15 downto 0);
        fwd_pending_br     : out std_logic  -- '1' if match found BUT data missing (BR must stall)
    );
end entity;

architecture rtl of store_buffer is

    type sb_ram_t is array (0 to SB_DEPTH-1) of store_buf_entry_t;
    signal fifo_ram : sb_ram_t;

    signal head      : integer range 0 to SB_DEPTH-1;
    signal addr_head : integer range 0 to SB_DEPTH-1;
    signal tail      : integer range 0 to SB_DEPTH-1;
    signal count     : integer range 0 to SB_DEPTH;

begin


    queue_full <= '1' when (SB_DEPTH - count < 2) else '0';
    is_empty   <= '1' when (count = 0) else '0';

    head_ip    <= fifo_ram(head).ip_addr when count > 0 else x"0000";
    head_addr  <= fifo_ram(head).addr    when count > 0 else x"0000";
    head_data  <= fifo_ram(head).data    when count > 0 else x"0000";
    
    head_done  <= '1' when (fifo_ram(head).v1 = '1' and fifo_ram(head).v2 = '1' and count > 0) else '0';


    process(load_addr_valid, load_addr, fifo_ram, head, count)
        variable match_found : std_logic;
        variable match_ready : std_logic;
        variable match_data  : std_logic_vector(15 downto 0);
        variable scan_idx    : integer;
    begin
        match_found := '0';
        match_ready := '0';
        match_data  := (others => '0');

        if load_addr_valid = '1' then
            for j in 0 to SB_DEPTH-1 loop
                if j < count then
                    scan_idx := (head + j) mod SB_DEPTH;
                    
                    -- If its a valid store AND its address is computed AND it matches the load
                    if fifo_ram(scan_idx).busy = '1' and 
                       fifo_ram(scan_idx).v1 = '1' and 
                       fifo_ram(scan_idx).addr = load_addr then
                        
                        match_found := '1';
                        match_ready := fifo_ram(scan_idx).v2;
                        match_data  := fifo_ram(scan_idx).data;
                    end if;
                end if;
            end loop;
        end if;

        fwd_valid   <= match_found and match_ready;
        fwd_data    <= match_data;
        fwd_pending <= match_found and (not match_ready); -- Tells LSU to stall
    end process;


    process(br_addr_valid, br_addr, fifo_ram, head, count)
        variable match_found : std_logic;
        variable match_ready : std_logic;
        variable match_data  : std_logic_vector(15 downto 0);
        variable scan_idx    : integer;
    begin
        match_found := '0';
        match_ready := '0';
        match_data  := (others => '0');

        if br_addr_valid = '1' then
            for j in 0 to SB_DEPTH-1 loop
                if j < count then
                    scan_idx := (head + j) mod SB_DEPTH;
                    
                    -- If its a valid store AND its address is computed AND it matches the load
                    if fifo_ram(scan_idx).busy = '1' and 
                       fifo_ram(scan_idx).v1 = '1' and 
                       fifo_ram(scan_idx).addr = br_addr then
                        
                        match_found := '1';
                        match_ready := fifo_ram(scan_idx).v2;
                        match_data  := fifo_ram(scan_idx).data;
                    end if;
                end if;
            end loop;
        end if;

        fwd_valid_br   <= match_found and match_ready;
        fwd_data_br    <= match_data;
        fwd_pending_br <= match_found and (not match_ready); -- Tells LSU to stall
    end process;
	 
    process(clk)
        variable v_is_enq_0  : boolean;
        variable v_is_enq_1  : boolean;
        variable v_is_commit : boolean;
        
        variable enq_fwd_0   : store_buf_entry_t;
        variable enq_fwd_1   : store_buf_entry_t;
        
        variable v_tail      : integer;
        variable v_addr_head : integer;
        variable v_enq_cnt   : integer;
        variable v_deq_cnt   : integer;
        variable available   : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                head      <= 0;
                addr_head <= 0;
                tail      <= 0;
                count     <= 0;
                for i in 0 to SB_DEPTH-1 loop
                    fifo_ram(i) <= EMPTY_STORE_ENTRY;
                end loop;
            else
                
                available   := SB_DEPTH - count;
                v_is_enq_0  := (disp_en_0 = '1' and available >= 1);
                v_is_enq_1  := (disp_en_1 = '1' and available >= 2);
            
                v_is_commit := (commit_en = '1' and count > 0 and 
                                fifo_ram(head).v1 = '1' and fifo_ram(head).v2 = '1');

                
                for i in 0 to SB_DEPTH-1 loop
                    if fifo_ram(i).busy = '1' and fifo_ram(i).v2 = '0' then
                        for b in 0 to 3 loop
                            if cdb_buses(b)(22) = '1' then 
                                if fifo_ram(i).data_tag = cdb_buses(b)(21 downto 16) then
                                    fifo_ram(i).data <= cdb_buses(b)(15 downto 0);
                                    fifo_ram(i).v2   <= '1';
                                end if;
                            end if;
                        end loop;
                    end if;
                end loop;

       
                v_addr_head := addr_head;
                
                if exec_addr_en = '1' and fifo_ram(v_addr_head).busy = '1' then
                    fifo_ram(v_addr_head).addr <= exec_addr;
                    fifo_ram(v_addr_head).v1   <= '1';
                    
                    if v_addr_head = SB_DEPTH - 1 then v_addr_head := 0; else v_addr_head := v_addr_head + 1; end if;
                end if;
                addr_head <= v_addr_head;

           
                v_tail := tail;
                v_enq_cnt := 0;

                if v_is_enq_0 then
                    enq_fwd_0 := disp_data_0;
                    enq_fwd_0.busy := '1';
                    
                    if enq_fwd_0.v2 = '0' then
                        for b in 0 to 3 loop
                            if cdb_buses(b)(22) = '1' and enq_fwd_0.data_tag = cdb_buses(b)(21 downto 16) then
                                enq_fwd_0.data := cdb_buses(b)(15 downto 0);
                                enq_fwd_0.v2   := '1';
                            end if;
                        end loop;
                    end if;

                    fifo_ram(v_tail) <= enq_fwd_0;
                    if v_tail = SB_DEPTH - 1 then v_tail := 0; else v_tail := v_tail + 1; end if;
                    v_enq_cnt := v_enq_cnt + 1;
                end if;

                if v_is_enq_1 then
                    enq_fwd_1 := disp_data_1;
                    enq_fwd_1.busy := '1';
                    
                    if enq_fwd_1.v2 = '0' then
                        for b in 0 to 3 loop
                            if cdb_buses(b)(22) = '1' and enq_fwd_1.data_tag = cdb_buses(b)(21 downto 16) then
                                enq_fwd_1.data := cdb_buses(b)(15 downto 0);
                                enq_fwd_1.v2   := '1';
                            end if;
                        end loop;
                    end if;

                    fifo_ram(v_tail) <= enq_fwd_1;
                    if v_tail = SB_DEPTH - 1 then v_tail := 0; else v_tail := v_tail + 1; end if;
                    v_enq_cnt := v_enq_cnt + 1;
                end if;

                tail <= v_tail;

                v_deq_cnt := 0;
                if v_is_commit then
                    fifo_ram(head).busy <= '0';
                    fifo_ram(head).v1   <= '0';
                    fifo_ram(head).v2   <= '0';

                    if head = SB_DEPTH - 1 then head <= 0; else head <= head + 1; end if;
                    v_deq_cnt := 1;
                end if;

                count <= count + v_enq_cnt - v_deq_cnt;

            end if;
        end if;
    end process;
end architecture;