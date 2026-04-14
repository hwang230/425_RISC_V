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

-- signal for fetch
signal fetch_pending: std_Logic := '0';
-- signals for decoding instructions
signal opcode: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000000";
signal opcode_type: STD_LOGIC_VECTOR(2 DOWNTO 0) := (others => '0');
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
    mem_delay : time := 1 ns;
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
constant ram_size_new: integer := 32768/4; -- to define the memory size 
signal d_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
signal d_addr: INTEGER RANGE 0 TO ram_size_new-1 := 0;
signal d_write: STD_LOGIC := '0';
signal d_read: STD_LOGIC := '0';
signal d_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
signal d_waitrequest: STD_LOGIC := '0';

-- memory signals for instruction memory
signal i_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0'); -- won't be needed
signal i_addr: INTEGER RANGE 0 TO ram_size_new-1 := 0;
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

-- intermediate signals for pipeline control
signal id_ex_alu_op: STD_LOGIC_VECTOR(3 downto 0); -- latch the operation
signal id_ex_opcode: STD_LOGIC_VECTOR(6 downto 0); -- latch the opcode
signal if_id_pc : integer := 0;
signal id_ex_pc : integer := 0;
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
signal mem_wb_rd_reg3: STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); -- to store the destination register from previous instruction in WB stage
signal id_ex_op_type: STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- to store the type of the instruction in EX stage for hazard detection
signal ex_mem_op_type: STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- to store the type of the instruction in MEM stage for hazard detection
signal mem_wb_op_type: STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); -- to store the type of the instruction in WB stage for hazard detection
signal id_ex_hazard: STD_LOGIC := '0'; -- to indicate if there is a hazard detected in EX stage
signal ex_mem_hazard: STD_LOGIC := '0'; -- to indicate if there is a hazard detected in MEM stage
signal mem_wb_hazard: STD_LOGIC := '0'; -- to indicate if there is a hazard detected in WB stage
signal uses_rs1: STD_LOGIC := '0'; -- whether current decoded instruction reads rs1
signal uses_rs2: STD_LOGIC := '0'; -- whether current decoded instruction reads rs2

-- prep immediates to be passed into the alu
signal alu_imm12: std_logic_vector(11 downto 0);
signal alu_imm20: std_logic_vector(19 downto 0);

-- signals for calculating branch and jump addresses
signal branch_taken: std_logic;
signal jump_taken: std_logic;
signal flush_taken: std_logic;
signal id_ex_target_imm: signed(31 downto 0);
signal target_address: std_logic_vector(31 downto 0);

-- signal to load from data mem
signal load_pending: std_logic := '0';
signal pending_rd: std_logic_vector(4 downto 0) := (others => '0');
signal pending_reg_write: std_logic := '0';
signal pending_alu_output: std_logic_vector(31 downto 0) := (others => '0');

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

-- select immediate value type
with id_ex_op_type select
alu_imm12 <= 
    id_ex_imm_I when I_TYPE,
    id_ex_imm_S when S_TYPE,
    id_ex_imm_B when B_TYPE,
    (others => '0') when others;

with id_ex_op_type select
alu_imm20 <=
    id_ex_imm_U when U_TYPE,
    id_ex_imm_J when J_TYPE,
    (others => '0') when others;

-- determine whether branch or jump is taken
branch_taken <= '1' when (id_ex_op_type = B_TYPE and ex_ALU_output(0) = '1') else '0';
jump_taken <= '1' when (id_ex_op_type = J_TYPE or (id_ex_op_type = I_TYPE and id_ex_opcode = OPCODE_JALR)) else '0';
flush_taken <= '1' when (branch_taken = '1' or jump_taken = '1') else '0';

-- Calculate the Target Address
-- JALR: target = rs1 + imm (already the ALU result)
-- JAL, Branches: target = PC + Immediate
id_ex_target_imm <= resize(signed(id_ex_imm_B & '0'), 32) when (id_ex_op_type = B_TYPE) else
                    resize(signed(id_ex_imm_J & '0'), 32) when (id_ex_op_type = J_TYPE) else
                    to_signed(0, 32);

target_address <= std_logic_vector((signed(id_ex_rs1_val) + resize(signed(id_ex_imm_I), 32)) and to_signed(-2, 32))
                  when (id_ex_op_type = I_TYPE and id_ex_opcode = OPCODE_JALR) else std_logic_vector(to_signed(id_ex_pc, 32) + id_ex_target_imm);


