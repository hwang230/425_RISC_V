library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_shift_tb is
end alu_shift_tb;

architecture behavior of alu_shift_tb is
    signal alu_op : std_logic_vector(3 downto 0) := (others => '0');
    signal rs1_val, rs2_val : std_logic_vector(31 downto 0) := (others => '0');
    signal output : std_logic_vector(31 downto 0);
begin
    uut: entity work.alu_shift
        port map (
            alu_op => alu_op,
            rs1_val => rs1_val,
            rs2_val => rs2_val,
            output => output
        );

    process
    begin
        report "starting shift component testing" severity warning;

        -- Test SLL: Shift left logical by 4 (0x00000001 << 4 = 0x00000010)
        alu_op <= "0110";
        rs1_val <= x"00000001";
        rs2_val <= x"00000004";
        wait for 10 ns;
        assert output = x"00000010" 
            report "SLL test failed" severity error;

        -- Test SRL: Shift right logical by 4 (0xF0000000 >> 4 = 0x0F000000)
        alu_op <= "0111";
        rs1_val <= x"F0000000";
        rs2_val <= x"00000004";
        wait for 10 ns;
        assert output = x"0F000000" 
            report "SRL test failed" severity error;

        -- Test SRA: Shift right arithmetic by 4 (0xF0000000 >> 4 = 0xFF000000, preserves sign)
        alu_op <= "1000";
        rs1_val <= x"F0000000";
        rs2_val <= x"00000004";
        wait for 10 ns;
        assert output = x"FF000000" 
            report "SRA test failed" severity error;

        -- Test Invalid operation
        alu_op <= "1111";  -- Invalid operation
        rs1_val <= x"F0000000";
        rs2_val <= x"00000004";
        wait for 10 ns;
        assert output = x"00000000" 
            report "Invalid op test failed" severity error;

        report "shift component testing done" severity warning;
        wait;
    end process;
end behavior;