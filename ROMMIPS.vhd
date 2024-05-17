library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROMMIPS is
   generic (
          dataWidth: natural := 32;           -- Largura dos dados (32 bits)
          addrWidth: natural := 32;           -- Largura do endereço (32 bits)
          memoryAddrWidth:  natural := 6      -- Largura do endereço da memória (6 bits, 64 posições)
   );
   port (
          Endereco : in  std_logic_vector (addrWidth-1 downto 0);  -- Endereço de entrada
          Dado     : out std_logic_vector (dataWidth-1 downto 0)   -- Dado de saída
   );
end entity;

architecture assincrona of ROMMIPS is
    -- Definição do tipo de dados para a memória ROM
    type blocoMemoria is array (0 to 2**memoryAddrWidth - 1) of std_logic_vector(dataWidth-1 downto 0);

    -- Função para inicializar a memória ROM com valores iniciais
    function initMemory return blocoMemoria is
        variable tmp : blocoMemoria := (others => (others => '0'));  -- Inicializa a memória com zeros
    begin
        -- Inicializa os endereços com valores específicos
        tmp(0) := x"AAAAAAAA";
        tmp(1) := x"42424242";
        tmp(2) := x"43434343";
        tmp(3) := x"44444444";
        tmp(4) := x"45454545";
        tmp(5) := x"46464646";
        tmp(6) := x"47474747";
        tmp(7) := x"55555555";
        return tmp;  -- Retorna a memória inicializada
    end function;

    -- Sinal da memória ROM inicializada com a função initMemory
    signal memROM: blocoMemoria := initMemory();

begin
    -- Processo assíncrono para ler a memória ROM
    process(Endereco)
    begin
        -- Verifica se o endereço está dentro do intervalo da memória
        if unsigned(Endereco(memoryAddrWidth-1 downto 0)) < 2**memoryAddrWidth then
            -- Atribui o dado da memória ROM ao sinal de saída Dado
            Dado <= memROM(to_integer(unsigned(Endereco(memoryAddrWidth-1 downto 0))));
        else
            -- Atribui zero ao sinal de saída Dado se o endereço estiver fora do intervalo
            Dado <= (others => '0');
        end if;
    end process;
end architecture assincrona;
