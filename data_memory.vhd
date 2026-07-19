library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_memory is
    generic (
        ADDR_WIDTH : integer := 9;
        DATA_WIDTH : integer := 16
    );
    port (
        clk       : in  std_logic;
        
        rd_addr1   : in  std_logic_vector(15 downto 0);
        rd_data1  : out std_logic_vector(DATA_WIDTH-1 downto 0);
		  rd_addr2   : in  std_logic_vector(15 downto 0);
        rd_data2  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        
        wr_en_0   : in  std_logic;
        wr_addr_0 : in  std_logic_vector(15 downto 0);
        wr_data_0 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        wr_en_1   : in  std_logic;
        wr_addr_1 : in  std_logic_vector(15 downto 0);
        wr_data_1 : in  std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture behavioral of data_memory is
    constant DEPTH : integer := 2**ADDR_WIDTH;
    type mem_array is array (0 to DEPTH-1) of std_logic_vector(7 downto 0);
    signal ram : mem_array := (others => (others => '0'));
begin
    process(clk)
        variable a0, a1 : integer;
    begin
        if rising_edge(clk) then

            if wr_en_0 = '1' then
                a0 := to_integer(unsigned(wr_addr_0(ADDR_WIDTH-1 downto 0)));
                ram(a0) <= wr_data_0(15 downto 8);
                if a0 + 1 < DEPTH then
                    ram(a0 + 1) <= wr_data_0(7 downto 0);
                end if;
            end if;
            if wr_en_1 = '1' then
                a1 := to_integer(unsigned(wr_addr_1(ADDR_WIDTH-1 downto 0)));
                ram(a1) <= wr_data_1(15 downto 8);
                if a1 + 1 < DEPTH then
                    ram(a1 + 1) <= wr_data_1(7 downto 0);
                end if;
            end if;
        end if;
    end process;

    rd_data1 <= ram(to_integer(unsigned(rd_addr1(ADDR_WIDTH-1 downto 0)))) &
               ram(to_integer(unsigned(rd_addr1(ADDR_WIDTH-1 downto 0)) + 1));
					
	
    rd_data2 <= ram(to_integer(unsigned(rd_addr2(ADDR_WIDTH-1 downto 0)))) &
               ram(to_integer(unsigned(rd_addr2(ADDR_WIDTH-1 downto 0)) + 1));
end architecture;