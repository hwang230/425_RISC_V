library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_mm_tb is
end avalon_mm_tb;

architecture behavior of avalon_mm_tb is

component avalon_mm is
    generic(
        ram_size : INTEGER := 32768
    );
    port(
        clk: in std_logic;
        reset: in std_logic;
        op_type: in std_logic;
        mem_waitrequest : in std_logic;
        mem_readdata : in std_logic_vector(7 downto 0);
        in_block: in std_logic_vector(127 downto 0);
        fsm_addr: in integer range 0 to ram_size-1;
        mem_addr : out integer range 0 to ram_size-1;
        mem_read : out std_logic;
        mem_write : out std_logic;
        mem_writedata : out std_logic_vector(7 downto 0);
        busy: out std_logic;
        out_block: out std_logic_vector(127 downto 0)
    );
end component;

-- test signals
signal clk: std_logic := '0';
signal reset: std_logic := '0';
constant clk_period: time := 1ns;

-- input signals
signal op_type: std_logic := '0';
signal mem_waitrequest: std_logic := '0';
signal mem_readdata: std_logic_vector(7 downto 0) := (others => '0');
signal in_block: std_logic_vector(127 downto 0) := (others => '0');
signal fsm_addr: integer := 0;

-- output signals
signal mem_addr: integer;
signal mem_read: std_logic;
signal mem_write: std_logic;
signal mem_writedata: std_logic_vector(7 downto 0);
signal busy: std_logic;
signal out_block: std_logic_vector(127 downto 0);

begin

-- connect component to the unit under testing
uut: avalon_mm
port map(
    clk => clk,
    reset => reset,
    op_type => op_type,
    mem_waitrequest => mem_waitrequest,
    mem_readdata => mem_readdata,
    in_block => in_block,
    fsm_addr => fsm_addr,
    mem_addr => mem_addr,
    mem_read => mem_read,
    mem_write => mem_write,
    mem_writedata => mem_writedata,
    busy => busy,
    out_block => out_block
);

clk_process: process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_mm_tb is
end avalon_mm_tb;

architecture behavior of avalon_mm_tb is

component avalon_mm is
    generic(
        ram_size : INTEGER := 32768
    );
    port(
        clk: in std_logic;
        reset: in std_logic;
        
        -- data translator
        op_type: in std_logic; -- read or write
        mem_waitrequest : in std_logic;
        mem_readdata : in std_logic_vector(7 downto 0);
        in_block: in std_logic_vector(127 downto 0);
        fsm_addr: in integer range 0 to ram_size-1;
        
        mem_addr : out integer range 0 to ram_size-1;
        mem_read : out std_logic; -- read operation
        mem_write : out std_logic; -- write operation
        mem_writedata : out std_logic_vector(7 downto 0); -- write output
        busy: out std_logic; -- signal to fsm that interface is busy
        out_block: out std_logic_vector(127 downto 0) -- read output
    );
end component;

-- test signals
-- input signals
signal clk: std_logic := '0';
signal reset: std_logic := '0';
constant clk_period: time := 1ns;

signal op_type: std_logic := '0';
signal mem_waitrequest: std_logic := '0';
signal mem_readdata: std_logic_vector(7 downto 0) := (others => '0');
signal in_block: std_logic_vector(127 downto 0) := (others => '0');
signal fsm_addr: integer := 0;

-- output signals
signal mem_addr: integer;
signal mem_read: std_logic;
signal mem_write: std_logic;
signal mem_writedata: std_logic_vector(7 downto 0);
signal busy: std_logic;
signal out_block: std_logic_vector(127 downto 0);

begin

-- connect component to the unit under testing
uut: avalon_mm
port map(
    clk => clk,
    reset => reset,
    op_type => op_type,
    mem_waitrequest => mem_waitrequest,
    mem_readdata => mem_readdata,
    in_block => in_block,
    fsm_addr => fsm_addr,
    mem_addr => mem_addr,
    mem_read => mem_read,
    mem_write => mem_write,
    mem_writedata => mem_writedata,
    busy => busy,
    out_block => out_block
);

clk_process: process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;

test_process: process
begin
    -- TEST 1: System Reset
    REPORT "RESET TEST CASE";
    reset <= '1';
    wait for clk_period;
    reset <= '0';
    wait for clk_period;
    
    ASSERT (busy = '0' and mem_read = '0' and mem_write = '0') 
        REPORT "Fail: Reset did not clear interface signals!" SEVERITY ERROR;

    -- TEST 2: Memory Read Operation (op_type = '0')
    -- The unit should read 16 bytes sequentially
    REPORT "READ TEST CASE (16 BYTES)";
    fsm_addr <= 1000;
    op_type <= '0';
    wait for clk_period; 
    
    for i in 0 to 15 loop
        -- Simulating memory providing data (16, 17, 18...)
        mem_readdata <= std_logic_vector(to_unsigned(i + 16, 8));
        wait for 100 ps; -- ensure combinational logic finishes
        ASSERT (busy = '1') REPORT "Fail: Busy should be high during read!" SEVERITY ERROR;
        ASSERT (mem_read = '1') REPORT "Fail: Mem_read should be high!" SEVERITY ERROR;
        wait for clk_period - 100 ps;
        -- ensure we only wait for one clk period in each iteration
    end loop;
    
    wait for clk_period;
    ASSERT (busy = '0') REPORT "Fail: Busy did not drop after 16 bytes!" SEVERITY ERROR;

    -- TEST 3: Memory Waitrequest (Stress Test)
    -- If waitrequest is '1', the counter and address must freeze
    REPORT "WAITREQUEST FREEZE TEST";
    reset <= '1'; 
    wait for clk_period; 
    reset <= '0'; 
    wait for clk_period;
    
    mem_waitrequest <= '1';
    wait for clk_period * 3; -- for stalls cycle
    ASSERT (busy = '1') REPORT "Fail: Interface should be busy waiting!" SEVERITY ERROR;
    -- Check that address hasn't moved while waitrequest was high
    ASSERT (mem_addr = 0) REPORT "Fail: Address moved while waitrequest was high!" SEVERITY ERROR;
    
    mem_waitrequest <= '0';
    wait for clk_period;
    
    -- TEST 4: Memory Write Operation (op_type = '1')
    REPORT "WRITE TEST CASE";
    reset <= '1'; wait for clk_period; reset <= '0'; wait for clk_period;
    op_type <= '1';
    in_block <= x"11111111_22222222_33333333_44444444";
    wait for clk_period;
    
    ASSERT (mem_write = '1') REPORT "Fail: Mem_write should be high!" SEVERITY ERROR;
    -- x turns hexadecimals into binary;
    ASSERT (mem_writedata = x"44") REPORT "Fail: Wrong byte order on write!" SEVERITY ERROR;

    REPORT "ALL AVALON UNIT TESTS COMPLETED.";
    wait;
end process;

end behavior;