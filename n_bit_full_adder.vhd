

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_full_adder is
    generic (
        n : integer := 16       
    );
    port (
        a, b    : in std_logic_vector(n-1 downto 0); 
        c_in    : in std_logic;                      
        sum     : out std_logic_vector(n-1 downto 0); 
        c_out   : out std_logic                  
    );
end entity n_bit_full_adder;

architecture behavioral of n_bit_full_adder is
 
    signal result : unsigned(n downto 0);
    signal c_in_vec : unsigned(0 downto 0);
begin
    c_in_vec(0) <= c_in;
    result <= resize(unsigned(a), n+1) + resize(unsigned(b), n+1) + c_in_vec;
    sum <= std_logic_vector(result(n-1 downto 0));
    c_out <= result(n); 

end architecture behavioral;