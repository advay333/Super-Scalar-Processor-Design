library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity bp_pht is
    generic (
        N : integer := 16       
    );
    Port ( 
        clk:in std_logic;
        rst:in std_logic;
        --Inputs for addressing reads
        pc_0:in std_logic_vector(15 downto 0);
        pc_1:in std_logic_vector(15 downto 0);
        bhsr:in std_logic_vector(1 downto 0);
        --Inputs for updating states
        pc_mispred:in std_logic_vector(15 downto 0);
        bhsr_checkpoint:in std_logic_vector(1 downto 0);
        misprediction:in std_logic;
        was_branch:in std_logic;
        --Raw predictions for both instructions 
        pred_0:out std_logic;
        pred_1:out std_logic
    );
end bp_pht;

architecture pht_struct of bp_pht is
    type pht is array (0 to 4*N-1) of std_logic_vector(1 downto 0);
    signal entries: pht := (others => "00");
    signal index_0, index_1, index_update : integer range 0 to 4*N-1;
    signal entry_to_update, updated_entry : std_logic_vector(1 downto 0);
	 signal index_0_signal,index_1_signal,index_update_signal:std_logic_vector(5 downto 0);
begin

    -- converting bits to integer for array access
    -- concat appropiate bhsr to get actual address
	 index_0_signal<=bhsr & pc_0(4 downto 1);
	 index_1_signal<=bhsr & pc_1(4 downto 1);
	 index_update_signal<=bhsr_checkpoint & pc_mispred(4 downto 1);
    index_0 <= to_integer(unsigned(index_0_signal));
    index_1 <= to_integer(unsigned(index_1_signal));
    index_update <= to_integer(unsigned(index_update_signal));
    
    pred_0 <= entries(index_0)(1);
    pred_1 <= entries(index_1)(1);
    
    entry_to_update <= entries(index_update);
     
    fsm_bhb: entity work.fsm_2bit_bhb
    port map(
        input     => entry_to_update,
        to_update => misprediction,
        output    => updated_entry
    );
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                entries <= (others => "00");
            elsif was_branch = '1' then
                -- Only update the table if a branch actually resolved
                entries(index_update) <= updated_entry;
            end if;
        end if;
    end process;    
end pht_struct;