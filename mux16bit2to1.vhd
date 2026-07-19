library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux16bit2to1 is
    port ( 
        in0, in1 : in  std_logic_vector(15 downto 0);
        sel : in  std_logic;
        Y : out std_logic_vector(15 downto 0)  
    );
end mux16bit2to1;

architecture Behavioral of mux16bit2to1 is
begin
    process(in0, in1, sel)
    begin
        case sel is
            when '0' => Y <= in0; 
            when '1' => Y <= in1;  
				when others => Y <= (others => '0');
        end case;
    end process;
end Behavioral;
