LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instructionFetch is
	generic (larguraDados : natural := 32);
	port (
		JR		          : in std_logic;
		DadoLidoReg1    : in std_logic;
		pc4Out_inIfId   : out std_logic_vector(larguraDados-1 downto 0);
		romOut_inIfId	 : out std_logic_vector(larguraDados-1 downto 0)
	);
	end entity;

	architecture Behavioral of instructionFetch is
	begin
					 
	end architecture;