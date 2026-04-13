library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_arithmetic_tb is
end alu_arithmetic_tb;

architecture behavior of alu_arithmetic_tb is
    signal alu_op : std_logic_vector(3 downto 0) := (others => '0');
    signal rs1_val, rs2_val : std_logic_vector(31 downto 0) := (others => '0');
    signal output : std_logic_vector(31 downto 0);
begin
    uut: entity work.alu_arithmetic
        port map (
            alu_op => alu_op,
            rs1_val => rs1_val,
            rs2_val => rs2_val,
            output => output
        );

    process
    begin
        report "starting arithmetic component tests" severity warning;

        -- Test ADD: 15 + 10 = 25
        alu_op <= "0000";
        rs1_val <= std_logic_vector(to_signed(15, 32));
        rs2_val <= std_logic_vector(to_signed(10, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = 25 
            report "ADD test failed" severity error;

        -- Test SUB: 15 - 10 = 5
        alu_op <= "0001";
        rs1_val <= std_logic_vector(to_signed(15, 32));
        rs2_val <= std_logic_vector(to_signed(10, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = 5 
            report "SUB test failed" severity error;

        -- Test SUB with negative result
        alu_op <= "0001";
        rs1_val <= std_logic_vector(to_signed(5, 32));
        rs2_val <= std_logic_vector(to_signed(10, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = -5 
            report "SUB test failed" severity error;

        -- Test Invalid operation
        alu_op <= "1111";  -- Invalid operation
        rs1_val <= std_logic_vector(to_signed(15, 32));
        rs2_val <= std_logic_vector(to_signed(10, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = 0 report "Invalid op test failed" severity error;

        report "arithmetic component testing done" severity warning;
        wait;
    end process;
end behavior;