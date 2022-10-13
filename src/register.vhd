library ieee;
use ieee.std_logic_1164.all;

entity REG is
port(
	rdata_in  : in std_logic_vector(0 to 7);
	rdata_out : out std_logic_vector(0 to 15);
	rclk      : in std_logic_vector(0 to 1)
);
end entity REG;

architecture behavioral of REG is
	signal D  : std_logic_vector(0 to 7);
	signal Q0 : std_logic_vector(0 to 7);
	signal Q1 : std_logic_vector(0 to 7);
begin
main : process(rclk) is
begin
	if rclk(0 to 0) = "1" then
		Q0 <= D;
	end if;
	if rclk(1 to 1) = "1" then
		Q1 <= D;
	end if;
end process main;

D <= rdata_in;
rdata_out <= Q0 & Q1;

end architecture behavioral;