library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity branch_predictor is
    Port ( 
		  clk: in std_logic;
		  rst: in std_logic;
	 -- From the two instructions in fetch
		  pc_0 : in std_logic_vector(15 downto 0);
		  pc_1 : in std_logic_vector(15 downto 0);
	 -- From the execute stage
		  bhsr_checkpoint: in std_logic_vector(1 downto 0);
		  updated_bta: in std_logic_vector(15 downto 0);
		  pc_mispred: in std_logic_vector(15 downto 0);
		  misprediction: in std_logic;--This is 1 if and only of was branch is high and pred was wrong
		  was_branch: in std_logic;--to highlight a valid update to the 2 bit history table
	--To the next stages
		  next_address: out std_logic_vector(15 downto 0);
		  prediction: out std_logic_vector(1 downto 0);
		  bhsr_right_now: out std_logic_vector(1 downto 0)
    );
end branch_predictor;

architecture bp_struct of branch_predictor is

signal bta_0,bta_1: std_logic_vector(15 downto 0);
signal b_hit_0,b_hit_1: std_logic;
signal bhsr_out:std_logic_vector(1 downto 0);
signal pred_0,pred_1:std_logic;
signal final_pred:std_logic_vector(1 downto 0);
signal bhsr_updated_by_exec:std_logic_vector(1 downto 0);
signal imm_next_pc:std_logic_vector(15 downto 0);
signal c_out:std_logic;
begin
	BTB: entity work.bp_btb
	generic map(N=>16)
    port map (
			clk=>clk,
			rst=>rst,
	 --Inputs for addressing reads
			pc_0=>pc_0,
			pc_1=>pc_1,
			pc_mispred=>pc_mispred,
			updated_bta=>updated_bta,
			misprediction=>misprediction,
			was_branch=>was_branch,
	--Outputs of BTAs
			bta_0=>bta_0,
			b_hit_0=>b_hit_0,
			bta_1=>bta_1,
			b_hit_1=>b_hit_1
    );
	PHT: entity work.bp_pht
	generic map(n=>16)
    port map (
			clk=>clk,
			rst=>rst,
	 --Inputs for addressing reads
			pc_0=>pc_0,
			pc_1=>pc_1,
			bhsr=>bhsr_out,
			pc_mispred=>pc_mispred,
			bhsr_checkpoint=>bhsr_checkpoint,
			misprediction=>misprediction,
			was_branch=>was_branch,
	--Raw predictions for both instructions 
			pred_0=>pred_0,
			pred_1=>pred_1
    );
	branch_logic: entity work.bp_logic
    port map (
	 --Inputs about predictions and hits of btas
			pred_0=>pred_0,
			pred_1=>pred_1,
			b_hit_0=>b_hit_0,
			b_hit_1=>b_hit_1,
	--Final predictions depending on what happens in the two instrs
			final_pred=>final_pred
    ); 
	bhsr_updated_by_exec<=bhsr_checkpoint; 
	bhsr: entity work.bp_bhsr
    port map (
			clk=>clk,
			rst=>rst,
	 --Inputs which decide what is the next bhsr in the general case
			pred_0=>pred_0,
			pred_1=>pred_1,
			b_hit_0=>b_hit_0,
			b_hit_1=>b_hit_1,
	 --Inputs which decide what is the next bhsr in case of mispred
			bhsr_updated_by_exec=>bhsr_updated_by_exec,
			misprediction=>misprediction,
			was_branch=>was_branch,
	--current bhsr
			bhsr_out=>bhsr_out
    );
	 adder: entity work.n_bit_full_adder
	     generic map(n=>16)
    port map(
        a=>pc_1,
		  b=>std_logic_vector(to_unsigned(2,16)),
        c_in=>'0',                      
        sum=>imm_next_pc, 
        c_out=>c_out                
    );
	 final_mux: entity work.mux_4x1_16bit
	 port map(
		 in_0=>imm_next_pc,
		 in_1=>bta_0,
		 in_2=>bta_1,
		 in_3=>(others=>'1'),
		 sel=>final_pred,
		 output=>next_address
	 );
	 bhsr_right_now<=bhsr_out;
	 prediction<=final_pred;
end bp_struct;
