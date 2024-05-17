library ieee;
use ieee.std_logic_1164.all;

entity estendeSinalGenerico is
	generic
	(
		larguraDadoEntrada : natural  :=    16;
		larguraDadoSaida   : natural  :=    32
	);
	port
	(
		-- Input ports
		ORiANDi			 : in  std_logic;
		estendeSinal_IN : in  std_logic_vector(larguraDadoEntrada-1 downto 0);

		-- Output ports
		estendeSinal_OUT: out std_logic_vector(larguraDadoSaida-1 downto 0)
	);
end entity;

architecture comportamento of estendeSinalGenerico is
	begin

		estendeSinal_OUT <= (larguraDadoSaida-1 downto larguraDadoEntrada => estendeSinal_IN(larguraDadoEntrada-1)) & estendeSinal_IN else
								  (larguraDadoSaida-1 downto larguraDadoEntrada => '0') & estendeSinal_IN when ORiANDi = '1';

end architecture;