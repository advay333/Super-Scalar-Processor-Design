library ieee;
use ieee.std_logic_1164.all;
use work.common_pkg.all;

package alu_rs_types is
    constant CTRL_WIDTH : integer := 20;

    type alu_rs_entry_t is record
        busy           : std_logic;
        ip_addr        : std_logic_vector(15 downto 0);
        control        : std_logic_vector(CTRL_WIDTH-1 downto 0);
        
        op1_data       : std_logic_vector(15 downto 0);
        op1_tag        : std_logic_vector(5 downto 0);
        v1             : std_logic;
        
        op2_data       : std_logic_vector(15 downto 0);
        op2_tag        : std_logic_vector(5 downto 0);
        v2             : std_logic;
        
        rrf_dest       : std_logic_vector(5 downto 0);
        
        
        zero_flag      : std_logic;
        carry_flag     : std_logic;
        zero_valid     : std_logic;
        carry_valid    : std_logic;
        zero_flag_tag  : std_logic_vector(5 downto 0);
        carry_flag_tag : std_logic_vector(5 downto 0);
		  zero_dest_tag  : std_logic_vector(5 downto 0); 
			carry_dest_tag : std_logic_vector(5 downto 0);
			pc_dest_tag : std_logic_vector(5 downto 0);
    end record;

    constant EMPTY_ALU_ENTRY : alu_rs_entry_t := (
        busy => '0', ip_addr => x"0000", control => (others => '0'),
        op1_data => x"0000", op1_tag => "000000", v1 => '0',
        op2_data => x"0000", op2_tag => "000000", v2 => '0',
        rrf_dest => "000000", 
        zero_flag => '0', carry_flag => '0', 
        zero_valid => '0', carry_valid => '0', 
        zero_flag_tag => "000000", carry_flag_tag => "000000", zero_dest_tag => "000000", carry_dest_tag => "000000",pc_dest_tag => "000000"
    );

    type alu_rs_array_t is array (natural range <>) of alu_rs_entry_t;
end package;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_rs_types.all; 
use work.common_pkg.all;
entity alu_reservation_station is
    generic (
        RS_DEPTH : integer := 8
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;

       
        cdb_buses       : in  cdb_array_t;

        dispatch_en_0   : in  std_logic;
        dispatch_data_0 : in  alu_rs_entry_t;
        dispatch_en_1   : in  std_logic;
        dispatch_data_1 : in  alu_rs_entry_t;

        
        issue_en_0      : in  std_logic;
        issue_idx_0     : in  integer range 0 to RS_DEPTH-1;
        issue_en_1      : in  std_logic;
        issue_idx_1     : in  integer range 0 to RS_DEPTH-1;

        
        rs_array        : out alu_rs_array_t(0 to RS_DEPTH-1);
        rs_ready_flags  : out std_logic_vector(RS_DEPTH-1 downto 0);
        
       
        queue_full      : out std_logic
    );
end entity;
architecture rtl of alu_reservation_station is

    signal rs_ram : alu_rs_array_t(0 to RS_DEPTH-1);
    signal count  : integer range 0 to RS_DEPTH;

    signal alloc_idx_0   : integer range 0 to RS_DEPTH-1;
    signal alloc_idx_1   : integer range 0 to RS_DEPTH-1;
    signal can_alloc_0   : std_logic;
    signal can_alloc_1   : std_logic;

