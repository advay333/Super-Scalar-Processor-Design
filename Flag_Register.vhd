library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Flag_Register is
    Port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        
        -- Commit Stage Write Ports (Split for C and Z)
        commit_c_we   : in STD_LOGIC;
        commit_c_val  : in STD_LOGIC;
        commit_c_tag  : in STD_LOGIC_VECTOR(5 downto 0);
        
        commit_z_we   : in STD_LOGIC;
        commit_z_val  : in STD_LOGIC;
        commit_z_tag  : in STD_LOGIC_VECTOR(5 downto 0);
        
        -- Dispatch Stage Allocate Ports
        rrf_new_tag_z : in STD_LOGIC_VECTOR(5 downto 0);
        rrf_new_tag_c : in STD_LOGIC_VECTOR(5 downto 0);
        rrf_new_tag_en: in STD_LOGIC_VECTOR(1 downto 0); -- (1) for Carry, (0) for Zero
        
        -- Outputs
        flag_full_out : out STD_LOGIC_VECTOR(29 downto 0);
        only_value_out: out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity;

architecture design of Flag_Register is
    -- Bit 1 is Carry, Bit 0 is Zero
    signal registers : STD_LOGIC_VECTOR(15 downto 0) :=  (others => '0');
    signal Carry_Tag_In_RRF : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal Zero_Tag_In_RRF  : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal Do_I_Need_To_Look_In_RRF_for_Carry : STD_LOGIC := '0';
    signal Do_I_Need_To_Look_In_RRF_for_Zero  : STD_LOGIC := '0';
begin

    process(clk, rst)
    begin
        if rst = '1' then
            registers <= (others => '0');
            Do_I_Need_To_Look_In_RRF_for_Carry <= '0';
            Do_I_Need_To_Look_In_RRF_for_Zero  <= '0';
        elsif rising_edge(clk) then
            

            -- Carry Flag Logic
            if commit_c_we = '1' then
                registers(1) <= commit_c_val;
                
                if commit_c_tag = Carry_Tag_In_RRF then
                    Do_I_Need_To_Look_In_RRF_for_Carry <= '0';
                end if;
            end if;

            -- Zero Flag Logic
            if commit_z_we = '1' then
                registers(0) <= commit_z_val;
                -- Clear busy bit if the committing tag matches the currently mapped tag
                if commit_z_tag = Zero_Tag_In_RRF then
                    Do_I_Need_To_Look_In_RRF_for_Zero <= '0';
                end if;
            end if;
            
      
            
            if rrf_new_tag_en(0) = '1' then
                Do_I_Need_To_Look_In_RRF_for_Zero <= '1';
                Zero_Tag_In_RRF <= rrf_new_tag_z;
            end if;
            
            if rrf_new_tag_en(1) = '1' then
                Do_I_Need_To_Look_In_RRF_for_Carry <= '1';
                Carry_Tag_In_RRF <= rrf_new_tag_c;
            end if;
            
        end if;
    end process;
    
    flag_full_out  <= Do_I_Need_To_Look_In_RRF_for_Carry & Do_I_Need_To_Look_In_RRF_for_Zero & Carry_Tag_In_RRF & Zero_Tag_In_RRF & registers;
    only_value_out <= registers;

end architecture;