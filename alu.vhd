library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
	port(opcode: in std_logic;
		inputA, inputB: in std_logic_vector(15 downto 0);
		cin : in std_logic;
		comp : in std_logic;
		outputC: out std_logic_Vector(15 downto 0);
		zeroflag, carryflag: out std_logic
	);
end entity alu;

architecture manyoperationsatoncewow of alu is
	signal scarryflag, addcout: std_logic;
	
	signal b_bar, bmuxout, addoutput, nandout, soutputC: std_logic_vector(15 downto 0);
	
begin

	inv_inst : entity work.n_bit_inverter
	generic map(n => 16)
	port map(
		a => inputB, a_bar => b_bar
		);
		
		
	mux_inst : entity work.mux16bit2to1 port map(
			in0 => inputB, in1 => b_bar, sel => comp, Y => bmuxout
		);
		
	n_bit_addr_inst: entity work.n_bit_full_adder
	generic map(n => 16)
	port map(
	a => inputA, b => bmuxout, c_in => cin, sum => addoutput, c_out => addcout
	);
	
	
	n_bit_nand_inst : entity work.n_bit_nand
	generic map(n => 16)
	port map(
	a => inputA, b => bmuxout, output => nandout
	);
	
	
	mux_inst_final : entity work.mux16bit2to1 port map(
	in0 => addoutput, in1 => nandout, sel => opcode, Y => soutputC
	);
	
	mux2to1_inst : entity work.mux2to1 port map(
	in0 => addcout, in1 => '0', S => opcode, Y=> scarryflag 
	);
	
	
	zeroflag <= not (soutputC(0) or soutputC(1) or soutputC(2) or soutputC(3) or
                         soutputC(4) or soutputC(5) or soutputC(6) or soutputC(7) or
                         soutputC(8) or soutputC(9) or soutputC(10) or soutputC(11) or
                         soutputC(12) or soutputC(13) or soutputC(14) or soutputC(15)) after 1 ps;
	outputC <= soutputC after 1 ps;
	carryflag <= scarryflag after 1 ps;
end architecture;