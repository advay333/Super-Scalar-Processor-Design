library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;
use work.alu_rs_types.all;

entity alu_pipeline is
    port(
        clk: in std_logic;
        rst: in std_logic;
        
        -- Inputs from the scheduler
        alu_iss_valid : in std_logic;
        alu_iss_data  : in alu_rs_entry_t;
        
        -- Outputs to RS
        rs_bus: out std_logic_vector(38 downto 0);
        
        -- Write back stage to RRF
        wb_addr_rrf: out std_logic_vector(5 downto 0);
        wb_data_rrf: out std_logic_vector(15 downto 0);
        wb_valid_rrf:out std_logic;
        
        -- Write back stage to Flag RRFs
        wb_zero_flag : out std_logic;
        wb_zero_tag  : out std_logic_vector(5 downto 0);
        wb_zero_valid: out std_logic;
        
        wb_carry_flag : out std_logic;
        wb_carry_tag  : out std_logic_vector(5 downto 0);
        wb_carry_valid: out std_logic;
        
        -- Write back stage to ROB
        wb_ip_rob: out std_logic_vector(15 downto 0);
        wb_valid_rob: out std_logic;
        wb_flag_rob: out std_logic_vector(15 downto 0);
		  
		  wb_pc : out std_logic_vector(15 downto 0);
        wb_pc_tag  : out std_logic_vector(5 downto 0);
        wb_pc_valid: out std_logic
		  
    );
end entity alu_pipeline;

architecture alu_pipeline_struct of alu_pipeline is

    signal alu_out: std_logic_vector(15 downto 0);
    signal alu_zero_out, alu_carry_out: std_logic;
    
    -- Control signals to determine if this specific instruction actually updates flags
    signal inst_updates_zero  : std_logic;
    signal inst_updates_carry : std_logic;

    -- Pipeline Register
    signal exec_wb_reg_in, exec_wb_reg_out: std_logic_vector(70 downto 0);
	 
	 signal alu_cin : std_logic;
	 signal predicate_pass : std_logic;
	 
	 signal inst_is_nand    : std_logic;
    signal inst_comp       : std_logic;
    signal inst_add_carry  : std_logic;
    signal inst_cond_carry : std_logic;
    signal inst_cond_zero  : std_logic;
    
begin

	 inst_is_nand    <= alu_iss_data.control(14);
    inst_comp       <= alu_iss_data.control(13);
    inst_add_carry  <= alu_iss_data.control(12);
    inst_cond_carry <= alu_iss_data.control(11);
    inst_cond_zero  <= alu_iss_data.control(10);
	 
    inst_updates_zero  <= alu_iss_data.control(1); 
    inst_updates_carry <= alu_iss_data.control(0); 
	 
	 
	 predicate_pass <= '1' when (inst_cond_carry = '0' and inst_cond_zero = '0') else -- Unconditional
                      '1' when (inst_cond_carry = '1' and alu_iss_data.carry_flag = '1') else
                      '1' when (inst_cond_zero = '1'  and alu_iss_data.zero_flag = '1') else
                      '0';
	alu_cin <= alu_iss_data.carry_flag when (inst_add_carry = '1') else '0';
	

    ALU_INST: entity work.alu
    port map(
        opcode => inst_is_nand, -- Map from control 
        inputA => alu_iss_data.op1_data,
        inputB => alu_iss_data.op2_data,
        cin    => alu_cin, -- Map from alu_iss_data.carry_flag 
        comp   => inst_comp, -- Map from control 
        outputC=> alu_out,
        zeroflag=>alu_zero_out,
        carryflag=>alu_carry_out
    );


    exec_wb_reg_in(15 downto 0)  <= alu_iss_data.ip_addr;
    exec_wb_reg_in(31 downto 16) <= alu_out;
    exec_wb_reg_in(33 downto 32) <= alu_carry_out & alu_zero_out;
    exec_wb_reg_in(39 downto 34) <= alu_iss_data.rrf_dest;
    exec_wb_reg_in(40)           <= alu_iss_valid;
    
    -- Flag Destination Tags
    exec_wb_reg_in(46 downto 41) <= alu_iss_data.zero_dest_tag;
    exec_wb_reg_in(52 downto 47) <= alu_iss_data.carry_dest_tag;
    
    -- the Flag Valid bits (Only valid if instruction is valid AND it's supposed to update)
    exec_wb_reg_in(53)           <= alu_iss_valid and inst_updates_zero and predicate_pass;
    exec_wb_reg_in(54)           <= alu_iss_valid and inst_updates_carry and predicate_pass;
    
    exec_wb_reg_in(63 downto 55) <= (others => '0'); 
    
	 exec_wb_reg_in(69 downto 64) <= alu_iss_data.pc_dest_tag;
	 
	 
	 exec_wb_reg_in(70) <= alu_iss_valid and predicate_pass;
    PIPELINE_REG: entity work.n_bit_register
    generic map (
        n => 71 
    )
    port map(
        clk      => clk,                 
        reset    => rst,     
        write_en => '1',               
        data_in  => exec_wb_reg_in, 
        data_out => exec_wb_reg_out 
    );
    
  
    -- ROB Writeback
    wb_ip_rob                <= exec_wb_reg_out(15 downto 0);
    wb_flag_rob(1 downto 0)  <= exec_wb_reg_out(33 downto 32);
    wb_flag_rob(15 downto 2) <= (others=>'0');
    wb_valid_rob             <= exec_wb_reg_out(40);

    -- General RRF Writeback
    wb_valid_rrf <= exec_wb_reg_out(70);
    wb_data_rrf  <= exec_wb_reg_out(31 downto 16);
    wb_addr_rrf  <= exec_wb_reg_out(39 downto 34);
    
    -- Flag RRF Writebacks
    wb_zero_flag  <= exec_wb_reg_out(32);
    wb_zero_tag   <= exec_wb_reg_out(46 downto 41);
    wb_zero_valid <= exec_wb_reg_out(53);
    
    wb_carry_flag  <= exec_wb_reg_out(33);
    wb_carry_tag   <= exec_wb_reg_out(52 downto 47);
    wb_carry_valid <= exec_wb_reg_out(54);
    
--	 wb_pc  <= exec_wb_reg_out(15 downto 0);
	 wb_pc <= std_logic_vector(unsigned(exec_wb_reg_out(15 downto 0)) + 2);
    wb_pc_tag   <= exec_wb_reg_out(69 downto 64);
    wb_pc_valid <= exec_wb_reg_out(40);

    rs_bus(38 downto 33) <= exec_wb_reg_out(46 downto 41); -- Zero Flag Dest Tag
    rs_bus(32 downto 27) <= exec_wb_reg_out(52 downto 47); -- Carry Flag Dest Tag
    rs_bus(26)           <= exec_wb_reg_out(32);           -- Zero Flag Value
    rs_bus(25)           <= exec_wb_reg_out(53);           -- Zero Valid
    rs_bus(24)           <= exec_wb_reg_out(33);           -- Carry Flag Value
    rs_bus(23)           <= exec_wb_reg_out(54);           -- Carry Valid
    rs_bus(22)           <= exec_wb_reg_out(40);           -- Result Data Valid
    rs_bus(21 downto 16) <= exec_wb_reg_out(39 downto 34); -- Data Dest Tag
    rs_bus(15 downto 0)  <= exec_wb_reg_out(31 downto 16); -- Result Data

end architecture;
