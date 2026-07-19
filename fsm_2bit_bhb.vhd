library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm_2bit_bhb is
    Port ( 
        input: in std_logic_vector(1 downto 0);
        to_update: in std_logic;
        output:out std_logic_vector(1 downto 0)
    );
end fsm_2bit_bhb;

architecture fsm_2bit_bhb_struct of fsm_2bit_bhb is
	signal control_signal:std_logic_vector(2 downto 0);
begin
	-- MSB is misprediction
	 control_signal<=to_update & input;
	 with control_signal select
	 output <= 	  "00" when "000",
					  "00" when "001",
					  "11" when "010",
					  "11" when "011",
					  "01" when "100",
					  "11" when "101",
					  "00" when "110",
					  "10" when "111",
					  (others => '0') when others;
end fsm_2bit_bhb_struct;