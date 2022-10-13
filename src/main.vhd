library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library machxo2;
use machxo2.all;

entity CTRL is
port(
	reset   : in std_logic;

	address : out std_logic_vector(0 to 15);
	data    : inout std_logic_vector(0 to 7);
	we_bar  : out std_logic;
	mem_clk : out std_logic
);
end entity CTRL;

architecture behavioral of CTRL is

COMPONENT OSCH
	-- synthesis translate_off
	GENERIC (NOM_FREQ: string := "2.08");
	-- synthesis translate_on
	PORT (
		STDBY    : IN std_logic;
		OSC      : OUT std_logic;
		SEDSTDBY : OUT std_logic);
END COMPONENT;

-- Internal clock source
signal clk : std_logic;

-- RAM interface controls
signal we_bar_int : std_logic;
signal mem_clk_int : std_logic;

-- Intermediate buffer for RAM write
signal data_int : std_logic_vector(0 to 7);

-- Fetched command
signal stored : std_logic_vector(0 to 15);

alias stored0 is stored(0 to 7);
alias stored1 is stored(8 to 15);

alias cmd is stored(0 to 2);
alias ra is stored(3 to 5);
alias rb is stored(6 to 8);
alias rc is stored(13 to 15);
alias i10 is stored(6 to 15);
alias i7 is stored(9 to 15);

signal stored_clk : std_logic_vector(0 to 1);

-- Loading memory
signal shadow : std_logic_vector(0 to 15);
signal shadow_clk : std_logic_vector(0 to 1);

-- Registers
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

signal r_clk : std_logic_vector(0 to 7);

-- Register input interface
signal regin : std_logic_vector(0 to 15);

begin

storage : entity work.REG(behavioral)
	port map(data, stored, stored_clk);

shade : entity work.REG(behavioral)
	port map(data, shadow, shadow_clk);

r1 : entity work.REG16(behavioral)
	port map(regin, r(1), r_clk(1));
r2 : entity work.REG16(behavioral)
	port map(regin, r(2), r_clk(2));
r3 : entity work.REG16(behavioral)
	port map(regin, r(3), r_clk(3));
r4 : entity work.REG16(behavioral)
	port map(regin, r(4), r_clk(4));
r5 : entity work.REG16(behavioral)
	port map(regin, r(5), r_clk(5));
r6 : entity work.REG16(behavioral)
	port map(regin, r(6), r_clk(6));
r7 : entity work.REG16(behavioral)
	port map(regin, r(7), r_clk(7));

OSCInst0: OSCH
-- synthesis translate_off
GENERIC MAP( NOM_FREQ => "2.08" )
-- synthesis translate_on
PORT MAP (
	STDBY => '0',
	OSC => clk,
	SEDSTDBY => OPEN
);

main : process(clk) is

variable pc : natural := 0;
variable fcycle : natural := 0;
variable fcounter : natural := 0;

begin
	if rising_edge(clk) then
		if reset = '1' then
			pc := 0;
			fcycle := 0;
			fcounter := 0;
			mem_clk_int <= '0';
			stored_clk <= "00";
		else
			if fcycle = 0 then
				-- fetch the first part
				we_bar_int <= '1';
				stored_clk <= "10";
				address <= std_logic_vector(to_unsigned(2 * pc, 16));
				mem_clk_int <= '1';
			elsif fcycle = 1 then
				mem_clk_int <= '0';
				stored_clk <= "00";
			elsif fcycle = 2 then
				-- fetch the second part
				stored_clk <= "01";
				address <= std_logic_vector(to_unsigned(2 * pc + 1, 16));
				mem_clk_int <= '1';
			elsif fcycle = 3 then
				mem_clk_int <= '0';
				stored_clk <= "00";
				pc := pc + 1;
			elsif fcycle = 4 then
				if cmd = "000" then
					-- ADD
					regin <= std_logic_vector(signed(r(to_integer(unsigned(rb)))) + signed(r(to_integer(unsigned(rc)))));
				elsif cmd = "001" then
					-- ADDI
					regin <= std_logic_vector(signed(r(to_integer(unsigned(rb)))) + signed(i7));
				elsif cmd = "010" then
					-- NAND
					regin <= not (r(to_integer(unsigned(rb))) and r(to_integer(unsigned(rc))));
				elsif cmd = "011" then
					-- LUI
					regin <= i10 & "000000";
				elsif cmd = "100" then
					-- SW
					we_bar_int <= '0';
					address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)), 16));
					data_int <= r(to_integer(unsigned(ra)))(0 to 7);
					mem_clk_int <= '1';
				elsif cmd = "101" then
					-- LW
					shadow_clk <= "10";
					address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)), 16));
					mem_clk_int <= '1';
				elsif cmd = "110" then
					-- BEQ
					if r(to_integer(unsigned(ra))) = r(to_integer(unsigned(rb))) then
						pc := pc + to_integer(signed(i7));
					end if;
				elsif cmd = "111" then
					-- JALR
					regin <= std_logic_vector(to_unsigned(pc, 16));
					pc := to_integer(unsigned(r(to_integer(unsigned(rb)))));
				end if;
			elsif fcycle = 5 then
				if cmd = "000" or cmd = "001" or cmd = "010" or cmd = "011" or cmd = "111" then
					r_clk(to_integer(unsigned(ra))) <= '1';
				else
					mem_clk_int <= '0';
					shadow_clk <= "00";
				end if;
			elsif fcycle = 6 then
				if cmd = "000" or cmd = "001" or cmd = "010" or cmd = "011" or cmd = "111" then
					r_clk(to_integer(unsigned(ra))) <= '0';
				else
					if cmd = "100" then
						data_int <= r(to_integer(unsigned(ra)))(8 to 15);
					elsif cmd = "101" then
						shadow_clk <= "01";
					end if;
					address <= std_logic_vector(to_unsigned(2 * to_integer(signed(r(to_integer(unsigned(rb)))) + signed(i7)) + 1, 16));
					mem_clk_int <= '1';
				end if;
			elsif fcycle = 7 then
				mem_clk_int <= '0';
				shadow_clk <= "00";
			elsif fcycle = 8 then
				if cmd = "101" then
					regin <= shadow;
				end if;
			elsif fcycle = 9 then
				if cmd = "101" then
					r_clk(to_integer(unsigned(ra))) <= '1';
				end if;
			elsif fcycle = 10 then
				if cmd = "101" then
					r_clk(to_integer(unsigned(ra))) <= '0';
				end if;
			end if;

			fcycle := fcycle + 1;

			if fcycle = 12 then
				fcycle := 0;
			end if;

			fcounter := fcounter + 1;

		end if;
	end if;

end process main;

we_bar <= we_bar_int;
mem_clk <= mem_clk_int;

data <= data_int when (we_bar_int = '0' and mem_clk_int = '1' and reset = '0') else (others => 'Z');

end architecture behavioral;