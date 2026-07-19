library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch_stage is
    port (
	 --Essential operations
	 clk: in std_logic;
	 rst: in std_logic;
	 --For writing in instructions by the test bench
	 imem_wr_en: in std_logic;
	 pc_wr_en: in std_logic;
	 imem_addr_control: in std_logic;
	 imem_addr: in std_logic_vector(15 downto 0);
	 imem_din: in std_logic_vector(15 downto 0);
	 --From the execute stage
	 bhsr_checkpoint: in std_logic_vector(1 downto 0);
	 updated_bta: in std_logic_vector(15 downto 0);
	 pc_mispred: in std_logic_vector(15 downto 0);
	 was_branch: in std_logic;
	 misprediction: in std_logic;
	 updated_bta_valid: in std_logic;-- Whenever a instruction wants to update bta--Will be high if misprediction is high
	 --Outputs to the fetch_buffer
	 instr1:out std_logic_vector(15 downto 0);
	 instr2:out std_logic_vector(15 downto 0);
	 --debug signals for verification
	 next_address: out std_logic_vector(15 downto 0);
	 prediction: out std_logic_vector(1 downto 0);
	 bhsr_right_now: out std_logic_vector(1 downto 0);
    pc_out_1:out std_logic_vector(15 downto 0); 
    pc_out_2:out std_logic_vector(15 downto 0)
    );
end entity;

architecture fetch_struct of fetch_stage is
signal imem_mux_out: std_logic_vector(15 downto 0);
signal c_out: std_logic;
signal pc_out_plus_2:std_logic_vector(15 downto 0);
signal pc_in,pc_reg,pc_out: std_logic_vector(15 downto 0);
signal bp_next_address:std_logic_vector(15 downto 0);
begin
	IMEM_address_mux: entity work.mux_2x1_16bit
	port map(
        in_0 =>pc_out,
        in_1 =>imem_addr,
        sel  =>imem_addr_control,
        output =>imem_mux_out
	);
	
	IMEM: entity work.memory
	port map(
        clk        =>clk,
        wr_en      =>imem_wr_en,
        mem_addr   =>imem_mux_out,
        mem_d_in   =>imem_din,
        mem_d_out1 =>instr1,
		  mem_d_out2 =>instr2
	);
	
	 adder: entity work.n_bit_full_adder
	     generic map(n=>16)
    port map(
        a=>pc_out,
		  b=>std_logic_vector(to_unsigned(2,16)),
        c_in=>'0',                      
        sum=>pc_out_plus_2, 
        c_out=>c_out                
    );
	BP: entity work.branch_predictor
	port map(
		  clk=>clk,
		  rst=>rst,
	 -- From the two instructions in fetch
		  pc_0=>pc_out,
		  pc_1=>pc_out_plus_2,
	 -- From the execute stage
		  bhsr_checkpoint=>bhsr_checkpoint,
		  updated_bta=>updated_bta,
		  pc_mispred=>pc_mispred,
		  misprediction=>misprediction,--This is 1 if and only of was branch is high and pred was wrong
		  was_branch=>was_branch,--to highlight a valid update to the 2 bit history table
	--To the next stages
		  next_address=>bp_next_address,
		  prediction=>prediction,
		  bhsr_right_now=>bhsr_right_now
	);
	
	pc_in <= updated_bta when updated_bta_valid = '1' else bp_next_address; 
    -- Route to debug port
   next_address <= pc_in;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				pc_reg<= (others=>'0');
			elsif (pc_wr_en='1' or updated_bta_valid='1') then
				pc_reg<=pc_in;
			end if;
		end if;
	end process;
	pc_out<=pc_reg;
	pc_out_1<=pc_out;
	pc_out_2<=pc_out_plus_2;
end architecture;