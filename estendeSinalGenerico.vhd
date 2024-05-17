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
        -- Portas de entrada
        ORiANDi          : in  std_logic;
        estendeSinal_IN  : in  std_logic_vector(larguraDadoEntrada-1 downto 0);

        -- Portas de saída
        estendeSinal_OUT : out std_logic_vector(larguraDadoSaida-1 downto 0)
    );
end entity;

architecture comportamento of estendeSinalGenerico is
begin
    process(ORiANDi, estendeSinal_IN)
    begin
        if ORiANDi = '1' then
            estendeSinal_OUT <= (others => '0') & estendeSinal_IN;
        else
            estendeSinal_OUT <= (others => estendeSinal_IN(larguraDadoEntrada-1)) & estendeSinal_IN;
        end if;
    end process;
end architecture comportamento;
