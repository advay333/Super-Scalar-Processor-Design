library ieee;
use ieee.std_logic_1164.all;

package ROB_Queue is
	constant CTRL_WIDTH : integer := 20; 
	
    type ROB_Entry is record
        busy     : std_logic; 
        ip_addr  : std_logic_vector(15 downto 0);
		  control_signal : std_logic_vector(CTRL_WIDTH-1 downto 0);
        Is_This_A_Part_Of_Unresolved_Branch  : std_logic; --Speculative Bit
        ARF_Dest : std_logic_vector(2 downto 0);
        RRF_Dest  : std_logic_vector(5 downto 0);
		  RRF_Dest_PC  : std_logic_vector(5 downto 0);
		  RRF_Carry  : std_logic_vector(5 downto 0);
		  RRF_Zero  : std_logic_vector(5 downto 0);
        Tag       : std_logic_vector(2 downto 0);
		  WB_to_R0  : std_logic;
		  WB_to_Dest: std_logic;
        Inst_Write_Back_Karna_Hai_Kya : std_logic; --Valid
        Inst_Execute_Hogaya_Kya  : std_logic; --Done
        Flag_Register      : std_logic_vector(15 downto 0);
        
    end record;

    
    constant EMPTY_ENTRY : ROB_Entry:= (
        busy => '0', ip_addr => (others => '0'), control_signal =>(others => '0'),Is_This_A_Part_Of_Unresolved_Branch => '0',
        ARF_Dest => (others => '0'), RRF_Dest => (others => '0'), RRF_Dest_PC => (others => '0'), RRF_Carry => (others => '0'), RRF_Zero => (others => '0'),  Tag => (others => '0'),
        WB_to_R0 => '0', WB_to_Dest => '0', Inst_Write_Back_Karna_Hai_Kya => '0', Inst_Execute_Hogaya_Kya => '0', Flag_Register => (others => '0')
    );
	 
end package;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ROB_Queue.all;

entity ROB is
    generic (
        ROB_DEPTH : integer := 8  
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
		  
        data_in_0  : in  ROB_Entry;
		  data_in_1  : in  ROB_Entry;
		  
		  
        ip_addr_alu1       : in  std_logic_vector(15 downto 0);
		  ip_addr_alu2       : in  std_logic_vector(15 downto 0);
		  ip_addr_load       : in  std_logic_vector(15 downto 0);
		  ip_addr_store      : in  std_logic_vector(15 downto 0);
		  ip_addr_br         : in  std_logic_vector(15 downto 0);
		  done_alu1       : in  std_logic;
		  done_alu2       : in  std_logic;
		  done_load       : in  std_logic;
		  done_store      : in  std_logic;
		  done_br         : in  std_logic;
		  flag_alu1       : in  std_logic_vector(15 downto 0);
		  flag_alu2       : in  std_logic_vector(15 downto 0);
		  flag_load       : in  std_logic_vector(15 downto 0);
		  flag_store      : in  std_logic_vector(15 downto 0);
		  flag_br         : in  std_logic_vector(15 downto 0);
		  
		  
		  --speculation_resolved: in  std_logic; --will be same as done_br
		  branch_correct_predicted: in  std_logic;
		  branch_tag		 :in  std_logic_vector(2 downto 0);
		  
		  
		  
--		  write_out_addr1  : out std_logic_vector(2 downto 0);
--		  tag_out_addr1    : out std_logic_vector(5 downto 0);
--		  done_out_addr1   : out std_logic;
--		  
--		  write_out_addr2  : out std_logic_vector(2 downto 0);
--		  tag_out_addr2    : out std_logic_vector(5 downto 0);
--		  done_out_addr2   : out std_logic;
		  
		  top_data_0               : out ROB_Entry;
        top_ready_0              : out std_logic;
        
        top_data_1               : out ROB_Entry;
        top_ready_1              : out std_logic;
		  enq_en_0     : in  std_logic;
        deq_en_0     : in  std_logic;
		  enq_en_1     : in  std_logic;
        deq_en_1     : in  std_logic;
		  
        top_busy   : out std_logic;
        queue_full : out std_logic;
		  not_branch_in_ROB : out std_logic;
		  
		  alu1_wb_pc : in std_logic;
	     alu1_wb_arf : in std_logic;
		  alu2_wb_pc : in std_logic;
	     alu2_wb_arf : in std_logic;
		  load_wb_pc : in std_logic;
	     load_wb_arf : in std_logic;
		  store_wb_pc : in std_logic;
	     store_wb_arf : in std_logic;
		  br_wb_pc : in std_logic;
	     br_wb_arf : in std_logic;
		  
		  alu1_wb_pc_tag :in  std_logic_vector(5 downto 0);
		  alu2_wb_pc_tag :in  std_logic_vector(5 downto 0);
		  load_wb_pc_tag :in  std_logic_vector(5 downto 0);
		  store_wb_pc_tag :in  std_logic_vector(5 downto 0);
		  br_wb_pc_tag   :in  std_logic_vector(5 downto 0)
						
    );
