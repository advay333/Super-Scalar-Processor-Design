library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pkg.all;
use work.lsu_rs_types.all;
use work.branch_rs_types.all;
use work.alu_rs_types.all;
use work.store_buffer_types.all;
use work.ROB_Queue.all;

entity datapath is
    generic (
        CONTROL_WIDTH : integer := 20
    );
    port (
        clk            : in std_logic;
        rst            : in std_logic;
        
        -- External Instruction Memory (Testbench preload interface)
        imem_wr_en        : in std_logic;
        imem_addr_control : in std_logic;
        imem_addr         : in std_logic_vector(15 downto 0);
        imem_din          : in std_logic_vector(15 downto 0);
		  
		  dmem_wr_en        : in std_logic;
        dmem_addr         : in std_logic_vector(15 downto 0);
        dmem_din          : in std_logic_vector(15 downto 0)
        

    );
end entity;

architecture struct of datapath is


    -- GLOBAL BUSES & STALL SIGNALS
    
    signal cdb_buses   : cdb_array_t;
    signal stall_fetch : std_logic;
	 signal not_stall_fetch : std_logic;
    
    -- FETCH TO DECODE SIGNALS
    
    signal fetch_inst1, fetch_inst2 : std_logic_vector(15 downto 0);
    signal fetch_pc1, fetch_pc2     : std_logic_vector(15 downto 0);
    signal bp_prediction, concat_ctag_ztag     : std_logic_vector(1 downto 0);
	 
	 
	 signal bhsr_right_now_sig : std_logic_vector(1 downto 0);
	 signal next_address_sig : std_logic_vector(15 downto 0);
    
    signal was_branch      : std_logic;
    signal misprediction, not_misprediction, updated_bta_valid_sig  : std_logic;
    signal pc_mispred      : std_logic_vector(15 downto 0);
    signal updated_bta     : std_logic_vector(15 downto 0);
    signal bhsr_checkpoint : std_logic_vector(1 downto 0);

	 
	 
    -- DECODE STAGE SIGNALS
    
    signal dec_bhsr_out : std_logic_vector(1 downto 0);
    signal dec_pred1, dec_pred2 : std_logic;
    signal and_dec_pred_2_dec_pred_1 : std_logic_vector(1 downto 0);
    -- Instruction 1 Decode
    signal dec_writes_flags_1 : std_logic_vector(1 downto 0);
    signal dec_is_load_1, dec_is_store_1, dec_writes_r0_1 : std_logic;
    signal dec_is_adc_1, dec_is_adz_1 : std_logic;
    
    -- Instruction 2 Decode
    signal dec_writes_flags_2 : std_logic_vector(1 downto 0);
    signal dec_is_load_2, dec_is_store_2, dec_writes_r0_2 : std_logic;
    signal dec_is_adc_2, dec_is_adz_2 : std_logic;
    
   
    signal control_vec_1, control_vec_2 : std_logic_vector(CONTROL_WIDTH-1 downto 0);
	 
	 
    
    -- DECODE TO DISPATCH SIGNALS 
    
    signal dec_op1, dec_op2 : std_logic_vector(3 downto 0);
    signal dec_ra1, dec_rb1, dec_ra2, dec_rb2 : std_logic_vector(5 downto 0);
    signal dec_imm1, dec_imm2 : std_logic_vector(15 downto 0);
    signal dec_dest1, dec_dest2 : std_logic_vector(2 downto 0);
    signal dec_dep_bits : std_logic_vector(1 downto 0);
    signal dec_ctrl1, dec_ctrl2 : std_logic_vector(CONTROL_WIDTH-1 downto 0);
    signal i1_rc, i1_wc, i1_rz, i1_wz, i2_rc, i2_wc, i2_rz, i2_wz : std_logic;
	 signal dec_pc2_out, dec_pc1_out : std_logic_vector(15 downto 0);
	 signal i1_isa_opcode,i2_isa_opcode:std_logic_vector(3 downto 0);
    
    -- DISPATCH OUTPUTS & RRF ALLOCATION
    
    -- Outputs from Dispatch
    signal disp_alu_vec_0, disp_alu_vec_1 : std_logic_vector(CONTROL_WIDTH + 91 downto 0);
    signal disp_lsu_vec_0, disp_lsu_vec_1 : std_logic_vector(CONTROL_WIDTH + 91 downto 0);
    signal disp_br_vec_0,  disp_br_vec_1  : std_logic_vector(CONTROL_WIDTH + 111 downto 0);
    signal disp_rob_vec_0, disp_rob_vec_1 : std_logic_vector(CONTROL_WIDTH + 47 downto 0);
    signal disp_sb_vec_0,  disp_sb_vec_1  : std_logic_vector(56 downto 0);
    
    -- Unpacked Record Types for RS/ROB
    signal alu_disp_data_0, alu_disp_data_1 : alu_rs_entry_t;
    signal lsu_disp_data_0, lsu_disp_data_1 : lsu_rs_entry_t;
    signal br_disp_data_0,  br_disp_data_1  : branch_rs_entry_t;
    signal rob_data_in_0,   rob_data_in_1   : ROB_Entry;
    signal sb_disp_data_0,  sb_disp_data_1  : store_buf_entry_t;
    
    -- Dispatch Enables
    signal alu_disp_en, lsu_disp_en, br_disp_en, sb_disp_en : std_logic_vector(1 downto 0);
    signal rob_disp_en : std_logic;

    -- Tag Management
    signal rrf_new_tag_1, rrf_new_tag_2, rrf_new_tag_3, rrf_new_tag_4 : std_logic_vector(5 downto 0);
    signal tag_alloc_en, rrf_pc_wr : std_logic_vector(3 downto 0);

    
    -- ARF / RRF / FLAG BUSES
    
    signal arf_read_addrs : std_logic_vector(11 downto 0);
    signal arf_write_tags : std_logic_vector(5 downto 0);
    signal rrf_read_addrs : std_logic_vector(23 downto 0);
    
    signal arf_d1, arf_d2, arf_d3, arf_d4 : std_logic_vector(22 downto 0);
    signal rrf_d3, rrf_d4, rrf_d5, rrf_d6 : std_logic_vector(17 downto 0);
    
	 signal zero_appended_rrf_d3, zero_appended_rrf_d4, zero_appended_rrf_d5, zero_appended_rrf_d6 : std_logic_vector(22 downto 0);
    signal c_tag_write, z_tag_write : std_logic_vector(5 downto 0);
    signal c_tag_we, z_tag_we : std_logic;
    
    signal flag_full_out : std_logic_vector(29 downto 0);
    signal arch_flag_out : std_logic_vector(15 downto 0);
    signal c_rrf_out, z_rrf_out : std_logic_vector(2 downto 0);
    signal gen_busy_bits, c_busy_bits, z_busy_bits : std_logic_vector(63 downto 0);

    
    -- SCHEDULER & PIPELINE SIGNALS
    
    
    signal alu_rs_full, lsu_rs_full, br_rs_full, rob_full, sb_full : std_logic;
    signal alu_exec_ready_0, alu_exec_ready_1, lsu_exec_ready, br_exec_ready : std_logic;
    
	 signal not_alu_rs_full, not_lsu_rs_full, not_br_rs_full, not_rob_full, not_sb_full, no_branch_in_ROB : std_logic;
	 
    -- RS Status
    signal alu_rs_array : alu_rs_array_t(0 to 7);
    signal alu_rs_ready_flags : std_logic_vector(7 downto 0);
    signal lsu_top_data : lsu_rs_entry_t;
    signal br_top_data  : branch_rs_entry_t;
    signal lsu_top_ready, lsu_top_busy, br_top_ready, br_top_busy, br_rs_empty, sb_is_empty : std_logic;
    
    -- Issue Controls
    signal alu_issue_en_0, alu_issue_en_1, lsu_deq_en, br_deq_en : std_logic;
    signal alu_issue_idx_0, alu_issue_idx_1 : integer range 0 to 7;
    signal alu_exec_valid_0, alu_exec_valid_1, lsu_exec_valid, br_exec_valid : std_logic;
    signal alu_exec_data_0, alu_exec_data_1 : alu_rs_entry_t;
    signal lsu_exec_data : lsu_rs_entry_t;
    signal br_exec_data  : branch_rs_entry_t;

    -- Pipeline Writebacks
    signal alu0_wb_addr, alu1_wb_addr, ls_wb_addr, br_wb_addr : std_logic_vector(5 downto 0);
    signal alu0_wb_data, alu1_wb_data, ls_wb_data, br_wb_data : std_logic_vector(15 downto 0);
    signal alu0_wb_val, alu1_wb_val, ls_wb_val, br_wb_val     : std_logic;
	 signal alu0_wb_pc_valid, alu1_wb_pc_valid, ls_wb_pc_valid, br_wb_pc_valid, br_wb_misprediction    : std_logic;
    signal alu0_z_tag, alu1_z_tag, ls_z_tag, br_z_tag         : std_logic_vector(5 downto 0);
    signal alu0_z_flag, alu1_z_flag, ls_z_flag, br_z_flag     : std_logic;
    signal alu0_z_val, alu1_z_val, ls_z_val, br_z_val         : std_logic;
    signal alu0_c_tag, alu1_c_tag, ls_c_tag, br_c_tag         : std_logic_vector(5 downto 0);
	 signal alu0_wb_pc_tag, alu1_wb_pc_tag, ls_wb_pc_tag, br_wb_pc_tag : std_logic_vector(5 downto 0);
    signal alu0_c_flag, alu1_c_flag, ls_c_flag, br_c_flag     : std_logic;
    signal alu0_c_val, alu1_c_val, ls_c_val, br_c_val, sb_stall_pls, is_inst_store, is_inst_load : std_logic := '0';
    signal alu0_wb_ip, alu1_wb_ip, ls_wb_ip, br_wb_ip         : std_logic_vector(15 downto 0);
	 signal alu0_wb_pc, alu1_wb_pc, ls_wb_pc, br_wb_pc : std_logic_vector(15 downto 0);
    signal alu0_wb_v_rob, alu1_wb_v_rob, ls_wb_v_rob, br_wb_v_rob : std_logic;
    signal alu0_wb_f_rob, alu1_wb_f_rob, ls_wb_f_rob, br_wb_f_rob : std_logic_vector(15 downto 0);

    
    -- COMMIT & MEMORY SIGNALS
    
    signal rob_top_data_0, rob_top_data_1 : ROB_Entry;
    signal rob_top_ready_0, rob_top_ready_1, rob_deq_0, rob_deq_1 : std_logic;
    signal br_addr_valid, store_deq_req_0, sb_commit_en : std_logic;
    signal br_mem_addr, lsu_mem_addr, sb_head_addr, sb_head_data,sb_head_ip, sb_fwd_data, sb_fwd_data_2 : std_logic_vector(15 downto 0);
    signal lsu_mem_valid, sb_head_done, sb_fwd_valid, sb_fwd_valid_2, sb_fwd_pending, sb_fwd_pending_br : std_logic;
    
    signal commit_rf_a5, commit_rf_a6, commit_rf_a7, br_pred_tag : std_logic_vector(2 downto 0);
    signal commit_rf_a5_tag, commit_rf_a6_tag, commit_rf_a7_tag : std_logic_vector(5 downto 0);
    signal commit_is_ROB_a5, commit_is_ROB_a6, commit_is_ROB_a7 : std_logic;
    signal commit_rf_d5, commit_rf_d6, commit_rf_d7 : std_logic_vector(15 downto 0);
    signal commit_is_ROB_a1, commit_is_ROB_a2, commit_is_ROB_a15, commit_is_ROB_a16 : std_logic;
    signal commit_rrf_a1, commit_rrf_a2, commit_rrf_a15, commit_rrf_a16 : std_logic_vector(5 downto 0);
    signal general_rrf_d1, general_rrf_d2, general_rrf_d15, general_rrf_d16 : std_logic_vector(17 downto 0);
    signal flag_wr_en, carry_sec_we, zero_sec_we, c_we, c_val, z_we, z_val : std_logic;
    signal c_tag, z_tag : std_logic_vector(5 downto 0);
	 
	 signal temp_exec_addr_en, temp_load_addr_valid : std_logic;
	 
    -- DATA MEMORY & FORWARDING SIGNALS
    
    signal dmem_rd_data, dmem_rd_data_br   : std_logic_vector(15 downto 0);
    signal mem_din_to_lsu, mem_din_to_br : std_logic_vector(15 downto 0);
    signal internal_sb_stall, is_lm_sm_reg : std_logic;
    
    signal mem_wr_en, mem_wr_en_1      : std_logic;
    signal mem_data_addr, mem_data_addr_1, New_Inst1, New_Inst2, inp_inst1, inp_inst2  : std_logic_vector(15 downto 0);
    signal mem_wr_data, mem_wr_data_1, Output_inst1, Output_inst2   : std_logic_vector(15 downto 0);

	 
	 -- concat signal declaration
	 			signal concat_c_tag_we, concat_z_tag_we : std_logic_vector(1 downto 0);
		signal concat_rrf_carry_wr_en, concat_rrf_zero_wr_en, Pop_Cnt : std_logic_vector(3 downto 0);
		signal concat_rrf_wr_en : std_logic_vector(7 downto 0);
		signal concat_arf_wr_en : std_logic_vector(2 downto 0);
	 
	signal i1_is_nand, i1_comp, i1_add_carry, i1_cond_carry, i1_cond_zero, pc_stall, is_lm_sm,lm_sm_rst : std_logic;
	signal i2_is_nand, i2_comp, i2_add_carry, i2_cond_carry, i2_cond_zero, lm_sm_flag_reg : std_logic;
	signal carry_tag_i1, out_imm_ls_sm, in_imm_ls_sm :  std_logic_vector(5 downto 0);
   signal carry_tag_i2 :  std_logic_vector(5 downto 0);
   signal zero_tag_i1  :  std_logic_vector(5 downto 0);
   signal zero_tag_i2  :  std_logic_vector(5 downto 0);
   signal carry_rrf_tag_enable :  std_logic_vector(1 downto 0);
   signal zero_rrf_tag_enable  :  std_logic_vector(1 downto 0);
 
	signal reg_New_Inst1 : std_logic_vector(15 downto 0);
	signal reg_New_Inst2 : std_logic_vector(15 downto 0);
	

    
	 
	 
