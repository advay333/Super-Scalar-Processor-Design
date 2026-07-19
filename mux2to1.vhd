library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2to1 is
    Port (
        in0 : in  std_logic;
        in1 : in  std_logic;
        S : in  std_logic;
        Y : out std_logic
    );
end mux2to1;

architecture Behavioral of mux2to1 is
begin
    Y <= (not S and in0) or (S and in1);
end Behavioral;