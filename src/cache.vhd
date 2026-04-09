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


-- fsm state declaraion
type state_type is (IDLE, WRITEBACK, REFETCH, COMPLETE, STORE_BLOCK, WAIT_COMPLETE);
signal state: state_type := IDLE;

-- signals to remember the request
signal pending_read  : std_logic := '0';
signal pending_write : std_logic := '0';
signal req_tag       : std_logic_vector(5 downto 0) := (others => '0');
signal req_index     : std_logic_vector(4 downto 0) := (others => '0');
signal req_offset    : std_logic_vector(1 downto 0) := (others => '0');
signal req_writedata : std_logic_vector(31 downto 0) := (others => '0');
signal byte_count    : integer range 0 to 15 := 0;
signal refetch_block  : std_logic_vector(127 downto 0) := (others => '0');
signal read_issued  : std_logic := '0';
signal write_issued : std_logic := '0';

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
		variable shift: integer;
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
			state <= IDLE;
			pending_read  <= '0';
			pending_write <= '0';
			req_tag <= (others => '0');
			req_index <= (others => '0');
			req_offset <= (others => '0');
			req_writedata <= (others => '0');
			byte_count <= 0;
			refetch_block <= (others => '0');

		
		elsif (rising_edge(clock))then
			-- only triggers when a read or write is requested
			-- m_* variables are used when connecting to memory - default to 0
			m_read <= '0';
			m_write <= '0';
			s_waitrequest <= '1';
			write_word <= '0';
			write_block <= '0';
			
			case state is 
				when IDLE =>
					if (s_read = '1') then
					-- case of requesting read 
					-- read hit: 
						if (hit = '1') then
							-- write the result to cache output
							s_readdata <= data_out;
							-- reset waitrequest to 0 once transaction completes
							s_waitrequest <= '0';
							pending_read <= '0';
							pending_write <= '0';
						else 
							-- read miss
							-- Dirty cache
							-- store the request information 
							req_tag    <= tag;
							req_index  <= index;
							req_offset <= word_offset;
							byte_count <= 0;
							pending_read  <= '1';
							pending_write <= '0';

							if (dirty = '1') then
								state <= WRITEBACK;
								-- should go through avalon bus now
							else 
								-- Not dirty cache -> no need to writeback
								-- fetch from memory
								state <= REFETCH;
							end if;
						end if;
					elsif (s_write = '1') then 
					-- case of requesting write
						if (hit = '1') then
							-- tell storage what data to write
							data_in <= s_writedata; 
							-- tell storage to store this value to the specified addr
							write_word <= '1';
							s_waitrequest <= '0';
							pending_read <= '0';
							pending_write <= '0';
						else
							-- write miss 
							-- Dirty cache
							req_writedata <= s_writedata;
							req_tag    <= tag;
							req_index  <= index;
							req_offset <= word_offset;
							byte_count <= 0;
							pending_read  <= '0';
							pending_write <= '1';

							if (dirty = '1') then
								state <= WRITEBACK;
							else 
							-- Not dirty cache
								state <= REFETCH;
							end if;
						end if;
					end if;
				
				when WRITEBACK =>
					m_addr <= to_integer(unsigned(tag_out & req_index & "0000")) + byte_count;
					shift := 8 * byte_count;

					-- byte request not yet launched
					if write_issued = '0' then
						m_write <= '1';
						m_writedata <= block_out(shift + 7 downto shift);
						write_issued <= '1';
					else
						-- request issued for this byte so deassert m_write
						m_write <= '0';
						if m_waitrequest = '0' then
							if byte_count = 15 then
								-- reset after all bytes transferred
								byte_count <= 0;
								write_issued <= '0';
								state <= REFETCH;
							else
								-- increase if not reached 16 bytes yet
								byte_count <= byte_count + 1;
								write_issued <= '0';
							end if;
						end if;
					end if;	

				when REFETCH =>
    					m_addr <= to_integer(unsigned(req_tag & req_index & "0000")) + byte_count;
    					shift := 8 * byte_count;
						
						-- byte request not yet launched
    					if read_issued = '0' then
							m_read <= '1';
							read_issued <= '1';
						else
						-- request issued for this byte so deassert m_read
							m_read <= '0';

						if m_waitrequest = '0' then
							refetch_block(shift + 7 downto shift) <= m_readdata;

							if byte_count = 15 then
								-- reset after all bytes transferred
								byte_count <= 0;
								read_issued <= '0';
								state <= COMPLETE;
							else
								-- increase if not reached 16 bytes yet
								byte_count <= byte_count + 1;
								read_issued <= '0';
							end if;
						end if;
					end if;


				when COMPLETE =>
					-- first move the fetch block into storage
					if (pending_read = '1') then
						-- serving read miss by preparing block back to storage
						block_in <= refetch_block;

						-- select the requested word based on offset
						if req_offset = "00" then
							s_readdata <= refetch_block(31 downto 0);
						elsif req_offset = "01" then
							s_readdata <= refetch_block(63 downto 32);
						elsif req_offset = "10" then
							s_readdata <= refetch_block(95 downto 64);
						else
							s_readdata <= refetch_block(127 downto 96);
						end if;

					elsif (pending_write = '1') then
						-- serving write miss by preparing the block with the data that needs to be written to
						if req_offset = "00" then
							block_in <= refetch_block(127 downto 32) & req_writedata;
						elsif req_offset = "01" then
							block_in <= refetch_block(127 downto 64) & req_writedata & refetch_block(31 downto 0);
						elsif req_offset = "10" then
							block_in <= refetch_block(127 downto 96) & req_writedata & refetch_block(63 downto 0);
						else
							block_in <= req_writedata & refetch_block(95 downto 0);
						end if;
					end if;
					-- bring state back to IDLE after completing
					state <= STORE_BLOCK;

				when STORE_BLOCK => 
					-- store block back to storage by triggering with write_block
					-- turn off the request 
					write_block <= '1';
					state <= WAIT_COMPLETE;
				when WAIT_COMPLETE =>
					-- cache_storage has now updated. 'hit' will correctly evaluate to '1'.
					-- Safe to release the testbench and return to IDLE.
					s_waitrequest <= '0';
					pending_read <= '0';
					pending_write <= '0';
					state <= IDLE;
			end case;
		end if; 
	end process;

end arch;