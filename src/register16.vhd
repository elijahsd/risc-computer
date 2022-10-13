library ieee;
use ieee.std_logic_1164.all;

entity REG16 is
port(
	rdata_in  : in std_logic_vector(0 to 15);
	rdata_out : out std_logic_vector(0 to 15);
	rclk      : in std_logic
);
end entity REG16;

architecture behavioral of REG16 is
	signal D  : std_logic_vector(0 to 15);
	signal Q  : std_logic_vector(0 to 15);
begin
main : process(rclk) is
begin
	if rclk = '1' then
		Q <= D;
	end if;
end process main;

D <= rdata_in;
rdata_out <= Q;

end architecture behavioral;