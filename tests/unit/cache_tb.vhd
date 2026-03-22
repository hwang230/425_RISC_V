library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
generic(
    ram_size : INTEGER := 32768
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
    s_addr : in std_logic_vector (31 downto 0);
    s_read : in std_logic;
    s_readdata : out std_logic_vector (31 downto 0);
    s_write : in std_logic;
    s_writedata : in std_logic_vector (31 downto 0);
    s_waitrequest : out std_logic; 

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clock : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clock,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clock,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clock <= '0';
  wait for clk_period/2;
  clock <= '1';
  wait for clk_period/2;
end process;

test_process : process
    -- signals to turn off during reset
    procedure do_reset is
    begin
        s_addr <= (others => '0');
        s_read <= '0';
        s_write <= '0';
        s_writedata <= (others => '0');

        reset <= '1';
        wait for 5 * clk_period;
        wait until rising_edge(clock);
        reset <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);
    end procedure;
        
    -- signals to put when performing read
    procedure cpu_read(
        constant addr_v : in std_logic_vector(31 downto 0);
        variable data_v : out std_logic_vector(31 downto 0);
        constant msg    : in string
    ) is
    begin
        wait until falling_edge(clock);
        s_addr <= addr_v;
        s_read <= '1';
        s_write <= '0';
        s_writedata <= (others => '0');

        wait until rising_edge(clock);
        while s_waitrequest /= '0' loop
            wait until rising_edge(clock);
        end loop;

        data_v := s_readdata;

        wait until falling_edge(clock);
        s_read <= '0';
        s_addr <= (others => '0');

        report "READ done: " & msg;
    end procedure;
        
    -- function to facilitate write operation
    procedure cpu_write(
        constant addr_v : in std_logic_vector(31 downto 0);
        constant data_v : in std_logic_vector(31 downto 0);
        constant msg    : in string
    ) is
    begin
        wait until falling_edge(clock);
        s_addr <= addr_v;
        s_writedata <= data_v;
        s_write <= '1';
        s_read <= '0';

        wait until rising_edge(clock);
        while s_waitrequest /= '0' loop
            wait until rising_edge(clock);
        end loop;

        wait until falling_edge(clock);
        s_write <= '0';
        s_addr <= (others => '0');
        s_writedata <= (others => '0');

        report "WRITE done: " & msg;
    end procedure;

    variable rd_data : std_logic_vector(31 downto 0);
    variable a0_init : std_logic_vector(31 downto 0);
    variable b0_init : std_logic_vector(31 downto 0);

    -- Same index, different tags
    -- tag = bits [14:9], index = bits [8:4], word offset = bits [3:2]
    constant A0 : std_logic_vector(31 downto 0) := x"00000000"; -- tag 0, index 0, word 0
    constant A1 : std_logic_vector(31 downto 0) := x"00000004"; -- tag 0, index 0, word 1
    constant B0 : std_logic_vector(31 downto 0) := x"00000200"; -- tag 1, index 0, word 0
    constant C0 : std_logic_vector(31 downto 0) := x"00000400"; -- tag 2, index 0, word 0
    constant D0 : std_logic_vector(31 downto 0) := x"00000600"; -- tag 3, index 0, word 0

    constant W1 : std_logic_vector(31 downto 0) := x"DEADBEEF";
    constant W2 : std_logic_vector(31 downto 0) := x"CAFEBABE";
    constant W3 : std_logic_vector(31 downto 0) := x"12345678";
begin
    report "Starting cache testbench";

    -- Reset
    do_reset;

    -- CASE 1: READ miss on empty/clean line
    cpu_read(A0, a0_init, "Case 1: read miss on empty/clean line");

    -- CASE 7: READ hit, clean
    cpu_read(A0, rd_data, "Case 7: read hit clean");
    assert rd_data = a0_init report "Case 7 failed: clean read hit did not return original data" severity error;

    -- CASE 5: READ miss with clean eviction
    cpu_read(B0, b0_init, "Case 5: read miss with clean eviction");

    -- Verify A0 still preserved in memory
    cpu_read(A0, rd_data, "Verify A0 after clean eviction");
    assert rd_data = a0_init report "Clean eviction path failed: A0 changed unexpectedly" severity error;

    -- CASE 9: WRITE miss on clean/empty line
    cpu_write(C0, W1, "Case 9: write miss on clean/empty line");

    -- CASE 15/16: WRITE hit on cached line
    cpu_write(C0, W2, "Case 15/16: write hit on cached line");

    -- CASE 8: READ hit, dirty
    cpu_read(C0, rd_data, "Case 8: read hit dirty");
    assert rd_data = W2 report "Case 8 failed: dirty read hit did not return latest data" severity error;

    -- CASE 6: READ miss with dirty eviction
    cpu_read(D0, rd_data, "Case 6: read miss with dirty eviction");

    -- Verify dirty writeback happened for C0
    cpu_read(C0, rd_data, "Verify dirty writeback of C0");
    assert rd_data = W2 report "Dirty writeback failed: C0 was not preserved in memory" severity error;

    -- CASE 13: WRITE miss with clean eviction
    cpu_read(A1, rd_data, "Load clean line for later clean write miss");
    cpu_write(B0, W3, "Case 13: write miss with clean eviction");

    cpu_read(B0, rd_data, "Verify write-miss update of B0");
    assert rd_data = W3 report "Case 13 failed: B0 did not contain written value" severity error;

    -- CASE 14: WRITE miss with dirty eviction
    cpu_write(B0, W1, "Make B0 dirty first");
    cpu_write(A0, W2, "Case 14: write miss with dirty eviction");

    cpu_read(B0, rd_data, "Verify dirty writeback of B0");
    assert rd_data = W1 report "Case 14 failed: B0 dirty eviction did not write back" severity error;

    -- CASE 15/16 again: WRITE hit
    cpu_write(A0, W3, "Case 15/16 again: write hit on A0");
    cpu_read(A0, rd_data, "Verify write hit on A0");
    assert rd_data = W3 report "Write hit verification failed on A0" severity error;

    -- report "All reachable cache test cases completed successfully." severity note;
    wait;
end process;

end behavior;
