library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_logical_tb is
end alu_logical_tb;

architecture behavior of alu_logical_tb is
    signal alu_op : std_logic_vector(3 downto 0) := (others => '0');
    signal rs1_val, rs2_val : std_logic_vector(31 downto 0) := (others => '0');
    signal output : std_logic_vector(31 downto 0);
begin
    uut: entity work.alu_logical
        port map (
            alu_op => alu_op,
            rs1_val => rs1_val,
            rs2_val => rs2_val,
            output => output
        );

    process
    begin
        -- Test AND: 0xAAAAAAAA & 0x55555555 = 0x00000000
        alu_op <= "0011";
        rs1_val <= x"AAAAAAAA";
        rs2_val <= x"55555555";
        wait for 10 ns;
        assert output = x"00000000" 
            report "AND test failed" severity error;

        -- Test OR: 0xAAAAAAAA | 0x55555555 = 0xFFFFFFFF
        alu_op <= "0100";
        rs1_val <= x"AAAAAAAA";
        rs2_val <= x"55555555";
        wait for 10 ns;
        assert output = x"FFFFFFFF" 
            report "OR test failed" severity error;

        -- Test XOR: 0xAAAAAAAA ^ 0x00000000 = 0xAAAAAAAA
        alu_op <= "0101";
        rs1_val <= x"AAAAAAAA";
        rs2_val <= x"00000000";
        wait for 10 ns;
        assert output = x"AAAAAAAA" 
            report "XOR test failed" severity error;

        -- Test Invalid operation
        alu_op <= "1111";  -- Invalid operation
        rs1_val <= x"AAAAAAAA";
        rs2_val <= x"55555555";
        wait for 10 ns;
        assert output = (others => '0') 
            report "Invalid op test failed" severity error;

        wait;
    end process;
end behavior;