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
signal rs2: STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
signal rs1: STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
signal rd: STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";

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
signal i_writedata: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0'); -- won't be needed
signal i_addr: INTEGER RANGE 0 TO ram_size_-1 := 0;
signal i_write: STD_LOGIC := '0'; -- won't be needed
signal i_read: STD_LOGIC := '0';
signal i_readdata: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
signal i_waitrequest: STD_LOGIC := '0';

-- declare the register file
-- initialize to all 0s
type reg_file_t is array (0 to 31) of std_logic_vector(31 downto 0);
signal regs: reg_file_t := (others => (others => '0')); -- register file with 32 registers with 32 bits each
signal pc: INTEGER := 0; -- program counter
signal instr: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0'); -- store the fetched instruction
signal fetch_busy: STD_LOGIC := '0'; -- to inform that we are not done fetching
signal fetch_count: INTEGER range 0 to 3 := 0; -- count how many bytes are fetched for instruction
signal instr_IF_ID: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0'); -- to latch instruction from fetch to decode

-- intermediate signal to inform next stage to proceed
signal fetch_done: STD_LOGIC := '0';
signal decode_done: STD_LOGIC := '0';
signal id_alu_op: STD_LOGIC_VECTOR(3 downto 0); 
signal id_mem_read: STD_LOGIC := '0'; -- store control signal for load operation
signal id_mem_write: STD_LOGIC := '0'; -- store control signal for store operation
signal id_reg_write: STD_LOGIC := '0'; -- store control signal for load operation
signal id_ex_alu_op: STD_LOGIC_VECTOR(3 downto 0); -- latch the operation
signal id_ex_rs2_val, id_ex_rs1_val: STD_LOGIC_VECTOR(31 downto 0); -- latch the values from registrs
signal id_ex_rd: STD_LOGIC_VECTOR(4 downto 0); -- latch the destination register
signal id_ex_mem_read: STD_LOGIC := '0'; -- to indicate if instruction requires access to data memory (latched from decode)
signal id_ex_mem_write: STD_LOGIC := '0'; -- to indicate if instruction requires access to data memory (latched from decode)
signal ex_ALU_output: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- result from ALU
signal ex_mem_ALU_output: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- latch ALU result onto register
signal ex_mem_mem_read: STD_LOGIC := '0'; -- to latch the signal from decode to memory for load
signal ex_mem_mem_write: STD_LOGIC := '0'; -- to latch the signal from decode to memory for store
signal ex_mem_rd: STD_LOGIC_VECTOR(4 downto 0); -- latch the rd from EX to MEM
signal mem_wb_rd: STD_LOGIC_VECTOR(4 downto 0); -- latch the rd from EX to MEM
signal mem_wb_ALU_output: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- latch alu output from ex_mem to mem_wb
signal id_ex_reg_write: STD_LOGIC := '0'; -- check if the instruction is a register operand
signal ex_mem_reg_write: STD_LOGIC := '0'; -- latch the reg_write signal from execute to memory
signal mem_wb_reg_write: STD_LOGIC := '0'; -- latch the reg_write signal from memory to writeback
begin
-- data memory
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

-- instruction memory
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

-- trigger when opcode, funct3 and funct7 are changed
-- TODO: 
-- Input: opcode, funct3, funct7
-- Output: assign the correct id_alu_op
-- This is combinational logic triggered by sensitivities in opcode, funct3 and funct7. 
-- This is used to ensure decode finishes in 1 cc
process(opcode, funct3, funct7) 
begin
    -- reset to default
    id_alu_op <= "0000";

    -- determine which process 
    case opcode is

    end case; 
    -- determine control signal
    if (opcode = OPCODE_LOAD) then
        -- load op
        id_mem_read <= '1';
        id_mem_write <= '0';
        id_reg_write <= '0';
    elsif (opcode = OPCODE_STORE) then
        -- store op
        id_mem_write <= '1';
        id_mem_read <= '0';
        id_reg_write <= '0';
    elsif (opcode = OPCODE_R) then
        -- ALU with register
        id_reg_write <= '1';
        id_mem_read <= '0';
        id_mem_write <= '0';
    else 
        -- rest of ALU
        id_mem_read <= '0';
        id_mem_write <= '0';
        id_reg_write <= '0';
    end if;
    -- go back to execute 
