library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_shift is 
    port(
        alu_op: in std_logic_vector(3 downto 0);
        rs1_val, rs2_val: std_logic_vector(31 downto 0);

        output: out std_logic_vector(31 downto 0)
    );
end alu_shift;

-- covers SLL, SRL, SRA
architecture arch of alu_shift is

    constant ALU_SLL : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRL : std_logic_vector(3 downto 0) := "0111";
    constant ALU_SRA : std_logic_vector(3 downto 0) := "1000";

    signal temp : std_logic_vector(31 downto 0);
    signal shift_amt : integer range 0 to 31;

begin

    shift_amt <= to_integer(unsigned(rs2_val(4 downto 0)));

    process(alu_op, rs1_val, rs2_val, shift_amt)
    begin

        case alu_op is
            when ALU_SLL =>
                temp <= std_logic_vector(shift_left(unsigned(rs1_val), shift_amt));
            when ALU_SRL =>
                temp <= std_logic_vector(shift_right(unsigned(rs1_val), shift_amt));
            when ALU_SRA =>
                temp <= std_logic_vector(shift_right(signed(rs1_val), shift_amt));
            when others =>
                temp <= (others => '0');
        end case;
    end process;
    output <= temp;
end arch;