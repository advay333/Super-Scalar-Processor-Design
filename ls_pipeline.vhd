library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;
use work.lsu_rs_types.all;

entity ls_pipeline is
    port(
        clk: in std_logic;
        rst: in std_logic;
        
        -- Inputs from scheduler
        ls_iss_valid : in std_logic;
        ls_iss_data  : in lsu_rs_entry_t;

		  
        -- Outputs to RS
        rs_bus: out std_logic_vector(38 downto 0);
        
        -- Write back to RRF
        wb_addr_rrf: out std_logic_vector(5 downto 0);
        wb_data_rrf: out std_logic_vector(15 downto 0);
        wb_valid_rrf: out std_logic;
        
        -- Write back to Flag RRFs
        wb_zero_flag : out std_logic;
        wb_zero_tag  : out std_logic_vector(5 downto 0);
        wb_zero_valid: out std_logic;
        
        wb_carry_flag : out std_logic;
        wb_carry_tag  : out std_logic_vector(5 downto 0);
        wb_carry_valid: out std_logic;
        
		  wb_pc : out std_logic_vector(15 downto 0);
        wb_pc_tag  : out std_logic_vector(5 downto 0);
        wb_pc_valid: out std_logic;
		  
		  
        -- Write back to ROB  
        wb_ip_rob: out std_logic_vector(15 downto 0);
        wb_valid_rob: out std_logic;
        wb_flag_rob: out std_logic_vector(15 downto 0);
        
        -- To the data memory and store buffer
        mem_addr:out std_logic_vector(15 downto 0);
        mem_addr_valid:out std_logic;

        mem_din:in std_logic_vector(15 downto 0);
        sb_stall_pls:in std_logic;
		  
		  is_inst_store:out std_logic;
		  is_inst_load: out std_logic
    );
end entity ls_pipeline;

architecture ls_pipeline_struct of ls_pipeline is
    signal exec_mem_reg_in, exec_mem_reg_out : std_logic_vector(62 downto 0); 
    signal load_value : std_logic_vector(15 downto 0);
    signal mem_wb_reg_in, mem_wb_reg_out : std_logic_vector(79 downto 0);
    
    signal not_sb_stall_pls : std_logic;
    signal alu_out : std_logic_vector(15 downto 0);
    signal alu_zero_out, alu_carry_out : std_logic;
    
    -- Flag Control
    signal inst_updates_zero : std_logic;
    signal loaded_data_is_zero : std_logic;
    
begin
    not_sb_stall_pls <= not sb_stall_pls;
    
   
    inst_updates_zero <= ls_iss_data.control(1); 

    ALU_INST: entity work.alu
    port map(
        opcode => '0',
        inputA => ls_iss_data.op1_data,
        inputB => ls_iss_data.imm, -- For load/store address calculation
        cin  => '0',
        comp => '0',
        outputC => alu_out,
        zeroflag => alu_zero_out,
        carryflag => alu_carry_out
    );
    

    exec_mem_reg_in(15 downto 0)  <= ls_iss_data.ip_addr;
    exec_mem_reg_in(31 downto 16) <= alu_out;
    exec_mem_reg_in(33 downto 32) <= alu_carry_out & alu_zero_out;
    exec_mem_reg_in(39 downto 34) <= ls_iss_data.rrf_dest;
    exec_mem_reg_in(40)           <= ls_iss_valid;
    

    exec_mem_reg_in(46 downto 41) <= ls_iss_data.zero_dest_tag;
    exec_mem_reg_in(52 downto 47) <= ls_iss_data.carry_dest_tag;
    exec_mem_reg_in(53)           <= ls_iss_valid and inst_updates_zero;
    exec_mem_reg_in(54)           <= '0'; --Wasted bit, probably because of some earlier mistake
    exec_mem_reg_in(60 downto 55) <= ls_iss_data.pc_dest_tag;
	 exec_mem_reg_in(62 downto 61) <= ls_iss_data.control(9 downto 8);
	 
    EX_MEM_REG: entity work.n_bit_register
    generic map ( n => 63 )
    port map(
        clk      => clk,                  
        reset    => rst,      
        write_en => not_sb_stall_pls,               
        data_in  => exec_mem_reg_in, 
        data_out => exec_mem_reg_out 
    );
    mem_addr_valid <= exec_mem_reg_out(40);

    mem_addr   <= exec_mem_reg_out(31 downto 16);
    load_value <= mem_din;
    -- Evaluate Zero Flag based on the memory data
    loaded_data_is_zero <= '1' when load_value = x"0000" else '0';
    mem_wb_reg_in(54 downto 0)  <= exec_mem_reg_out(54 downto 0);
    mem_wb_reg_in(70 downto 55) <= load_value;
    mem_wb_reg_in(71)           <= loaded_data_is_zero;
    mem_wb_reg_in(77 downto 72) <= exec_mem_reg_out(60 downto 55);
	 mem_wb_reg_in(79 downto 78) <= exec_mem_reg_out(62 downto 61);--Not used further
	 is_inst_load <= exec_mem_reg_out(62);
	 is_inst_store<= exec_mem_reg_out(61);
    MEM_WB_REG: entity work.n_bit_register
    generic map ( n => 80 )
    port map(
        clk      => clk,                  
        reset    => rst,      
        write_en => not_sb_stall_pls,               
        data_in  => mem_wb_reg_in, 
        data_out => mem_wb_reg_out 
    );

    wb_ip_rob                <= mem_wb_reg_out(15 downto 0);
    wb_flag_rob(1 downto 0)  <= mem_wb_reg_out(33 downto 32);
    wb_flag_rob(15 downto 2) <= (others=>'0');
    wb_valid_rob             <= mem_wb_reg_out(40);

    wb_valid_rrf <= mem_wb_reg_out(40);
    wb_data_rrf  <= mem_wb_reg_out(70 downto 55);
    wb_addr_rrf  <= mem_wb_reg_out(39 downto 34);

    wb_zero_flag  <= mem_wb_reg_out(71);           -- Evaluated zero flag from loaded data
    wb_zero_tag   <= mem_wb_reg_out(46 downto 41);
    wb_zero_valid <= mem_wb_reg_out(53);
    
    wb_carry_flag  <= '0';                         -- Grounded
    wb_carry_tag   <= mem_wb_reg_out(52 downto 47);
    wb_carry_valid <= '0';                         -- LSU never updates carry

	 
	 wb_pc <= mem_wb_reg_out(15 downto 0);
    wb_pc_tag  <= mem_wb_reg_out(77 downto 72);
    wb_pc_valid <= mem_wb_reg_out(40);
		
    rs_bus(38 downto 33) <= mem_wb_reg_out(46 downto 41); -- Zero Flag Dest Tag
    rs_bus(32 downto 27) <= mem_wb_reg_out(52 downto 47); -- Carry Flag Dest Tag
    rs_bus(26)           <= mem_wb_reg_out(71);           -- Zero Flag Value (From Mem Data)
    rs_bus(25)           <= mem_wb_reg_out(53);           -- Zero Valid
    rs_bus(24)           <= '0';                          -- Carry Flag Value
    rs_bus(23)           <= '0';                          -- Carry Valid
    rs_bus(22)           <= mem_wb_reg_out(40);           -- Result Data Valid
    rs_bus(21 downto 16) <= mem_wb_reg_out(39 downto 34); -- Data Dest Tag
    rs_bus(15 downto 0)  <= mem_wb_reg_out(70 downto 55); -- Loaded Data
end architecture;