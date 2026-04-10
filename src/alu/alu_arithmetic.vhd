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

-- covers ADD, ADDI, SUB
architecture arch of alu_arithmetic is

    constant ALU_ADD : std_logic_vector(3 downto 0) := "0000"; -- cover ADD and ADDI
    constant ALU_SUB : std_logic_vector(3 downto 0) := "0001";

    signal temp : std_logic_vector(32 downto 0);

begin

    process(alu_op, rs1_val, rs2_val)
    begin
        case alu_op is
            when ALU_ADD =>
                temp <= std_logic_vector(resize(signed(rs1_val), 33) + resize(signed(rs2_val), 33));
            when ALU_SUB =>
                temp <= std_logic_vector(resize(signed(rs1_val), 33) - resize(signed(rs2_val), 33));
            when others =>
                temp <= (others => '0');
        end case;
    end process;
    output <= temp(31 downto 0);
end arch;