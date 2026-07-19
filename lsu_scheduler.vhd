library ieee;
use ieee.std_logic_1164.all;
use work.lsu_rs_types.all;

entity lsu_scheduler is
    port (
        -- Inputs from LS RS
        top_data    : in  lsu_rs_entry_t;
        top_ready   : in  std_logic;
        top_busy    : in  std_logic;

        -- Input from LS Pipeline
        exec_ready  : in  std_logic;

        -- Output to LS RS
        deq_en      : out std_logic;

        -- Combinational Outputs 
        issue_valid : out std_logic;
        issue_data  : out lsu_rs_entry_t
    );
end entity;

architecture rtl of lsu_scheduler is


    signal will_issue : std_logic;

begin


    will_issue <= top_busy and top_ready and exec_ready;


    deq_en <= will_issue;

    issue_valid <= will_issue;

    issue_data <= top_data when will_issue = '1' else EMPTY_ENTRY;

end architecture;