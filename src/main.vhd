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

signal alui0 : std_logic_vector(0 to 15);
signal alui1 : std_logic_vector(0 to 15);
signal aluo : std_logic_vector(0 to 15);

-- registers
signal r0 : std_logic_vector(0 to 15) := "0000000000000000";
signal r1 : std_logic_vector(0 to 15);
signal r2 : std_logic_vector(0 to 15);
signal r3 : std_logic_vector(0 to 15);
signal r4 : std_logic_vector(0 to 15);
signal r5 : std_logic_vector(0 to 15);
signal r6 : std_logic_vector(0 to 15);
signal r7 : std_logic_vector(0 to 15);

begin

main : process(clk) is

variable pc : natural := 0;
variable pcs : natural;
constant divider : integer := 20800;
variable cycle_counter : integer := 0;
variable valid : boolean := false;

begin
	if rising_edge(clk) and reset = '0' then
		-- getting the current command
		pcs := pc;
		we_bar <= '1';
		address <= std_logic_vector(to_unsigned(2 * pcs, address'length));
		mem_clk <= '1';
		stored0 <= data after 75 ns;
		mem_clk <= '0' after 100 ns;
		address <= std_logic_vector(to_unsigned(2 * pcs + 1, address'length)) after 125 ns;
		mem_clk <= '1' after 125ns;
		stored1 <= data after 200 ns;
		mem_clk <= '0' after 225 ns;
		valid := true;
		pc := pc + 1;
	end if;
	if falling_edge(clk) then
		if valid then
			valid := false;
			if cmd = "000" then
			elsif cmd = "001" then
			elsif cmd = "010" then
			elsif cmd = "011" then
			elsif cmd = "100" then
			elsif cmd = "101" then
			elsif cmd = "110" then
			elsif cmd = "111" then
			end if;
		end if;
	end if;

end process main;

end architecture behavioral;