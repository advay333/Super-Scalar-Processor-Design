library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_nand is
    generic (
        n : integer := 16       
    );
    port (
        a   : in std_logic_vector(n-1 downto 0);
		  b	: in std_logic_vector(n-1 downto 0);
        output   : out std_logic_vector(n-1 downto 0)                 
    );
end entity n_bit_nand;

architecture structural of n_bit_nand is

begin

    gen_nand: for i in 0 to n-1 generate
        nand_inst: entity work.nand_block
            port map (
                a     => a(i),   
					 b		=>	b(i),
                output => output(i)
            );
    end generate gen_nand;
 
end architecture structural;