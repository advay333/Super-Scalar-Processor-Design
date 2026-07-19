library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--Dispatch has to read 4 operands, assign 2 tags, 2 more tags for PC
--Dispatch will also generate tags, for that it need the whole busy bit ka row, i will update busy bit using tag_enable  for the 4 input tags

--Execute will write into  RRF : 4 pipelines - 2 writes each maximum possible

-- Write back from ROB: will need to write at max 3 things from RRF to ARF




entity RRF is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        rrf_wr_en : in  STD_LOGIC_VECTOR(7 downto 0); 
		  
        is_ROB_a1 : in STD_LOGIC; -- if ROB is the one reading these values out in WriteBack stage, then set Busy Bit 0
		  is_ROB_a2 : in STD_LOGIC; -- if ROB is the one reading these values out in WriteBack stage, then set Busy Bit 0
		  is_ROB_a15: in STD_LOGIC; -- if ROB is the one reading these values out in WriteBack stage, then set Busy Bit 0
		  is_ROB_a16: in STD_LOGIC; -- if ROB is the one reading these values out in WriteBack stage, then set Busy Bit 0
		  
		  
--Read Ports		  
        rrf_a1    : in  STD_LOGIC_VECTOR(5 downto 0); 
        rrf_a2    : in  STD_LOGIC_VECTOR(5 downto 0);
		  rrf_a3    : in  STD_LOGIC_VECTOR(5 downto 0);
        rrf_a4    : in  STD_LOGIC_VECTOR(5 downto 0);
		  rrf_a5    : in  STD_LOGIC_VECTOR(5 downto 0);
        rrf_a6    : in  STD_LOGIC_VECTOR(5 downto 0);
		  rrf_a15   : in  STD_LOGIC_VECTOR(5 downto 0);
        rrf_a16   : in  STD_LOGIC_VECTOR(5 downto 0);
		  
        rrf_d1    : out STD_LOGIC_VECTOR(17 downto 0);
        rrf_d2    : out STD_LOGIC_VECTOR(17 downto 0);
		  rrf_d3    : out STD_LOGIC_VECTOR(17 downto 0);
        rrf_d4    : out STD_LOGIC_VECTOR(17 downto 0);
		  rrf_d5    : out STD_LOGIC_VECTOR(17 downto 0);
        rrf_d6    : out STD_LOGIC_VECTOR(17 downto 0);
		  rrf_d15   : out STD_LOGIC_VECTOR(17 downto 0);
        rrf_d16   : out STD_LOGIC_VECTOR(17 downto 0);
		  
		  
--Write Ports        
        rrf_a7    : in  STD_LOGIC_VECTOR(5 downto 0);
        rrf_a8    : in  STD_LOGIC_VECTOR(5 downto 0);
		  rrf_a9    : in  STD_LOGIC_VECTOR(5 downto 0);
        rrf_a10   : in  STD_LOGIC_VECTOR(5 downto 0);
		  rrf_a11   : in  STD_LOGIC_VECTOR(5 downto 0); -- for PC
		  rrf_a12   : in  STD_LOGIC_VECTOR(5 downto 0); -- for PC
		  rrf_a13   : in  STD_LOGIC_VECTOR(5 downto 0); -- for PC
		  rrf_a14   : in  STD_LOGIC_VECTOR(5 downto 0); -- for PC
        rrf_d7    : in  STD_LOGIC_VECTOR(15 downto 0);
        rrf_d8    : in  STD_LOGIC_VECTOR(15 downto 0);
		  rrf_d9    : in  STD_LOGIC_VECTOR(15 downto 0);
        rrf_d10   : in  STD_LOGIC_VECTOR(15 downto 0);
		  rrf_d11   : in  STD_LOGIC_VECTOR(15 downto 0); -- for PC
		  rrf_d12   : in  STD_LOGIC_VECTOR(15 downto 0); -- for PC
		  rrf_d13   : in  STD_LOGIC_VECTOR(15 downto 0); -- for PC
		  rrf_d14   : in  STD_LOGIC_VECTOR(15 downto 0); -- for PC
		  
		  Busy_Bit_Array : out STD_LOGIC_VECTOR(63 downto 0); --output for tag generator
		  rrf_new_tag_1 : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_2 : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_3 : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_4 : in STD_LOGIC_VECTOR(5 downto 0);
		  rrf_new_tag_enable: in STD_LOGIC_VECTOR(3 downto 0)
		  
    );
end entity;

architecture design of RRF is
    type reg_array is array (0 to 63) of STD_LOGIC_VECTOR(15 downto 0);
	 
    signal registers : reg_array := (others => (others => '0'));
	 signal Has_Entry_RRF : STD_LOGIC_VECTOR(63 downto 0) := (others=>'0'); --Busy Bit
	 signal Does_Entry_Have_Correct_Value_RRF : STD_LOGIC_VECTOR(63 downto 0) := (others=>'0'); -- Valid Bit