end entity;

architecture rtl of ROB is

    type rob_ram_t is array (0 to ROB_DEPTH-1) of ROB_Entry;
    signal fifo_ram : rob_ram_t;
	 type buses is array (0 to 4) of std_logic_vector(44 downto 0); 
    signal head  : integer range 0 to ROB_DEPTH-1;
    signal tail, actual_tail  : integer range 0 to ROB_DEPTH-1;
    signal count : integer range 0 to ROB_DEPTH;
--	 signal write_out_addr1, write_out_addr2  : std_logic_vector(2 downto 0);
--	 signal tag_out_addr1, tag_out_addr2    : std_logic_vector(5 downto 0);
--	 signal data_out_addr1, data_out_addr2   : std_logic_vector(15 downto 0);
--	 signal deq_en_0, deq_en_1  :  std_logic;
	 signal cdb_buses : buses := (others => (others => '0'));
	 signal next_head : integer range 0 to ROB_DEPTH-1;
	 signal tail_data_0 : ROB_Entry;

begin


    
    queue_full <= '1' when (ROB_DEPTH - count < 2) else '0';
    top_busy   <= '1' when (count > 0) else '0';
    cdb_buses(0) <= alu1_wb_pc_tag & alu1_wb_pc & alu1_wb_arf & "0000" & ip_addr_alu1 & flag_alu1 & done_alu1;
	 cdb_buses(1) <= alu2_wb_pc_tag & alu2_wb_pc & alu2_wb_arf & "0000" & ip_addr_alu2 & flag_alu2 & done_alu2;
	 cdb_buses(2) <= load_wb_pc_tag & load_wb_pc & load_wb_arf & "0000" & ip_addr_load & flag_load & done_load;
	 cdb_buses(3) <= store_wb_pc_tag & store_wb_pc & store_wb_arf & "0000" & ip_addr_store & flag_store & done_store;
	 cdb_buses(4) <= br_wb_pc_tag & br_wb_pc & br_wb_arf & branch_correct_predicted & branch_tag & ip_addr_br & flag_br & done_br;
	 
	 next_head <= 0 when head = ROB_DEPTH - 1 else head + 1;
	 
	 top_data_0  <= fifo_ram(head) when count > 0 else EMPTY_ENTRY;
    top_ready_0 <= '1' when count > 0 and fifo_ram(head).Inst_Execute_Hogaya_Kya = '1' else '0';
    
    
    top_data_1  <= fifo_ram(next_head) when count > 1 else EMPTY_ENTRY;
    top_ready_1 <= '1' when count > 1 and fifo_ram(next_head).Inst_Execute_Hogaya_Kya = '1' else '0';
	 
	 
    
