library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_2x1_16bit is
    Port ( 
        in_0 : in  STD_LOGIC_VECTOR (15 downto 0);
        in_1 : in  STD_LOGIC_VECTOR (15 downto 0);
        sel  : in  STD_LOGIC;
        output : out STD_LOGIC_VECTOR (15 downto 0)
    );
end mux_2x1_16bit;

architecture Behavioral of mux_2x1_16bit is
begin
    with sel select
        output <= in_0 when '0',
                    in_1 when '1',
                    (others => '0') when others; 
end Behavioral;