library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity full_adder is
	port(a, b, c_in: in std_logic;
		s, c_out: out std_logic);
end full_adder;

architecture full_adder_arc of full_adder is
	signal s1, s2, s3: std_logic;
begin
	s1 <= a xor b;
	s <= s1 xor c_in;
	s2 <= a nand b;
	s3 <= s1 nand c_in;
	c_out <= s2 nand s3;
end full_adder_arc;