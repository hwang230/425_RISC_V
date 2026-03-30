library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor is 
    port(
        clock: in std_logic;
        reset: in std_logic


    );
end processor;

architecture arch of processor is

-- opcode encoding from reference sheet
constant OPCODE_R: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110011";
constant OPCODE_IMM: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010011";
constant OPCODE_LOAD: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000011";
constant OPCODE_STORE: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100011";
constant OPCODE_B: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100011";
constant OPCODE_JAL: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1101111";
constant OPCODE_JALR: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100111";
constant OPCODE_AUIPC: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010111";
constant OPCODE_LUI: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110111";

-- signals for decoding instructions
signal opcode: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000000";
signal funct7: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000000";
signal funct3: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";

-- instructions encoding
constant ALU_ADD : std_logic_vector(3 downto 0) := "0000"; -- cover ADD and ADDI
constant ALU_SUB : std_logic_vector(3 downto 0) := "0001";
constant ALU_MUL : std_logic_vector(3 downto 0) := "0010";
constant ALU_AND : std_logic_vector(3 downto 0) := "0011"; -- cover AND and ANDI
constant ALU_OR  : std_logic_vector(3 downto 0) := "0100"; -- cover OR and ORI
constant ALU_XOR : std_logic_vector(3 downto 0) := "0101"; -- cover XORI
constant ALU_SLL : std_logic_vector(3 downto 0) := "0110";
constant ALU_SRL : std_logic_vector(3 downto 0) := "0111";
constant ALU_SRA : std_logic_vector(3 downto 0) := "1000";
constant ALU_SLT : std_logic_vector(3 downto 0) := "1001"; -- cover SLTI
constant ALU_BEQ : std_logic_vector(3 downto 0) := "1010";
constant ALU_BNE : std_logic_vector(3 downto 0) := "1011";
constant ALU_BLT : std_logic_vector(3 downto 0) := "1100";
constant ALU_BGE : std_logic_vector(3 downto 0) := "1101";

-- mem class definition
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

-- memory signals for data memory
constant ram_size_: integer := 32768;
signal d_writedata: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
signal d_addr: INTEGER RANGE 0 TO ram_size_-1 := 0;
signal d_write: STD_LOGIC := '0';
signal d_read: STD_LOGIC := '0';
signal d_readdata: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
signal d_waitrequest: STD_LOGIC := '0';

-- memory signals for instruction memory
signal i_writedata: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
signal i_addr: INTEGER RANGE 0 TO ram_size_-1 := 0;
signal i_write: STD_LOGIC := '0';
signal i_read: STD_LOGIC := '0';
signal i_readdata: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
signal i_waitrequest: STD_LOGIC := '0';

-- declare the register file
-- initialize to all 0s
type reg_file_t is array (0 to 31) of std_logic_vector(31 downto 0);
signal regs: reg_file_t := (others => (others => '0'));



begin

D_MEM: memory
port map(
    clock => clock,
    writedata => d_writedata,
    address => d_addr,
    memwrite => d_write,
    memread => d_read,
    readdata => d_readdata,
    waitrequest => d_waitrequest
); 

I_MEM: memory
port map(
    clock => clock,
    writedata => i_writedata,
    address => i_addr,
    memwrite => i_write,
    memread => i_read,
    readdata => i_readdata,
    waitrequest => i_waitrequest
);

process(clock, reset)
begin

end process; 
end arch;