library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_inverter is
    generic (
        n : integer := 16       
    );
    port (
        a   : in std_logic_vector(n-1 downto 0); 
        a_bar   : out std_logic_vector(n-1 downto 0)                 
    );
end entity n_bit_inverter;

architecture structural of n_bit_inverter is

begin

    gen_inv: for i in 0 to n-1 generate
        inverter_inst: entity work.inverter
            port map (
                a     => a(i),   
                a_bar => a_bar(i)
            );
    end generate gen_inv;
 
end architecture structural;