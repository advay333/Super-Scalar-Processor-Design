library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ROB_Queue.all;

entity Commit_From_ROB is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
		  --ROB
        top_data_0               : in ROB_Entry;
        top_ready_0              : in std_logic;
        deq_en_0                 : out  std_logic;
        top_data_1               : in ROB_Entry;
        top_ready_1              : in std_logic;
		  deq_en_1                 : out std_logic;
		  
		  --ARF
		  rf_a5    : out  STD_LOGIC_VECTOR(2 downto 0);
		  rf_a5_tag: out STD_LOGIC_VECTOR(5 downto 0);
		  is_ROB_a5: out STD_LOGIC;
        rf_a6    : out STD_LOGIC_VECTOR(2 downto 0);
		  rf_a6_tag: out STD_LOGIC_VECTOR(5 downto 0);
		  is_ROB_a6: out STD_LOGIC;
		  rf_a7    : out STD_LOGIC_VECTOR(2 downto 0);
		  rf_a7_tag: out STD_LOGIC_VECTOR(5 downto 0);
		  is_ROB_a7: out STD_LOGIC;
        rf_d5    : out STD_LOGIC_VECTOR(15 downto 0);
        rf_d6    : out STD_LOGIC_VECTOR(15 downto 0);
		  rf_d7    : out STD_LOGIC_VECTOR(15 downto 0);
		  
		  --RRF
		  is_ROB_a1 : out STD_LOGIC; 
		  is_ROB_a2 : out STD_LOGIC; 
		  is_ROB_a15: out STD_LOGIC; 
		  is_ROB_a16: out STD_LOGIC; 
		  
		  rrf_a1    : out  STD_LOGIC_VECTOR(5 downto 0); 
        rrf_a2    : out  STD_LOGIC_VECTOR(5 downto 0);
		  rrf_a15   : out  STD_LOGIC_VECTOR(5 downto 0); 
        rrf_a16   : out  STD_LOGIC_VECTOR(5 downto 0);
		  
		  rrf_d1    : in STD_LOGIC_VECTOR(17 downto 0);
        rrf_d2    : in STD_LOGIC_VECTOR(17 downto 0);
		  rrf_d15   : in STD_LOGIC_VECTOR(17 downto 0);
        rrf_d16   : in STD_LOGIC_VECTOR(17 downto 0);
		  
		  
		  --write to flag
		  
		 commit_c_we  : out STD_LOGIC;
    
		 commit_c_val : out STD_LOGIC;  
		 commit_c_tag : out STD_LOGIC_VECTOR(5 downto 0);
		 
		 commit_z_we  : out STD_LOGIC;
		 commit_z_val : out STD_LOGIC;  
		 commit_z_tag : out STD_LOGIC_VECTOR(5 downto 0);
		  
		 store_deq_req_0: in std_logic
		  
    );
end entity;

