library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity bp_bhsr is
    Port ( 
        clk: in std_logic;
        rst: in std_logic;
        
        --Inputs which decide what is the next bhsr in the general case
        pred_0: in std_logic;
        pred_1: in std_logic;
        b_hit_0: in std_logic;
        b_hit_1: in std_logic;
        
        --Inputs which decide what is the next bhsr in case of mispred
        bhsr_updated_by_exec: in std_logic_vector(1 downto 0);
        misprediction: in std_logic;
		  was_branch: in std_logic;
        
        --current bhsr
        bhsr_out: out std_logic_vector(1 downto 0)
    );
end bp_bhsr;

architecture bhsr_struct of bp_bhsr is
    signal bhsr_reg: std_logic_vector(1 downto 0);
begin   
    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                bhsr_reg <= "00";
                
            -- Misprediction Override
            elsif misprediction='1' and was_branch='1' then
                bhsr_reg <= bhsr_updated_by_exec;
                
            -- First instruction is branch and taken (Shift 1 bit)
            elsif b_hit_0='1' and pred_0='1' then
                bhsr_reg <= bhsr_reg(0) & '1';
            
            --  Both are branches, Instr 0 NT, Instr 1 Taken (Shift 2 bits)
            elsif b_hit_0='1' and pred_0='0' and b_hit_1='1' and pred_1='1' then
                bhsr_reg <= '0' & '1'; 
                
            -- Both are branches, Instr 0 NT, Instr 1 NT (Shift 2 bits)
            elsif b_hit_0='1' and pred_0='0' and b_hit_1='1' and pred_1='0' then
                bhsr_reg <= '0' & '0';
                
            --  Instr 0 is NT, Instr 1 is not branch (Shift 1 bit)
            elsif b_hit_0='1' and pred_0='0' and b_hit_1='0' then
                bhsr_reg <= bhsr_reg(0) & '0';
            
            -- First instruction is not branch, Second is (Shift 1 bit)
            elsif b_hit_0='0' and b_hit_1='1' then
                bhsr_reg <= bhsr_reg(0) & pred_1;
					 
            --  Neither are branches
            else
                bhsr_reg <= bhsr_reg;
            end if;
        end if;
    end process;
    
    bhsr_out <= bhsr_reg;
end bhsr_struct;