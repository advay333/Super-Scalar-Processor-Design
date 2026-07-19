library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inverter is
    generic (
        n : integer := 16       
    );
    port (
        a   : in std_logic; 
        a_bar   : out std_logic                 
    );
end entity inverter;

architecture behavioral of inverter is

begin
    a_bar <= not a;
end architecture behavioral;