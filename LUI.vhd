library ieee;
use ieee.std_logic_1164.all;

-- Declaração da entidade LUI para carregar os 16 bits superiores de um registrador de 32 bits com valor imediato.

entity LUI is
    port
    (
        entrada  : in  std_logic_vector(15 downto 0);  -- Entrada de 16 bits.
        saida : out std_logic_vector(31 downto 0)   -- Saída de 32 bits, com 16 bits inferiores zerados.
    );
	 
end entity;

-- Arquitetura comportamental do componente LUI.

architecture comportamento of LUI is

begin

    -- Concatena a entrada de 16 bits com 16 bits de zeros para formar a saída de 32 bits.
    -- Esta operação carrega a parte imediata no registro com zeros nos bits inferiores.
	 
    saida <= entrada & "0000000000000000";  -- Adiciona 16 zeros diretamente à entrada para formar a saída.
	 
end architecture;