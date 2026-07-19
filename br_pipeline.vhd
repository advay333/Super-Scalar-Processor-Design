library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;
use work.branch_rs_types.all;

entity br_pipeline is
    port(
        clk : in std_logic;
        rst : in std_logic;
        
        -- Inputs from scheduler
        br_iss_valid : in std_logic;
        br_iss_data  : in branch_rs_entry_t;
        
        -- Outputs to RS
        rs_bus: out std_logic_vector(38 downto 0);
        
        -- Write back stage to RRF (linking instructions)
        wb_addr_rrf  : out std_logic_vector(5 downto 0);
        wb_data_rrf  : out std_logic_vector(15 downto 0);
        wb_valid_rrf : out std_logic;
        
        --  Write back stage to Flag RRFs
        wb_zero_flag : out std_logic;
        wb_zero_tag  : out std_logic_vector(5 downto 0);
        wb_zero_valid: out std_logic;
        
        wb_carry_flag : out std_logic;
        wb_carry_tag  : out std_logic_vector(5 downto 0);
        wb_carry_valid: out std_logic;
		  
        wb_pc : out std_logic_vector(15 downto 0);
        wb_pc_tag  : out std_logic_vector(5 downto 0);
        wb_pc_valid: out std_logic;
        
        -- Exec stage to branch predictor (Now Delayed to Write-back stage)
        was_branch      : out std_logic;
        misprediction   : out std_logic;
        bhsr_checkpoint : out std_logic_vector(1 downto 0);
        updated_bta     : out std_logic_vector(15 downto 0);
        pc_mispred      : out std_logic_vector(15 downto 0);
		  updated_bta_valid: out std_logic;
        
        -- Write back stage to ROB for speculatives  
        tag          : out std_logic_vector(2 downto 0);
        wb_ip_rob    : out std_logic_vector(15 downto 0);
        wb_valid_rob : out std_logic;
        wb_flag_rob  : out std_logic_vector(15 downto 0);
        wb_misprediction: out std_logic;
        
        -- For accessing memory
        mem_addr       : out std_logic_vector(15 downto 0);
        mem_addr_valid : out std_logic;
        mem_din        : in  std_logic_vector(15 downto 0);
        sb_stall_pls   : in  std_logic 
    );
end entity br_pipeline;

architecture br_pipeline_struct of br_pipeline is
    constant B_TAG_WIDTH : integer := 3;
    constant CTRL_WIDTH  : integer := 20; 
    
    signal not_sb_stall_pls : std_logic;
    signal opcode           : std_logic_vector(3 downto 0);
    
    signal alu_out          : std_logic_vector(15 downto 0);
    signal alu_zero_out     : std_logic;
    signal alu_carry_out    : std_logic;
    
    signal alu_out_r0          : std_logic_vector(15 downto 0);
    signal alu_zero_out_r0     : std_logic;
    signal alu_carry_out_r0    : std_logic;
    
    signal alu_out_jump         : std_logic_vector(15 downto 0);
    signal alu_zero_out_jump     : std_logic;
    signal alu_carry_out_jump    : std_logic;
    
    signal shifted_imm      : std_logic_vector(15 downto 0);
    signal branch_address   : std_logic_vector(15 downto 0);
    signal jump_address   : std_logic_vector(15 downto 0);
    signal c_out            : std_logic;
    signal branch_taken     : std_logic;
    signal to_link          : std_logic;
    signal to_link_2        : std_logic;
    
    signal is_r0_inst       : std_logic;
    signal is_jlr_jri_inst  : std_logic;
    signal is_branch   : std_logic;
    signal misprediction_sig : std_logic;
	 
    signal final_wb:std_logic_vector(15 downto 0);
    
    -- Flag control signals
    signal inst_updates_zero  : std_logic;
    signal inst_updates_carry : std_logic;
    
    signal r0_inst_exec_mem_in : std_logic_vector(41 downto 0);
    signal br_exec_mem_in      : std_logic_vector(41 downto 0);
    signal jlr_jri_exec_mem_in : std_logic_vector(41 downto 0);
    signal exec_mem_in_base    : std_logic_vector(41 downto 0);
    
    signal exec_mem_in_final   : std_logic_vector(62+B_TAG_WIDTH+CTRL_WIDTH downto 0);
    signal exec_mem_reg_out    : std_logic_vector(62+B_TAG_WIDTH+CTRL_WIDTH downto 0);
    signal mem_wb_reg_in       : std_logic_vector(78+B_TAG_WIDTH+CTRL_WIDTH  downto 0);
    signal mem_wb_reg_out      : std_logic_vector(78+B_TAG_WIDTH+CTRL_WIDTH  downto 0);

    -- New signals for Branch Predictor Output delay (36 bits total)
    -- bit 0: was_branch
    -- bit 1: misprediction
    -- bits 3 downto 2: bhsr_checkpoint
    -- bits 19 downto 4: pc_mispred
    -- bits 35 downto 20: updated_bta
    signal bp_exec_to_mem : std_logic_vector(36 downto 0);
    signal bp_mem_to_wb   : std_logic_vector(36 downto 0);
    signal bp_wb_out      : std_logic_vector(36 downto 0);

	 signal alu_input_b: std_logic_vector(15 downto 0);
	 signal inst_add_carry,inst_is_nand,inst_comp,alu_cin:std_logic;
