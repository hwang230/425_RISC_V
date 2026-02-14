library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avalon_mm is
	generic(
		ram_size : INTEGER := 32768
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		
--		data translator
		op_type: in std_logic; -- read or write
		mem_waitrequest : in std_logic;
		mem_readdata : in std_logic_vector(7 downto 0);
		in_block: in std_logic_vector(127 downto 0);
		fsm_addr: in integer range 0 to ram_size-1;
		
		mem_addr : out integer range 0 to ram_size-1;
		mem_read : out std_logic; -- read operation
		mem_write : out std_logic; -- write operation
		mem_writedata : out std_logic_vector(7 downto 0); -- write output
		busy: out std_logic; -- signal to fsm that interface is busy
		out_block: out std_logic_vector(127 downto 0) -- read output
	);
end avalon_mm;

architecture interface of avalon_mm is	
	
	signal byte_counter: integer := 0;
	signal tmp_busy: std_logic := '0';
	signal tmp_out_block: std_logic_vector(127 downto 0);
	
begin

	process(clk, reset)
	
			variable shift: integer := 0;
	
	begin
		if reset = '1' then
		
			byte_counter <= 0;
			tmp_busy <= '0';
			mem_read <= '0';
			mem_write <= '0';

		elsif rising_edge(clk) and mem_waitrequest = '0' then
			
			if byte_counter < 16 then
				
				tmp_busy <= '1';
				shift := 8 * byte_counter;
				
				if op_type = '0' then
					-- reading from memory
					
					mem_read <= '1';
					mem_write <= '0';
					
					tmp_out_block(shift+7 downto shift) <= mem_readdata;
					
				else
					-- writing to memory
					mem_read <= '0';
					mem_write <= '1';
					
					mem_writedata <= in_block(shift+7 downto shift);
					
				end if;
								
				mem_addr <= fsm_addr + byte_counter;
				byte_counter <= byte_counter + 1;
				
			else 
			
				tmp_busy <= '0';
				mem_read <= '0';
				mem_write <= '0';
				out_block <= tmp_out_block;
			
			end if;

			
		end if;

	end process;
	
	busy <= tmp_busy;
	
end interface;