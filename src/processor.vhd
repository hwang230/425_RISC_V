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

-- type of operations
constant R_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
constant I_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
constant S_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
constant B_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
constant U_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
constant J_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";

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
    writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size/4-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;

-- memory signals for data memory
constant ram_size_: integer := 32768/4; -- to define the memory size 
signal d_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
signal d_addr: INTEGER RANGE 0 TO ram_size_-1 := 0;
signal d_write: STD_LOGIC := '0';
signal d_read: STD_LOGIC := '0';
signal d_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
signal d_waitrequest: STD_LOGIC := '0';

-- memory signals for instruction memory
signal i_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0'); -- won't be needed
signal i_addr: INTEGER RANGE 0 TO ram_size_-1 := 0;
signal i_write: STD_LOGIC := '0'; -- won't be needed
signal i_read: STD_LOGIC := '0';
signal i_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
signal i_waitrequest: STD_LOGIC := '0';

-- declare the register file
-- initialize to all 0s
type reg_file_t is array (0 to 31) of std_logic_vector(31 downto 0);
signal regs: reg_file_t := (others => (others => '0')); -- register file with 32 registers with 32 bits each
signal pc: INTEGER := 0; -- program counter
signal if_id_instr: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0'); -- to latch instruction from fetch to decode

-- intermediate signal to inform next stage to proceed
signal start_new_fetch: STD_LOGIC := '1'; -- to inform fetch stage to fetch new instructions 
signal id_alu_op: STD_LOGIC_VECTOR(3 downto 0); 
signal id_mem_read: STD_LOGIC := '0'; -- store control signal for load operation
signal id_mem_write: STD_LOGIC := '0'; -- store control signal for store operation
signal id_mem_to_reg_write: STD_LOGIC := '0'; -- store control signal for mem to register operation
signal id_reg_write: STD_LOGIC := '0'; -- store control signal for load operation
signal id_ex_alu_op: STD_LOGIC_VECTOR(3 downto 0); -- latch the operation
signal id_ex_rs2_val, id_ex_rs1_val: STD_LOGIC_VECTOR(31 downto 0); -- latch the values from registrs
signal id_ex_rd: STD_LOGIC_VECTOR(4 downto 0); -- latch the destination register
signal id_ex_mem_read: STD_LOGIC := '0'; -- to indicate if instruction requires access to data memory (latched from decode)
signal id_ex_mem_write: STD_LOGIC := '0'; -- to indicate if instruction requires access to data memory (latched from decode)
signal id_ex_mem_to_reg_write: STD_LOGIC := '0'; -- to latch the mem_to_reg controls signal
signal ex_ALU_output: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- result from ALU
signal ex_mem_ALU_output: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- latch ALU result onto register
signal ex_mem_mem_read: STD_LOGIC := '0'; -- to latch the signal from decode to memory for load
signal ex_mem_mem_write: STD_LOGIC := '0'; -- to latch the signal from decode to memory for store
signal ex_mem_rd: STD_LOGIC_VECTOR(4 downto 0); -- latch the rd from EX to MEM
signal ex_mem_mem_to_reg_write: STD_LOGIC := '0'; -- latch the mem_to_reg signal
signal ex_mem_rs2_val: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- to latch rs2 value for store
signal mem_wb_rd: STD_LOGIC_VECTOR(4 downto 0); -- latch the rd from EX to MEM
signal mem_wb_ALU_output: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- latch alu output from ex_mem to mem_wb
signal id_ex_reg_write: STD_LOGIC := '0'; -- check if the instruction is a register operand
signal ex_mem_reg_write: STD_LOGIC := '0'; -- latch the reg_write signal from execute to memory
signal mem_wb_reg_write: STD_LOGIC := '0'; -- latch the reg_write signal from memory to writeback
signal mem_wb_mem_to_reg_write: STD_LOGIC := '0'; -- latch the mem_to_reg signal from memory to writeback
signal mem_mem_transfer_done: STD_LOGIC := '0'; -- to indicate if the memory operations in MEM is completed or not
signal mem_read_data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- to store the read data
signal mem_wb_read_data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- to latch read data

-- for decode to store the immediate values
signal imm_I: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal imm_S: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal imm_B: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal imm_U: STD_LOGIC_VECTOR(19 downto 0) := (others => '0');
signal imm_J: STD_LOGIC_VECTOR(19 downto 0) := (others  => '0');
-- for execute to store the immediate values
signal id_ex_imm_I: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal id_ex_imm_S: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal id_ex_imm_B: STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal id_ex_imm_U: STD_LOGIC_VECTOR(19 downto 0) := (others => '0');
signal id_ex_imm_J: STD_LOGIC_VECTOR(19 downto 0) := (others => '0');