begin

    not_sb_stall_pls <= not sb_stall_pls;
    opcode <= br_iss_data.control(18 downto 15); 
    
    -- Extract Flag Update Control Bits 
    inst_updates_zero  <= br_iss_data.control(1);
    inst_updates_carry <= br_iss_data.control(0);

    --BRANCH OR JAL
    BR_ALU_INST: entity work.alu
    port map(
        opcode    => '0',
        inputA    => br_iss_data.op1_data,
        inputB    => br_iss_data.op2_data,
        cin       => '1', 
        comp      => '1',
        outputC   => alu_out,
        zeroflag  => alu_zero_out,
        carryflag => alu_carry_out
    );
    
    branch_decider: entity work.branch_module
    port map(
        zero       => alu_zero_out,
        overflow   => alu_out(15),
        op_code    => opcode,
        branch_res => branch_taken
    );
    
    shifted_imm <= br_iss_data.imm(14 downto 0) & '0'; 
    pc_imm_adder: entity work.n_bit_full_adder
    generic map(n => 16)
    port map(
        a     => br_iss_data.ip_addr,
        b     => shifted_imm,
        c_in  => '0',
        sum   => branch_address,
        c_out => c_out
    );
    
    to_link <= '1' when (opcode = "1100") else '0';--branch or jal writes back only if jal 
    br_exec_mem_in(15 downto 0)  <= br_iss_data.ip_addr;
    br_exec_mem_in(31 downto 16) <= std_logic_vector(unsigned(br_iss_data.ip_addr)+to_unsigned(2,16));
    br_exec_mem_in(33 downto 32) <= alu_carry_out & alu_zero_out;
    br_exec_mem_in(39 downto 34) <= br_iss_data.rrf_dest;
    br_exec_mem_in(40)           <= br_iss_valid;
    br_exec_mem_in(41)           <= to_link;
    
    --R0 WRITING
    R0_ALU_INST: entity work.alu
    port map(
        opcode    => inst_is_nand,
        inputA    => br_iss_data.op1_data,
        inputB    => alu_input_b,
        cin       => alu_cin, 
        comp      => inst_comp,
        outputC   => alu_out_r0,
        zeroflag  => alu_zero_out_r0,
        carryflag => alu_carry_out_r0
    );
	 alu_input_b<= br_iss_data.imm when (opcode="0000" or opcode="0011") else br_iss_data.op2_data;
	 inst_is_nand    <= br_iss_data.control(14);
    inst_add_carry  <= br_iss_data.control(12);
	 alu_cin <= br_iss_data.carry_flag when (inst_add_carry = '1') else '0';
    inst_comp       <= br_iss_data.control(13);

    r0_inst_exec_mem_in(15 downto 0)  <= br_iss_data.ip_addr;
    r0_inst_exec_mem_in(31 downto 16) <= alu_out_r0;
    r0_inst_exec_mem_in(33 downto 32) <= alu_carry_out_r0 & alu_zero_out_r0;
    r0_inst_exec_mem_in(39 downto 34) <= br_iss_data.rrf_dest;
    r0_inst_exec_mem_in(40)           <= br_iss_valid;
    r0_inst_exec_mem_in(41)           <= '1';--R0 always writes back
    
    --JLR AND JRI TYPE
    JUMP_ALU_INST: entity work.alu
    port map(
        opcode    => '0',
        inputA    => br_iss_data.op1_data,
        inputB    => shifted_imm,
        cin       => '0', 
        comp      => '0',
        outputC   => alu_out_jump,
        zeroflag  => alu_zero_out_jump,
        carryflag => alu_carry_out_jump
    );
    
    jump_address<=alu_out_jump when opcode(1)='1' else br_iss_data.op2_data;
    to_link_2<='1' when (opcode = "1101") else '0';
    jlr_jri_exec_mem_in(15 downto 0)  <= br_iss_data.ip_addr;
    jlr_jri_exec_mem_in(31 downto 16) <= std_logic_vector(unsigned(br_iss_data.ip_addr)+to_unsigned(2,16));
    jlr_jri_exec_mem_in(33 downto 32) <= alu_carry_out_jump & alu_zero_out_jump;
    jlr_jri_exec_mem_in(39 downto 34) <= br_iss_data.rrf_dest;
    jlr_jri_exec_mem_in(40)           <= br_iss_valid;
    jlr_jri_exec_mem_in(41)           <= to_link_2;
    
    is_branch <= '1' when ((opcode(3)='1' and opcode(2)='0') or opcode = "1100") and br_iss_valid = '1' else '0';
    is_jlr_jri_inst<= '1' when ((opcode(3)='1' and opcode(2)='1' and opcode(0)='1') and br_iss_valid = '1') else '0';
    is_r0_inst<='1' when(( is_branch='0' and is_jlr_jri_inst='0') and br_iss_valid='1') else '0';     
    misprediction_sig <= (br_iss_data.pred_dir xor (branch_taken or to_link)) and is_branch and br_iss_valid;
    
    -- Bundle the Branch Predictor Signals into bp_exec_to_mem to be pipelined
    bp_exec_to_mem(0) <= is_branch;
    bp_exec_to_mem(1) <= misprediction_sig;
    bp_exec_to_mem(3 downto 2) <= br_iss_data.control(7 downto 6);
    bp_exec_to_mem(19 downto 4) <= br_iss_data.ip_addr;
    bp_exec_to_mem(35 downto 20) <= branch_address when is_branch = '1' else alu_out_r0 when is_r0_inst='1' else jump_address;
	 bp_exec_to_mem(36)<= misprediction_sig or is_jlr_jri_inst or is_r0_inst;
		
    exec_mem_in_base <= br_exec_mem_in      when is_branch = '1' else 
                        r0_inst_exec_mem_in when is_r0_inst = '1' else 
                        jlr_jri_exec_mem_in;
                        
    --Branch and JAL: Write back nothing if branch, and link address if JAL-->Taken care by valid bit
    --R0 type: Write back whatever is required, if load type then we get mem loaded value else alu_out
    --JRI and JLR: Write back is PC+2 when JLR else nothing, handled by valid bit.
    exec_mem_in_final(41 downto 0) <= exec_mem_in_base;
    --branch tag for ROB
    exec_mem_in_final(42+B_TAG_WIDTH-1 downto 42) <= br_iss_data.branch_tag;
    --control bits for later stages
    exec_mem_in_final(42+B_TAG_WIDTH+CTRL_WIDTH-1 downto 42+B_TAG_WIDTH) <= br_iss_data.control;
    --zero dest tag for writing back flag register 
    exec_mem_in_final(47+B_TAG_WIDTH+CTRL_WIDTH downto 42+B_TAG_WIDTH+CTRL_WIDTH) <= br_iss_data.zero_dest_tag;
    --carry dest tag for writing back carry register
    exec_mem_in_final(53+B_TAG_WIDTH+CTRL_WIDTH downto 48+B_TAG_WIDTH+CTRL_WIDTH) <= br_iss_data.carry_dest_tag;
    --carry and zero writeback valid flags
    exec_mem_in_final(54+B_TAG_WIDTH+CTRL_WIDTH) <= br_iss_valid and inst_updates_zero;
    exec_mem_in_final(55+B_TAG_WIDTH+CTRL_WIDTH) <= br_iss_valid and inst_updates_carry;
    --pc dest rrf register for r0 update
    exec_mem_in_final(61+B_TAG_WIDTH+CTRL_WIDTH downto 56+B_TAG_WIDTH+CTRL_WIDTH) <= br_iss_data.pc_dest_tag;
    --For removing mispredicted instructions from ROB
    exec_mem_in_final(62+B_TAG_WIDTH+CTRL_WIDTH)<=misprediction_sig;