end process;

-- processor pipeline 
process(clock, reset)
begin
    if (reset = '1') then 
        -- reset all intermediate signals here
    elsif (rising_edge(clock)) then
        -- IF stage
        if (fetch_busy = '0') then
            -- tell memory to get the data
            i_read <= '1';
            i_addr <= pc;
            fetch_busy <= '1';
            fetch_count <= 0;
        else 
            -- only take data when request served
            if i_waitrequest = '0' then
            -- Retrieve 4 bytes, but each memory access returns 1 byte
                instr(fetch_count*8+7 downto fetch_count*8) <= i_readdata;

                -- adjust pc and reset to take in another cycle
                if (fetch_count = 3) then
                    i_read <= '0'; -- turn off after retrieving
                    pc <= pc + 4; -- normal cases
                    fetch_busy <= '0';
                    instr_IF_ID <= i_readdata & instr(23 downto 0);
                    -- tell decode to start as we got all 32 bits
                    fetch_done <= '1';
                else 
                    -- not done, continue to fetch another byte
                    fetch_count <= fetch_count + 1;
                    i_addr <= pc + fetch_count + 1;
                end if;
            end if;
        end if;
        
        -- ID stage 
        -- should only decode once instr_IF_ID is filled
        if (fetch_done = '1') then
            fetch_done <= '0';
            -- assign each var the respective value retrieved from fetch 
            opcode <= instr_IF_ID(6 downto 0);
            funct3 <= instr_IF_ID(14 downto 12);
            funct7 <= instr_IF_ID(31 downto 25);
            rs1 <= instr_IF_ID(19 downto 15);
            rs2 <= instr_IF_ID(24 downto 20);
            rd  <= instr_IF_ID(11 downto 7);
        end if;  
        
        -- Latch result from DECODE to EXECUTE
        id_ex_alu_op <= id_alu_op;
        id_ex_rs1_val <= regs(to_integer(unsigned(rs1))); -- 32 bit value stored in rs1
        id_ex_rs2_val <= regs(to_integer(unsigned(rs2))); -- 32 bit value stored in rs2
        id_ex_rd <= rd;
        id_ex_mem_write <= id_mem_write;
        id_ex_mem_read <= id_mem_read;
        id_ex_reg_write <= id_reg_write;


        -- EX stage
        -- TODO
        -- Input: id_ex_alu_op, id_ex_rs1, id_ex_rs2, id_ex_rd
        -- Output: ex_ALU_output
        -- Task: create ALU module that performs the operation
        
        -- latch the control signals for mem stage from decode 
        -- latch the control signals and relevant intermediate results
        ex_mem_mem_read <= id_ex_mem_read;
        ex_mem_mem_write <= id_ex_mem_write;
        ex_mem_rd <= id_ex_rd;
        ex_mem_reg_write <= id_ex_reg_write; 
        ex_mem_ALU_output <= ex_ALU_output;

        -- MEM stage
        if (ex_mem_mem_read = '1') then
            -- perform load 
            -- TODO: implement loading 4 bytes value from mem
            -- Constraint: MEM access only return 1 byte each
        elsif (ex_mem_mem_write = '1') then
            -- perform store
            -- TODO: implement storing 4 bytes value to mem
            -- Constraint: MEM access only performs 1 byte each
        end if;
        -- latch the control signals and relevant intermediate results
        mem_wb_rd <= ex_mem_rd;
        mem_wb_ALU_output <= ex_mem_ALU_output;
        mem_wb_reg_write <= ex_mem_reg_write; 

        -- WB stage
        -- Writing back to registers where needed
        if (mem_wb_reg_write = '1') then
            regs(to_integer(unsigned(mem_wb_rd))) <= mem_wb_ALU_output;
        end if;
    end if;


end process; 
end arch;