-- ALU module declaration and signal assignment
ALU: entity work.alu
port map(
    alu_op => id_ex_alu_op,
    opcode_type => id_ex_op_type,
    opcode => id_ex_opcode,
    rs1_val => id_ex_rs1_val,
    rs2_val => id_ex_rs2_val,
    imm12 => alu_imm12,
    imm20 => alu_imm20,
    pc => id_ex_pc,
    output => ex_ALU_output
);

-- processor pipeline 
process(clock, reset)
    -- added variables for decode to get the control siganls within the same cycle
    variable cur_opcode: STD_LOGIC_VECTOR(6 downto 0);
    variable cur_funct3: STD_LOGIC_VECTOR(2 downto 0);
    variable cur_funct7: STD_LOGIC_VECTOR(6 downto 0);
    variable cur_rs1: STD_LOGIC_VECTOR(4 downto 0);
    variable cur_rs2: STD_LOGIC_VECTOR(4 downto 0);
    variable cur_rd: STD_LOGIC_VECTOR(4 downto 0);
    variable cur_opcode_type : STD_LOGIC_VECTOR(2 downto 0);
    variable cur_imm_I: STD_LOGIC_VECTOR(11 downto 0);
    variable cur_imm_S: STD_LOGIC_VECTOR(11 downto 0);
    variable cur_imm_B: STD_LOGIC_VECTOR(11 downto 0);
    variable cur_imm_U: STD_LOGIC_VECTOR(19 downto 0);
    variable cur_imm_J: STD_LOGIC_VECTOR(19 downto 0);
    variable cur_uses_rs1: STD_LOGIC;
    variable cur_uses_rs2: STD_LOGIC;
    variable cur_id_alu_op: STD_LOGIC_VECTOR(3 downto 0);
    variable cur_id_mem_read: STD_LOGIC;
    variable cur_id_mem_write: STD_LOGIC;
    variable cur_id_reg_write: STD_LOGIC;
    variable cur_id_mem_to_reg_write: STD_LOGIC;
    variable stall: STD_LOGIC;