--============================================================================	
    -- Main Pipeline Exec-Mem Stage Register
    EXEC_MEM_REG: entity work.n_bit_register
    generic map ( n => 63+B_TAG_WIDTH+CTRL_WIDTH ) 
    port map(
        clk      => clk,                 
        reset    => rst,     
        write_en => not_sb_stall_pls,           
        data_in  => exec_mem_in_final, 
        data_out => exec_mem_reg_out
    );

    -- Parallel Pipeline Exec-Mem Stage Register for BP Signals
    BP_EXEC_MEM_REG: entity work.n_bit_register
    generic map ( n => 37 )
    port map(
        clk      => clk,
        reset    => rst,
        write_en => not_sb_stall_pls,
        data_in  => bp_exec_to_mem,
        data_out => bp_mem_to_wb
    );

    mem_addr       <= exec_mem_reg_out(31 downto 16);
    mem_addr_valid <= '1';
    mem_wb_reg_in(62+B_TAG_WIDTH+CTRL_WIDTH downto 0)  <= exec_mem_reg_out(62+B_TAG_WIDTH+CTRL_WIDTH downto 0);
    --Input from memory which is used for load
    mem_wb_reg_in(78+B_TAG_WIDTH+CTRL_WIDTH downto 63+B_TAG_WIDTH+CTRL_WIDTH) <= mem_din;
