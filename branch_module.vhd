library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_module is
	port(
			zero: in std_logic;
			overflow : in std_logic; -- Here overflow means negative result of ALU
			op_code  : in std_logic_vector(3 downto 0);
			branch_res: out std_logic
	);
end entity branch_module;

architecture rtl of branch_module is
	signal ble_res,blt_res,beq_res:std_logic;
begin
	beq_res<=(not op_code(0)) and (not op_code(1)) and zero and (not overflow);
	blt_res<=(  op_code(0)  ) and (not op_code(1)) and (not zero) and overflow;
	ble_res<=(not op_code(0)) and (   op_code(1)  ) and (zero xor overflow);
	branch_res<=(beq_res or ble_res or blt_res) and op_code(3) and (not op_code(2));
end architecture rtl;

	