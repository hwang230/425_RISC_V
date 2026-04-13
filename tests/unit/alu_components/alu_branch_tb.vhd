library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_branch_tb is
end alu_branch_tb;

architecture behavior of alu_branch_tb is
    signal alu_op : std_logic_vector(3 downto 0) := (others => '0');
    signal rs1_val, rs2_val : std_logic_vector(31 downto 0) := (others => '0');
    signal output : std_logic_vector(31 downto 0);
begin
    uut: entity work.alu_branch
        port map (
            alu_op => alu_op,
            rs1_val => rs1_val,
            rs2_val => rs2_val,
            output => output
        );

    process
    begin
        report "starting branch component tests" severity warning;

        -- Test BEQ: Equal values -> Output should be 1
        alu_op <= "1010";
        rs1_val <= std_logic_vector(to_signed(50, 32));
        rs2_val <= std_logic_vector(to_signed(50, 32));
        wait for 10 ns;
        assert output = x"00000001" 
            report "BEQ test failed" severity error;

        -- Test BNE: Unequal values -> Output should be 1
        alu_op <= "1011";
        rs1_val <= std_logic_vector(to_signed(50, 32));
        rs2_val <= std_logic_vector(to_signed(100, 32));
        wait for 10 ns;
        assert output = x"00000001" 
            report "BNE test failed" severity error;

        -- Test BLT/SLT: rs1 < rs2 -> Output should be 1
        alu_op <= "1100";
        rs1_val <= std_logic_vector(to_signed(-10, 32));
        rs2_val <= std_logic_vector(to_signed(10, 32));
        wait for 10 ns;
        assert output = x"00000001" 
            report "BLT test failed" severity error;

        -- Test BGE: rs1 >= rs2 -> Output should be 1
        alu_op <= "1101";
        rs1_val <= std_logic_vector(to_signed(20, 32));
        rs2_val <= std_logic_vector(to_signed(10, 32));
        wait for 10 ns;
        assert output = x"00000001" 
            report "BGE test failed" severity error;

        -- Test BEQ false condition
        alu_op <= "1010";
        rs1_val <= std_logic_vector(to_signed(50, 32));
        rs2_val <= std_logic_vector(to_signed(60, 32));
        wait for 10 ns;
        assert output = x"00000000" 
            report "BEQ false test failed" severity error;

        -- Test Invalid operation
        alu_op <= "1111";  -- Invalid operation
        rs1_val <= std_logic_vector(to_signed(50, 32));
        rs2_val <= std_logic_vector(to_signed(50, 32));
        wait for 10 ns;
        assert output = x"00000000" 
            report "Invalid op test failed" severity error;

        report "branch component testing done" severity warning;
        wait;
    end process;
end behavior;