begin

    rs_array <= rs_ram;

    process(rs_ram)
    begin
        for i in 0 to RS_DEPTH-1 loop
            if rs_ram(i).busy = '1' and rs_ram(i).v1 = '1' and rs_ram(i).v2 = '1' and rs_ram(i).zero_valid = '1' and rs_ram(i).carry_valid = '1' then
                rs_ready_flags(i) <= '1';
            else
                rs_ready_flags(i) <= '0';
            end if;
        end loop;
    end process;

    queue_full <= '1' when (RS_DEPTH - count < 2) else '0';

    process(rs_ram)
        variable found_0 : boolean;
        variable found_1 : boolean;
    begin
        alloc_idx_0 <= 0; alloc_idx_1 <= 0;
        can_alloc_0 <= '0'; can_alloc_1 <= '0';
        found_0     := false; found_1     := false;

        for i in 0 to RS_DEPTH-1 loop
            if rs_ram(i).busy = '0' then
                if not found_0 then
                    alloc_idx_0 <= i; can_alloc_0 <= '1'; found_0 := true;
                elsif not found_1 then
                    alloc_idx_1 <= i; can_alloc_1 <= '1'; found_1 := true;
                    exit;
                end if;
            end if;
        end loop;
    end process;

    process(clk)
        variable is_disp_0  : boolean;
        variable is_disp_1  : boolean;
        variable is_issue_0 : boolean;
        variable is_issue_1 : boolean;
        variable disp_fwd_0 : alu_rs_entry_t;
        variable disp_fwd_1 : alu_rs_entry_t;
        variable d_count    : integer;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= 0;
                for i in 0 to RS_DEPTH-1 loop
                    rs_ram(i) <= EMPTY_ALU_ENTRY;
                end loop;
            else
                is_disp_0  := (dispatch_en_0 = '1' and can_alloc_0 = '1');
                is_disp_1  := (dispatch_en_1 = '1' and can_alloc_1 = '1');
                is_issue_0 := (issue_en_0 = '1' and rs_ram(issue_idx_0).busy = '1');
                is_issue_1 := (issue_en_1 = '1' and rs_ram(issue_idx_1).busy = '1');

            
                for i in 0 to RS_DEPTH-1 loop
                    if rs_ram(i).busy = '1' then
                        for b in 0 to 3 loop
                            if cdb_buses(b)(22) = '1' then 
                                --  Data Operands
                                if rs_ram(i).v1 = '0' and rs_ram(i).op1_tag = cdb_buses(b)(21 downto 16) then
                                    rs_ram(i).op1_data <= cdb_buses(b)(15 downto 0);
                                    rs_ram(i).v1       <= '1';
                                end if;
                                if rs_ram(i).v2 = '0' and rs_ram(i).op2_tag = cdb_buses(b)(21 downto 16) then
                                    rs_ram(i).op2_data <= cdb_buses(b)(15 downto 0);
                                    rs_ram(i).v2       <= '1';
                                end if;
                            end if;
                            
                        
                            --  Zero Flag (Check Zero Valid bit 25)
                            if rs_ram(i).zero_valid = '0' and rs_ram(i).zero_flag_tag = cdb_buses(b)(38 downto 33) and cdb_buses(b)(25) = '1' then
                                rs_ram(i).zero_flag <= cdb_buses(b)(26);
                                rs_ram(i).zero_valid <= '1';
                            end if;
                            
                            --  Carry Flag (Check Carry Valid bit 23)
                            if rs_ram(i).carry_valid = '0' and rs_ram(i).carry_flag_tag = cdb_buses(b)(32 downto 27) and cdb_buses(b)(23) = '1' then
                                rs_ram(i).carry_flag <= cdb_buses(b)(24);
                                rs_ram(i).carry_valid <= '1';
                            end if;
                        end loop;
                    end if;
                end loop;

    
                if is_disp_0 then
                    disp_fwd_0 := dispatch_data_0;
                    disp_fwd_0.busy := '1';
                    
                    for b in 0 to 3 loop
                        if cdb_buses(b)(22) = '1' then
                            if disp_fwd_0.v1 = '0' and disp_fwd_0.op1_tag = cdb_buses(b)(21 downto 16) then
                                disp_fwd_0.op1_data := cdb_buses(b)(15 downto 0);
                                disp_fwd_0.v1       := '1';
                            end if;
                            if disp_fwd_0.v2 = '0' and disp_fwd_0.op2_tag = cdb_buses(b)(21 downto 16) then
                                disp_fwd_0.op2_data := cdb_buses(b)(15 downto 0);
                                disp_fwd_0.v2       := '1';
                            end if;
                        end if;
                        
                        -- 0-Cycle Forwarding for Flags
                        if disp_fwd_0.zero_valid = '0' and disp_fwd_0.zero_flag_tag = cdb_buses(b)(38 downto 33) and cdb_buses(b)(25) = '1' then
                            disp_fwd_0.zero_flag := cdb_buses(b)(26);
                            disp_fwd_0.zero_valid := '1';
                        end if;
                        if disp_fwd_0.carry_valid = '0' and disp_fwd_0.carry_flag_tag = cdb_buses(b)(32 downto 27) and cdb_buses(b)(23) = '1' then
                            disp_fwd_0.carry_flag := cdb_buses(b)(24);
                            disp_fwd_0.carry_valid := '1';
                        end if;
                    end loop;
                    rs_ram(alloc_idx_0) <= disp_fwd_0;
                end if;

                if is_disp_1 then
                    disp_fwd_1 := dispatch_data_1;
                    disp_fwd_1.busy := '1';
                    
                    for b in 0 to 3 loop
                        if cdb_buses(b)(22) = '1' then
                            if disp_fwd_1.v1 = '0' and disp_fwd_1.op1_tag = cdb_buses(b)(21 downto 16) then
                                disp_fwd_1.op1_data := cdb_buses(b)(15 downto 0);
                                disp_fwd_1.v1       := '1';
                            end if;
                            if disp_fwd_1.v2 = '0' and disp_fwd_1.op2_tag = cdb_buses(b)(21 downto 16) then
                                disp_fwd_1.op2_data := cdb_buses(b)(15 downto 0);
                                disp_fwd_1.v2       := '1';
                            end if;
                        end if;
                        
                        if disp_fwd_1.zero_valid = '0' and disp_fwd_1.zero_flag_tag = cdb_buses(b)(38 downto 33) and cdb_buses(b)(25) = '1' then
                            disp_fwd_1.zero_flag := cdb_buses(b)(26);
                            disp_fwd_1.zero_valid := '1';
                        end if;
                        if disp_fwd_1.carry_valid = '0' and disp_fwd_1.carry_flag_tag = cdb_buses(b)(32 downto 27) and cdb_buses(b)(23) = '1' then
                            disp_fwd_1.carry_flag := cdb_buses(b)(24);
                            disp_fwd_1.carry_valid := '1';
                        end if;
                    end loop;
                    rs_ram(alloc_idx_1) <= disp_fwd_1;
                end if;


                if is_issue_0 then
                    rs_ram(issue_idx_0).busy <= '0';
                    rs_ram(issue_idx_0).v1   <= '0';
                    rs_ram(issue_idx_0).v2   <= '0';
                end if;

                if is_issue_1 then
                    rs_ram(issue_idx_1).busy <= '0';
                    rs_ram(issue_idx_1).v1   <= '0';
                    rs_ram(issue_idx_1).v2   <= '0';
                end if;


                d_count := 0;
                if is_disp_0  then d_count := d_count + 1; end if;
                if is_disp_1  then d_count := d_count + 1; end if;
                if is_issue_0 then d_count := d_count - 1; end if;
                if is_issue_1 then d_count := d_count - 1; end if;
                
                count <= count + d_count;

            end if;
        end if;
    end process;
end architecture;