begin



    -- CONTROL VECTOR FOR EXECUTION PIPELINES
    
    -- The Dispatch stage passes these blindly. The Execution stages unpack them.
    
    -- Packing for Instruction 1
	 control_vec_1(19)           <= '0';
    control_vec_1(18 downto 15) <= i1_isa_opcode; 
    control_vec_1(14)           <= i1_is_nand;
    control_vec_1(13)           <= i1_comp;
    control_vec_1(12)           <= i1_add_carry;
    control_vec_1(11)           <= i1_cond_carry;
    control_vec_1(10)           <= i1_cond_zero;
	 control_vec_1(9)           <= dec_is_load_1;
	 control_vec_1(8)           <= dec_is_store_1;
    control_vec_1(7 downto 6)  <= dec_bhsr_out;    -- Branch History Checkpoint
--    control_vec_1(5 downto 4)  <= "00";           
    control_vec_1(5 downto 2)  <= dec_op1;         -- Opcode
    control_vec_1(1)           <= i1_wz;           -- Zero Flag Write Enable
    control_vec_1(0)           <= i1_wc;           -- Carry Flag Write Enable

    -- Packing for Instruction 2
	 control_vec_2(19)           <='0';
    control_vec_2(18 downto 15) <= i2_isa_opcode;
    control_vec_2(14)           <= i2_is_nand;
    control_vec_2(13)           <= i2_comp;
    control_vec_2(12)           <= i2_add_carry;
    control_vec_2(11)           <= i2_cond_carry;
    control_vec_2(10)           <= i2_cond_zero;
	 control_vec_2(9)           <= dec_is_load_2;
	 control_vec_2(8)           <= dec_is_store_2; 
    control_vec_2(7 downto 6)  <= dec_bhsr_out;
