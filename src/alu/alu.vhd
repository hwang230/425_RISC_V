library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is 
    port(
        alu_op: in std_logic_vector(3 downto 0);
        opcode_type: in std_logic_vector(2 downto 0); 
        opcode: in std_logic_vector(6 downto 0);

        rs1_val: in std_logic_vector(31 downto 0);
        rs2_val: in std_logic_vector(31 downto 0);
        imm12: in std_logic_vector(11 downto 0);
        imm20: in std_logic_vector(19 downto 0);
        pc: in integer;

        output: out std_logic_vector(31 downto 0)
    );
end alu;

architecture arch of alu is

    constant R_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
    constant I_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
    constant S_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
    constant B_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
    constant U_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
    constant J_TYPE: STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";

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

    component alu_arithmetic is
        port(
            alu_op: in std_logic_vector(3 downto 0); 
            rs1_val, rs2_val: std_logic_vector(31 downto 0); 
            output: out std_logic_vector(31 downto 0)
        );
    end component;

    component alu_branch is 
        port(
            alu_op: in std_logic_vector(3 downto 0);
            rs1_val, rs2_val: std_logic_vector(31 downto 0);
            output: out std_logic_vector(31 downto 0)
        );
    end component;

    component alu_logical is 
        port(
            alu_op: in std_logic_vector(3 downto 0);
            rs1_val, rs2_val: std_logic_vector(31 downto 0);
            output: out std_logic_vector(31 downto 0)
        );
    end component;

    component alu_multiply is 
        port(
            alu_op: in std_logic_vector(3 downto 0);
            rs1_val, rs2_val: std_logic_vector(31 downto 0);
            output: out std_logic_vector(31 downto 0)
        );
    end component;

    component alu_shift is 
        port(
            alu_op: in std_logic_vector(3 downto 0);
            rs1_val, rs2_val: std_logic_vector(31 downto 0);
            output: out std_logic_vector(31 downto 0)
        );
    end component;

    signal pc_vec: std_logic_vector(31 downto 0);
    signal op_A, op_B: std_logic_vector(31 downto 0);
    signal arithmetic_res, branch_res, logical_res, multiply_res, shift_res: std_logic_vector(31 downto 0);

begin

    pc_vec <= std_logic_vector(to_signed(pc, 32));

    process(alu_op, opcode_type, opcode, rs1_val, rs2_val, imm12, imm20, pc_vec)
    begin
        case opcode_type is
            when R_TYPE | B_TYPE=>
                op_A <= rs1_val;
                op_B <= rs2_val;
            when I_TYPE | S_TYPE =>
                if (opcode = "1100111") then -- JALR case
                    op_A <= pc_vec;
                    op_B <= x"00000004";
                else -- Standard I-Type (addi, lw, etc.)
                    op_A <= rs1_val;
                    op_B <= (31 downto 12 => imm12(11)) & imm12;
                end if;
            when U_TYPE =>
                if (opcode = "0010111") then op_A <= pc_vec;
                else op_A <= (others => '0'); end if; -- LUI case
                op_B <= imm20 & "000000000000"; -- Upper-shifted 20-bit
            when J_TYPE =>
                op_A <= pc_vec;
                op_B <= x"00000004"; -- Constant 4 for PC+4
            when others =>
                op_A <= (others => '0');
                op_B <= (others => '0');
        end case;
    end process;

    UNIT_ARITH: alu_arithmetic port map(alu_op => alu_op, rs1_val => op_A, rs2_val => op_B, output => arithmetic_res);
    UNIT_BR: alu_branch port map(alu_op => alu_op, rs1_val => op_A, rs2_val => op_B, output => branch_res);
    UNIT_LOGIC: alu_logical port map(alu_op => alu_op, rs1_val => op_A, rs2_val => op_B, output => logical_res);
    UNIT_MULT: alu_multiply port map(alu_op => alu_op, rs1_val => op_A, rs2_val => op_B, output => multiply_res);
    UNIT_SHIFT: alu_shift port map(alu_op => alu_op, rs1_val => op_A, rs2_val => op_B, output => shift_res);

    process(alu_op, arithmetic_res, multiply_res, logical_res, shift_res, branch_res)
    begin
        case alu_op is
            when ALU_ADD | ALU_SUB =>
                output <= arithmetic_res;
            when ALU_MUL =>
                output <= multiply_res;
            when ALU_BEQ | ALU_BGE | ALU_BLT | ALU_BNE | ALU_SLT =>
                output <= branch_res;
            when ALU_AND | ALU_OR | ALU_XOR =>
                output <= logical_res;
            when ALU_SLL | ALU_SRL | ALU_SRA =>
                output <= shift_res;
            when others =>
                output <= (others => '0');
        end case;
    end process;

end arch;