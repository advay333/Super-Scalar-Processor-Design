	library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

	entity decoder is
		 Port (
			  ir1, ir2     : in  std_logic_vector(15 downto 0);
			  ip1, ip2     : in  std_logic_vector(15 downto 0);
			  bhsr         : in  std_logic_vector(1 downto 0);
			  pred1, pred2 : in  std_logic;

			  -- Instruction 1 outputs
			  writes_flags_1                       : out std_logic_vector(1 downto 0);
			  is_load_1, is_store_1                : out std_logic;
			  writes_to_r0_1                       : out std_logic;
			  is_adc_acc_ndc_ncc_1                 : out std_logic;
			  is_adz_acz_ndz_ncz_1                 : out std_logic;
			  addresses_of_register_to_read_from_1 : out std_logic_vector(5 downto 0);
			  operation_type_1                     : out std_logic_vector(3 downto 0);
			  immediate_of_operation_1             : out std_logic_vector(15 downto 0);
			  address_of_register_to_write_to_1    : out std_logic_vector(2 downto 0);
			  i1_reads_c, i1_writes_c              : out std_logic;
			  i1_reads_z, i1_writes_z              : out std_logic;
			  i1_isa_opcode                        : out std_logic_vector(3 downto 0);

			  -- Instruction 2 outputs
			  writes_flags_2                       : out std_logic_vector(1 downto 0);
			  is_load_2, is_store_2                : out std_logic;
			  writes_to_r0_2                       : out std_logic;
			  is_adc_acc_ndc_ncc_2                 : out std_logic;
			  is_adz_acz_ndz_ncz_2                 : out std_logic;
			  addresses_of_register_to_read_from_2 : out std_logic_vector(5 downto 0);
			  operation_type_2                     : out std_logic_vector(3 downto 0);
			  immediate_of_operation_2             : out std_logic_vector(15 downto 0);
			  address_of_register_to_write_to_2    : out std_logic_vector(2 downto 0);
			  i2_reads_c, i2_writes_c              : out std_logic;
			  i2_reads_z, i2_writes_z              : out std_logic;
			  i2_isa_opcode                        : out std_logic_vector(3 downto 0);

			  dependency_bits                      : out std_logic_vector(1 downto 0);

			  -- Pass-through outputs (entity-declared names)
			  ip1_out   : out std_logic_vector(15 downto 0);
			  ip2_out   : out std_logic_vector(15 downto 0);
			  bhsr_out  : out std_logic_vector(1 downto 0);
			  pred1_out : out std_logic;
			  pred2_out : out std_logic;
			  -- Instruction 1 Micro-ops
        i1_is_nand, i1_comp, i1_add_carry, i1_cond_carry, i1_cond_zero : out std_logic;
        -- Instruction 2 Micro-ops
        i2_is_nand, i2_comp, i2_add_carry, i2_cond_carry, i2_cond_zero : out std_logic
		 );
	end decoder;

	architecture Behavioral of decoder is

		 signal op1 : std_logic_vector(3 downto 0);
		 signal ra1, rb1, rc1, dest1, read1_1, read2_1 : std_logic_vector(2 downto 0);
		 signal cz1 : std_logic_vector(1 downto 0);
		 signal we1, r1_en_1, r2_en_1 : std_logic;
		 signal i1_wr_c_int, i1_wr_z_int : std_logic;

		 signal op2 : std_logic_vector(3 downto 0);
		 signal ra2, rb2, rc2, dest2, read1_2, read2_2 : std_logic_vector(2 downto 0);
		 signal cz2 : std_logic_vector(1 downto 0);
		 signal we2, r1_en_2, r2_en_2 : std_logic;
		 signal i2_wr_c_int, i2_wr_z_int : std_logic;

	begin
		 -- Extract Fields
		 op1 <= ir1(15 downto 12); ra1 <= ir1(11 downto 9); rb1 <= ir1(8 downto 6);
		 rc1 <= ir1(5 downto 3);   cz1 <= ir1(1 downto 0);
		 op2 <= ir2(15 downto 12); ra2 <= ir2(11 downto 9); rb2 <= ir2(8 downto 6);
		 rc2 <= ir2(5 downto 3);   cz2 <= ir2(1 downto 0);

		 --  INSTRUCTION 1
		 i1_isa_opcode<=op1;
		 operation_type_1 <= "0000" when (op1 = "0001" or op1 = "0010") else
									"0001" when  op1 = "0000" else
									"0010" when  op1 = "0100" else
									"0011" when  op1 = "0101" else
									"0100" when  op1 = "0011" else
									"0101" when  op1 = "1100" else
									"0110" when (op1 = "1000" or op1 = "1001" or op1 = "1010") else
									"0111" when  op1 = "1101" else
									"1000" when  op1 = "1111" else "1111";

		 dest1 <= rc1 when (op1 = "0001" or op1 = "0010") else
					 rb1 when  op1 = "0000" else
					 ra1 when (op1 = "0100" or op1 = "0011" or op1 = "1100" or op1 = "1101") else
					 "001" when (op1 = "0101") else
					 "001";
		 address_of_register_to_write_to_1 <= dest1;
		 we1 <= '1' when (op1 = "0001" or op1 = "0010" or op1 = "0000" or op1 = "0100" or
								op1 = "0011" or op1 = "1100" or op1 = "1101") else '0';
		 writes_to_r0_1 <= '1' when (we1 = '1' and dest1 = "000") else '0';

		 read1_1 <= rb1 when (op1 = "0100" or op1 = "1101") else ra1;
		 r1_en_1 <= '1' when (op1 /= "0011" and op1 /= "1100") else '0';
		 read2_1 <= rb1;
		 r2_en_1 <= '1' when (op1 = "0001" or op1 = "0010" or op1 = "0101" or
									 op1 = "1000" or op1 = "1001" or op1 = "1010") else '0';
		 addresses_of_register_to_read_from_1 <= read1_1 & read2_1;

		 immediate_of_operation_1 <=
			  std_logic_vector(resize(signed(ir1(8 downto 0)), 16))
					when (op1 = "0011" or op1 = "1100" or op1 = "1111") else
			  std_logic_vector(resize(signed(ir1(5 downto 0)), 16));

		 is_load_1  <= '1' when op1 = "0100" else '0';
		 is_store_1 <= '1' when op1 = "0101" else '0';

		 is_adc_acc_ndc_ncc_1 <= '1' when (op1 = "0001" or op1 = "0010") and cz1 = "10" else '0';
		 is_adz_acz_ndz_ncz_1 <= '1' when (op1 = "0001" or op1 = "0010") and cz1 = "01" else '0';

		 i1_reads_c  <= '1' when (op1 = "0001" and (cz1 = "10" or cz1 = "11")) or
										  (op1 = "0010" and cz1 = "10") else '0';
		 i1_reads_z  <= '1' when (op1 = "0001" or op1 = "0010") and cz1 = "01" else '0';
		 i1_wr_c_int <= '1' when (op1 = "0001" or op1 = "0000") else '0';
		 i1_wr_z_int <= '1' when (op1 = "0001" or op1 = "0010" or op1 = "0000" or op1 = "0100") else '0';
		 i1_writes_c <= i1_wr_c_int;
		 i1_writes_z <= i1_wr_z_int;
		 writes_flags_1 <= i1_wr_c_int & i1_wr_z_int;
	
		-- MICRO-OP EXTRACTION 
        -- Instruction 1
        i1_is_nand    <= '1' when (op1 = "0010") else '0';
        i1_comp       <= ir1(2) when (op1 = "0001" or op1 = "0010") else '0';
        i1_add_carry  <= '1' when (op1 = "0001" and cz1 = "11") else '0';
        i1_cond_carry <= '1' when ((op1 = "0001" or op1 = "0010") and cz1 = "10") else '0';
        i1_cond_zero  <= '1' when ((op1 = "0001" or op1 = "0010") and cz1 = "01") else '0';


		 -- INSTRUCTION 2 
		 i2_isa_opcode<=op2;
		 operation_type_2 <= "0000" when (op2 = "0001" or op2 = "0010") else
									"0001" when  op2 = "0000" else
									"0010" when  op2 = "0100" else
									"0011" when  op2 = "0101" else
									"0100" when  op2 = "0011" else
									"0101" when  op2 = "1100" else
									"0110" when (op2 = "1000" or op2 = "1001" or op2 = "1010") else
									"0111" when  op2 = "1101" else
									"1000" when  op2 = "1111" else "1111";

		 dest2 <= rc2 when (op2 = "0001" or op2 = "0010") else
					 rb2 when  op2 = "0000" else
					 ra2 when (op2 = "0100" or op2 = "0011" or op2 = "1100" or op2 = "1101") else
					 "001" when (op2 = "0101") else
					 "001";
		 address_of_register_to_write_to_2 <= dest2;
		 we2 <= '1' when (op2 = "0001" or op2 = "0010" or op2 = "0000" or op2 = "0100" or
								op2 = "0011" or op2 = "1100" or op2 = "1101") else '0';
		 writes_to_r0_2 <= '1' when (we2 = '1' and dest2 = "000") else '0';

		 read1_2 <= rb2 when (op2 = "0100" or op2 = "1101") else ra2;
		 r1_en_2 <= '1' when (op2 /= "0011" and op2 /= "1100") else '0';
		 read2_2 <= rb2;
		 r2_en_2 <= '1' when (op2 = "0001" or op2 = "0010" or op2 = "0101" or
									 op2 = "1000" or op2 = "1001" or op2 = "1010") else '0';
		 addresses_of_register_to_read_from_2 <= read1_2 & read2_2;

		 immediate_of_operation_2 <=
			  std_logic_vector(resize(signed(ir2(8 downto 0)), 16))
					when (op2 = "0011" or op2 = "1100" or op2 = "1111") else
			  std_logic_vector(resize(signed(ir2(5 downto 0)), 16));

		 is_load_2  <= '1' when op2 = "0100" else '0';
		 is_store_2 <= '1' when op2 = "0101" else '0';

		 is_adc_acc_ndc_ncc_2 <= '1' when (op2 = "0001" or op2 = "0010") and cz2 = "10" else '0';
		 is_adz_acz_ndz_ncz_2 <= '1' when (op2 = "0001" or op2 = "0010") and cz2 = "01" else '0';

		 i2_reads_c  <= '1' when (op2 = "0001" and (cz2 = "10" or cz2 = "11")) or
										  (op2 = "0010" and cz2 = "10") else '0';
		 i2_reads_z  <= '1' when (op2 = "0001" or op2 = "0010") and cz2 = "01" else '0';
		 i2_wr_c_int <= '1' when (op2 = "0001" or op2 = "0000") else '0';
		 i2_wr_z_int <= '1' when (op2 = "0001" or op2 = "0010" or op2 = "0000" or op2 = "0100") else '0';
		 i2_writes_c <= i2_wr_c_int;
		 i2_writes_z <= i2_wr_z_int;
		 writes_flags_2 <= i2_wr_c_int & i2_wr_z_int;

		        -- Instruction 2
        i2_is_nand    <= '1' when (op2 = "0010") else '0';
        i2_comp       <= ir2(2) when (op2 = "0001" or op2 = "0010") else '0';
        i2_add_carry  <= '1' when (op2 = "0001" and cz2 = "11") else '0';
        i2_cond_carry <= '1' when ((op2 = "0001" or op2 = "0010") and cz2 = "10") else '0';
        i2_cond_zero  <= '1' when ((op2 = "0001" or op2 = "0010") and cz2 = "01") else '0';

		 dependency_bits(0) <= '1' when (we1 = '1' and r1_en_2 = '1' and dest1 = read1_2) else '0';
		 dependency_bits(1) <= '1' when (we1 = '1' and r2_en_2 = '1' and dest1 = read2_2) else '0';

		 ip1_out   <= ip1;
		 ip2_out   <= ip2;
		 bhsr_out  <= bhsr;
		 pred1_out <= pred1;
		 pred2_out <= pred2;

	end Behavioral;

