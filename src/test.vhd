library ieee;
use ieee.std_logic_1164.all;

entity test_bench is
end entity test_bench;

architecture test_cpu of test_bench is
	signal clk     : std_logic;
	signal reset   : std_logic;

	signal address : std_logic_vector(0 to 15);
	signal data    : std_logic_vector(0 to 7);
	signal we_bar  : std_logic;
	signal mem_clk : std_logic;

	signal data_int : std_logic_vector(0 to 7);

begin
	dut : entity work.CTRL(behavioral)
	port map ( clk, reset, address, data, we_bar, mem_clk );

stimulus : process is
begin
	reset <= '0';
	clk <= '0', '1' after    25 ns, '0' after   250 ns, '1' after   500 ns, '0' after   750 ns,
				 '1' after  1000 ns, '0' after  1250 ns, '1' after  1500 ns, '0' after  1750 ns,
				 '1' after  2000 ns, '0' after  2250 ns, '1' after  2500 ns, '0' after  2750 ns,
				 '1' after  3000 ns, '0' after  3250 ns, '1' after  3500 ns, '0' after  3750 ns,
				 '1' after  4000 ns, '0' after  4250 ns, '1' after  4500 ns, '0' after  4750 ns,
				 '1' after  5000 ns, '0' after  5250 ns, '1' after  5500 ns, '0' after  5750 ns,
				 '1' after  6000 ns, '0' after  6250 ns, '1' after  6500 ns, '0' after  6750 ns,
				 '1' after  7000 ns, '0' after  7250 ns, '1' after  7500 ns, '0' after  7750 ns,
				 '1' after  8000 ns, '0' after  8250 ns, '1' after  8500 ns, '0' after  8750 ns,
				 '1' after  9000 ns, '0' after  9250 ns, '1' after  9500 ns, '0' after  9750 ns,
				 '1' after 10000 ns, '0' after 10250 ns, '1' after 10500 ns, '0' after 10750 ns,
				 '1' after 11000 ns, '0' after 11250 ns, '1' after 11500 ns, '0' after 11750 ns;

--	data <= "00100100" after   25 ns, "00000011" after  500 ns, -- ADDI R1 R0 3
--			"00101000" after 1000 ns, "10000001" after 1500 ns, -- ADDI R2 R1 1
--			"00001100" after 2000 ns, "10000010" after 2500 ns, -- ADD R3 R1 R2
--			"01010001" after 3000 ns, "10000001" after 3500 ns; -- NAND R4 R3 R1 (3)
--	data <= "01100111" after   25 ns, "11111111" after  500 ns; -- LUI R1
--	data <= "00100100" after   25 ns, "00000001" after  500 ns, -- ADDI R1 R0 1
--			"00001000" after 1000 ns, "00000000" after 1500 ns, -- ADD R2 R0 R0
--			"11100101" after 2000 ns, "00000000" after 2500 ns; -- JARL R1 R2(SAVE R1)
--	data <= "00100100" after   25 ns, "00000001" after  500 ns, -- ADDI R1 R0 1
--			"00101000" after 1000 ns, "00000001" after 1500 ns, -- ADDI R2 R0 1
--			"11100001" after 2000 ns, "00000000" after 2500 ns; -- JARL R0 R2
--	data <= "00100100" after   25 ns, "00000011" after  500 ns, -- ADDI R1 R0 3
--			"00101000" after 1000 ns, "00000001" after 1500 ns, -- ADDI R2 R0 1
--			"11000101" after 2000 ns, "01000010" after 2500 ns; -- BEQ
--	data <= "00100100" after   25 ns, "00000001" after  500 ns, -- ADDI R1 R0 1
--			"00101000" after 1000 ns, "00000001" after 1500 ns, -- ADDI R2 R0 1
--			"11000101" after 2000 ns, "01111110" after 2500 ns; -- BEQ
--	data <= "00100100" after   25 ns, "00000011" after  500 ns, -- ADDI R1 R0 3
--			"10101000" after 1000 ns, "10000001" after 1500 ns; -- LW R2 R1 1
--	data <= "00100100" after   25 ns, "00000011" after  500 ns, -- ADDI R1 R0 3
--			"00101000" after 1000 ns, "00000111" after 1500 ns, -- ADDI R2 R0 7
--			"10001000" after 2000 ns, "11111111" after 2500 ns; -- SW R2 R1 -1 (address = 3-1=2 (4 and 5), data = 00000000 and 00000111)

-- 0000: 0110010000000000    | LUI R1 0
-- 0001: 0010010010000111    | ADDI R1 R1 7
-- 0002: 1110000010000000    | JALR R0 R1
-- 0003: 1000000000000000    | DATA 32768
-- 0004: 1000000000000001    | DATA 32769
-- 0005: 1000000000000010    | DATA 32770
-- 0006: 1000000000000011    | DATA 32771
-- 0007: 0010010000000101    | ADDI R1 R0 5
-- 0008: 0111100000000000    | LUI R6 0
-- 0009: 0011101100000011    | ADDI R6 R6 3
-- 000a: 1011111100000000    | LW R7 R6 0
-- 000b: 1000011110000000    | SW R1 R7 0
-- 000c: 0111100000000000    | LUI R6 0
-- 000d: 0011101100001100    | ADDI R6 R6 12
-- 000e: 1111100000000000    | JALR R6 R0

data <= 
"01100100" after 25 ns, "00000000" after 500 ns,
"00100100" after 1000 ns, "10000111" after 1500 ns,
"11100000" after 2000 ns, "10000000" after 2500 ns,
"00100100" after 3000 ns, "00000101" after 3500 ns,
"01111000" after 4000 ns, "00000000" after 4500 ns,
"00111011" after 5000 ns, "00000011" after 5500 ns,
"10111111" after 6000 ns, "00000000" after 6500 ns,
                     "10000000" after 6750 ns, "00000000" after 7250 ns,
"10000111" after 7500 ns, "10000000" after 8000 ns,
"01111000" after 8500 ns, "00000000" after 9000 ns,
"00111011" after 9500 ns, "00001100" after 10000 ns,
"11111000" after 10500 ns, "00000000" after 11000 ns;

	wait;
end process stimulus;

-- data <= data_int; -- when (we_bar = '0' and mem_clk = '1') else (others => 'Z');

end architecture test_cpu;