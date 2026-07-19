library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity branch_tag_register is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        enable      : in  std_logic;
        tag_in      : in  unsigned(2 downto 0);
        tag_out     : out unsigned(2 downto 0)
    );
end entity;

architecture design of branch_tag_register is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tag_out <= "000";
            elsif enable = '1' then
                tag_out <= tag_in;
            end if;
        end if;
    end process;
end architecture;