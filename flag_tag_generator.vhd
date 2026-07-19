library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity flag_tag_generator is
    port (
        din               : in  std_logic_vector(63 downto 0);
        rrf_is_free       : out std_logic;
        rrf_tag_addresses : out std_logic_vector(11 downto 0)
    );
end entity;

architecture design of flag_tag_generator is
begin
    process(din)
        variable zeros_found : integer range 0 to 2;
        variable addr1 : std_logic_vector(5 downto 0);
        variable addr2 : std_logic_vector(5 downto 0);
    begin
        zeros_found := 0;
        addr1 := (others => '0');
        addr2 := (others => '0');

        for i in 63 downto 0 loop
            if din(i) = '0' then
                if zeros_found = 0 then
                    addr1 := std_logic_vector(to_unsigned(i, 6));
                    zeros_found := zeros_found + 1;
                elsif zeros_found = 1 then
                    addr2 := std_logic_vector(to_unsigned(i, 6));
                    zeros_found := zeros_found + 1;
                end if;
            end if;
        end loop;

        if zeros_found = 2 then
            rrf_is_free <= '1';
            rrf_tag_addresses <= addr1 & addr2;
        else
            rrf_is_free <= '0';
            rrf_tag_addresses <= (others => '0');
        end if;
    end process;
end architecture;