library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity processor_tb is
end processor_tb;

architecture behavior of processor_tb is

component processor is
    port(
        clock : in std_logic;
        reset : in std_logic
    );
end component;

signal clock : std_logic := '0';
signal reset : std_logic := '0';

constant clk_period : time := 1 ns;
constant run_cycles : natural := 10000;

begin

dut: processor
port map(
    clock => clock,
    reset => reset
);

clk_process : process
begin
    loop
        clock <= '0';
        wait for clk_period / 2;
        clock <= '1';
        wait for clk_period / 2;
    end loop;
end process;

stimulus : process
begin
    report "Starting processor testbench";

    reset <= '1';
    wait for 5 * clk_period;
    wait until rising_edge(clock);
    reset <= '0';

    -- Run the processor for 10000 cycles
    for cycle in 1 to run_cycles loop
        wait until rising_edge(clock);
    end loop;

    report "Simulation Completed: The output files are memory.txt and register_file.txt";
    stop;
end process;

end behavior;
