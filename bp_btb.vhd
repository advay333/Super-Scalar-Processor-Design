library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity bp_btb is
    generic (
        N : integer := 16       
    );
    Port ( 
			clk: in std_logic;
			rst: in std_logic;
	 --Inputs for addressing reads
			pc_0: in std_logic_vector(15 downto 0);
			pc_1: in std_logic_vector(15 downto 0);
	 --Inputs from exec stage
			pc_mispred: in std_logic_vector(15 downto 0);
			updated_bta: in std_logic_vector(15 downto 0);
			misprediction: in std_logic;
			was_branch: in std_logic;
	--Outputs of BTAs
			bta_0: out std_logic_vector(15 downto 0);
			b_hit_0: out std_logic;
			bta_1: out std_logic_vector(15 downto 0);
			b_hit_1: out std_logic
    );
end bp_btb;

architecture btb_struct of bp_btb is
    type btb is array (0 to N-1) of std_logic_vector(32 downto 0);
	 signal entries: btb := (others => (others => '0'));
	 signal index_0, index_1, index_update : integer range 0 to N-1;
begin

    -- converting bits to integer for array access
    index_0 <= to_integer(unsigned(pc_0(4 downto 1)));
    index_1 <= to_integer(unsigned(pc_1(4 downto 1)));
    index_update <= to_integer(unsigned(pc_mispred(4 downto 1)));
	 
	 --No aliasing allowed in bta
    b_hit_0<='1' when (entries(index_0)(32) = '1' and entries(index_0)(15 downto 0) = pc_0) else '0';
	 bta_0<=entries(index_0)(31 downto 16);
	 
	 b_hit_1<='1' when (entries(index_1)(32) = '1' and entries(index_1)(15 downto 0) = pc_1) else '0';
	 bta_1<=entries(index_1)(31 downto 16);
	 
	 process(clk)
    begin
		if rising_edge(clk)  then
			if rst = '1' then
                entries <= (others => (others => '0'));
			elsif misprediction='1' and was_branch='1' then
				entries(index_update)(31 downto 16)<=updated_bta;
				entries(index_update)(32)<='1';
				entries(index_update)(15 downto 0) <= pc_mispred;
			end if;
		end if;
    end process;	
end btb_struct;
