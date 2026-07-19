library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_4x1_16bit is
    Port ( 
        in_0 : in  STD_LOGIC_VECTOR (15 downto 0);
        in_1 : in  STD_LOGIC_VECTOR (15 downto 0);
        in_2 : in  STD_LOGIC_VECTOR (15 downto 0);
        in_3 : in  STD_LOGIC_VECTOR (15 downto 0);
        sel  : in  STD_LOGIC_VECTOR (1 downto 0);
        output : out STD_LOGIC_VECTOR (15 downto 0)
    );
end mux_4x1_16bit;

architecture Behavioral of mux_4x1_16bit is
begin

    with sel select
        output <= in_0 when "00",
                    in_1 when "01",
                    in_2 when "10",
                    in_3 when "11",
                    (others => '0') when others; 

end Behavioral;