architecture design of Commit_From_ROB is
    type reg_array is array (0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
    signal registers : reg_array := (others => (others => '0'));
	 signal rrf_d1_sig: std_logic_vector(15 downto 0):= rrf_d1(16 downto 1);
	 signal rrf_d2_sig: std_logic_vector(15 downto 0):= rrf_d2(16 downto 1);
	 signal rrf_d15_sig: std_logic_vector(15 downto 0):= rrf_d15(16 downto 1);
	 signal rrf_d16_sig: std_logic_vector(15 downto 0):= rrf_d16(16 downto 1);
	signal sel : std_logic_vector(5 downto 0);
	signal sel2 : std_logic_vector(1 downto 0);
	signal flag_wr_en0, flag_wr_en1 :std_logic; ---as of now just made a signal, later will take this values from the controller
	signal deq_en_0_sig, deq_en_1_sig, is_ROB_a7_Sig, is_not_store_1, is_not_store_2: std_logic;
	signal inst0_c_we, is_dest_same : std_logic; ---as of now just made a signal, later will take this values from the controller
	 signal inst0_z_we : std_logic;
	 signal inst1_c_we : std_logic;
	 signal inst1_z_we : std_logic;

begin 
	inst0_c_we <= top_data_0.control_signal(0);
	inst0_z_we <= top_data_0.control_signal(1);
	inst1_c_we <= top_data_1.control_signal(0);
	inst1_z_we <= top_data_1.control_signal(1);
	rrf_d1_sig  <= rrf_d1(16 downto 1);
    rrf_d2_sig  <= rrf_d2(16 downto 1);
    rrf_d15_sig <= rrf_d15(16 downto 1);
    rrf_d16_sig <= rrf_d16(16 downto 1);
	sel2 <= (not(top_data_0.ARF_Dest(2) or top_data_0.ARF_Dest(1) or top_data_0.ARF_Dest(0)) & 
        not(top_data_1.ARF_Dest(2) or top_data_1.ARF_Dest(1) or top_data_1.ARF_Dest(0)));
	sel <= top_ready_1 & top_data_1.Inst_Write_Back_Karna_Hai_Kya & top_ready_0 & 
	top_data_0.Inst_Write_Back_Karna_Hai_Kya & top_data_0.WB_to_R0 & top_data_1.WB_to_R0;
	rrf_a1    <= top_data_0.RRF_Dest;
   rrf_a2    <= top_data_1.RRF_Dest;
   rrf_a15   <= top_data_0.RRF_Dest_PC;
   rrf_a16   <= top_data_1.RRF_Dest_PC; 
	deq_en_0_sig  <= top_ready_0 and top_data_0.Inst_Execute_Hogaya_Kya and not(top_data_0.Is_This_A_Part_Of_Unresolved_Branch);
	deq_en_1_sig  <= top_ready_1 and top_data_1.Inst_Execute_Hogaya_Kya and not(top_data_1.Is_This_A_Part_Of_Unresolved_Branch) and deq_en_0_sig;

	
	is_not_store_1 <= '0' when top_data_0.control_signal(18 downto 15) = "0101"
							else '1';
							
	is_not_store_2 <= '0' when top_data_1.control_signal(18 downto 15) = "0101"
							else '1';
	is_dest_same <= '1' when
    (top_data_0.ARF_Dest = top_data_1.ARF_Dest) and
    (deq_en_0_sig = '1') and
    (top_data_0.Inst_Write_Back_Karna_Hai_Kya = '1') and
	 (deq_en_1_sig = '1') and
    (top_data_1.Inst_Write_Back_Karna_Hai_Kya = '1') and (is_not_store_1 = '1') and (is_not_store_2 = '1') and (top_data_0.WB_to_Dest = '1') and (top_data_1.WB_to_Dest = '1')
	 else '0';
	 
	rf_a5     <= top_data_0.ARF_Dest;
	rf_a5_tag <= top_data_0.RRF_Dest;
	with is_dest_same select
	is_ROB_a5 <= '0' when '1',
						deq_en_0_sig and top_data_0.Inst_Write_Back_Karna_Hai_Kya and is_not_store_1 and top_data_0.WB_to_Dest when '0',
						deq_en_0_sig and top_data_0.Inst_Write_Back_Karna_Hai_Kya and is_not_store_1 and top_data_0.WB_to_Dest when others;
	
	rf_a6     <= top_data_1.ARF_Dest;
	rf_a6_tag <= top_data_1.RRF_Dest;
	is_ROB_a6 <= deq_en_1_sig and top_data_1.Inst_Write_Back_Karna_Hai_Kya and is_not_store_2 and top_data_1.WB_to_Dest;

	rf_a7    <= "000";
	
	with sel select
	rf_a7_tag <= top_data_1.RRF_Dest_PC when "111111",
					 top_data_1.RRF_Dest_PC when "111101",
					 top_data_1.RRF_Dest_PC when "111011",
					 top_data_1.RRF_Dest_PC when "111001",
					 top_data_0.RRF_Dest_PC when "111110",
					 top_data_0.RRF_Dest_PC when "001110",
					 top_data_0.RRF_Dest_PC when "001111",
					 top_data_0.RRF_Dest_PC when "101111",
					 top_data_0.RRF_Dest_PC when "101110",
					 top_data_0.RRF_Dest_PC when "011111",
					 top_data_0.RRF_Dest_PC when "011110",
					 "000000" when others;
	with sel select
	is_ROB_a7_Sig <= '1' when "111111",
						'1' when "111101",
						'1' when "111011",
						'1' when "111001",
						'1' when "111110",
						'1' when "001110",
						'1' when "001111",
						'1' when "101111",
						'1' when "101110",
						'1' when "011111",
						'1' when "011110",
						'0' when others;
	with sel2 select
	is_ROB_a7 <= is_ROB_a7_Sig when "00",
						'0' when others;
	rf_d5    <=rrf_d1_sig;
	rf_d6    <=rrf_d2_sig;
	with sel select
	
	rf_d7    <=  rrf_d16_sig when "111111",
					 rrf_d16_sig when "111101",
					 rrf_d16_sig when "111011",
					 rrf_d16_sig when "111001",
					 rrf_d15_sig when "111110",
					 rrf_d15_sig when "001110",
					 rrf_d15_sig when "001111",
					 rrf_d15_sig when "101111",
					 rrf_d15_sig when "101110",
					 rrf_d15_sig when "011111",
					 rrf_d15_sig when "011110",
					 x"0000" when others;
	
	
   is_ROB_a1  <= deq_en_0_sig;
	is_ROB_a2  <= deq_en_1_sig;
	is_ROB_a15 <= deq_en_0_sig;
	is_ROB_a16 <= deq_en_1_sig; 
  
   deq_en_0 <=deq_en_0_sig or store_deq_req_0;
	deq_en_1 <=deq_en_1_sig;
	
	
	commit_c_we  <= (deq_en_1_sig and inst1_c_we) or (deq_en_0_sig and inst0_c_we);
    
    commit_c_val <= top_data_1.Flag_Register(1) when (deq_en_1_sig = '1' and inst1_c_we = '1') else 
                    top_data_0.Flag_Register(1);
                    
    commit_c_tag <= top_data_1.RRF_Carry when (deq_en_1_sig = '1' and inst1_c_we = '1') else 
                    top_data_0.RRF_Carry;

    
    commit_z_we  <= (deq_en_1_sig and inst1_z_we) or (deq_en_0_sig and inst0_z_we);
    
    commit_z_val <= top_data_1.Flag_Register(0) when (deq_en_1_sig = '1' and inst1_z_we = '1') else 
                    top_data_0.Flag_Register(0);
                    
    commit_z_tag <= top_data_1.RRF_Zero when (deq_en_1_sig = '1' and inst1_z_we = '1') else 
                    top_data_0.RRF_Zero;
end architecture;