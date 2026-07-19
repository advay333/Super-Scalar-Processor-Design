library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity n_bit_register is
    generic (
        n : integer := 16
    );
    port (
        clk      : in  std_logic;                 
        reset    : in  std_logic;                  
        write_en : in  std_logic;               
        data_in  : in  std_logic_vector(n-1 downto 0); 
        data_out : out std_logic_vector(n-1 downto 0) 
    );
end entity;

architecture Behavioral of n_bit_register is
    signal reg : std_logic_vector(n-1 downto 0):= (others => '0'); 
begin
    process(clk, reset)
    begin
        if reset = '1' then
            reg <= (others => '0'); 
        elsif rising_edge(clk) then
            if write_en = '1' then
                reg <= data_in;
            end if;
        end if;
    end process;

    data_out <= reg;  
end architecture;