--	 deq_en_0 <= fifo_ram(head).Inst_Execute_Hogaya_Kya;
--	 deq_en_1 <= fifo_ram(next_head).Inst_Execute_Hogaya_Kya;
--    
--    write_out_addr1 <= fifo_ram(head).ARF_Dest;
--	 tag_out_addr1 <= fifo_ram(head).RRF_Dest;
--	 done_out_addr1 <= fifo_ram(head).Inst_Execute_Hogaya_Kya;


    process(clk)
		  variable v_tail      : integer;
        variable v_head      : integer;
        variable v_enq_cnt   : integer;
        variable v_deq_cnt   : integer;
        variable available   : integer;
        
    begin
        if rising_edge(clk) then
            if rst = '1' then
                head  <= 0;
                tail  <= 0;
                count <= 0;
                -- Explicitly initialize the RAM to clear all busy bits
                for i in 0 to ROB_DEPTH-1 loop
                    fifo_ram(i) <= EMPTY_ENTRY;
                end loop;
            else
				
                available := ROB_DEPTH - count;

          
   
                for i in 0 to ROB_DEPTH-1 loop

                    if fifo_ram(i).busy = '1' then
                        for b in 0 to 4 loop
                            if cdb_buses(b)(0) = '1' then 
                                -- update the done flag
                                if fifo_ram(i).ip_addr = cdb_buses(b)(32 downto 17) and  fifo_ram(i).RRF_Dest_PC = cdb_buses(b)(44 downto 39) then
                                    fifo_ram(i).Inst_Execute_Hogaya_Kya <= '1';
												fifo_ram(i).WB_to_R0 <= cdb_buses(b)(38);
												fifo_ram(i).WB_to_Dest <= cdb_buses(b)(37);
												fifo_ram(i).Inst_Execute_Hogaya_Kya <= '1';
                                    fifo_ram(i).Flag_Register       <= cdb_buses(b)(16 downto 1);
                                end if;
                                
                            end if;
                        end loop;
								
								if cdb_buses(4)(0) = '1' then 
									  -- for branches
									  --if fifo_ram(i).ip_addr = cdb_buses(4)(32 downto 17) then
									  
										if cdb_buses(4)(36) = '1' then --correctly predicted branch, just change speculative for that tag to 0
										
											
											if fifo_ram(i).busy = '1' and fifo_ram(i).Tag = cdb_buses(4)(35 downto 33) then
												 fifo_ram(i).Is_This_A_Part_Of_Unresolved_Branch <= '0';
												 fifo_ram(i).Tag <= "000";
												 
											end if;
											
											
											
										else  --incorrectly predicted branch, just change valid to 0, and set done 1 so that it leaves ROB
											
											if fifo_ram(i).busy = '1' and not(fifo_ram(i).Tag = "000") then
														fifo_ram(i).Tag <= "000";
												if fifo_ram(i).Is_This_A_Part_Of_Unresolved_Branch = '1' then
													 fifo_ram(i).Is_This_A_Part_Of_Unresolved_Branch <= '0';
													 fifo_ram(i).Inst_Write_Back_Karna_Hai_Kya <= '0';
													 fifo_ram(i).Inst_Execute_Hogaya_Kya <= '1';
													 fifo_ram(i).Tag <= "000";
												end if;
											end if;
												
										end if;
									  
								 end if; 
								
                    end if;
                end loop;

                
                -- ENQUEUE

                v_tail := tail;
                v_enq_cnt := 0;

                if enq_en_0 = '1' and available >= 1 then
                    fifo_ram(v_tail) <= data_in_0;
                    fifo_ram(v_tail).busy <= '1';
						  if cdb_buses(4)(0) = '1' then 
									  -- for branches
									  --if fifo_ram(i).ip_addr = cdb_buses(4)(32 downto 17) then
									  
										if cdb_buses(4)(36) = '1' then --correctly predicted branch, just change speculative for that tag to 0
										
											
											if fifo_ram(v_tail).busy = '1' and fifo_ram(v_tail).Tag = cdb_buses(4)(35 downto 33) then
												 fifo_ram(v_tail).Is_This_A_Part_Of_Unresolved_Branch <= '0';
												 fifo_ram(v_tail).Tag <= "000";
												 
											end if;
											
											
											
										else  --incorrectly predicted branch, just change valid to 0, and set done 1 so that it leaves ROB
											
											if fifo_ram(v_tail).busy = '1' and not(fifo_ram(v_tail).Tag = "000") then
												if fifo_ram(v_tail).Is_This_A_Part_Of_Unresolved_Branch = '1' then
													 fifo_ram(v_tail).Is_This_A_Part_Of_Unresolved_Branch <= '0';
													 fifo_ram(v_tail).Inst_Write_Back_Karna_Hai_Kya <= '0';
													 fifo_ram(v_tail).Inst_Execute_Hogaya_Kya <= '1';
													 fifo_ram(v_tail).Tag <= "000";
												end if;
											end if;
												
										end if;
									  
								 end if; 
								
                    if v_tail = ROB_DEPTH - 1 then v_tail := 0; else v_tail := v_tail + 1; end if;
                    v_enq_cnt := v_enq_cnt + 1;
                end if;

                if enq_en_1 = '1' and available >= 2 then
                    fifo_ram(v_tail) <= data_in_1;
                    fifo_ram(v_tail).busy <= '1';
						  if cdb_buses(4)(0) = '1' then 
									  -- for branches
									  --if fifo_ram(i).ip_addr = cdb_buses(4)(32 downto 17) then
									  
										if cdb_buses(4)(36) = '1' then --correctly predicted branch, just change speculative for that tag to 0
										
											
											if fifo_ram(v_tail).busy = '1' and fifo_ram(v_tail).Tag = cdb_buses(4)(35 downto 33) then
												 fifo_ram(v_tail).Is_This_A_Part_Of_Unresolved_Branch <= '0';
												 fifo_ram(v_tail).Tag <= "000";
												 
											end if;
											
											
											
										else  --incorrectly predicted branch, just change valid to 0, and set done 1 so that it leaves ROB
											
											if fifo_ram(v_tail).busy = '1' and not(fifo_ram(v_tail).Tag = "000") then
												if fifo_ram(v_tail).Is_This_A_Part_Of_Unresolved_Branch = '1' then
													 fifo_ram(v_tail).Is_This_A_Part_Of_Unresolved_Branch <= '0';
													 fifo_ram(v_tail).Inst_Write_Back_Karna_Hai_Kya <= '0';
													 fifo_ram(v_tail).Inst_Execute_Hogaya_Kya <= '1';
													 fifo_ram(v_tail).Tag <= "000";
												end if;
											end if;
												
										end if;
									  
								 end if; 						  
                    if v_tail = ROB_DEPTH - 1 then v_tail := 0; else v_tail := v_tail + 1; end if;
                    v_enq_cnt := v_enq_cnt + 1;
                end if;
                
                tail <= v_tail;

                
                --  DEQUEUE (COMMIT)
                
                v_head := head;
                v_deq_cnt := 0;

                -- dequeue sequentially - Strict In-Order Commit
                if deq_en_0 = '1' and count > 0 then
                    fifo_ram(v_head).busy <= '0';
                    fifo_ram(v_head).Inst_Execute_Hogaya_Kya <= '0';
                    if v_head = ROB_DEPTH - 1 then v_head := 0; else v_head := v_head + 1; end if;
                    v_deq_cnt := v_deq_cnt + 1;
                    
                    -- Only allow 2nd pop if 1st pop was legal
                    if deq_en_1 = '1' and count > 1 then
                        fifo_ram(v_head).busy <= '0';
                        fifo_ram(v_head).Inst_Execute_Hogaya_Kya <= '0';
                        if v_head = ROB_DEPTH - 1 then v_head := 0; else v_head := v_head + 1; end if;
                        v_deq_cnt := v_deq_cnt + 1;
                    end if;
                end if;
                
                head <= v_head;

                
                --  UPDATE COUNTER
                
                count <= count + v_enq_cnt - v_deq_cnt;
            end if;
        end if;
    end process;
	 -- Replace the current actual_tail assignment with this:
	actual_tail <= ROB_DEPTH - 1 when tail = 0 else tail - 1;
	 --if tail = ROB_DEPTH - 1 then actual_tail := 0; else actual_tail := tail - 1; end if;
	 tail_data_0 <= fifo_ram(actual_tail) when count > 0 else EMPTY_ENTRY;
	 not_branch_in_ROB <= not(tail_data_0.Tag(0) or tail_data_0.Tag(1) or tail_data_0.Tag(2));
end architecture;