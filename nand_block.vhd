library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nand_block is
    port (
        a   : in std_logic; 
		  b 	: in std_logic;
        output   : out std_logic                 
    );
end entity nand_block;

architecture behavioral of nand_block is

begin
    output <= a nand b;
end architecture behavioral;