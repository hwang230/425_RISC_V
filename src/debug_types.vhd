library ieee;
use ieee.std_logic_1164.all;

package debug_types is
    type reg_file_t is array (0 to 31) of std_logic_vector(31 downto 0);
    type memory_word_array_t is array (0 to 8191) of std_logic_vector(31 downto 0);
end package;

package body debug_types is
end package body;
