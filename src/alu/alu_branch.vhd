library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_branch is 
    port(
        alu_op: in std_logic_vector(3 downto 0);
        rs2_val, rs1_val: std_logic_vector(31 downto 0);

        output: out std_logic_vector(31 downto 0)
    );
end alu_branch;

-- covers SLT, SLTI, BEQ, BNE, BLT, BGE
architecture arch of alu_branch is

    constant ALU_SLT : std_logic_vector(3 downto 0) := "1001"; -- cover SLTI
    constant ALU_BEQ : std_logic_vector(3 downto 0) := "1010";
    constant ALU_BNE : std_logic_vector(3 downto 0) := "1011";
    constant ALU_BLT : std_logic_vector(3 downto 0) := "1100";
    constant ALU_BGE : std_logic_vector(3 downto 0) := "1101";

    signal temp : std_logic;

begin

    process(alu_op, rs1_val, rs2_val)
    begin
        case alu_op is
            when ALU_BEQ =>
                if rs1_val = rs2_val then
                    temp <= '1';
                else
                    temp <= '0';
                end if;
            when ALU_BNE =>
                if rs1_val /= rs2_val then
                    temp <= '1';
                else
                    temp <= '0';
                end if;
            when ALU_BLT | ALU_SLT =>
                if signed(rs1_val) < signed(rs2_val) then
                    temp <= '1';
                else
                    temp <= '0';
                end if;
            when ALU_BGE =>
                if signed(rs1_val) >= signed(rs2_val) then
                    temp <= '1';
                else
                    temp <= '0';
                end if;
            when others =>
                temp <= '0';
        end case;
    end process;
    output <= (0 => temp, others => '0');
end arch;