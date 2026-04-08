library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_arithmetic is 
    port(
        alu_op: in std_logic_vector(3 downto 0);
        rs2_val, rs1_val: std_logic_vector(31 downto 0);

        output: out std_logic_vector(31 downto 0)
    );
end alu_arithmetic;

-- covers AND, ANDI, OR, ORI, XOR, XORI
architecture arch of alu_arithmetic is

    constant ALU_AND : std_logic_vector(3 downto 0) := "0011"; -- cover AND and ANDI
    constant ALU_OR  : std_logic_vector(3 downto 0) := "0100"; -- cover OR and ORI
    constant ALU_XOR : std_logic_vector(3 downto 0) := "0101"; -- cover XORI

    signal temp : std_logic_vector(31 downto 0);

begin

    process(alu_op, rs1_val, rs2_val)
    begin
        case alu_op is
            when ALU_AND =>
                temp <= std_logic_vector(rs1_val and rs2_val);
            when ALU_OR =>
                temp <= std_logic_vector(rs1_val or rs2_val);
            when ALU_XOR =>
                temp <= std_logic_vector(rs1_val xor rs2_val);
            when others =>
                temp <= (others => '0');
        end case;
    end process;
    output <= temp;
end arch;