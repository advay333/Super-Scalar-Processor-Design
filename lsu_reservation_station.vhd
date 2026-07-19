library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

package lsu_rs_types is
    constant CTRL_WIDTH : integer := 20; 

    type lsu_rs_entry_t is record
        busy           : std_logic; 
        ip_addr        : std_logic_vector(15 downto 0);
        control        : std_logic_vector(CTRL_WIDTH-1 downto 0);
        op1_data       : std_logic_vector(15 downto 0);
        op1_tag        : std_logic_vector(5 downto 0);
        v1             : std_logic;
        op2_data       : std_logic_vector(15 downto 0);
        op2_tag        : std_logic_vector(5 downto 0);
        v2             : std_logic;
        imm            : std_logic_vector(15 downto 0);
        rrf_dest       : std_logic_vector(5 downto 0);
        zero_dest_tag  : std_logic_vector(5 downto 0);
        carry_dest_tag : std_logic_vector(5 downto 0);
		  pc_dest_tag : std_logic_vector(5 downto 0);
    end record;

    
    constant EMPTY_ENTRY : lsu_rs_entry_t := (
        busy => '0', ip_addr => x"0000", control => (others => '0'),
        op1_data => x"0000", op1_tag => "000000", v1 => '0',
        op2_data => x"0000", op2_tag => "000000", v2 => '0',
        imm => x"0000", rrf_dest => "000000",
        zero_dest_tag => "000000", carry_dest_tag => "000000", pc_dest_tag => "000000"
    );

end package;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lsu_rs_types.all;
use work.common_pkg.all;

entity lsu_reservation_station is
    generic (
        RS_DEPTH : integer := 8  
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        cdb_buses  : in  cdb_array_t;
        
        -- 2-Way Enqueue (From Dispatch)
        enq_en_0   : in  std_logic;
        data_in_0  : in  lsu_rs_entry_t;
        enq_en_1   : in  std_logic;
        data_in_1  : in  lsu_rs_entry_t;
        
        -- 1-Way Dequeue (From Scheduler)
        deq_en     : in  std_logic;
        
        -- Combinational Outputs
        top_data   : out lsu_rs_entry_t;
        top_ready  : out std_logic;
        top_busy   : out std_logic;
        queue_full : out std_logic
    );
end entity;

architecture rtl of lsu_reservation_station is

    type rs_ram_t is array (0 to RS_DEPTH-1) of lsu_rs_entry_t;
    signal fifo_ram : rs_ram_t;

    signal head  : integer range 0 to RS_DEPTH-1;
    signal tail  : integer range 0 to RS_DEPTH-1;
    signal count : integer range 0 to RS_DEPTH;

begin


   
    queue_full <= '1' when (RS_DEPTH - count < 2) else '0';
    top_busy   <= '1' when (count > 0) else '0';
    
    top_data   <= fifo_ram(head) when count > 0 else EMPTY_ENTRY;
    
    top_ready  <= '1' when (fifo_ram(head).v1 = '1' and 
                            fifo_ram(head).v2 = '1' and 
                            count > 0) else '0';


    process(clk)
        variable v_is_enq_0 : boolean;
        variable v_is_enq_1 : boolean;
        variable v_is_deq   : boolean;
        
        variable enq_fwd_0  : lsu_rs_entry_t;
        variable enq_fwd_1  : lsu_rs_entry_t;
        
        variable v_tail     : integer;
        variable v_enq_cnt  : integer;
        variable v_deq_cnt  : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                head  <= 0;
                tail  <= 0;
                count <= 0;
                for i in 0 to RS_DEPTH-1 loop
                    fifo_ram(i) <= EMPTY_ENTRY;
                end loop;
            else
                -- Determine valid operations 
                v_is_enq_0 := (enq_en_0 = '1' and count < RS_DEPTH);
