library ieee;
use ieee.std_logic_1164.all;

entity estendeSinalGenerico is
    generic
    (
        larguraDadoEntrada  : natural := 16;
        larguraDadoSaida : natural := 32
    );
    port
    (
        estendeSinal_IN  : in  std_logic_vector(larguraDadoEntrada-1 downto 0);
        ORiANDi          : in  std_logic;
        estendeSinal_OUT : out std_logic_vector(larguraDadoSaida-1 downto 0)
    );
end entity;

architecture comportamento of estendeSinalGenerico is
    signal msb        : std_logic;
    signal SignExtImm : std_logic_vector(larguraDadoSaida-1 downto 0);
    signal ZeroExtImm : std_logic_vector(larguraDadoSaida-1 downto 0);
begin
    msb              <= estendeSinal_IN(larguraDadoEntrada-1);
	 
    SignExtImm       <= "0000000000000000" & estendeSinal_IN when msb = '0' else 
								"1111111111111111" & estendeSinal_IN;
								
    ZeroExtImm       <= "0000000000000000" & estendeSinal_IN;
	 
    estendeSinal_OUT <= ZeroExtImm when ORiANDi = '1' else 
								SignExtImm;
end architecture;