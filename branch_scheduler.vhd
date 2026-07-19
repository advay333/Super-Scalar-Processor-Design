library ieee;
use ieee.std_logic_1164.all;
use work.branch_rs_types.all; 

entity branch_scheduler is
    port (
        -- Inputsfrom  BR RS
        top_data    : in  branch_rs_entry_t;
        top_ready   : in  std_logic;
        top_busy    : in  std_logic;

        -- Input from Branch Pipeline
        exec_ready  : in  std_logic;

        -- Output to  BR RS
        deq_en      : out std_logic;

        -- Combinational Outputs
        issue_valid : out std_logic;
        issue_data  : out branch_rs_entry_t
    );
end entity;

architecture rtl of branch_scheduler is

    signal will_issue : std_logic;

begin


    will_issue <= top_busy and top_ready and exec_ready;

   
    deq_en <= will_issue;

    issue_valid <= will_issue;

    
    issue_data <= top_data when will_issue = '1' else EMPTY_BRANCH_ENTRY;

end architecture;