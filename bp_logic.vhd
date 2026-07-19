library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity bp_logic is
    Port ( 
	 --Inputs about predictions and hits of btas
			pred_0: in std_logic;
			pred_1: in std_logic;
			b_hit_0: in std_logic;
			b_hit_1: in std_logic;
	 --Final predictions depending on what happens in the two instrs
			final_pred: out std_logic_vector(1 downto 0)
    );
end bp_logic;

architecture bp_logic_struct of bp_logic is
 signal take_branch_0, take_branch_1:std_logic;
begin	
	take_branch_0<=pred_0 and b_hit_0;
	take_branch_1<= (not take_branch_0) and pred_1 and b_hit_1;
	final_pred<= take_branch_1 & take_branch_0;
end bp_logic_struct;
