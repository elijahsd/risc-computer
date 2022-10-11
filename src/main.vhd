library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CTRL is
port(
	clk     : in std_logic;
	reset   : in std_logic;
	
	address : out std_logic_vector(0 to 15);
	data    : inout std_logic_vector(0 to 7);
	we_bar  : out std_logic;
	mem_clk : out std_logic
);
end entity CTRL;

architecture behavioral of CTRL is

signal we_bar_int : std_logic := '1';
signal mem_clk_int : std_logic := '0';

signal data_int : std_logic_vector(0 to 7);

-- fetched data
signal stored : std_logic_vector(0 to 15);

alias stored0 is stored(0 to 7);
alias stored1 is stored(8 to 15);

alias cmd is stored(0 to 2);
alias ra is stored(3 to 5);
alias rb is stored(6 to 8);
alias rc is stored(13 to 15);
alias i10 is stored(6 to 15);
alias i7 is stored(9 to 15);

-- registers
type registers is array(0 to 7) of std_logic_vector(0 to 15);
signal r : registers := (
	"0000000000000000",
	"0000000000000000",
	"0000000000000000",
	"0000000000000000",
	"0000000000000000",
	"0000000000000000",
	"0000000000000000",
	"0000000000000000"
);

signal shadow : std_logic_vector(0 to 7);

begin

main : process(clk) is

variable pc : natural := 0;
variable pcs : natural;
variable fcycle : natural := 0;

begin
	if rising_edge(clk) and (reset = '0') then
		if fcycle = 0 or fcycle = 1 then
			pcs := pc;
			we_bar_int <= '1';
			mem_clk_int <= '1', '0' after 100 ns;
			address <= std_logic_vector(to_unsigned(2 * pcs + fcycle, 16));
		end if;
		if fcycle = 0 then
			-- fetch the first part
			stored0 <= data after 50ns;
		end if;
		if fcycle = 1 then
			-- fetch the second part
			stored1 <= data after 50ns;
			pc := pc + 1;
		end if;
		fcycle := fcycle + 1;
	end if;

	if falling_edge(clk) then
		if fcycle = 2 then
			if cmd = "000" then
				-- ADD
				if ra /= "000" then
					r(to_integer(unsigned(ra))) <= std_logic_vector(signed(r(to_integer(unsigned(rb)))) + signed(r(to_integer(unsigned(rc)))));
				end if;
				fcycle := 0;
			elsif cmd = "001" then
				-- ADDI
				if ra /= "000" then
					r(to_integer(unsigned(ra))) <= std_logic_vector(signed(r(to_integer(unsigned(rb)))) + signed(i7));
				end if;
				fcycle := 0;
			elsif cmd = "010" then
				-- NAND
				if ra /= "000" then
					r(to_integer(unsigned(ra))) <= not (r(to_integer(unsigned(rb))) and r(to_integer(unsigned(rc))));
				end if;
				fcycle := 0;
			elsif cmd = "011" then
				-- LUI
				if ra /= "000" then
					r(to_integer(unsigned(ra))) <= i10 & "000000";
				end if;
				fcycle := 0;
			elsif cmd = "100" then
				-- SW
				we_bar_int <= '0';
				address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)), 16));
				mem_clk_int <= '1', '0' after 100 ns;
				data_int <= r(to_integer(unsigned(ra)))(0 to 7) after 50 ns;
			elsif cmd = "101" then
				-- LW
				if ra /= "000" then
					we_bar_int <= '1';
					address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)), 16));
					mem_clk_int <= '1', '0' after 100 ns;
					shadow <= data after 50 ns;
				else
					fcycle := 0;
				end if;
			elsif cmd = "110" then
				-- BEQ
				if r(to_integer(unsigned(ra))) = r(to_integer(unsigned(rb))) then
					pc := pc + to_integer(signed(i7));
				end if;
				fcycle := 0;
			elsif cmd = "111" then
				-- JALR
				if ra /= "000" then
					r(to_integer(unsigned(ra))) <= std_logic_vector(to_unsigned(pc, 16));
				end if;
				pc := to_integer(unsigned(r(to_integer(unsigned(rb)))));
				fcycle := 0;
			end if;
		end if;
		if fcycle = 3 then
			if cmd = "100" then
				-- SW
				we_bar_int <= '0';
				address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)) + 1, 16));
				mem_clk_int <= '1', '0' after 100 ns;
				data_int <= r(to_integer(unsigned(ra)))(8 to 15) after 50 ns;
				fcycle := 0;
			elsif cmd = "101" then
				-- LW
				if ra /= "000" then
					we_bar_int <= '1';
					address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)) + 1, 16));
					mem_clk_int <= '1', '0' after 100 ns;
					r(to_integer(unsigned(ra))) <= shadow & data after 50 ns;
				end if;
				fcycle := 0;
			end if;
		end if;
	end if;

end process main;

we_bar <= we_bar_int;
mem_clk <= mem_clk_int;

data <= data_int when (we_bar_int = '0' and mem_clk_int = '1' and reset = '0') else (others => 'Z');

end architecture behavioral;