begin


    process(clk, rst)
    begin
        if rst = '1' then
            registers <= (others => (others => '0'));
				Has_Entry_RRF <= (others => '0');
				Does_Entry_Have_Correct_Value_RRF <= (others => '0');
        elsif rising_edge(clk) then
		  
				--Writing
            
            if rrf_wr_en(0) = '1'  and Has_Entry_RRF(to_integer(unsigned(rrf_a7))) = '1' then
                registers(to_integer(unsigned(rrf_a7))) <= rrf_d7;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a7))) <= '1';
            end if;
            
            
            if rrf_wr_en(1) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a8))) = '1' then
                registers(to_integer(unsigned(rrf_a8))) <= rrf_d8;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a8))) <= '1';
            end if;
				
				
				if rrf_wr_en(2) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a9))) = '1' then
                registers(to_integer(unsigned(rrf_a9))) <= rrf_d9;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a9))) <= '1';
            end if;
				
				if rrf_wr_en(3) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a10))) = '1' then
                registers(to_integer(unsigned(rrf_a10))) <= rrf_d10;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a10))) <= '1';
            end if;
            
            
            if rrf_wr_en(4) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a11))) = '1' then
                registers(to_integer(unsigned(rrf_a11))) <= rrf_d11;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a11))) <= '1';
            end if;
				
				
				if rrf_wr_en(5) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a12))) = '1' then
                registers(to_integer(unsigned(rrf_a12))) <= rrf_d12;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a12))) <= '1';
            end if;
				
				if rrf_wr_en(6) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a13))) = '1' then
                registers(to_integer(unsigned(rrf_a13))) <= rrf_d13;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a13))) <= '1';
            end if;
            
            
            if rrf_wr_en(7) = '1' and Has_Entry_RRF(to_integer(unsigned(rrf_a14))) = '1' then
                registers(to_integer(unsigned(rrf_a14))) <= rrf_d14;
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a14))) <= '1';
            end if;
				

				
				
				
				--Assigning Entires
				
				if rrf_new_tag_enable(0) = '1' then
                registers(to_integer(unsigned(rrf_new_tag_1))) <= (others =>'0');
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_new_tag_1))) <= '0';
					 Has_Entry_RRF(to_integer(unsigned(rrf_new_tag_1))) <= '1';
            end if;
				
				if rrf_new_tag_enable(1) = '1' then
                registers(to_integer(unsigned(rrf_new_tag_2))) <= (others =>'0');
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_new_tag_2))) <= '0';
					 Has_Entry_RRF(to_integer(unsigned(rrf_new_tag_2))) <= '1';
            end if;
				
				if rrf_new_tag_enable(2) = '1' then
                registers(to_integer(unsigned(rrf_new_tag_3))) <= (others =>'0');
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_new_tag_3))) <= '0';
					 Has_Entry_RRF(to_integer(unsigned(rrf_new_tag_3))) <= '1';
            end if;
				
				if rrf_new_tag_enable(3) = '1' then
                registers(to_integer(unsigned(rrf_new_tag_4))) <= (others =>'0');
					 Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_new_tag_4))) <= '0';
					 Has_Entry_RRF(to_integer(unsigned(rrf_new_tag_4))) <= '1';
            end if;
				
				
				
				
				
				--ROB commit
				
				if is_ROB_a1 = '1' then
					Has_Entry_RRF(to_integer(unsigned(rrf_a1))) <= '0';
					Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a1))) <= '0';
				end if;
				
				if is_ROB_a2 = '1' then
					Has_Entry_RRF(to_integer(unsigned(rrf_a2))) <= '0';
					Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a2))) <= '0';
				end if;
				
				if is_ROB_a15 = '1' then
					Has_Entry_RRF(to_integer(unsigned(rrf_a15))) <= '0';
					Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a15))) <= '0';
				end if;
				
				if is_ROB_a16 = '1' then
					Has_Entry_RRF(to_integer(unsigned(rrf_a16))) <= '0';
					Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a16))) <= '0';
				end if;
            
				
				
        end if;
    end process;

    
	 rrf_d1  <= Has_Entry_RRF(to_integer(unsigned(rrf_a1))) & registers(to_integer(unsigned(rrf_a1))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a1)));
    rrf_d2  <= Has_Entry_RRF(to_integer(unsigned(rrf_a2))) & registers(to_integer(unsigned(rrf_a2))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a2)));
	 rrf_d3  <= Has_Entry_RRF(to_integer(unsigned(rrf_a3))) & registers(to_integer(unsigned(rrf_a3))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a3)));
    rrf_d4  <= Has_Entry_RRF(to_integer(unsigned(rrf_a4))) & registers(to_integer(unsigned(rrf_a4))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a4)));
	 rrf_d5  <= Has_Entry_RRF(to_integer(unsigned(rrf_a5))) & registers(to_integer(unsigned(rrf_a5))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a5)));
    rrf_d6  <= Has_Entry_RRF(to_integer(unsigned(rrf_a6))) & registers(to_integer(unsigned(rrf_a6))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a6)));
	 rrf_d15 <= Has_Entry_RRF(to_integer(unsigned(rrf_a15))) & registers(to_integer(unsigned(rrf_a15))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a15)));
    rrf_d16 <= Has_Entry_RRF(to_integer(unsigned(rrf_a16))) & registers(to_integer(unsigned(rrf_a16))) & Does_Entry_Have_Correct_Value_RRF(to_integer(unsigned(rrf_a16)));
	 Busy_Bit_Array <= Has_Entry_RRF;

end architecture;