library ieee;
use ieee.std_logic_1164.all;

entity avgULAbit is
  port (
    A, B, SLT, invA, invB, cIn : in std_logic;
    sel : in std_logic_vector(1 downto 0);
    cOut, saida : out std_logic
  );
end entity;

architecture comportamento of avgULAbit is

  signal mOutA : std_logic;
  signal mOutB : std_logic;
  
  begin
  
    MUX_INV_A  : entity work.muxGenerico2x1 
					  generic map (larguraDados => 1)
					  port map (
								entradaA_MUX => A, 
								entradaB_MUX => not A, 
								seletor_MUX  => invA, 
								saida_MUX    => mOutA);
								
    MUX_INV_B  : entity work.muxGenerico2x1 
					  generic map (larguraDados => 1)
					  port map (
								entradaA_MUX => B, 
								entradaB_MUX => not B, 
								seletor_MUX  => invB, 
								saida_MUX    => mOutB);
								
    MUX_RESULT : entity work.muxGenerico4x1 
					  generic map (larguraDados => 1)
					  port map (
								entradaA_MUX => (mOutA and mOutB), 
								entradaB_MUX => (mOutA or mOutB), 
								entradaC_MUX => (cIn xor (mOutA xor mOutB)), 
								entradaD_MUX => SLT, 
								seletor_MUX  => sel, 
								saida_MUX    => saida);
	
	 cOut <= (mOutA and mOutB) or (cIn and (mOutA xor mOutB));
					 
end architecture;