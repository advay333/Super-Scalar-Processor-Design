library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_datapath is
end entity;

architecture behavior of tb_datapath is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal imem_wr_en        : std_logic := '0';
    signal imem_addr_control : std_logic := '1'; -- Start with external control
    signal imem_addr         : std_logic_vector(15 downto 0) := (others => '0');
    signal imem_din          : std_logic_vector(15 downto 0) := (others => '0');
	 
	 signal dmem_wr_en        : std_logic := '0';
    signal dmem_addr         : std_logic_vector(15 downto 0) := (others => '0');
    signal dmem_din          : std_logic_vector(15 downto 0) := (others => '0');

begin

    DUT: entity work.datapath
        generic map (
            CONTROL_WIDTH => 20
        )
        port map (
            clk               => clk,
            rst               => rst,
            
            -- IMEM Preload Interface routed to the internal Fetch Stage
            imem_wr_en        => imem_wr_en,
            imem_addr_control => imem_addr_control,
            imem_addr         => imem_addr,
            imem_din          => imem_din,
				
				dmem_wr_en        => dmem_wr_en,
            dmem_addr         => dmem_addr,
            dmem_din          => dmem_din
 
        );

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stim_proc: process
        file program_file      : text;
        variable text_line     : line;
        variable bin_inst      : std_logic_vector(15 downto 0);
        variable current_addr  : integer := 0;
        variable read_ok       : boolean;
    begin
       
        rst <= '1'; 
        imem_addr_control <= '1'; -- Tell IMEM to listen to the testbench
        imem_wr_en <= '0';
        wait for CLK_PERIOD * 2;
			
		  
        --  OPEN AND LOAD THE PROGRAM
		  
        file_open(program_file, "C:\Users\Shreya Nigam\Desktop\Desktop_1\Sem6\PD\superscalar_2\superscalar_4\superscalar_3\superscalar\program.txt", read_mode);
        report "Loading program.txt into Instruction Memory..." severity note;

        while not endfile(program_file) loop
            readline(program_file, text_line);
            
            if text_line'length = 0 then next; end if;

            read(text_line, bin_inst, read_ok); 
            
            if read_ok then
                imem_addr <= std_logic_vector(to_unsigned(current_addr, 16));
                imem_din  <= bin_inst;
                
                imem_wr_en <= '1';
                wait for CLK_PERIOD;
                imem_wr_en <= '0';
                
                current_addr := current_addr + 2;
            end if;
        end loop;
        file_close(program_file);
        
        -- Give the memory one cycle to settle the last write
        wait for CLK_PERIOD;

        imem_addr_control <= '0'; 
        wait for CLK_PERIOD;

        
        rst <= '0'; 
        report "Processor Execution Started." severity note;

        -- LET IT RUN
        wait for CLK_PERIOD * 500;

        report "Simulation time elapsed. Stopping." severity note;
        assert false report "SIMULATION COMPLETE" severity failure;
        wait;
    end process;
end architecture;