-- for hazard detection: store the destination register from previous instructions
signal id_ex_rd_reg1: STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); -- to store the destination register from previous instruction in EX stage
signal ex_mem_rd_reg2: STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); -- to store the destination register from previous instruction in MEM stage
signal id_ex_op_type: STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- to store the type of the instruction in EX stage for hazard detection
signal ex_mem_op_type: STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- to store the type of the instruction in MEM stage for hazard detection

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
        id_reg_write <= '1';
        id_mem_to_reg_write <= '1';
    elsif (opcode = OPCODE_STORE) then
        -- store op
        id_mem_write <= '1';
        id_mem_read <= '0';
        id_reg_write <= '0';
        id_mem_to_reg_write <= '0';
    elsif (opcode = OPCODE_R or opcode = OPCODE_IMM) then
        -- ALU with register
        id_reg_write <= '1';
        id_mem_read <= '0';
        id_mem_write <= '0';
        id_mem_to_reg_write <= '0';
    else 
        -- rest of ALU
        id_mem_read <= '0';
        id_mem_write <= '0';
        id_reg_write <= '0';
        id_mem_to_reg_write <= '0';
    end if;
    -- go back to execute 
end process;

-- processor pipeline 
process(clock, reset)
begin
    if (reset = '1') then 
        -- reset all intermediate signals here
    elsif (rising_edge(clock)) then

        --------------
        -- IF stage --
        --------------
        i_read <= '0';
        -- TODO: stall if hazard detected in ID 
        if (start_new_fetch = '1') then
            i_read <= '1';
            i_addr <= pc/4;
        end if;
        if (i_waitrequest = '0') then
            if_id_instr <= i_readdata;
            pc <= pc + 4;
        end if;

        --------------
        -- ID stage --
        -------------- 
        -- TODO: implement hazard detection
        -- Constraint: Check if the destination register from previous instructions are needed in either rs1 or rs2
        -- If hazard, should stall until the instruction completes 
        -- assign each var the respective value retrieved from fetch 
        opcode <= if_id_instr(6 downto 0);
        funct3 <= if_id_instr(14 downto 12);
        funct7 <= if_id_instr(31 downto 25);
        rs1 <= if_id_instr(19 downto 15);
        rs2 <= if_id_instr(24 downto 20);
        rd  <= if_id_instr(11 downto 7);
        imm_I <= if_id_instr(31 downto 20);
        imm_S <= if_id_instr(31 downto 25) & if_id_instr(11 downto 7);
        imm_B <= if_id_instr(31) & if_id_instr(7) & if_id_instr(30 downto 25) & if_id_instr(11 downto 8);
        imm_U <= if_id_instr(31 downto 12);
        imm_J <= if_id_instr(31) & if_id_instr(19 downto 12) & if_id_instr(20) & if_id_instr(30 downto 21);
        
        -- Latch result from DECODE to EXECUTE
        id_ex_alu_op <= id_alu_op;
        id_ex_rs1_val <= regs(to_integer(unsigned(rs1))); -- 32 bit value stored in rs1
        id_ex_rs2_val <= regs(to_integer(unsigned(rs2))); -- 32 bit value stored in rs2
        id_ex_rd <= rd;
        id_ex_mem_write <= id_mem_write;
        id_ex_mem_read <= id_mem_read;
        id_ex_reg_write <= id_reg_write;
        id_ex_mem_to_reg_write <= id_mem_to_reg_write;
        id_ex_imm_I <= imm_I;
        id_ex_imm_S <= imm_S;
        id_ex_imm_B <= imm_B;
        id_ex_imm_U <= imm_U;
        id_ex_imm_J <= imm_J;
        
        --------------
        -- EX stage --
        --------------

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
        ex_mem_mem_to_reg_write <= id_ex_mem_to_reg_write;
        ex_mem_rs2_val <= id_ex_rs2_val;

        ---------------
        -- MEM stage --
        ---------------

        -- turn off the data mem signals before then turn it on afterwards if necessary
        d_write <= '0';
        d_read <= '0';
        if (ex_mem_mem_read = '1') then
            -- perform load: MEM access now return 4 bytes each
            d_read <= '1';
            d_addr <= to_integer(unsigned(ex_mem_ALU_output(31 downto 2)));
            if (d_waitrequest = '0') then
                mem_wb_read_data <= d_readdata;
            end if;
        elsif (ex_mem_mem_write = '1') then
            -- perform store
            d_write <= '1';
            d_addr <= to_integer(unsigned(ex_mem_ALU_output(31 downto 2)));
            d_writedata <= ex_mem_rs2_val;
        end if;
        -- latch the control signals and relevant intermediate results

        mem_wb_rd <= ex_mem_rd;
        mem_wb_ALU_output <= ex_mem_ALU_output;
        mem_wb_reg_write <= ex_mem_reg_write; 
        mem_wb_mem_to_reg_write <= ex_mem_mem_to_reg_write;

        --------------
        -- WB stage --
        --------------
        
        -- Writing back to registers where needed
        -- protect x0 register 
        if (mem_wb_reg_write = '1' and mem_wb_rd /= "00000") then
            if (mem_wb_mem_to_reg_write = '1') then
                -- load
                regs(to_integer(unsigned(mem_wb_rd))) <= mem_wb_read_data;
            else 
                -- regular R-type operation
                regs(to_integer(unsigned(mem_wb_rd))) <= mem_wb_ALU_output;
            end if;
            
        end if;
    end if;


end process; 
end arch;