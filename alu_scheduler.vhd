library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_rs_types.all;

entity alu_scheduler is
    generic (
        RS_DEPTH : integer := 8
    );
    port (
        -- Inputs from ALU RS
        rs_array       : in  alu_rs_array_t(0 to RS_DEPTH-1);
        rs_ready_flags : in  std_logic_vector(RS_DEPTH-1 downto 0);

       
        exec_ready_0   : in  std_logic;
        exec_ready_1   : in  std_logic;

        -- Outputs toALU RS
        issue_en_0     : out std_logic;
        issue_idx_0    : out integer range 0 to RS_DEPTH-1;
        issue_en_1     : out std_logic;
        issue_idx_1    : out integer range 0 to RS_DEPTH-1;

        -- Combinational Outputs
        issue_valid_0  : out std_logic;
        issue_data_0   : out alu_rs_entry_t;
        issue_valid_1  : out std_logic;
        issue_data_1   : out alu_rs_entry_t
    );
end entity;

architecture rtl of alu_scheduler is
begin


    process(rs_ready_flags, exec_ready_0, exec_ready_1, rs_array)
        variable count        : integer range 0 to 2;
        variable temp_idx_0   : integer range 0 to RS_DEPTH-1;
        variable temp_idx_1   : integer range 0 to RS_DEPTH-1;
        variable temp_valid_0 : std_logic;
        variable temp_valid_1 : std_logic;
        
        
        variable final_en_0   : std_logic;
        variable final_idx_0  : integer range 0 to RS_DEPTH-1;
        variable final_en_1   : std_logic;
        variable final_idx_1  : integer range 0 to RS_DEPTH-1;
    begin
        count        := 0;
        temp_idx_0   := 0;
        temp_idx_1   := 0;
        temp_valid_0 := '0';
        temp_valid_1 := '0';

        final_en_0   := '0';
        final_idx_0  := 0;
        final_en_1   := '0';
        final_idx_1  := 0;


        for i in 0 to RS_DEPTH-1 loop
            if rs_ready_flags(i) = '1' then
                if count = 0 then
                    temp_idx_0   := i;
                    temp_valid_0 := '1';
                    count        := 1;
                elsif count = 1 then
                    temp_idx_1   := i;
                    temp_valid_1 := '1';
                    count        := 2;
                    exit; 
                end if;
            end if;
        end loop;

        if exec_ready_0 = '1' and exec_ready_1 = '1' then
            -- Both free: normal routing
            final_en_0  := temp_valid_0;
            final_idx_0 := temp_idx_0;
            final_en_1  := temp_valid_1;
            final_idx_1 := temp_idx_1;

        elsif exec_ready_0 = '1' and exec_ready_1 = '0' then
            -- ALU 1 stalled
            final_en_0  := temp_valid_0;
            final_idx_0 := temp_idx_0;
            final_en_1  := '0';
            final_idx_1 := 0;

        elsif exec_ready_0 = '0' and exec_ready_1 = '1' then
            -- ALU 0 stalled
            final_en_0  := '0';
            final_idx_0 := 0;
            final_en_1  := temp_valid_0; 
            final_idx_1 := temp_idx_0;

        else
            -- Both stalled
            final_en_0  := '0';
            final_idx_0 := 0;
            final_en_1  := '0';
            final_idx_1 := 0;
        end if;


        issue_en_0  <= final_en_0;
        issue_idx_0 <= final_idx_0;
        issue_en_1  <= final_en_1;
        issue_idx_1 <= final_idx_1;

        -- Tell the pipelines what data is valid
        issue_valid_0 <= final_en_0;
        if final_en_0 = '1' then
            issue_data_0 <= rs_array(final_idx_0);
        else
            issue_data_0 <= EMPTY_ALU_ENTRY;
        end if;

        issue_valid_1 <= final_en_1;
        if final_en_1 = '1' then
            issue_data_1 <= rs_array(final_idx_1);
        else
            issue_data_1 <= EMPTY_ALU_ENTRY;
        end if;

    end process;

end architecture;