--                v_is_enq_1 := (enq_en_1 = '1' and (count + 1) < RS_DEPTH);
					 if v_is_enq_0 then
							 v_is_enq_1 := (enq_en_1='1' and (count+1) < RS_DEPTH);
						else
							 v_is_enq_1 := (enq_en_1='1' and count < RS_DEPTH);
					 end if;
                v_is_deq   := (deq_en = '1' and count > 0);


                for i in 0 to RS_DEPTH-1 loop
                    if fifo_ram(i).busy = '1' then
                        for b in 0 to 3 loop
                            if cdb_buses(b)(22) = '1' then 
                                -- Check op1
                                if fifo_ram(i).v1 = '0' and fifo_ram(i).op1_tag = cdb_buses(b)(21 downto 16) then
                                    fifo_ram(i).op1_data <= cdb_buses(b)(15 downto 0);
                                    fifo_ram(i).v1       <= '1';
                                end if;
                                -- Check op2
                                if fifo_ram(i).v2 = '0' and fifo_ram(i).op2_tag = cdb_buses(b)(21 downto 16) then
                                    fifo_ram(i).op2_data <= cdb_buses(b)(15 downto 0);
                                    fifo_ram(i).v2       <= '1';
                                end if;
                            end if;
                        end loop;
                    end if;
                end loop;

                
                v_tail := tail;
                v_enq_cnt := 0;

                -- first instruction
                if v_is_enq_0 then
                    enq_fwd_0 := data_in_0;
                    enq_fwd_0.busy := '1'; 
                    
                    for b in 0 to 3 loop
                        if cdb_buses(b)(22) = '1' then
                            if enq_fwd_0.v1 = '0' and enq_fwd_0.op1_tag = cdb_buses(b)(21 downto 16) then
                                enq_fwd_0.op1_data := cdb_buses(b)(15 downto 0);
                                enq_fwd_0.v1       := '1';
                            end if;
                            if enq_fwd_0.v2 = '0' and enq_fwd_0.op2_tag = cdb_buses(b)(21 downto 16) then
                                enq_fwd_0.op2_data := cdb_buses(b)(15 downto 0);
                                enq_fwd_0.v2       := '1';
                            end if;
                        end if;
                    end loop;

                    fifo_ram(v_tail) <= enq_fwd_0;
                    if v_tail = RS_DEPTH - 1 then v_tail := 0; else v_tail := v_tail + 1; end if;
                    v_enq_cnt := v_enq_cnt + 1;
                end if;

                --  second instruction
                if v_is_enq_1 then
                    enq_fwd_1 := data_in_1;
                    enq_fwd_1.busy := '1'; 
                    
                    for b in 0 to 3 loop
                        if cdb_buses(b)(22) = '1' then
                            if enq_fwd_1.v1 = '0' and enq_fwd_1.op1_tag = cdb_buses(b)(21 downto 16) then
                                enq_fwd_1.op1_data := cdb_buses(b)(15 downto 0);
                                enq_fwd_1.v1       := '1';
                            end if;
                            if enq_fwd_1.v2 = '0' and enq_fwd_1.op2_tag = cdb_buses(b)(21 downto 16) then
                                enq_fwd_1.op2_data := cdb_buses(b)(15 downto 0);
                                enq_fwd_1.v2       := '1';
                            end if;
                        end if;
                    end loop;

                    fifo_ram(v_tail) <= enq_fwd_1;
                    if v_tail = RS_DEPTH - 1 then v_tail := 0; else v_tail := v_tail + 1; end if;
                    v_enq_cnt := v_enq_cnt + 1;
                end if;

                -- Update the actual tail flip-flop
                tail <= v_tail;

        
                v_deq_cnt := 0;
                if v_is_deq then
                    fifo_ram(head).busy <= '0';
                    fifo_ram(head).v1   <= '0';
                    fifo_ram(head).v2   <= '0';

                    if head = RS_DEPTH - 1 then head <= 0; else head <= head + 1; end if;
                    v_deq_cnt := 1;
                end if;

                count <= count + v_enq_cnt - v_deq_cnt;

            end if;
        end if;
    end process;
end architecture;