--    control_vec_2(5 downto 4)  <= "00";
    control_vec_2(5 downto 2)  <= dec_op2;
    control_vec_2(1)           <= i2_wz;
    control_vec_2(0)           <= i2_wc;
	 
	 


    -- STORE-TO-LOAD FORWARDING MUX & STALL LOGIC
    
    -- If the Store Buffer has a matching address and the data is ready, 
    -- bypass the Data Memory and use the forwarded data.
    mem_din_to_lsu <= sb_fwd_data when (sb_fwd_valid = '1') else dmem_rd_data;
	 
	 mem_din_to_br <= sb_fwd_data_2 when (sb_fwd_valid_2 = '1') else dmem_rd_data_br;
    
    -- Stall the pipelines if the Store Buffer has a matching address 
    -- but the data hasn't arrived from the ALU yet.
    internal_sb_stall <= sb_fwd_pending or sb_fwd_pending_br;
	 
	 
	pc_stall <= not_stall_fetch and (not is_lm_sm);
    
    -- FETCH STAGE
    
	 not_stall_fetch <= not stall_fetch;
    u_fetch: entity work.fetch_stage
        port map (
            clk => clk, 
				rst => rst,
            pc_wr_en => pc_stall, 	-- Halts PC if Dispatch or RS queues are full
				
				
				
            -- these will come from testbench
				
            imem_wr_en => imem_wr_en, 		--
				imem_addr_control => imem_addr_control,
            imem_addr => imem_addr, 
				imem_din => imem_din,
            
				
				-- these will come branch pipeline
				
            was_branch => was_branch, 
				misprediction => misprediction,
            pc_mispred => pc_mispred, 
				updated_bta => updated_bta,
            bhsr_checkpoint => bhsr_checkpoint,
            updated_bta_valid => updated_bta_valid_sig,
				
				-- will go to fetch buffer
				
            instr1 => fetch_inst1, 
				instr2 => fetch_inst2,
            pc_out_1 => fetch_pc1, 
				pc_out_2 => fetch_pc2,
            prediction => bp_prediction,
				next_address => next_address_sig,
				bhsr_right_now => bhsr_right_now_sig
        );


    -- INSTRUCTION DECODER
    
   	 
	 lm_sm_imm_reg: entity work.n_bit_register 
		 generic map(n =>6)
		 port map (
			  clk     => clk,                 
			  reset    => rst,                  
			  write_en => '1',               
			  data_in  => out_imm_ls_sm,
			  data_out => in_imm_ls_sm 
		 );
		 
	
	lm_sm_inst1_reg: entity work.n_bit_register
		 generic map(n => 16)
		 port map(
			  clk      => clk,
			  reset    => rst,
			  write_en => '1',
			  data_in  => New_Inst1,
			  data_out => reg_New_Inst1
		 );

	lm_sm_inst2_reg: entity work.n_bit_register
		 generic map(n => 16)
		 port map(
			  clk      => clk,
			  reset    => rst,
			  write_en => '1',
			  data_in  => New_Inst2,
			  data_out => reg_New_Inst2
		 );
	process(clk)
	begin
		 if rising_edge(clk) then
			  if rst = '1' then
					is_lm_sm_reg <= '0';
			  else
					is_lm_sm_reg <= is_lm_sm;
			  end if;
		 end if;
	end process;
	
	lm_sm_mux_i1: entity work.mux16bit2to1
		 port map(
			  in0 => fetch_inst1,
			  in1 => reg_New_Inst1,   
			  sel => is_lm_sm_reg,
			  Y   => inp_inst1
		 );

	lm_sm_mux_i2: entity work.mux16bit2to1
		 port map(
			  in0 => fetch_inst2,
			  in1 => reg_New_Inst2,   
			  sel => is_lm_sm_reg,
			  Y   => inp_inst2
		 );

	 --lm_sm_rst <= not pc_stall;
	 lm_sm: entity work.Multi_Inst_Block
     port map(
				clk			=> clk,
				rst 			=> rst,
				IR1         => inp_inst1,
				IR2			 => inp_inst2,
				inp_imm     => in_imm_ls_sm,
				--lm_sm_rst   => lm_sm_rst,-- not of PC_en
				flag_reg    =>lm_sm_flag_reg,
				imm_out     => out_imm_ls_sm,
				Pop_Cnt     => Pop_Cnt,
				New_Inst1   => New_Inst1, -- goes back to IF
				New_Inst2   => New_Inst2, -- goes back to IF
				Output_Inst => Output_inst1, -- first  output instruction
				Output_Inst2 => Output_inst2,  -- second output instruction
				is_lm_sm    => is_lm_sm  -- goes into controller
				);

	 

    u_decoder: entity work.decoder
        port map (
            -- Inputs from Fetch Stage
            ir1   => Output_inst1,   
            ir2   => Output_inst2,   
            ip1   => fetch_pc1,    
            ip2   => fetch_pc2,   
            bhsr  => bhsr_right_now_sig,         
            pred1 => bp_prediction(0),
            pred2 => bp_prediction(1), 

            -- Instruction 1 Decoded Outputs
            writes_flags_1                       => dec_writes_flags_1,
            is_load_1                            => dec_is_load_1,
            is_store_1                           => dec_is_store_1,
            writes_to_r0_1                       => dec_writes_r0_1,
            is_adc_acc_ndc_ncc_1                 => dec_is_adc_1,
            is_adz_acz_ndz_ncz_1                 => dec_is_adz_1,
            addresses_of_register_to_read_from_1 => dec_ra1,
            operation_type_1                     => dec_op1,
            immediate_of_operation_1             => dec_imm1,
            address_of_register_to_write_to_1    => dec_dest1,
            i1_reads_c                           => i1_rc,
            i1_writes_c                          => i1_wc,
            i1_reads_z                           => i1_rz,
            i1_writes_z                          => i1_wz,
				i1_isa_opcode                        => i1_isa_opcode,

            -- Instruction 2 Decoded Outputs
            writes_flags_2                       => dec_writes_flags_2,
            is_load_2                            => dec_is_load_2,
            is_store_2                           => dec_is_store_2,
            writes_to_r0_2                       => dec_writes_r0_2,
            is_adc_acc_ndc_ncc_2                 => dec_is_adc_2,
            is_adz_acz_ndz_ncz_2                 => dec_is_adz_2,
            addresses_of_register_to_read_from_2 => dec_ra2,
            operation_type_2                     => dec_op2,
            immediate_of_operation_2             => dec_imm2,
            address_of_register_to_write_to_2    => dec_dest2,
            i2_reads_c                           => i2_rc,
            i2_writes_c                          => i2_wc,
            i2_reads_z                           => i2_rz,
            i2_writes_z                          => i2_wz,
				i2_isa_opcode                        => i2_isa_opcode,


            -- Dependency & Pass-through Signals
            dependency_bits => dec_dep_bits,
            ip1_out         => dec_pc1_out, -- Already routed from fetch_pc1
            ip2_out         => dec_pc2_out, -- Already routed from fetch_pc2
            bhsr_out        => dec_bhsr_out,
            pred1_out       => dec_pred1,
            pred2_out       => dec_pred2,
				
				
			  i1_is_nand =>i1_is_nand,
			  i1_comp=> i1_comp,
			  i1_add_carry=>i1_add_carry ,
			  i1_cond_carry=>i1_cond_carry,
			  i1_cond_zero=>i1_cond_zero , 
        
			  i2_is_nand=>i2_is_nand,
			  i2_comp=>i2_comp,
			  i2_add_carry=>i2_add_carry,
			  i2_cond_carry=>i2_cond_carry,
			  i2_cond_zero=>i2_cond_zero
        );
	
    
    -- DISPATCH ROUTER
    
	 not_alu_rs_full <= not alu_rs_full;
	 not_lsu_rs_full <= not lsu_rs_full;
	 not_br_rs_full <= not br_rs_full;
	 not_rob_full <= not rob_full;
	 not_sb_full <= not sb_full;
	 
    u_dispatch: entity work.dispatch_top
        generic map (control_bits_width => CONTROL_WIDTH)
        port map (
            clk => clk, 
				rst => rst,
            
            
            alu_rs_is_free => not_alu_rs_full, 
				ls_rs_is_free => not_lsu_rs_full,
            br_rs_is_free => not_br_rs_full, 
				br_rs_is_empty => no_branch_in_ROB,
            rob_is_free => not_rob_full, 
				sb_is_free => not_sb_full,
            stall_fetch => stall_fetch,

            -- Decoded Instructions
            ip1 => dec_pc1_out, 
				ip2 => dec_pc2_out,
            operation_type_1 => dec_op1, 
				operation_type_2 => dec_op2,
            addresses_of_register_to_read_from_1 => dec_ra1, 
				addresses_of_register_to_read_from_2 => dec_ra2,
            immediate_of_operation_1 => dec_imm1, 
				immediate_of_operation_2 => dec_imm2,
            address_of_register_to_write_to_1 => dec_dest1, 
				address_of_register_to_write_to_2 => dec_dest2,
            dependency_bits => dec_dep_bits, 
				control_signals_for_i1 => control_vec_1, 
				control_signals_for_i2 => control_vec_2,
            i1_reads_c => i1_rc, 
				i1_writes_c => i1_wc, 
				i1_reads_z => i1_rz, 
				i1_writes_z => i1_wz,
            i2_reads_c => i2_rc, 
				i2_writes_c => i2_wc, 
				i2_reads_z => i2_rz, 
				i2_writes_z => i2_wz,
            branch_predictor_bits => and_dec_pred_2_dec_pred_1,

            --ARF
            operand_1_register_to_read_1 => arf_d1, 
				operand_1_register_to_read_2 => arf_d2,
            operand_2_register_to_read_1 => arf_d3,
				operand_2_register_to_read_2 => arf_d4,
            cz_flag_arf_data => flag_full_out,
            read_addresses_of_arf => arf_read_addrs,
            write_tags_to_these_addresses_of_arf => arf_write_tags,

            -- RRF
            rrf_busy_bits_col => gen_busy_bits, 
				zero_flag_rrf_busy_bits_col => z_busy_bits, 
				carry_flag_rrf_busy_bits_col => c_busy_bits,
            operand_1_register_to_read_1_tag_rrf_data =>zero_appended_rrf_d6 , -- Mapping 18-bit RRF read to 23-bit dispatch expectations
            operand_1_register_to_read_2_tag_rrf_data => zero_appended_rrf_d5,
            operand_2_register_to_read_1_tag_rrf_data => zero_appended_rrf_d4,
            operand_2_register_to_read_2_tag_rrf_data => zero_appended_rrf_d3,
            c_flag_rrf_data => c_rrf_out,
				z_flag_rrf_data => z_rrf_out,
            
            read_addresses_of_rrf => rrf_read_addrs,
				carry_tag_i1 => carry_tag_i1,
				carry_tag_i2 => carry_tag_i2,
				zero_tag_i1  => zero_tag_i1,
				zero_tag_i2  => zero_tag_i2,
				carry_rrf_tag_enable => carry_rrf_tag_enable,
				zero_rrf_tag_enable  => zero_rrf_tag_enable,
            new_tags_of_rrf_for_writing_to_i1_destination => rrf_new_tag_1, 
				new_tags_of_rrf_for_writing_to_i2_destination => rrf_new_tag_2,
            new_tags_of_rrf_for_writing_to_i1_pc => rrf_new_tag_3, 
				new_tags_of_rrf_for_writing_to_i2_pc => rrf_new_tag_4,
            write_new_busy_bits_value_tags_etc_enable => tag_alloc_en,
            write_tag_to_c_flag_arf => c_tag_write, 
				write_tag_to_z_flag_arf => z_tag_write,
            c_flag_arf_write_enable => c_tag_we, 
				z_flag_arf_write_enable => z_tag_we,

            -- Outputs to RS/ROB
            data_to_write_to_alu_rs_for_i1 => disp_alu_vec_0, 
				data_to_write_to_alu_rs_for_i2 => disp_alu_vec_1, 
				alu_rs_write_enable => alu_disp_en,
            data_to_write_to_ls_rs_for_i1  => disp_lsu_vec_0, 
				data_to_write_to_ls_rs_for_i2  => disp_lsu_vec_1, 
				ls_rs_write_enable  => lsu_disp_en,
            data_to_write_to_br_rs_for_i1  => disp_br_vec_0,  
				data_to_write_to_br_rs_for_i2  => disp_br_vec_1,  
				br_rs_write_enable  => br_disp_en,
            data_to_write_to_rob_for_i1    => disp_rob_vec_0, 
				data_to_write_to_rob_for_i2    => disp_rob_vec_1, 
				rob_write_enable    => rob_disp_en,
            data_to_write_to_sb_for_i1     => disp_sb_vec_0,  
				data_to_write_to_sb_for_i2     => disp_sb_vec_1,  
				sb_write_enable     => sb_disp_en
        );
		zero_appended_rrf_d3 <= "00000"& rrf_d3;
		zero_appended_rrf_d4 <= "00000"& rrf_d4;
		zero_appended_rrf_d5 <= "00000"& rrf_d5;
		zero_appended_rrf_d6 <= "00000"& rrf_d6;
		and_dec_pred_2_dec_pred_1<= dec_pred2 & dec_pred1;
		

    process(disp_alu_vec_0, disp_alu_vec_1, disp_lsu_vec_0, disp_lsu_vec_1, 
            disp_br_vec_0, disp_br_vec_1, disp_rob_vec_0, disp_rob_vec_1, 
            disp_sb_vec_0, disp_sb_vec_1)
    begin

        -- Instruction 1
        alu_disp_data_0.busy           <= disp_alu_vec_0(41);--
        alu_disp_data_0.ip_addr        <= disp_alu_vec_0(57 downto 42);--
        alu_disp_data_0.control        <= disp_alu_vec_0(57+ CONTROL_WIDTH downto 58); -- Lower 8 bits of Control
        alu_disp_data_0.op1_data       <= disp_alu_vec_0(40 downto 25);--
        alu_disp_data_0.op1_tag        <= disp_alu_vec_0(30 downto 25);
        alu_disp_data_0.v1             <= disp_alu_vec_0(24);--
        alu_disp_data_0.op2_data       <= disp_alu_vec_0(23 downto 8);--
        alu_disp_data_0.op2_tag        <= disp_alu_vec_0(13 downto 8);
        alu_disp_data_0.v2             <= disp_alu_vec_0(7);--
        alu_disp_data_0.rrf_dest       <= disp_alu_vec_0(5 downto 0);
        
        -- Flag Extraction (from full_flags_i1)
        alu_disp_data_0.zero_flag      <= disp_alu_vec_0(58 + CONTROL_WIDTH);
        alu_disp_data_0.carry_flag     <= disp_alu_vec_0(59+ CONTROL_WIDTH);
        alu_disp_data_0.zero_valid     <= disp_alu_vec_0(60+ CONTROL_WIDTH);-- verify
        alu_disp_data_0.carry_valid    <= disp_alu_vec_0(61+ CONTROL_WIDTH);-- verify ask suketu
        alu_disp_data_0.zero_flag_tag  <= disp_alu_vec_0(67+ CONTROL_WIDTH downto 62+ CONTROL_WIDTH);
        alu_disp_data_0.carry_flag_tag <= disp_alu_vec_0(73+ CONTROL_WIDTH downto 68+ CONTROL_WIDTH);
        alu_disp_data_0.zero_dest_tag  <= disp_alu_vec_0(79+ CONTROL_WIDTH downto 74+ CONTROL_WIDTH);
        alu_disp_data_0.carry_dest_tag <= disp_alu_vec_0(85+ CONTROL_WIDTH downto 80+ CONTROL_WIDTH);
        alu_disp_data_0.pc_dest_tag    <= disp_alu_vec_0(91+ CONTROL_WIDTH downto 86+ CONTROL_WIDTH);

        -- Instruction 2
        alu_disp_data_1.busy           <= disp_alu_vec_1(41);
        alu_disp_data_1.ip_addr        <= disp_alu_vec_1(57 downto 42);
        alu_disp_data_1.control        <= disp_alu_vec_1(57+CONTROL_WIDTH downto 58);
        alu_disp_data_1.op1_data       <= disp_alu_vec_1(40 downto 25);
        alu_disp_data_1.op1_tag        <= disp_alu_vec_1(30 downto 25);
        alu_disp_data_1.v1             <= disp_alu_vec_1(24);
        alu_disp_data_1.op2_data       <= disp_alu_vec_1(23 downto 8);
        alu_disp_data_1.op2_tag        <= disp_alu_vec_1(13 downto 8);
        alu_disp_data_1.v2             <= disp_alu_vec_1(7);
        alu_disp_data_1.rrf_dest       <= disp_alu_vec_1(5 downto 0);
		  
        alu_disp_data_1.zero_flag      <= disp_alu_vec_1(58+CONTROL_WIDTH);
        alu_disp_data_1.carry_flag     <= disp_alu_vec_1(59+CONTROL_WIDTH);
        alu_disp_data_1.zero_valid     <= disp_alu_vec_1(60+CONTROL_WIDTH);
        alu_disp_data_1.carry_valid    <= disp_alu_vec_1(61+CONTROL_WIDTH);
        alu_disp_data_1.zero_flag_tag  <= disp_alu_vec_1(67+CONTROL_WIDTH downto 62+CONTROL_WIDTH);
        alu_disp_data_1.carry_flag_tag <= disp_alu_vec_1(73+CONTROL_WIDTH downto 68+CONTROL_WIDTH);
        alu_disp_data_1.zero_dest_tag  <= disp_alu_vec_1(79+CONTROL_WIDTH downto 74+CONTROL_WIDTH);
        alu_disp_data_1.carry_dest_tag <= disp_alu_vec_1(85+CONTROL_WIDTH downto 80+CONTROL_WIDTH);
        alu_disp_data_1.pc_dest_tag    <= disp_alu_vec_1(91+CONTROL_WIDTH downto 86+CONTROL_WIDTH);


        -- Instruction 1
        lsu_disp_data_0.busy           <= disp_lsu_vec_0(41);
        lsu_disp_data_0.ip_addr        <= disp_lsu_vec_0(57 downto 42);
        lsu_disp_data_0.control        <= disp_lsu_vec_0(57+CONTROL_WIDTH downto 58);
        lsu_disp_data_0.op1_data       <= disp_lsu_vec_0(40 downto 25);
        lsu_disp_data_0.op1_tag        <= disp_lsu_vec_0(30 downto 25);
        lsu_disp_data_0.v1             <= disp_lsu_vec_0(24);
        lsu_disp_data_0.op2_data       <= disp_lsu_vec_0(23 downto 8);
        lsu_disp_data_0.op2_tag        <= disp_lsu_vec_0(13 downto 8);
        lsu_disp_data_0.v2             <= disp_lsu_vec_0(7);
        lsu_disp_data_0.rrf_dest       <= disp_lsu_vec_0(5 downto 0);
        lsu_disp_data_0.imm            <= disp_lsu_vec_0(CONTROL_WIDTH + 73 downto CONTROL_WIDTH + 58);
        lsu_disp_data_0.zero_dest_tag  <= disp_lsu_vec_0(CONTROL_WIDTH + 79 downto CONTROL_WIDTH + 74);
        lsu_disp_data_0.carry_dest_tag <= disp_lsu_vec_0(CONTROL_WIDTH + 85 downto CONTROL_WIDTH + 80);
        lsu_disp_data_0.pc_dest_tag    <= disp_lsu_vec_0(CONTROL_WIDTH + 91 downto CONTROL_WIDTH + 86);

        -- Instruction 2
        lsu_disp_data_1.busy           <= disp_lsu_vec_1(41);
        lsu_disp_data_1.ip_addr        <= disp_lsu_vec_1(57 downto 42);
        lsu_disp_data_1.control        <= disp_lsu_vec_1(57+CONTROL_WIDTH downto 58);
        lsu_disp_data_1.op1_data       <= disp_lsu_vec_1(40 downto 25);
        lsu_disp_data_1.op1_tag        <= disp_lsu_vec_1(30 downto 25);
        lsu_disp_data_1.v1             <= disp_lsu_vec_1(24);
        lsu_disp_data_1.op2_data       <= disp_lsu_vec_1(23 downto 8);
        lsu_disp_data_1.op2_tag        <= disp_lsu_vec_1(13 downto 8);
        lsu_disp_data_1.v2             <= disp_lsu_vec_1(7);
        lsu_disp_data_1.rrf_dest       <= disp_lsu_vec_1(5 downto 0);
        lsu_disp_data_1.imm            <= disp_lsu_vec_1(CONTROL_WIDTH + 73 downto CONTROL_WIDTH + 58);
        lsu_disp_data_1.zero_dest_tag  <= disp_lsu_vec_1(CONTROL_WIDTH + 79 downto CONTROL_WIDTH + 74);
        lsu_disp_data_1.carry_dest_tag <= disp_lsu_vec_1(CONTROL_WIDTH + 85 downto CONTROL_WIDTH + 80);
        lsu_disp_data_1.pc_dest_tag    <= disp_lsu_vec_1(CONTROL_WIDTH + 91 downto CONTROL_WIDTH + 86);


        -- Instruction 1
        br_disp_data_0.busy           <= disp_br_vec_0(61);
        br_disp_data_0.ip_addr        <= disp_br_vec_0(77 downto 62);
        br_disp_data_0.control        <= disp_br_vec_0(77+CONTROL_WIDTH downto 78);
        br_disp_data_0.op1_data       <= disp_br_vec_0(60 downto 45);
        br_disp_data_0.op1_tag        <= disp_br_vec_0(50 downto 45);
        br_disp_data_0.v1             <= disp_br_vec_0(44);
        br_disp_data_0.op2_data       <= disp_br_vec_0(43 downto 28);
        br_disp_data_0.op2_tag        <= disp_br_vec_0(33 downto 28);
        br_disp_data_0.v2             <= disp_br_vec_0(27);
        br_disp_data_0.imm            <= disp_br_vec_0(26 downto 11);
        br_disp_data_0.rrf_dest       <= disp_br_vec_0(10 downto 5);
        br_disp_data_0.branch_tag     <= disp_br_vec_0(4 downto 2); 
        br_disp_data_0.pred_dir       <= disp_br_vec_0(0);

        br_disp_data_0.zero_flag      <= disp_br_vec_0(CONTROL_WIDTH + 78);
        br_disp_data_0.carry_flag     <= disp_br_vec_0(CONTROL_WIDTH + 79);
        br_disp_data_0.zero_valid     <= disp_br_vec_0(CONTROL_WIDTH + 80);
        br_disp_data_0.carry_valid    <= disp_br_vec_0(CONTROL_WIDTH + 81);
        br_disp_data_0.zero_flag_tag  <= disp_br_vec_0(CONTROL_WIDTH + 87 downto CONTROL_WIDTH + 82);
        br_disp_data_0.carry_flag_tag <= disp_br_vec_0(CONTROL_WIDTH + 93 downto CONTROL_WIDTH + 88);
        br_disp_data_0.zero_dest_tag  <= disp_br_vec_0(CONTROL_WIDTH + 99 downto CONTROL_WIDTH + 94);
        br_disp_data_0.carry_dest_tag <= disp_br_vec_0(CONTROL_WIDTH + 105 downto CONTROL_WIDTH + 100);
        br_disp_data_0.pc_dest_tag    <= disp_br_vec_0(CONTROL_WIDTH + 111 downto CONTROL_WIDTH + 106);

        -- Instruction 2
        br_disp_data_1.busy           <= disp_br_vec_1(61);
        br_disp_data_1.ip_addr        <= disp_br_vec_1(77 downto 62);
        br_disp_data_1.control        <= disp_br_vec_1(77+CONTROL_WIDTH downto 78);
        br_disp_data_1.op1_data       <= disp_br_vec_1(60 downto 45);
        br_disp_data_1.op1_tag        <= disp_br_vec_1(50 downto 45);
        br_disp_data_1.v1             <= disp_br_vec_1(44);
        br_disp_data_1.op2_data       <= disp_br_vec_1(43 downto 28);
        br_disp_data_1.op2_tag        <= disp_br_vec_1(33 downto 28);
        br_disp_data_1.v2             <= disp_br_vec_1(27);
        br_disp_data_1.imm            <= disp_br_vec_1(26 downto 11);
        br_disp_data_1.rrf_dest       <= disp_br_vec_1(10 downto 5);
        br_disp_data_1.branch_tag     <= disp_br_vec_1(4 downto 2); 
        br_disp_data_1.pred_dir       <= disp_br_vec_1(0);
        br_disp_data_1.zero_flag      <= disp_br_vec_1(CONTROL_WIDTH + 78);
        br_disp_data_1.carry_flag     <= disp_br_vec_1(CONTROL_WIDTH + 79);
        br_disp_data_1.zero_valid     <= disp_br_vec_1(CONTROL_WIDTH + 80);
        br_disp_data_1.carry_valid    <= disp_br_vec_1(CONTROL_WIDTH + 81);
        br_disp_data_1.zero_flag_tag  <= disp_br_vec_1(CONTROL_WIDTH + 87 downto CONTROL_WIDTH + 82);
        br_disp_data_1.carry_flag_tag <= disp_br_vec_1(CONTROL_WIDTH + 93 downto CONTROL_WIDTH + 88);
        br_disp_data_1.zero_dest_tag  <= disp_br_vec_1(CONTROL_WIDTH + 99 downto CONTROL_WIDTH + 94);
        br_disp_data_1.carry_dest_tag <= disp_br_vec_1(CONTROL_WIDTH + 105 downto CONTROL_WIDTH + 100);
        br_disp_data_1.pc_dest_tag    <= disp_br_vec_1(CONTROL_WIDTH + 111 downto CONTROL_WIDTH + 106);


        -- Instruction 1
        rob_data_in_0.busy                                <= '1';
        rob_data_in_0.ip_addr                             <= disp_rob_vec_0(47 downto 32);
        rob_data_in_0.control_signal                      <= disp_rob_vec_0(47+CONTROL_WIDTH downto 48);
        rob_data_in_0.Is_This_A_Part_Of_Unresolved_Branch <= disp_rob_vec_0(31);
        rob_data_in_0.ARF_Dest                            <= disp_rob_vec_0(30 downto 28);
        rob_data_in_0.RRF_Dest                            <= disp_rob_vec_0(27 downto 22);
        rob_data_in_0.Tag                                 <= disp_rob_vec_0(21 downto 19);
        rob_data_in_0.Inst_Write_Back_Karna_Hai_Kya       <= disp_rob_vec_0(18); 
        rob_data_in_0.Inst_Execute_Hogaya_Kya             <= '0';
		  rob_data_in_0.WB_to_R0									 <= '0';
		  rob_data_in_0.WB_to_Dest									 <= '0';
        rob_data_in_0.Flag_Register                       <= (others => '0');
        rob_data_in_0.RRF_Dest_PC                         <= rrf_new_tag_3;
        rob_data_in_0.RRF_Carry                           <= carry_tag_i1; 
        rob_data_in_0.RRF_Zero                            <= zero_tag_i1;

        -- Instruction 2
        rob_data_in_1.busy                                <= '1';
        rob_data_in_1.ip_addr                             <= disp_rob_vec_1(47 downto 32);
        rob_data_in_1.control_signal                      <= disp_rob_vec_1(47+CONTROL_WIDTH downto 48);
        rob_data_in_1.Is_This_A_Part_Of_Unresolved_Branch <= disp_rob_vec_1(31);
        rob_data_in_1.ARF_Dest                            <= disp_rob_vec_1(30 downto 28);
        rob_data_in_1.RRF_Dest                            <= disp_rob_vec_1(27 downto 22);
        rob_data_in_1.Tag                                 <= disp_rob_vec_1(21 downto 19);
        rob_data_in_1.Inst_Write_Back_Karna_Hai_Kya       <= disp_rob_vec_1(18); 
        rob_data_in_1.Inst_Execute_Hogaya_Kya             <= '0';
		  rob_data_in_1.WB_to_R0									 <= '0';
		  rob_data_in_1.WB_to_Dest									 <= '0';
        rob_data_in_1.Flag_Register                       <= (others => '0');
        rob_data_in_1.RRF_Dest_PC                         <= rrf_new_tag_4;
        rob_data_in_1.RRF_Carry                           <= carry_tag_i2;
        rob_data_in_1.RRF_Zero                            <= zero_tag_i2;


        -- Instruction 1
        sb_disp_data_0.busy       <= disp_sb_vec_0(56);
        sb_disp_data_0.ip_addr    <= disp_sb_vec_0(55 downto 40);
        sb_disp_data_0.addr       <= disp_sb_vec_0(39 downto 24);
        sb_disp_data_0.v1         <= disp_sb_vec_0(23);
        sb_disp_data_0.data       <= disp_sb_vec_0(22 downto 7);
        sb_disp_data_0.data_tag   <= disp_sb_vec_0(6 downto 1);
        sb_disp_data_0.v2         <= disp_sb_vec_0(0);

        -- Instruction 2
        sb_disp_data_1.busy       <= disp_sb_vec_1(56);
        sb_disp_data_1.ip_addr    <= disp_sb_vec_1(55 downto 40);
        sb_disp_data_1.addr       <= disp_sb_vec_1(39 downto 24);
        sb_disp_data_1.v1         <= disp_sb_vec_1(23);
        sb_disp_data_1.data       <= disp_sb_vec_1(22 downto 7);
        sb_disp_data_1.data_tag   <= disp_sb_vec_1(6 downto 1);
        sb_disp_data_1.v2         <= disp_sb_vec_1(0);
    end process;


    u_alu_rs: entity work.alu_reservation_station
        generic map (RS_DEPTH => 8)
        port map (clk=>clk, 
						rst=>rst, 
						cdb_buses=>cdb_buses, 
						dispatch_en_0=>alu_disp_en(0), 
						dispatch_data_0=>alu_disp_data_0, 
						dispatch_en_1=>alu_disp_en(1), 
						dispatch_data_1=>alu_disp_data_1, 
						issue_en_0=>alu_issue_en_0, 
						issue_idx_0=>alu_issue_idx_0, 
						issue_en_1=>alu_issue_en_1, 
						issue_idx_1=>alu_issue_idx_1, 
						rs_array=>alu_rs_array, 
						rs_ready_flags=>alu_rs_ready_flags, 
						queue_full=>alu_rs_full
						);

    u_alu_scheduler: entity work.alu_scheduler
        generic map (RS_DEPTH => 8)
        port map (rs_array=>alu_rs_array, 
						rs_ready_flags=>alu_rs_ready_flags, 
						exec_ready_0=>alu_exec_ready_0, 
						exec_ready_1=>alu_exec_ready_1, 
						issue_en_0=>alu_issue_en_0, 
						issue_idx_0=>alu_issue_idx_0, 
						issue_en_1=>alu_issue_en_1, 
						issue_idx_1=>alu_issue_idx_1, 
						issue_valid_0=>alu_exec_valid_0, 
						issue_data_0=>alu_exec_data_0, 
						issue_valid_1=>alu_exec_valid_1, 
						issue_data_1=>alu_exec_data_1
						);

    u_lsu_rs: entity work.lsu_reservation_station
        generic map (RS_DEPTH => 8)
        port map (clk=>clk, rst=>rst, 
						cdb_buses=>cdb_buses, 
						enq_en_0=>lsu_disp_en(0), 
						data_in_0=>lsu_disp_data_0, 
						enq_en_1=>lsu_disp_en(1), 
						data_in_1=>lsu_disp_data_1, 
						deq_en=>lsu_deq_en, 
						top_data=>lsu_top_data, 
						top_ready=>lsu_top_ready, 
						top_busy=>lsu_top_busy, 
						queue_full=>lsu_rs_full
						);

    u_lsu_scheduler: entity work.lsu_scheduler
        port map (
		  top_data=>lsu_top_data, 
		  top_ready=>lsu_top_ready, 
		  top_busy=>lsu_top_busy, 
		  exec_ready=>lsu_exec_ready, 
		  deq_en=>lsu_deq_en, 
		  issue_valid=>lsu_exec_valid, 
		  issue_data=>lsu_exec_data
		  );

    u_branch_rs: entity work.branch_reservation_station
        generic map (RS_DEPTH => 8)
        port map (clk=>clk, 
						rst=>rst, 
						cdb_buses=>cdb_buses, 
						enq_en_0=>br_disp_en(0), 
						data_in_0=>br_disp_data_0, 
						enq_en_1=>br_disp_en(1), 
						data_in_1=>br_disp_data_1, 
						deq_en=>br_deq_en, 
						top_data=>br_top_data, 
						top_ready=>br_top_ready, 
						top_busy=>br_top_busy, 
						queue_full=>br_rs_full, 
						is_empty=>br_rs_empty
						);
	
    u_branch_scheduler: entity work.branch_scheduler
        port map (top_data=>br_top_data, 
						top_ready=>br_top_ready, 
						top_busy=>br_top_busy, 
						exec_ready=>br_exec_ready, 
						deq_en=>br_deq_en, 
						issue_valid=>br_exec_valid, 
						issue_data=>br_exec_data
						);

  
    --  EXECUTION PIPELINES

    u_alu_pipeline_0: entity work.alu_pipeline
        port map (clk=>clk, 
						rst=>rst, 
						alu_iss_valid=>alu_exec_valid_0, 
						alu_iss_data=>alu_exec_data_0, 
						rs_bus=>cdb_buses(0), 
						wb_addr_rrf=>alu0_wb_addr, 
						wb_data_rrf=>alu0_wb_data, 
						wb_valid_rrf=>alu0_wb_val, 
						wb_zero_flag=>alu0_z_flag, 
						wb_zero_tag=>alu0_z_tag, 
						wb_zero_valid=>alu0_z_val, 
						wb_carry_flag=>alu0_c_flag, 
						wb_carry_tag=>alu0_c_tag, 
						wb_carry_valid=>alu0_c_val, 
						wb_ip_rob=>alu0_wb_ip, 
						wb_valid_rob=>alu0_wb_v_rob, 
						wb_flag_rob=>alu0_wb_f_rob, 
						wb_pc=>alu0_wb_pc, 
						wb_pc_tag=>alu0_wb_pc_tag, 
						wb_pc_valid=>alu0_wb_pc_valid
						
						);
						
						
    u_alu_pipeline_1: entity work.alu_pipeline
        port map (clk=>clk, 
						rst=>rst, 
						alu_iss_valid=>alu_exec_valid_1, 
						alu_iss_data=>alu_exec_data_1, 
						rs_bus=>cdb_buses(1), 
						wb_addr_rrf=>alu1_wb_addr, 
						wb_data_rrf=>alu1_wb_data, 
						wb_valid_rrf=>alu1_wb_val, 
						wb_zero_flag=>alu1_z_flag, 
						wb_zero_tag=>alu1_z_tag, 
						wb_zero_valid=>alu1_z_val, 
						wb_carry_flag=>alu1_c_flag, 
						wb_carry_tag=>alu1_c_tag, 
						wb_carry_valid=>alu1_c_val, 
						wb_ip_rob=>alu1_wb_ip, 
						wb_valid_rob=>alu1_wb_v_rob, 
						wb_flag_rob=>alu1_wb_f_rob, 
						wb_pc=>alu1_wb_pc, 
						wb_pc_tag=>alu1_wb_pc_tag, 
						wb_pc_valid=>alu1_wb_pc_valid
						);
						
						
    alu_exec_ready_0 <= '1'; alu_exec_ready_1 <= '1';

    u_ls_pipeline: entity work.ls_pipeline
        port map (clk=>clk, 
						rst=>rst, 
						ls_iss_valid=>lsu_exec_valid, 
						ls_iss_data=>lsu_exec_data, 
						rs_bus=>cdb_buses(2), 
						wb_addr_rrf=>ls_wb_addr, 
						wb_data_rrf=>ls_wb_data, 
						wb_valid_rrf=>ls_wb_val, 
						wb_zero_flag=>ls_z_flag,
						wb_zero_tag=>ls_z_tag, 
						wb_zero_valid=>ls_z_val, 
						wb_carry_flag=>ls_c_flag, 
						wb_carry_tag=>ls_c_tag, 
						wb_carry_valid=>ls_c_val, 
						wb_ip_rob=>ls_wb_ip, 
						wb_valid_rob=>ls_wb_v_rob, 
						wb_flag_rob=>ls_wb_f_rob, 
						wb_pc=>ls_wb_pc, 
						wb_pc_tag=>ls_wb_pc_tag, 
						wb_pc_valid=>ls_wb_pc_valid, 
						mem_addr=>lsu_mem_addr, 
						mem_addr_valid=>lsu_mem_valid, 
						mem_din=>mem_din_to_lsu, 
						sb_stall_pls=>sb_fwd_pending,
						is_inst_store => is_inst_store,
						is_inst_load => is_inst_load
						);
						
    lsu_exec_ready <= not sb_fwd_pending;

    u_br_pipeline: entity work.br_pipeline
        port map (clk=>clk, 
						rst=>rst, 
						
						br_iss_valid=>br_exec_valid, 
						br_iss_data=>br_exec_data, 
						rs_bus=>cdb_buses(3), 
						wb_addr_rrf=>br_wb_addr, 
						wb_data_rrf=>br_wb_data, 
						wb_valid_rrf=>br_wb_val, 
						wb_zero_flag=>br_z_flag, 
						wb_zero_tag=>br_z_tag, 
						wb_zero_valid=>br_z_val, 
						wb_carry_flag=>br_c_flag, 
						wb_carry_tag=>br_c_tag, 
						wb_carry_valid=>br_c_val, 
						wb_ip_rob=>br_wb_ip, 
						wb_valid_rob=>br_wb_v_rob, 
						wb_flag_rob=>br_wb_f_rob, 
						wb_pc=>br_wb_pc, 
						wb_pc_tag=>br_wb_pc_tag, 
						wb_pc_valid=>br_wb_pc_valid,
						wb_misprediction => br_wb_misprediction,
						was_branch=>was_branch, 
						misprediction=>misprediction, 
						bhsr_checkpoint=>bhsr_checkpoint, 
						updated_bta=>updated_bta,
						updated_bta_valid => updated_bta_valid_sig,
						pc_mispred=>pc_mispred, 
						tag=>br_pred_tag, 
						mem_addr=>br_mem_addr, 
						mem_addr_valid=>br_addr_valid, 
						mem_din=>mem_din_to_br, 
						sb_stall_pls=>sb_fwd_pending_br
						);
						
    br_exec_ready <= not sb_fwd_pending_br;


    -- DATA MEMORY
    u_data_memory: entity work.data_memory
        generic map (
            ADDR_WIDTH => 9,  
            DATA_WIDTH => 16
        )
        port map (
            clk       => clk,
            
            
            rd_addr1   => lsu_mem_addr,
            rd_data1   => dmem_rd_data,
            
				rd_addr2   => br_mem_addr,
            rd_data2   => dmem_rd_data_br,
				
          
            wr_en_0   => mem_wr_en,
            wr_addr_0 => mem_data_addr,
            wr_data_0 => mem_wr_data,
				
				wr_en_1   => dmem_wr_en,
            wr_addr_1 => dmem_addr ,
            wr_data_1 => dmem_din
            
        );
   
	
	
	
	
	
    u_rob: entity work.ROB
        generic map (ROB_DEPTH => 8)
        port map (clk=>clk, 
						rst=>rst, 
						enq_en_0=>rob_disp_en, 
						data_in_0=>rob_data_in_0, 
						enq_en_1=>rob_disp_en, 
						data_in_1=>rob_data_in_1, 
						queue_full=>rob_full, 
						top_busy=>open, 
						top_data_0=>rob_top_data_0, 
						top_ready_0=>rob_top_ready_0, 
						deq_en_0=>rob_deq_0, 
						top_data_1=>rob_top_data_1, 
						top_ready_1=>rob_top_ready_1, 
						deq_en_1=>rob_deq_1, 
						ip_addr_alu1=>alu0_wb_ip,
					   alu1_wb_pc => alu0_wb_pc_valid,
						alu1_wb_arf =>alu0_wb_val,
						done_alu1=>alu0_wb_v_rob, 
						flag_alu1=>alu0_wb_f_rob,
					   alu1_wb_pc_tag => alu0_wb_pc_tag,	
						ip_addr_alu2=>alu1_wb_ip, 
					   alu2_wb_pc => alu1_wb_pc_valid,
						alu2_wb_arf =>alu1_wb_val,
						done_alu2=>alu1_wb_v_rob, 
						flag_alu2=>alu1_wb_f_rob,
						alu2_wb_pc_tag => alu1_wb_pc_tag,
						ip_addr_load=>ls_wb_ip, 
					   load_wb_pc => ls_wb_pc_valid,
						load_wb_pc_tag => ls_wb_pc_tag,
						load_wb_arf => ls_wb_val,						
						done_load=>ls_wb_v_rob, 
						flag_load=>ls_wb_f_rob, 
						ip_addr_store=>br_wb_ip, 
					   store_wb_pc => ls_wb_pc_valid,
						store_wb_pc_tag => ls_wb_pc_tag,
						store_wb_arf => '0',						
						done_store=>br_wb_v_rob, 
						flag_store=>br_wb_f_rob, 
						ip_addr_br=>br_wb_ip, 
					   br_wb_pc => br_wb_pc_valid,
						br_wb_arf => br_wb_val,
						br_wb_pc_tag => br_wb_pc_tag,
						done_br=>br_wb_v_rob, 
						flag_br=>br_wb_f_rob, 
						branch_correct_predicted=>not_misprediction, 
						branch_tag=>br_pred_tag,
						not_branch_in_ROB => no_branch_in_ROB
						
						);
			not_misprediction <= not (br_wb_misprediction or updated_bta_valid_sig);
			
    u_store_buffer: entity work.store_buffer
        generic map (SB_DEPTH => 8)
        port map (clk=>clk, 
						rst=>rst, 
						cdb_buses=>cdb_buses, 
						disp_en_0=>sb_disp_en(0), 
						disp_data_0=>sb_disp_data_0, 
						disp_en_1=>sb_disp_en(1), 
						disp_data_1=>sb_disp_data_1, 
						queue_full=>sb_full, 
						exec_addr_en=> temp_exec_addr_en, 
						exec_addr=>lsu_mem_addr, 
						br_addr_valid => br_addr_valid,
						br_addr => br_mem_addr,
						load_addr_valid=>temp_load_addr_valid, 
						load_addr=>lsu_mem_addr, 
						fwd_valid=>sb_fwd_valid, 
						fwd_data=>sb_fwd_data, 
						fwd_valid_br => sb_fwd_valid_2,
						fwd_data_br => sb_fwd_data_2,
						fwd_pending=>sb_fwd_pending,
						fwd_pending_br => sb_fwd_pending_br,
						commit_en=>sb_commit_en, 
						head_ip=>sb_head_ip, 
						head_addr=>sb_head_addr, 
						head_data=>sb_head_data, 
						head_done=>sb_head_done, 
						is_empty=>sb_is_empty
						);

						temp_load_addr_valid <= is_inst_load and lsu_mem_valid;
						temp_exec_addr_en <= is_inst_store and lsu_mem_valid;
    u_store_retire: entity work.Store_Retire_Controller
        port map (rob_top_data_0=>rob_top_data_0, 
						sb_head_ip=>sb_head_ip, 
						sb_head_addr=>sb_head_addr, 
						sb_head_data=>sb_head_data, 
						sb_head_done=>sb_head_done, 
						sb_is_empty=>sb_is_empty, 
						mem_wr_en=>mem_wr_en, 
						mem_data_addr=>mem_data_addr, 
						mem_data=>mem_wr_data, 
						sb_commit_en=>sb_commit_en, 
						store_deq_req_0=>store_deq_req_0
						);

    u_commit: entity work.Commit_From_ROB
        port map (clk=>clk, 
						rst=>rst, 
						top_data_0=>rob_top_data_0, 
						top_ready_0=>rob_top_ready_0, 
						deq_en_0=>rob_deq_0, 
						top_data_1=>rob_top_data_1, 
						top_ready_1=>rob_top_ready_1, 
						deq_en_1=>rob_deq_1, 
						rf_a5=>commit_rf_a5, 
						rf_a5_tag=>commit_rf_a5_tag, 
						is_ROB_a5=>commit_is_ROB_a5, 
						rf_a6=>commit_rf_a6, 
						rf_a6_tag=>commit_rf_a6_tag, 
						is_ROB_a6=>commit_is_ROB_a6, 
						rf_a7=>commit_rf_a7, 
						rf_a7_tag=>commit_rf_a7_tag, 
						is_ROB_a7=>commit_is_ROB_a7, 
						rf_d5=>commit_rf_d5, 
						rf_d6=>commit_rf_d6, 
						rf_d7=>commit_rf_d7, 
						is_ROB_a1=>commit_is_ROB_a1, 
						is_ROB_a2=>commit_is_ROB_a2, 
						is_ROB_a15=>commit_is_ROB_a15, 
						is_ROB_a16=>commit_is_ROB_a16, 
						rrf_a1=>commit_rrf_a1, 
						rrf_a2=>commit_rrf_a2, 
						rrf_a15=>commit_rrf_a15, 
						rrf_a16=>commit_rrf_a16, 
						rrf_d1=>general_rrf_d1, 
						rrf_d2=>general_rrf_d2, 
						rrf_d15=>general_rrf_d15, 
						rrf_d16=>general_rrf_d16,
						commit_c_we=>c_we, 
						commit_c_val=>c_val, 
						commit_c_tag=>c_tag, 
						commit_z_we=>z_we, 
						commit_z_val=>z_val, 
						commit_z_tag=>z_tag, 
						store_deq_req_0=>store_deq_req_0
						);
	concat_arf_wr_en <= commit_is_ROB_a7 & commit_is_ROB_a6 & commit_is_ROB_a5;
	

    u_arf: entity work.ARF
        port map (clk=>clk, 
						rst=>rst, 
						rf_wr_en=>concat_arf_wr_en, 
						rf_a5=>commit_rf_a5, 
						rf_a5_tag=>commit_rf_a5_tag, 
						is_ROB_a5=>commit_is_ROB_a5, 
						rf_d5=>commit_rf_d5, 
						 
						rf_a6=>commit_rf_a6, 
						rf_a6_tag=>commit_rf_a6_tag, 
						is_ROB_a6=>commit_is_ROB_a6, 
						rf_d6=>commit_rf_d6, 
						
						rf_a7=>commit_rf_a7, 
						rf_a7_tag=>commit_rf_a7_tag, 
						is_ROB_a7=>commit_is_ROB_a7, 
						rf_d7=>commit_rf_d7, 
						rf_a1=>arf_read_addrs(11 downto 9), 
						rf_a2=>arf_read_addrs(8 downto 6), 
						rf_a3=>arf_read_addrs(5 downto 3), 
						rf_a4=>arf_read_addrs(2 downto 0), 
						rf_d1=>arf_d1, 
						rf_d2=>arf_d2, 
						rf_d3=>arf_d3, 
						rf_d4=>arf_d4, 
						tag_address=>arf_write_tags, 
						rrf_new_tag_1=>rrf_new_tag_1, 
						rrf_new_tag_2=>rrf_new_tag_2, 
						rrf_new_tag_3=>rrf_new_tag_4, --intentional because of internal working
						rrf_new_tag_4=>rrf_new_tag_3, --intentional because of internal working
						rrf_new_tag_enable=>tag_alloc_en
						);
	rrf_pc_wr <=   br_wb_pc_valid & ls_wb_pc_valid & alu1_wb_pc_valid & alu0_wb_pc_valid ;
	concat_rrf_wr_en <= rrf_pc_wr & br_wb_val & ls_wb_val & alu1_wb_val & alu0_wb_val;
	
	
    u_general_rrf: entity work.RRF
        port map (clk=>clk, 
						rst=>rst, 
						rrf_wr_en=>concat_rrf_wr_en, 
						rrf_a7=>alu0_wb_addr, 
						rrf_d7=>alu0_wb_data, 
						
						rrf_a8=>alu1_wb_addr, 
						rrf_d8=>alu1_wb_data, 
						
						rrf_a9=>ls_wb_addr, 
						rrf_d9=>ls_wb_data, 
						 
						rrf_a10=>br_wb_addr, 
						rrf_d10=>br_wb_data, 
						
						rrf_a11=>alu0_wb_pc_tag, 
						rrf_a12=>alu1_wb_pc_tag, 
						rrf_a13=>ls_wb_pc_tag, 
						rrf_a14=>br_wb_pc_tag, 
						rrf_d11=>alu0_wb_pc, 
						rrf_d12=>alu1_wb_pc, 
						rrf_d13=>ls_wb_pc, 
						rrf_d14=>br_wb_pc, 
						is_ROB_a1=>commit_is_ROB_a1, 
						rrf_a1=>commit_rrf_a1, 
						rrf_d1=>general_rrf_d1, 
						is_ROB_a2=>commit_is_ROB_a2, 
						rrf_a2=>commit_rrf_a2, 
						rrf_d2=>general_rrf_d2, 
						is_ROB_a15=>commit_is_ROB_a15, 
						rrf_a15=>commit_rrf_a15, 
						rrf_d15=>general_rrf_d15, 
						is_ROB_a16=>commit_is_ROB_a16, 
						rrf_a16=>commit_rrf_a16, 
						rrf_d16=>general_rrf_d16, 
						rrf_a3=>rrf_read_addrs(23 downto 18), 
						rrf_a4=>rrf_read_addrs(17 downto 12), 
						rrf_a5=>rrf_read_addrs(11 downto 6), 
						rrf_a6=>rrf_read_addrs(5 downto 0), 
						rrf_d3=>rrf_d3, 
						rrf_d4=>rrf_d4, 
						rrf_d5=>rrf_d5, 
						rrf_d6=>rrf_d6, 
						rrf_new_tag_1=>rrf_new_tag_1, 
						rrf_new_tag_2=>rrf_new_tag_2, 
						rrf_new_tag_3=>rrf_new_tag_3, 
						rrf_new_tag_4=>rrf_new_tag_4, 
						rrf_new_tag_enable=>tag_alloc_en, 
						Busy_Bit_Array=>gen_busy_bits
						);

    u_flag_register: entity work.Flag_Register
        port map (clk=>clk, 
						rst=>rst, 
						commit_c_we=>c_we, 
						commit_c_val=>c_val, 
						commit_c_tag=>c_tag, 
						commit_z_we=>z_we, 
						commit_z_val=>z_val, 
						commit_z_tag=>z_tag, 
						rrf_new_tag_z=>z_tag_write, 
						rrf_new_tag_c=>c_tag_write, 
						rrf_new_tag_en=>concat_ctag_ztag, 
						flag_full_out=>flag_full_out, 
						only_value_out=>arch_flag_out
						);
						
						concat_ctag_ztag <= c_tag_we & z_tag_we;
		concat_rrf_zero_wr_en <= br_z_val & ls_z_val & alu1_z_val & alu0_z_val;
    u_zero_rrf: entity work.RRF_zero
        port map (clk=>clk, 
						rst=>rst, 
						rrf_wr_en=>concat_rrf_zero_wr_en, 
						rrf_a7=>alu0_z_tag, 
						rrf_d7=>alu0_z_flag, 
						 
						rrf_a8=>alu1_z_tag, 
						rrf_d8=>alu1_z_flag, 
						
						rrf_a9=>ls_z_tag, 
						rrf_d9=>ls_z_flag, 
						
						rrf_a10=>br_z_tag, 
						rrf_d10=>br_z_flag, 
						is_ROB_a1=>rob_top_data_0.control_signal(1), 
						rrf_a1=>rob_top_data_0.RRF_Zero, 
						is_ROB_a2=>rob_top_data_1.control_signal(1), 
						rrf_a2=>rob_top_data_1.RRF_Zero,  
						rrf_a3=>"000000", 
						rrf_a4=>"000000", 
						rrf_a5=>flag_full_out(21 downto 16), 
						rrf_a6=>"000000", 
						rrf_d1=>open, 
						rrf_d2=>open, 
						rrf_d3=>open, 
						rrf_d4=>open, 
						rrf_d5=>z_rrf_out, 
						rrf_d6=>open, 
						rrf_new_tag_1=>zero_tag_i1, 
						rrf_new_tag_2=>zero_tag_i2, 
						rrf_new_tag_enable=>zero_rrf_tag_enable, 
						Busy_Bit_Array=>z_busy_bits
						);
						
						
		concat_rrf_carry_wr_en <= br_c_val & ls_c_val & alu1_c_val & alu0_c_val;
		
		

    u_carry_rrf: entity work.RRF_carry
        port map (clk=>clk, 
						rst=>rst, 
						rrf_wr_en=>concat_rrf_carry_wr_en, 
						rrf_a7=>alu0_c_tag, 
						rrf_d7=>alu0_c_flag, 
						 
						rrf_a8=>alu1_c_tag, 
						rrf_d8=>alu1_c_flag, 
						
						rrf_a9=>ls_c_tag,
						rrf_d9=>ls_c_flag, 
						 
						rrf_a10=>br_c_tag, 
						rrf_d10=>br_c_flag, 
						is_ROB_a1=>rob_top_data_0.control_signal(0), 
						rrf_a1=>rob_top_data_0.RRF_Carry, 
						is_ROB_a2=>rob_top_data_1.control_signal(0), 
						rrf_a2=>rob_top_data_1.RRF_Carry,  
						rrf_a3=>"000000", 
						rrf_a4=>"000000", 
						rrf_a5=>flag_full_out(27 downto 22), 
						rrf_a6=>"000000", 
						rrf_d1=>open, 
						rrf_d2=>open, 
						rrf_d3=>open, 
						rrf_d4=>open, 
						rrf_d5=>c_rrf_out, 
						rrf_d6=>open, 
						rrf_new_tag_1=>carry_tag_i1, 
						rrf_new_tag_2=>carry_tag_i2, 
						rrf_new_tag_enable=> carry_rrf_tag_enable, 
						Busy_Bit_Array=>c_busy_bits
						);
			
			
			
			
end architecture;