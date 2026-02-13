library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_storage is
	port(
		-- Inputs:
		clock: in std_logic;
		reset: in std_logic;
		word_offset: in std_logic_vector(1 downto 0); -- 2^2 words per block (4 words per block)
		index: in std_logic_vector(4 downto 0); -- 2^5 blocks (32 blocks) 
		tag: in std_logic_vector(5 downto 0); -- 15 address bits - 2 offset bits - 5 index bits - 2 last bits
		write_word: in std_logic;
		write_block: in std_logic;
		data_in: in std_logic_vector(31 downto 0);
		block_in: in std_logic_vector(127 downto 0);

		-- Outputs:
		hit: out std_logic;
		dirty: out std_logic;
		tag_out: out std_logic_vector(5 downto 0); -- return address
		data_out: out std_logic_vector(31 downto 0);
		block_out: out std_logic_vector(127 downto 0);
	);
end cache_storage;

architecture rtl of cache_storage is

	type data_array is array (0 to 31) of std_logic_vector(127 downto 0);
	type tag_array is array (0 to 31) of std_logic_vector(5 downto 0);
	type valid_dirty_array is array (0 to 31) of std_logic;

	signal data: data_array;
	signal tags: tag_array;
	signal valid_bits: valid_dirty_array;
	signal dirty_bits: valid_dirty_array;
	signal row: integer range 0 to 31;

begin
	-- block determined by data(row)
	row <= to_integer(unsigned(index)); -- convert index value into an integer

	-- Process for picking the 32-bit word
	process(row, data, tags, valid_bits, dirty_bits, tag, word_offset)
	begin
		-- hit/miss logic
		if (valid_bits(row) = '1') and (tags(row) = tag) then
			hit <= '1';
		else
			hit <= '0';
		end if;

		-- picking word within the specified block
		if word_offset = "00" then -- word 1
			data_out <= data(row)(31 downto 0);
		elsif word_offset = "01" then -- word 2
			data_out <= data(row)(63 downto 32);
		elsif word_offset = "10" then -- word 3
			data_out <= data(row)(95 downto 64);
		else -- "11" word 4
			data_out <= data(row)(127 downto 96);
		end if;
		
		dirty <= dirty_bits(row);
		tag_out <= tags(row);
		block_out <= data(row);

	end process;

	-- writing to cache
	process(clock, reset)
	begin

		if reset = '1' then -- clear valid and dirty bits in cache
			for n in 0 to 31 loop
				valid_bits(n) <= '0';
				dirty_bits(n) <= '0';
			end loop;

		elsif rising_edge(clk) then

			if write_word = '1' then
				dirty_bits(row) <= '1';

				-- writing to the specific word of the block
				if word_offset = "00" then -- word 1
					data(row)(31 downto 0) <= data_in;
				elsif word_offset = "01" then -- word 2
					data(row)(63 downto 32) <= data_in;
				elsif word_offset = "10" then -- word 3
					data(row)(95 downto 64) <= data_in;
				else -- "11" word 4
					data(row)(127 downto 96) <= data_in;
				end if;

			elsif write_block = '1' then

				valid_bits(row) <= '1';
				dirty_bits(row) <= '0';
				tags(row) <= tag;
				data(row) <= block_in;

			end if;
		end if;
	end process;
end rtl;
				
				















