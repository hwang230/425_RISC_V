library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
	generic(
		ram_size : INTEGER := 32768
	);
	port(
		clock : in std_logic;
		reset : in std_logic;
		
		-- Avalon interface --
		s_addr : in std_logic_vector (31 downto 0);
		s_read : in std_logic;
		s_readdata : out std_logic_vector (31 downto 0);
		s_write : in std_logic;
		s_writedata : in std_logic_vector (31 downto 0);
		s_waitrequest : out std_logic; 
		
		m_addr : out integer range 0 to ram_size-1;
		m_read : out std_logic;
		m_readdata : in std_logic_vector (7 downto 0);
		m_write : out std_logic;
		m_writedata : out std_logic_vector (7 downto 0);
		m_waitrequest : in std_logic
	);
end cache;

architecture arch of cache is
-- declare components 
-- cache_storage
component cache_storage is
	port(
		clock       : in std_logic;
		reset       : in std_logic;
		word_offset : in std_logic_vector(1 downto 0);
		index       : in std_logic_vector(4 downto 0);
		tag         : in std_logic_vector(5 downto 0);
		write_word  : in std_logic;
		write_block : in std_logic;
		data_in     : in std_logic_vector(31 downto 0);
		block_in    : in std_logic_vector(127 downto 0);

		hit         : out std_logic;
		dirty       : out std_logic;
		valid       : out std_logic;
		tag_match   : out std_logic;
		tag_out     : out std_logic_vector(5 downto 0);
		data_out    : out std_logic_vector(31 downto 0);
		block_out   : out std_logic_vector(127 downto 0)
	);
end component;

-- declare signals here

-- inputs from storage
signal tag: std_logic_vector(5 downto 0);
signal index: std_logic_vector(4 downto 0);
signal word_offset: std_logic_vector(1 downto 0);
signal write_word: std_logic := '0';
signal write_block: std_logic := '0';
signal data_in: std_logic_vector(31 downto 0) := (others => '0');
signal block_in: std_logic_vector(127 downto 0) := (others => '0');
-- outputs from storage
signal hit: std_logic;
signal dirty: std_logic;
signal valid: std_logic;
signal tag_match: std_logic;    
signal tag_out: std_logic_vector(5 downto 0);
signal data_out: std_logic_vector(31 downto 0);
signal block_out: std_logic_vector(127 downto 0);



begin
-- make circuits here

	-- decode the address
	tag <= s_addr(14 downto 9);
	index <= s_addr(8 downto 4); 
	word_offset <= s_addr(3 downto 2);

	u_storage: entity work.cache_storage
		port map(
			clock       => clock,
            reset       => reset,
            word_offset => word_offset,
            index       => index,
            tag         => tag,
            write_word  => write_word,
            write_block => write_block,
            data_in     => data_in,
            block_in    => block_in,
            hit         => hit,
            dirty       => dirty,
            valid       => valid,
            tag_match   => tag_match,
            tag_out     => tag_out,
            data_out    => data_out,
            block_out   => block_out
		);

	process(clock, reset)
	begin
		if (reset = '1') then
			-- reset all intermediate signals
            write_word <= '0';
			write_block <= '0';
			s_readdata <= (others => '0');
			s_waitrequest <= '1';
			m_read <= '0';
			m_write <= '0';
			m_writedata <= (others => '0');
			m_addr <= 0;

		elsif (rising_edge(clock))then
			-- only triggers when a read or write is requested
			-- m_* variables are used when connecting to memory - default to 0
			m_read <= '0';
			m_write <= '0';
			s_waitrequest <= '1';
			write_word <= '0';
			write_block <= '0';
			if (s_read = '1') then
			-- case of requesting read 
			-- read hit: 
				if (hit = '1') then
					-- write the result to cache output
					s_readdata <= data_out;
					-- reset waitrequest to 0 once transaction completes
					s_waitrequest <= '0';
				else 
					-- read miss

				end if;
			elsif (s_write = '1') then 
			-- case of requesting write
				if (hit = '1') then
					-- tell storage what data to write
					data_in <= s_writedata; 
					-- tell storage to store this value to the specified addr
					write_word <= '1';

					s_waitrequest <= '0';
				else
					-- write miss 
				end if;
			end if;

		end if; 
	end process;

end arch;