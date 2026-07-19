library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag_generator is
    port (
        din               : in  std_logic_vector(63 downto 0);
        rrf_is_free       : out std_logic;
        rrf_tag_addresses : out std_logic_vector(23 downto 0)
    );
end entity;

architecture design of tag_generator is
begin
    process(din)
        -- Keep track of how many zeros we've found (capped at 4)
        variable zeros_found : integer range 0 to 4;
        
        -- Variables to store the 6-bit addresses of the first four zeros
        variable addr1 : std_logic_vector(5 downto 0);
        variable addr2 : std_logic_vector(5 downto 0);
        variable addr3 : std_logic_vector(5 downto 0);
        variable addr4 : std_logic_vector(5 downto 0);
    begin
        zeros_found := 0;
        addr1 := (others => '0');
        addr2 := (others => '0');
        addr3 := (others => '0');
        addr4 := (others => '0');

        -- Loop from MSB to LSB to find the highest addresses with a '0'
        for i in 63 downto 0 loop
            if din(i) = '0' then
                if zeros_found = 0 then
                    addr1 := std_logic_vector(to_unsigned(i, 6));
                    zeros_found := zeros_found + 1;
                elsif zeros_found = 1 then
                    addr2 := std_logic_vector(to_unsigned(i, 6));
                    zeros_found := zeros_found + 1;
                elsif zeros_found = 2 then
                    addr3 := std_logic_vector(to_unsigned(i, 6));
                    zeros_found := zeros_found + 1;
                elsif zeros_found = 3 then
                    addr4 := std_logic_vector(to_unsigned(i, 6));
                    zeros_found := zeros_found + 1;
                end if;
                -- If zeros_found is 4, we ignore further zeros
            end if;
        end loop;

        -- Output logic based on whether we found at least 4 zeros
        if zeros_found = 4 then
            rrf_is_free <= '1';
            -- Concatenate the four 6-bit addresses into the 24-bit output
            rrf_tag_addresses <= addr1 & addr2 & addr3 & addr4;
        else
            rrf_is_free <= '0';
            rrf_tag_addresses <= (others => '0');
        end if;
    end process;
end architecture;