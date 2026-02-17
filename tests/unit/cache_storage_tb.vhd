library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_storage_tb is
end cache_storage_tb;

architecture behavior of cache_storage_tb is

component cache_storage is
port(
    -- Inputs:
    clock: in std_logic;
    reset: in std_logic;
    word_offset: in std_logic_vector(1 downto 0); -- 2^2 words per block (4 words per block)
    index: in std_logic_vector(4 downto 0); -- 2^5 blocks (32 blocks) 
    tag: in std_logic_vector(5 downto 0); -- 15 address bits - 2 offset bits - 5 index bits - 2 last bits
    write_word: in std_logic;
    write_block: in std_logic;
    data_in: in std_logic_vector(31 downto 0);
    block_in: in std_logic_vector(127 downto 0);

    -- Outputs:
    hit: out std_logic;
    dirty: out std_logic;
    valid: out std_logic;
    tag_match: out std_logic;
    tag_out: out std_logic_vector(5 downto 0); -- return address
    data_out: out std_logic_vector(31 downto 0);
    block_out: out std_logic_vector(127 downto 0) 
);
end component;

-- test signals
-- input signals
signal clock: std_logic := '0';
signal reset: std_Logic := '0';
constant clk_period: time := 1ns;

signal word_offset: std_logic_vector(1 downto 0) := "00";
signal index: std_logic_vector(4 downto 0) := (others => '0');
signal tag: std_logic_vector(5 downto 0) := (others => '0');
signal write_word: std_logic := '0';
signal write_block: std_logic := '0';
signal data_in: std_logic_vector(31 downto 0) := (others => '0');
signal block_in: std_logic_vector(127 downto 0) := (others => '0');

-- output signals
signal hit: std_logic;
signal dirty: std_logic;
signal valid: std_logic;
signal tag_match: std_logic;
signal tag_out: std_logic_vector(5 downto 0);
signal data_out: std_logic_vector(31 downto 0);
signal block_out: std_logic_vector(127 downto 0);

begin

-- connect component to the unit under testing
uut: cache_storage
port map(
    clock => clock,
    reset => reset, 
    word_offset => word_offset, 
    index => index, 
    tag => tag,
    write_word => write_word, 
    write_block => write_block,
    data_in => data_in,
    block_in => block_in,
    hit => hit,
    dirty => dirty, 
    valid => valid,
    tag_match => tag_match,
    tag_out => tag_out, 
    data_out => data_out, 
    block_out => block_out
);

clk_process: process
begin
    clock <= '0';
    wait for clk_period/2;
    clock <= '1';
    wait for clk_period/2;
end process;

test_process: process
begin 
    -- TEST 1: System Reset
    REPORT "Reset Test Case";
    reset <= '1';
    wait for clk_period;
    reset <= '0';
    wait for clk_period;
    
    ASSERT (valid = '0' and dirty = '0' and hit = '0') REPORT "FAIL: Reset did not clear status bits!" SEVERITY ERROR;

    -- TEST 2: Cold Miss & Allocation (Write Block)
    -- Simulating a memory fill to the very last row at index 31
    index <= "11111"; 
    tag   <= "101010"; 
    block_in <= x"DDDDDDDD_CCCCCCCC_BBBBBBBB_AAAAAAAA"; -- x turns hexadecimals into binary
    
    wait for 100 ps; -- ensure combinational logic finishes
    ASSERT (hit = '0') REPORT "FAIL: Should be a miss before writing." SEVERITY ERROR;
    
    write_block <= '1';
    wait for clk_period;
    write_block <= '0';
    wait for 100 ps;
    
    ASSERT (valid = '1' and hit = '1') REPORT "FAIL: Block not allocated correctly." SEVERITY ERROR;

    -- TEST 3: Word Slicing (Multiplexer Check)
    -- Testing if the combinational data_out picks the right word
    word_offset <= "00"; 
    wait for 100 ps;
    ASSERT (data_out = x"AAAAAAAA") REPORT "FAIL: Offset 00 failed." SEVERITY ERROR;
    
    word_offset <= "11"; 
    wait for 100 ps;
    ASSERT (data_out = x"DDDDDDDD") REPORT "FAIL: Offset 11 failed." SEVERITY ERROR;

    -- TEST 4: CPU Write Hit (Dirty Bit Check)
    -- CPU modifies Word 2 (offset 01)
    data_in <= x"12345678";
    word_offset <= "01";
    write_word <= '1';
    wait for clk_period;
    write_word <= '0';
    wait for 100 ps;
    
    ASSERT (dirty = '1') REPORT "FAIL: Dirty bit should be set after CPU write." SEVERITY ERROR;
    ASSERT (data_out = x"12345678") REPORT "FAIL: Data not updated in storage." SEVERITY ERROR;

    -- TEST 5: Conflict Miss (Tag Comparison)
    -- Same index (31), but a completely different tag
    tag <= "010101"; 
    wait for 100 ps;
    
    ASSERT (tag_match = '0' and hit = '0') REPORT "FAIL: Should miss on tag mismatch." SEVERITY ERROR;
    ASSERT (valid = '1' and dirty = '1') REPORT "FAIL: Valid/Dirty should persist on miss." SEVERITY ERROR;

    REPORT "ALL STORAGE UNIT TESTS COMPLETED.";
    wait; 
end process;
end; 