begin
    if (reset = '1') then 
        -- reset all intermediate signals here
        regs <= (others => (others => '0'));
        pc <= 0;
        if_id_instr <= (others => '0');
        if_id_pc <= 0;
        id_ex_alu_op <= (others => '0');
        id_ex_opcode <= (others => '0');
        id_ex_rs1_val <= (others => '0');
        id_ex_rs2_val <= (others => '0');
        id_ex_rd <= (others => '0');
        id_ex_mem_read <= '0';
        id_ex_mem_write <= '0';
        id_ex_mem_to_reg_write <= '0';
        ex_mem_ALU_output <= (others => '0');
        ex_mem_mem_read <= '0';
        ex_mem_mem_write <= '0';
        ex_mem_rd <= (others => '0');
        ex_mem_mem_to_reg_write <= '0';
        ex_mem_rs2_val <= (others => '0');
        mem_wb_rd <= (others => '0');
        mem_wb_ALU_output <= (others => '0');
        id_ex_rd_reg1 <= (others => '0');
        ex_mem_rd_reg2 <= (others => '0');
        mem_wb_rd_reg3 <= (others => '0');
        id_ex_op_type <= (others => '0');
        ex_mem_op_type <= (others => '0');
        mem_wb_op_type <= (others => '0');
        id_ex_hazard <= '0';
        ex_mem_hazard <= '0';
        mem_wb_hazard <= '0';
        uses_rs1 <= '0';
        uses_rs2 <= '0';
    elsif (rising_edge(clock)) then
        -- setting up the control signals for current instruction
        cur_opcode := if_id_instr(6 downto 0);
        cur_funct3 := if_id_instr(14 downto 12);
        cur_funct7 := if_id_instr(31 downto 25);
        cur_rs1 := if_id_instr(19 downto 15);
        cur_rs2 := if_id_instr(24 downto 20);
        cur_rd := if_id_instr(11 downto 7);
        cur_opcode_type := (others => '0');
        cur_imm_I := if_id_instr(31 downto 20);
        cur_imm_S := if_id_instr(31 downto 25) & if_id_instr(11 downto 7);
        cur_imm_B := if_id_instr(31) & if_id_instr(7) & if_id_instr(30 downto 25) & if_id_instr(11 downto 8);
        cur_imm_U := if_id_instr(31 downto 12);
        cur_imm_J := if_id_instr(31) & if_id_instr(19 downto 12) & if_id_instr(20) & if_id_instr(30 downto 21);

        -- determine if the current instruction uses rs1 and rs2 for hazard detection
        if (cur_opcode = OPCODE_R or cur_opcode = OPCODE_STORE or cur_opcode = OPCODE_B) then
            cur_uses_rs1 := '1';
            cur_uses_rs2 := '1';
        elsif (cur_opcode = OPCODE_IMM or cur_opcode = OPCODE_LOAD or cur_opcode = OPCODE_JALR) then
            cur_uses_rs1 := '1';
            cur_uses_rs2 := '0';
        else
            cur_uses_rs1 := '0';
            cur_uses_rs2 := '0';
        end if;

        -- Decode ALU and writeback/memory controls locally so ID/EX sees a
        -- self-consistent set of values in this clock cycle.
        cur_id_alu_op := ALU_ADD;
        cur_id_mem_read := '0';
        cur_id_mem_write := '0';
        cur_id_reg_write := '0';
        cur_id_mem_to_reg_write := '0';

        case cur_opcode is
            when OPCODE_R =>
                cur_opcode_type := R_TYPE;
                cur_id_reg_write := '1';
                if (cur_funct7 = "0000001" and cur_funct3 = "000") then
                    cur_id_alu_op := ALU_MUL;
                else
                    case cur_funct3 is
                        when "000" =>
                            if (cur_funct7 = "0100000") then
                                cur_id_alu_op := ALU_SUB;
                            else
                                cur_id_alu_op := ALU_ADD;
                            end if;
                        when "100" =>
                            cur_id_alu_op := ALU_XOR;
                        when "110" =>
                            cur_id_alu_op := ALU_OR;
                        when "111" =>
                            cur_id_alu_op := ALU_AND;
                        when "001" =>
                            cur_id_alu_op := ALU_SLL;
                        when "010" | "011" =>
                            cur_id_alu_op := ALU_SLT;
                        when "101" =>
                            if (cur_funct7 = "0100000") then
                                cur_id_alu_op := ALU_SRA;
                            else
                                cur_id_alu_op := ALU_SRL;
                            end if;
                        when others =>
                            cur_id_alu_op := ALU_ADD;
                    end case;
                end if;

            when OPCODE_IMM =>
                cur_opcode_type := I_TYPE;
                cur_id_reg_write := '1';
                case cur_funct3 is
                    when "000" =>
                        cur_id_alu_op := ALU_ADD;
                    when "100" =>
                        cur_id_alu_op := ALU_XOR;
                    when "110" =>
                        cur_id_alu_op := ALU_OR;
                    when "111" =>
                        cur_id_alu_op := ALU_AND;
                    when "001" =>
                        cur_id_alu_op := ALU_SLL;
                    when "010" | "011" =>
                        cur_id_alu_op := ALU_SLT;
                    when "101" =>
                        if (cur_funct7 = "0100000") then
                            cur_id_alu_op := ALU_SRA;
                        else
                            cur_id_alu_op := ALU_SRL;
                        end if;
                    when others =>
                        cur_id_alu_op := ALU_ADD;
                end case;

            when OPCODE_LOAD =>
                cur_opcode_type := I_TYPE;
                cur_id_alu_op := ALU_ADD;
                cur_id_mem_read := '1';
                cur_id_reg_write := '1';
                cur_id_mem_to_reg_write := '1';

            when OPCODE_STORE =>
                cur_opcode_type := S_TYPE;
                cur_id_alu_op := ALU_ADD;
                cur_id_mem_write := '1';

            when OPCODE_B =>
                cur_opcode_type := B_TYPE;
                case cur_funct3 is
                    when "000" =>
                        cur_id_alu_op := ALU_BEQ;
                    when "001" =>
                        cur_id_alu_op := ALU_BNE;
                    when "100" | "110" =>
                        cur_id_alu_op := ALU_BLT;
                    when "101" | "111" =>
                        cur_id_alu_op := ALU_BGE;
                    when others =>
                        cur_id_alu_op := ALU_BEQ;
                end case;

            when OPCODE_JAL | OPCODE_JALR | OPCODE_LUI | OPCODE_AUIPC =>
                if (cur_opcode = OPCODE_JAL) then
                    cur_opcode_type := J_TYPE;
                elsif (cur_opcode = OPCODE_JALR) then
                    cur_opcode_type := I_TYPE;
                else
                    cur_opcode_type := U_TYPE;
                end if;
                cur_id_alu_op := ALU_ADD;
                cur_id_reg_write := '1';

            when others =>
                cur_opcode_type := (others => '0');
                cur_id_alu_op := ALU_ADD;
        end case;

        stall := '0';
        
        -- This injects a 1-cycle bubble into EX behind every Load
        if (id_ex_mem_read = '1') then 
            stall := '1';
        end if;
        
        -- logic to determine whether stall is occuring or not
        if (id_ex_reg_write = '1' and id_ex_rd_reg1 /= "00000" and
            ((cur_uses_rs1 = '1' and id_ex_rd_reg1 = cur_rs1) or
             (cur_uses_rs2 = '1' and id_ex_rd_reg1 = cur_rs2))) then
            id_ex_hazard <= '1';
            stall := '1';
        else
            id_ex_hazard <= '0';
        end if;
        if (ex_mem_reg_write = '1' and ex_mem_rd_reg2 /= "00000" and
            ((cur_uses_rs1 = '1' and ex_mem_rd_reg2 = cur_rs1) or
             (cur_uses_rs2 = '1' and ex_mem_rd_reg2 = cur_rs2))) then
            ex_mem_hazard <= '1';
            stall := '1';
        else
            ex_mem_hazard <= '0';
        end if;
        if (mem_wb_reg_write = '1' and mem_wb_rd /= "00000" and
            ((cur_uses_rs1 = '1' and mem_wb_rd = cur_rs1) or
             (cur_uses_rs2 = '1' and mem_wb_rd = cur_rs2))) then
            mem_wb_hazard <= '1';
            stall := '1';
        else
            mem_wb_hazard <= '0';
        end if;

        -- Loads spend one extra cycle in load_pending before MEM/WB updates are
        -- visible to this process, so keep decode stalled on that destination.
        if (load_pending = '1' and pending_reg_write = '1' and pending_rd /= "00000" and
            ((cur_uses_rs1 = '1' and pending_rd = cur_rs1) or
             (cur_uses_rs2 = '1' and pending_rd = cur_rs2))) then
            stall := '1';
        end if;

        --------------
        -- IF stage --
        --------------

        -- Default: do not issue a new read unless we choose to below
        i_read <= '0';

        -- Control transfer has priority
        if (flush_taken = '1') then
            pc <= to_integer(unsigned(target_address));

            -- flush younger fetched instruction
            if_id_instr <= (others => '0');
            if_id_pc <= 0;

            -- cancel any in-flight fetch bookkeeping
            fetch_pending <= '0';

        elsif (stall = '0') then
            if (fetch_pending = '0') then
                -- Step 1: issue memory read for current PC
                i_addr <= pc / 4;
                i_read <= '1';
                -- to account for one cycle delay from accessing instruction memory
                fetch_pending <= '1';

            elsif (i_waitrequest = '0') then
                -- Step 2: returned instruction is now valid
                if_id_instr <= i_readdata;
                if_id_pc <= pc;

                -- advance PC only after instruction is accepted
                pc <= pc + 4;

                -- lower the control after finishing the fetch
                fetch_pending <= '0';
            end if;
        end if;

        --------------
        -- ID stage --
        -------------- 

        -- assign each var the respective value retrieved from fetch 
        -- if stall occurs, if_id_instr will not get updated and the same instruction will
        -- stay in decode until hazard resolved
        -- Simply latch the signals here
        opcode <= cur_opcode;
        opcode_type <= cur_opcode_type;
        funct3 <= cur_funct3;
        funct7 <= cur_funct7;
        rs1 <= cur_rs1;
        rs2 <= cur_rs2;
        rd  <= cur_rd;
        imm_I <= cur_imm_I;
        imm_S <= cur_imm_S;
        imm_B <= cur_imm_B;
        imm_U <= cur_imm_U;
        imm_J <= cur_imm_J;
        uses_rs1 <= cur_uses_rs1;
        uses_rs2 <= cur_uses_rs2;


        -- Latch result from DECODE to EXECUTE
        -- when stall occurs, insert NOPs
        if (stall = '1' or flush_taken = '1') then
            -- insert addi x0, x0, 0 as the bubble instruction in EX stage
            id_ex_alu_op <= "0000";
            id_ex_opcode <= "0000000";
            id_ex_pc <= 0;
            id_ex_rs1_val <= (others => '0');
            id_ex_rs2_val <= (others => '0');
            id_ex_rd <= "00000";
            id_ex_mem_write <= '0';
            id_ex_mem_read <= '0';
            id_ex_reg_write <= '0';
            id_ex_mem_to_reg_write <= '0';
            id_ex_imm_I <= (others => '0');
            id_ex_imm_S <= (others => '0');
            id_ex_imm_B <= (others => '0');
            id_ex_imm_U <= (others => '0');
            id_ex_imm_J <= (others => '0');
            id_ex_rd_reg1 <= (others => '0'); 
            id_ex_op_type <= (others => '0');
        else
            -- if no stalls, simply latch the values from decode to execute
            id_ex_alu_op <= cur_id_alu_op;
            id_ex_opcode <= cur_opcode;
            id_ex_pc <= if_id_pc;
            id_ex_rs1_val <= regs(to_integer(unsigned(cur_rs1))); -- 32 bit value stored in rs1
            id_ex_rs2_val <= regs(to_integer(unsigned(cur_rs2))); -- 32 bit value stored in rs2
            id_ex_rd <= cur_rd;
            id_ex_mem_write <= cur_id_mem_write;
            id_ex_mem_read <= cur_id_mem_read;
            id_ex_reg_write <= cur_id_reg_write;
            id_ex_mem_to_reg_write <= cur_id_mem_to_reg_write;
            id_ex_imm_I <= cur_imm_I;
            id_ex_imm_S <= cur_imm_S;
            id_ex_imm_B <= cur_imm_B;
            id_ex_imm_U <= cur_imm_U;
            id_ex_imm_J <= cur_imm_J;
            id_ex_rd_reg1 <= cur_rd; -- for hazard detection
            id_ex_op_type <= cur_opcode_type; -- decoded instruction type for later stages
        end if;

        --------------
        -- EX stage --
        --------------
        -- latch the control signals for mem stage from decode 
        -- main logic already performed in the ALU module, we just need to latch the 
        -- results and the controls signals to MEM stage
        ex_mem_mem_read <= id_ex_mem_read;
        ex_mem_mem_write <= id_ex_mem_write;
        ex_mem_rd <= id_ex_rd;
        ex_mem_reg_write <= id_ex_reg_write; 
        ex_mem_ALU_output <= ex_ALU_output;
        ex_mem_mem_to_reg_write <= id_ex_mem_to_reg_write;
        ex_mem_rs2_val <= id_ex_rs2_val;
        ex_mem_rd_reg2 <= id_ex_rd_reg1; -- for hazard detection
        ex_mem_op_type <= id_ex_op_type; -- for hazard detection
        ex_mem_reg_write <= id_ex_reg_write; -- for hazard detection

        ---------------
        -- MEM stage --
        ---------------

        -- turn off the data mem signals before then turn it on afterwards if necessary
        d_write <= '0';
        d_read <= '0';
        if load_pending = '1' then
            -- Second iter goes in here for load
            -- Data is ready in d_readdata
            mem_wb_read_data <= d_readdata;
            mem_wb_rd <= pending_rd;
            mem_wb_rd_reg3 <= pending_rd;
            mem_wb_reg_write <= pending_reg_write;
            mem_wb_mem_to_reg_write <= '1';
            mem_wb_op_type <= I_TYPE;
            -- lower the signal to ensure loading finished
            load_pending <= '0';

        elsif ex_mem_mem_read = '1' then
            -- set the addr and read signal
            d_read <= '1';
            d_addr <= to_integer(unsigned(ex_mem_ALU_output(31 downto 2)));

            -- this accounts for the extra cycle required to receive the data back
            -- First iter goes in here for load
            pending_rd <= ex_mem_rd;
            pending_reg_write <= ex_mem_reg_write;
            pending_alu_output <= ex_mem_ALU_output;
            load_pending <= '1';

        elsif ex_mem_mem_write = '1' then
            -- set the addr, writedata and write signal
            d_write <= '1';
            d_addr <= to_integer(unsigned(ex_mem_ALU_output(31 downto 2)));
            d_writedata <= ex_mem_rs2_val;

            -- latch the signals
            mem_wb_rd <= ex_mem_rd;
            mem_wb_rd_reg3 <= ex_mem_rd;
            mem_wb_ALU_output <= ex_mem_ALU_output;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg_write <= ex_mem_mem_to_reg_write;
            mem_wb_op_type <= ex_mem_op_type;
        else
            -- default: just latch the values
            mem_wb_rd <= ex_mem_rd;
            mem_wb_rd_reg3 <= ex_mem_rd;
            mem_wb_ALU_output <= ex_mem_ALU_output;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg_write <= ex_mem_mem_to_reg_write;
            mem_wb_op_type <= ex_mem_op_type;
        end if;
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
