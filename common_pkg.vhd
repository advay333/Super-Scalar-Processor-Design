library ieee;
use ieee.std_logic_1164.all;

package common_pkg is
    -- CDB lane encoding (Expanded to 39 bits to avoid overlap)
    --  bits 38:33   : zero flag tag (6-bit)
    --  bits 32:27   : carry flag tag (6-bit)
    --  bit  26      : zero flag value
    --  bit  25      : valid of zero
    --  bit  24      : carry flag value
    --  bit  23      : valid of carry
    --  bit  22      : valid (1 = result present on this lane)
    --  bits 21:16   : RRF destination tag  (6-bit)
    --  bits 15:0    : result data          (16-bit)
    type cdb_array_t is array (0 to 3) of std_logic_vector(38 downto 0);
end package common_pkg;