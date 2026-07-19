library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    port (
        clk        : in  STD_LOGIC;
        wr_en      : in  STD_LOGIC;
        mem_addr   : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_d_in   : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_d_out1  : out STD_LOGIC_VECTOR(15 downto 0);
		  mem_d_out2 : out STD_LOGIC_VECTOR(15 downto 0)
    );
end entity;

architecture design of memory is
    -- 2^16 = 65536 byte locations
    type mem_array is array (0 to 511) of STD_LOGIC_VECTOR(7 downto 0);
    signal ram : mem_array := (others => ("00111110"));
begin

    process(clk)
        variable addr_int : integer;
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                addr_int := to_integer(unsigned(mem_addr));
                ram(addr_int) <= mem_d_in(15 downto 8);
                if addr_int < 65535 then
                    ram(addr_int + 1) <= mem_d_in(7 downto 0);
                end if;
            end if;
        end if;
    end process;

    mem_d_out1 <= ram(to_integer(unsigned(mem_addr))) & 
                 ram(to_integer(unsigned(mem_addr) + 1));
		
    mem_d_out2 <= ram(to_integer(unsigned(mem_addr) + 2)) & 
                 ram(to_integer(unsigned(mem_addr) + 3));
		

end architecture;