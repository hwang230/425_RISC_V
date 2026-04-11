library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_multiply is 
    port(
        alu_op: in std_logic_vector(3 downto 0);
        rs1_val, rs2_val: std_logic_vector(31 downto 0);

        output: out std_logic_vector(31 downto 0)
    );
end alu_multiply;

-- covers MUL
architecture arch of alu_multiply is

    constant ALU_MUL : std_logic_vector(3 downto 0) := "0010";

    signal temp : std_logic_vector(63 downto 0);
    signal signed_rs1_val, signed_rs2_val : signed(31 downto 0);

begin

    signed_rs1_val <= signed(rs1_val);
    signed_rs2_val <= signed(rs2_val);

    process(alu_op, signed_rs1_val, signed_rs2_val)
    begin

        case alu_op is
            when ALU_MUL =>
                temp <= std_logic_vector(signed_rs1_val * signed_rs2_val);
            when others =>
                temp <= (others => '0');
        end case;
    end process;
    output <= temp(31 downto 0);
end arch;