library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multi_Inst_Block is
     port(clk			 : in  std_logic;
			 rst			 : in  std_logic;
			 IR1         : in  std_logic_vector(15 downto 0);
			 IR2			 : in  std_logic_vector(15 downto 0);
          inp_imm     : in  std_logic_vector(5 downto 0);
          --lm_sm_rst   : in  std_logic; -- not of PC_en
          flag_reg    : out std_logic;
          imm_out     : out std_logic_vector(5 downto 0);
          Pop_Cnt     : out std_logic_vector(3 downto 0);
          New_Inst1   : out std_logic_vector(15 downto 0); -- goes back to IF
			 New_Inst2   : out std_logic_vector(15 downto 0); -- goes back to IF
          Output_Inst : out std_logic_vector(15 downto 0); -- first  output instruction
          Output_Inst2: out std_logic_vector(15 downto 0); -- second output instruction
          is_lm_sm    : out std_logic  -- goes into controller
          );
end entity;

architecture struct of Multi_Inst_Block is

    -- After clearing the 1st found register bit
    signal temp_inst   : std_logic_vector(15 downto 0);
    -- After clearing the 2nd found register bit (goes to New_Inst)
    signal temp_inst_2 : std_logic_vector(15 downto 0);

    
    signal adder_output  : std_logic_vector(5 downto 0);
    signal cout1         : std_logic;

   
    signal adder2_output : std_logic_vector(5 downto 0);
    signal cout2         : std_logic;

    signal reg_a         : std_logic_vector(2 downto 0);

    -- First instruction signals
    signal dest_reg      : std_logic_vector(2 downto 0);
    signal imm           : std_logic_vector(5 downto 0); -- effective imm for inst 1
    signal nop           : std_logic_vector(15 downto 0);
    signal flag_reg_sig, Is_IR1_LM_SM, Is_IR2_LM_SM, Is_N1_LM_SM  : std_logic;

    -- Second instruction signals
    signal dest_reg2     : std_logic_vector(2 downto 0);
    signal imm2          : std_logic_vector(5 downto 0); -- effective imm for inst 2
    signal nop2          : std_logic_vector(15 downto 0);
    signal flag_reg_sig2 : std_logic;

    signal LM_SM         : std_logic:= '0';
    signal LM_SM_vec, IR     : std_logic_vector(15 downto 0);
	 signal sel           : std_logic_vector(1 downto 0);

    component n_bit_full_adder is
        generic (n : integer := 16);
        port (
            a, b  : in  std_logic_vector(n-1 downto 0);
            c_in  : in  std_logic;
            sum   : out std_logic_vector(n-1 downto 0);
            c_out : out std_logic
        );
    end component n_bit_full_adder;