--===================================================================================================
    -- Main Pipeline Mem-WB Stage Register
    MEM_WB_REG: entity work.n_bit_register
    generic map ( n => 79+B_TAG_WIDTH+CTRL_WIDTH  ) 
    port map(
        clk      => clk,                 
        reset    => rst,     
        write_en => not_sb_stall_pls,               
        data_in  => mem_wb_reg_in,
        data_out => mem_wb_reg_out
    );

    -- Parallel Pipeline Mem-WB Stage Register for BP Signals
    BP_MEM_WB_REG: entity work.n_bit_register
    generic map ( n => 37 )
    port map(
        clk      => clk,
        reset    => rst,
        write_en => not_sb_stall_pls,
        data_in  => bp_mem_to_wb,
        data_out => bp_wb_out
    );

    -- Writeback Unpacking
    wb_ip_rob                <= mem_wb_reg_out(15 downto 0);
    wb_flag_rob(1 downto 0)  <= mem_wb_reg_out(33 downto 32);
    wb_flag_rob(15 downto 2) <= (others => '0');
    wb_valid_rob             <= mem_wb_reg_out(40);
    tag                      <= mem_wb_reg_out(42+B_TAG_WIDTH-1 downto 42);
    wb_misprediction         <= mem_wb_reg_out(62+B_TAG_WIDTH+CTRL_WIDTH);
    
    --Decides whether I give result of (alu_out/wb from branches) or (load from memory) 
    final_wb<=mem_wb_reg_out(31 downto 16) when mem_wb_reg_out(42+B_TAG_WIDTH+9)='0' else mem_wb_reg_out(78+B_TAG_WIDTH+CTRL_WIDTH downto 63+B_TAG_WIDTH+CTRL_WIDTH);
    
    wb_valid_rrf <= mem_wb_reg_out(41);
    wb_data_rrf  <= final_wb;
    wb_addr_rrf  <= mem_wb_reg_out(39 downto 34);
    
    wb_zero_flag  <= mem_wb_reg_out(32);
    -- Alu Zero Out
    wb_zero_tag   <= mem_wb_reg_out(47+B_TAG_WIDTH+CTRL_WIDTH downto 42+B_TAG_WIDTH+CTRL_WIDTH);
    wb_zero_valid <= mem_wb_reg_out(54+B_TAG_WIDTH+CTRL_WIDTH);
    
    wb_carry_flag  <= mem_wb_reg_out(33); -- Alu Carry Out
    wb_carry_tag   <= mem_wb_reg_out(53+B_TAG_WIDTH+CTRL_WIDTH downto 48+B_TAG_WIDTH+CTRL_WIDTH);
    wb_carry_valid <= mem_wb_reg_out(55+B_TAG_WIDTH+CTRL_WIDTH);
    
    wb_pc <= bp_wb_out(35 downto 20) when bp_wb_out(36)='1'--basically put updated_bta when updated_bta_valid
				else mem_wb_reg_out(15 downto 0);
    wb_pc_tag <= mem_wb_reg_out(61+B_TAG_WIDTH+CTRL_WIDTH downto 56+B_TAG_WIDTH+CTRL_WIDTH);
    wb_pc_valid <= mem_wb_reg_out(40);
    
    rs_bus(38 downto 33) <= mem_wb_reg_out(47+B_TAG_WIDTH+CTRL_WIDTH downto 42+B_TAG_WIDTH+CTRL_WIDTH); -- Zero Flag Dest Tag
    rs_bus(32 downto 27) <= mem_wb_reg_out(53+B_TAG_WIDTH+CTRL_WIDTH downto 48+B_TAG_WIDTH+CTRL_WIDTH);
    -- Carry Flag Dest Tag
    rs_bus(26)           <= mem_wb_reg_out(32);
    -- Zero Flag Value
    rs_bus(25)           <= mem_wb_reg_out(54+B_TAG_WIDTH+CTRL_WIDTH);
    -- Zero Valid
    rs_bus(24)           <= mem_wb_reg_out(33);
    -- Carry Flag Value
    rs_bus(23)           <= mem_wb_reg_out(55+B_TAG_WIDTH+CTRL_WIDTH);
    -- Carry Valid
    rs_bus(22)           <= mem_wb_reg_out(41);
    -- Result Data Valid
    rs_bus(21 downto 16) <= mem_wb_reg_out(39 downto 34);
    -- Data Dest Tag
    rs_bus(15 downto 0)  <= final_wb; -- Result Data
    

    was_branch      <= bp_wb_out(0);
    misprediction   <= bp_wb_out(1);
    bhsr_checkpoint <= bp_wb_out(3 downto 2);
    pc_mispred      <= bp_wb_out(19 downto 4);
    updated_bta     <= bp_wb_out(35 downto 20);
	 updated_bta_valid<=bp_wb_out(36);

end architecture;