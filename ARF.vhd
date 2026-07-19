library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Dispatch will read at max 4 operands, it will write at max 4 tags 
--Commit stage will write 3 entries maximum


entity ARF is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        rf_wr_en : in  STD_LOGIC_VECTOR(2 downto 0); 
        
        rf_a1    : in  STD_LOGIC_VECTOR(2 downto 0);
        rf_a2    : in  STD_LOGIC_VECTOR(2 downto 0);
		  rf_a3    : in  STD_LOGIC_VECTOR(2 downto 0);
        rf_a4    : in  STD_LOGIC_VECTOR(2 downto 0);
        rf_d1    : out STD_LOGIC_VECTOR(22 downto 0);
        rf_d2    : out STD_LOGIC_VECTOR(22 downto 0);
		  rf_d3    : out STD_LOGIC_VECTOR(22 downto 0);
        rf_d4    : out STD_LOGIC_VECTOR(22 downto 0);
        
        rf_a5    : in  STD_LOGIC_VECTOR(2 downto 0);
		  rf_a5_tag: in  STD_LOGIC_VECTOR(5 downto 0);
		  is_ROB_a5: in STD_LOGIC;
        rf_a6    : in  STD_LOGIC_VECTOR(2 downto 0);
		  rf_a6_tag: in  STD_LOGIC_VECTOR(5 downto 0);
		  is_ROB_a6: in STD_LOGIC;
		  rf_a7    : in  STD_LOGIC_VECTOR(2 downto 0);
		  rf_a7_tag: in  STD_LOGIC_VECTOR(5 downto 0);
		  is_ROB_a7: in STD_LOGIC;
        rf_d5    : in  STD_LOGIC_VECTOR(15 downto 0);
        rf_d6    : in  STD_LOGIC_VECTOR(15 downto 0);
		  rf_d7    : in  STD_LOGIC_VECTOR(15 downto 0);
		  
		  tag_address   : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_1 : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_2 : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_3 : in STD_LOGIC_VECTOR(5 downto 0); --This will be the tag for R0 from the 2nd inst
		  rrf_new_tag_4 : in STD_LOGIC_VECTOR(5 downto 0); -- I will not use this becuase this is the tag generated for R0 from the 1st inst in the 2 way fetch
		  rrf_new_tag_enable: in STD_LOGIC_VECTOR(3 downto 0)
    );
end entity;

architecture design of ARF is
    type reg_array is array (0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
	 type tag_array is array (0 to 7) of STD_LOGIC_VECTOR(5 downto 0);
    signal registers : reg_array := (others => (others => '0'));
	 signal Tag_In_RRF : tag_array := (others => (others => '0')); --TAG
	 signal Do_I_Need_To_Look_In_RRF : STD_LOGIC_VECTOR(7 downto 0) := (others=>'0'); -- Busy Bit
begin

    process(clk, rst)
    begin
        if rst = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            
            if rf_wr_en(0) = '1' and is_ROB_a5 = '1' then
                registers(to_integer(unsigned(rf_a5))) <= rf_d5;
					 if rf_a5_tag = Tag_In_RRF(to_integer(unsigned(rf_a5))) and is_ROB_a5 = '1' then
						Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a5))) <= '0';
					 end if;
            end if;
            
            if rf_wr_en(1) = '1'  and is_ROB_a6 = '1' then
                registers(to_integer(unsigned(rf_a6))) <= rf_d6;
					 if rf_a6_tag = Tag_In_RRF(to_integer(unsigned(rf_a6))) and is_ROB_a6 = '1' then
						Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a6))) <= '0';
					 end if;
            end if;
				
				if rf_wr_en(2) = '1' and is_ROB_a7 = '1' then
                registers(to_integer(unsigned(rf_a7))) <= rf_d7;
					 if rf_a7_tag = Tag_In_RRF(to_integer(unsigned(rf_a7))) and is_ROB_a7 = '1' then
						Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a7))) <= '0';
					 end if;
            end if;
            
				
				
				if rrf_new_tag_enable(0) = '1' then
					 Do_I_Need_To_Look_In_RRF(to_integer(unsigned(tag_address(5 downto 3)))) <= '1';
					 Tag_In_RRF(to_integer(unsigned(tag_address(5 downto 3)))) <= rrf_new_tag_1;
            end if;
				
				if rrf_new_tag_enable(1) = '1' then
					 Do_I_Need_To_Look_In_RRF(to_integer(unsigned(tag_address(2 downto 0)))) <= '1';
					 Tag_In_RRF(to_integer(unsigned(tag_address(2 downto 0)))) <= rrf_new_tag_2;
            end if;
				
				if rrf_new_tag_enable(2) = '1' then
					 Do_I_Need_To_Look_In_RRF(0) <= '1';
					 Tag_In_RRF(0) <= rrf_new_tag_3;
            end if;
				
	
				
				
        end if;
    end process;
	 

    rf_d1  <= Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a1))) & registers(to_integer(unsigned(rf_a1))) & Tag_In_RRF(to_integer(unsigned(rf_a1)));
    rf_d2  <= Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a2))) & registers(to_integer(unsigned(rf_a2))) & Tag_In_RRF(to_integer(unsigned(rf_a2)));
	 rf_d3  <= Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a3))) & registers(to_integer(unsigned(rf_a3))) & Tag_In_RRF(to_integer(unsigned(rf_a3)));
    rf_d4  <= Do_I_Need_To_Look_In_RRF(to_integer(unsigned(rf_a4))) & registers(to_integer(unsigned(rf_a4))) & Tag_In_RRF(to_integer(unsigned(rf_a4)));
	 
end architecture;