begin

    is_lm_sm <= LM_SM and not(nop(0));

    
    -- Adder 1: inp_imm + 2  (offset for the 1st output instruction)
    NEW_IMM: n_bit_full_adder
        generic map(n => 6)
        port map(
            a     => inp_imm,
            b     => std_logic_vector(to_signed(2, 6)),
            c_in  => '0',
            sum   => adder_output,
            c_out => cout1
        );

    -- Adder 2: inp_imm + 4  (offset for the 2nd output instruction)
    NEW_IMM2: n_bit_full_adder
        generic map(n => 6)
        port map(
            a     => inp_imm,
            b     => std_logic_vector(to_signed(4, 6)),
            c_in  => '0',
            sum   => adder2_output,
            c_out => cout2
        );

   
	 Is_IR1_LM_SM <= (not IR1(15)) and IR1(14) and IR1(13);
	 Is_IR2_LM_SM <= (not IR2(15)) and IR2(14) and IR2(13);
	 sel <= Is_IR1_LM_SM & Is_IR2_LM_SM;
	 IR <=IR1;
	 
	 
	 
	 
    process(IR, temp_inst, adder_output, adder2_output)
        variable bit_cnt : integer;
    begin
        if rst = '1' then
            imm  <= (others => '0');
            imm2 <= std_logic_vector(to_signed(2, 6));
        else
            imm  <= adder_output;
            imm2 <= adder2_output;
        end if;

        bit_cnt := 0;
        for i in 0 to 8 loop
            if IR(i) = '1' then
                bit_cnt := bit_cnt + 1;
            end if;
        end loop;
        Pop_Cnt <= std_logic_vector(to_unsigned(bit_cnt, 4));
    end process;

 
    process(IR, LM_SM)
    begin
        if IR(0) = '1' then
            dest_reg     <= "111";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111111111110";

        elsif IR(1) = '1' then
            dest_reg     <= "110";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111111111101";

        elsif IR(2) = '1' then
            dest_reg     <= "101";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111111111011";

        elsif IR(3) = '1' then
            dest_reg     <= "100";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111111110111";

        elsif IR(4) = '1' then
            dest_reg     <= "011";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111111101111";

        elsif IR(5) = '1' then
            dest_reg     <= "010";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111111011111";

        elsif IR(6) = '1' then
            dest_reg     <= "001";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111110111111";

        elsif IR(7) = '1' then
            dest_reg     <= "000";
            flag_reg_sig <= '0';
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111101111111";

        elsif IR(8) = '1' then
            dest_reg     <= "111";   -- flag register slot
            flag_reg_sig <= '1' and LM_SM;
            nop          <= (others => '0');
            temp_inst    <= IR and "1111111011111111";

        else
            dest_reg     <= "000";
            flag_reg_sig <= '0';
            nop          <= (others => '1');
            temp_inst    <= IR;
        end if;
    end process;


	 
	 
    process(temp_inst, dest_reg,LM_SM)
    begin
        if temp_inst(0) = '1' then
            dest_reg2     <= "111";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111111111110";

        elsif temp_inst(1) = '1' then
            dest_reg2     <= "110";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111111111101";

        elsif temp_inst(2) = '1' then
            dest_reg2     <= "101";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111111111011";

        elsif temp_inst(3) = '1' then
            dest_reg2     <= "100";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111111110111";

        elsif temp_inst(4) = '1' then
            dest_reg2     <= "011";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111111101111";

        elsif temp_inst(5) = '1' then
            dest_reg2     <= "010";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111111011111";

        elsif temp_inst(6) = '1' then
            dest_reg2     <= "001";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111110111111";

        elsif temp_inst(7) = '1' then
            dest_reg2     <= "000";
            flag_reg_sig2 <= '0';
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111101111111";

        elsif temp_inst(8) = '1' then
            dest_reg2     <= "111";   -- flag register slot
            flag_reg_sig2 <= '1' and LM_SM;
            nop2          <= (others => '0');
            temp_inst_2   <= temp_inst and "1111111011111111";

        else
            
            -- Duplicate the first instruction; dest_reg/imm carry through.
            dest_reg2     <= dest_reg;
            flag_reg_sig2 <= '0';
            nop2          <= (others => '1');  
            temp_inst_2   <= temp_inst; 
		  end if;
    end process;

	 with sel select
		New_Inst1 <= temp_inst_2 when "10",
						 temp_inst_2 when "11",
						 IR1 when "00",
						 IR2 when "01",
						 IR1 when others;
	with sel select
		New_Inst2 <= IR2 when "10",
						 IR2 when "11",
						 IR2 when "00",
						 "0000111111000000" when "01",
						 IR2 when others;
	 
	 LM_SM     <= (Is_IR1_LM_SM or Is_IR2_LM_SM) and not(rst) ;
    LM_SM_vec <= (others => LM_SM);
    reg_a     <= IR(11 downto 9);
    flag_reg  <= flag_reg_sig and LM_SM;


	 with sel select
		Output_Inst <= IR1 when "00",
							IR1 when "01",
		
							(LM_SM_vec and (not nop) and (IR(15 downto 14) & '0' & IR(12) & dest_reg & reg_a & imm))
						  or
						  ((not LM_SM_vec) and IR)
						  or
						  (LM_SM_vec and nop and "0000111111000000") when others;
						  
			
		
	
		
		
--		  (LM_SM_vec and (not nop) and (IR(15 downto 14) & '0' & IR(12) & dest_reg & reg_a & imm))
--        or
--        ((not LM_SM_vec) and IR)
--        or
--        (LM_SM_vec and nop and "0000111111000000");

 
	 with sel select
    Output_Inst2 <= IR2 when "00",
						  "0000111111000000" when "01",
--		 (LM_SM_vec and (not nop) and (not nop2)
--            and (IR(15 downto 14) & '0' & IR(12) & dest_reg2 & reg_a & imm2))
--        or
--        
--        (LM_SM_vec and (not nop) and nop2
--            and (IR(15 downto 14) & '0' & IR(12) & dest_reg  & reg_a & imm))
--        or 
--        (LM_SM_vec and nop and "1110000000000000") when (Is_IR1_LM_SM = '0') and (Is_IR2_LM_SM = '1')
        -- normal second instruction
        (LM_SM_vec and (not nop) and (not nop2)
            and (IR(15 downto 14) & '0' & IR(12) & dest_reg2 & reg_a & imm2))
        or
        -- odd – duplicate the first instruction
        (LM_SM_vec and (not nop) and nop2
            and (IR(15 downto 14) & '0' & IR(12) & dest_reg  & reg_a & imm))
        or
        -- Passthrough for not LM/SM instructions
        ((not LM_SM_vec) and IR)
        or
        -- NOP when there was all zero
        (LM_SM_vec and nop and "0000111111000000") when others;


    imm_out <= LM_SM_vec(5 downto 0) and imm2;

end struct;
