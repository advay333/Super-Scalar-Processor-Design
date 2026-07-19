library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ROB_Queue.all;         
use work.store_buffer_types.all; 

entity Store_Retire_Controller is
    port (

        rob_top_data_0    : in  ROB_Entry;
        
      
        sb_head_ip        : in  std_logic_vector(15 downto 0);
        sb_head_addr      : in  std_logic_vector(15 downto 0);
        sb_head_data      : in  std_logic_vector(15 downto 0);
        sb_head_done      : in  std_logic;
        sb_is_empty       : in  std_logic;

        mem_wr_en         : out std_logic;
        mem_data_addr     : out std_logic_vector(15 downto 0);
        mem_data          : out std_logic_vector(15 downto 0);

  
        sb_commit_en      : out std_logic;


        store_deq_req_0   : out std_logic
    );
end entity;

architecture rtl of Store_Retire_Controller is
    signal store_is_sync_and_ready : std_logic;
	 signal rob_top_is_store:std_logic;
	 signal opcode_at_top:std_logic_vector(3 downto 0);
begin
	opcode_at_top<=rob_top_data_0.control_signal(3 downto 0);
	rob_top_is_store<=(not opcode_at_top(3)) and (opcode_at_top(2)) and (not opcode_at_top(1)) and (opcode_at_top(0));

    store_is_sync_and_ready <= '1' when (rob_top_is_store = '1') and 
                                        (sb_is_empty = '0') and 
                                        (rob_top_data_0.ip_addr = sb_head_ip) and 
                                        (sb_head_done = '1') 
                                   else '0';

    mem_wr_en     <= store_is_sync_and_ready;
    mem_data_addr <= sb_head_addr;
    mem_data      <= sb_head_data;

  
    sb_commit_en  <= store_is_sync_and_ready;

 
    store_deq_req_0 <= store_is_sync_and_ready;

end architecture;