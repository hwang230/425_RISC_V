library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_mm is
	generic(
		ram_size : INTEGER := 32768;
	);

	port(
		clk: in std_logic;
		reset: in std_logic;
		
--		data translator
		op_type: in std_logic; -- read or write
		busy: out std_logic;
		
		
		in_block: in std_logic_vector(127 downto 0);
		out_block: out std_logic_vector(127 downto 0); 
		
		
		m_addr : out integer range 0 to ram_size-1;
		m_read : out std_logic;
		m_readdata : in std_logic_vector(7 downto 0);
		m_write : out std_logic;
		m_writedata : out std_logic_vector(7 downto 0);
		m_waitrequest : in std_logic
	);

architecture interface of avalon_mm is	
	signal byte_counter: integer := 0;
begin
process(clk, reset)
begin

end process;