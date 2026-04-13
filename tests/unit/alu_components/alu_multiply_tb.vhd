library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_multiply_tb is
end alu_multiply_tb;

architecture behavior of alu_multiply_tb is
    signal alu_op : std_logic_vector(3 downto 0) := (others => '0');
    signal rs1_val, rs2_val : std_logic_vector(31 downto 0) := (others => '0');
    signal output : std_logic_vector(31 downto 0);
begin
    uut: entity work.alu_multiply
        port map (
            alu_op => alu_op,
            rs1_val => rs1_val,
            rs2_val => rs2_val,
            output => output
        );

    process
    begin
        -- Test MUL: 5 * 6 = 30
        alu_op <= "0010";
        rs1_val <= std_logic_vector(to_signed(5, 32));
        rs2_val <= std_logic_vector(to_signed(6, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = 30 
            report "MUL test failed" severity error;

        -- Test MUL with negatives: -5 * 4 = -20
        alu_op <= "0010";
        rs1_val <= std_logic_vector(to_signed(-5, 32));
        rs2_val <= std_logic_vector(to_signed(4, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = -20 
            report "MUL negative test failed" severity error;

        -- Test MUL with negatives: -5 * -6 = 30
        alu_op <= "0010";
        rs1_val <= std_logic_vector(to_signed(-5, 32));
        rs2_val <= std_logic_vector(to_signed(-6, 32));
        wait for 10 ns;
        assert to_integer(signed(output)) = 30 
            report "MUL double negative test failed" severity error;

        -- Test Invalid operation
        alu_op <= "1111";  -- Invalid operation
        rs1_val <= std_logic_vector(to_signed(5, 32));
        rs2_val <= std_logic_vector(to_signed(6, 32));
        wait for 10 ns;
        assert output = (others => '0') 
            report "Invalid op test failed" severity error;

        wait;
    end process;
end behavior;