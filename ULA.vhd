library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    -- Biblioteca IEEE para funções aritméticas

entity ULA is
    generic
    (
        larguraDados : natural := 32
    );
    port
    (
      entradaA, entradaB : in STD_LOGIC_VECTOR((larguraDados-1) downto 0);
      ULACtrl            : in STD_LOGIC_VECTOR(3 downto 0);
      saida              : out STD_LOGIC_VECTOR((larguraDados-1) downto 0);
      flagZero           : out std_logic
    );
end entity;

architecture comportamento of ULA is

   signal invA     : std_logic;
	signal invB     : std_logic;
	
	signal sel_mux  : std_logic_vector(1 downto 0);
	
	signal cOut_0   : std_logic;
	signal cOut_1   : std_logic;
	signal cOut_2   : std_logic;
	signal cOut_3   : std_logic;
	signal cOut_4   : std_logic;
	signal cOut_5   : std_logic;
	signal cOut_6   : std_logic;
	signal cOut_7   : std_logic;
	signal cOut_8   : std_logic;
	signal cOut_9   : std_logic;
	signal cOut_10  : std_logic;
	signal cOut_11  : std_logic;
	signal cOut_12  : std_logic;
	signal cOut_13  : std_logic;
	signal cOut_14  : std_logic;
	signal cOut_15  : std_logic;
	signal cOut_16  : std_logic;
	signal cOut_17  : std_logic;
	signal cOut_18  : std_logic;
	signal cOut_19  : std_logic;
	signal cOut_20  : std_logic;
	signal cOut_21  : std_logic;
	signal cOut_22  : std_logic;
	signal cOut_23  : std_logic;
	signal cOut_24  : std_logic;
	signal cOut_25  : std_logic;
	signal cOut_26  : std_logic;
	signal cOut_27  : std_logic;
	signal cOut_28  : std_logic;
	signal cOut_29  : std_logic;
	signal cOut_30  : std_logic;
	signal overflow : std_logic;
	
	signal zero : std_logic_vector(larguraDados-1 downto 0) := (others => '0');

	begin
	
		invA    <= ULACtrl(3);
		invB    <= ULACtrl(2);
		sel_mux <= ULACtrl(1 downto 0);

		bit00 : entity work.avgULAbit 
				  port map (
						  A => entradaA(0), 
						  B => entradaB(0),
						  SLT => overflow,
						  invA => invA, 
						  invB => invB, 
						  sel => sel_mux, 
						  cIn => invB, 
						  cOut => cOut_0, 
						  saida => saida(0));

		bit01 : entity work.avgULAbit
				  port map (
						  A => entradaA(1),
						  B => entradaB(1),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_0,
						  cOut => cOut_1,
						  saida => saida(1));

		bit02 : entity work.avgULAbit
				  port map (
				 		  A => entradaA(2),
						  B => entradaB(2),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_1,
						  cOut => cOut_2,
						  saida => saida(2));

		bit03 : entity work.avgULAbit
				  port map (
						  A => entradaA(3),
						  B => entradaB(3),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_2,
						  cOut => cOut_3,
						  saida => saida(3));

		bit04 : entity work.avgULAbit
				  port map (
						  A => entradaA(4),
						  B => entradaB(4),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_3,
						  cOut => cOut_4,
						  saida => saida(4));

		bit05 : entity work.avgULAbit
				  port map (
						  A => entradaA(5),
						  B => entradaB(5),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_4,
						  cOut => cOut_5,
						  saida => saida(5));

		bit06 : entity work.avgULAbit
				  port map (
						  A => entradaA(6),
						  B => entradaB(6),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_5,
						  cOut => cOut_6,
						  saida => saida(6));

		bit07 : entity work.avgULAbit
				  port map (
						  A => entradaA(7),
						  B => entradaB(7),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_6,
						  cOut => cOut_7,
						  saida => saida(7));

		bit08 : entity work.avgULAbit
				  port map (
						  A => entradaA(8),
						  B => entradaB(8),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_7,
						  cOut => cOut_8,
						  saida => saida(8));

		bit09 : entity work.avgULAbit
				  port map (
						  A => entradaA(9),
						  B => entradaB(9),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_8,
						  cOut => cOut_9,
						  saida => saida(9));

		bit10 : entity work.avgULAbit
				  port map (
				 		  A => entradaA(10),
						  B => entradaB(10),
						  SLT => '0', 
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_9,
						  cOut => cOut_10,
						  saida => saida(10));

		bit11 : entity work.avgULAbit
				  port map (
						  A => entradaA(11),
						  B => entradaB(11),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_10,
						  cOut => cOut_11,
						  saida => saida(11));

		bit12 : entity work.avgULAbit
				  port map (
						  A => entradaA(12),
						  B => entradaB(12),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_11,
						  cOut => cOut_12,
						  saida => saida(12));

		bit13 : entity work.avgULAbit
				  port map (
						  A => entradaA(13),
						  B => entradaB(13),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_12,
						  cOut => cOut_13,
						  saida => saida(13));

		bit14 : entity work.avgULAbit
				  port map (
						  A => entradaA(14),
						  B => entradaB(14),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_13,
						  cOut => cOut_14,
						  saida => saida(14));

		bit15 : entity work.avgULAbit
				  port map (
						  A => entradaA(15),
						  B => entradaB(15),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_14,
						  cOut => cOut_15,
						  saida => saida(15));

		bit16 : entity work.avgULAbit
				  port map (
						  A => entradaA(16),
						  B => entradaB(16),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_15,
						  cOut => cOut_16,
						  saida => saida(16));

		bit17 : entity work.avgULAbit
				  port map (
						  A => entradaA(17),
						  B => entradaB(17),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_16,
						  cOut => cOut_17,
						  saida => saida(17));

		bit18 : entity work.avgULAbit
				  port map (
						  A => entradaA(18),
						  B => entradaB(18),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_17,
						  cOut => cOut_18,
						  saida => saida(18));

		bit19 : entity work.avgULAbit
				  port map (
						  A => entradaA(19),
						  B => entradaB(19),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_18,
						  cOut => cOut_19,
						  saida => saida(19));

		bit20 : entity work.avgULAbit
				  port map (
						  A => entradaA(20),
						  B => entradaB(20),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_19,
						  cOut => cOut_20,
						  saida => saida(20));

		bit21 : entity work.avgULAbit
				  port map (
						  A => entradaA(21),
						  B => entradaB(21),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_20,
						  cOut => cOut_21,
						  saida => saida(21));

		bit22 : entity work.avgULAbit
				  port map (
						  A => entradaA(22),
						  B => entradaB(22), 
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_21,
						  cOut => cOut_22,
						  saida => saida(22));

		bit23 : entity work.avgULAbit
				  port map (
						  A => entradaA(23),
						  B => entradaB(23),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_22,
						  cOut => cOut_23,
						  saida => saida(23));

		bit24 : entity work.avgULAbit
				  port map (
						  A => entradaA(24),
						  B => entradaB(24),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_23,
						  cOut => cOut_24,
						  saida => saida(24));

		bit25 : entity work.avgULAbit
				  port map (
						  A => entradaA(25),
						  B => entradaB(25),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_24,
						  cOut => cOut_25,
						  saida => saida(25));

		bit26 : entity work.avgULAbit
				  port map (
						  A => entradaA(26),
						  B => entradaB(26),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_25,
						  cOut => cOut_26,
						  saida => saida(26));

		bit27 : entity work.avgULAbit
				  port map (
						  A => entradaA(27),
						  B => entradaB(27),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_26,
						  cOut => cOut_27,
						  saida => saida(27));

		bit28 : entity work.avgULAbit
				  port map (
						  A => entradaA(28),
						  B => entradaB(28),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_27,
						  cOut => cOut_28,
						  saida => saida(28));

		bit29 : entity work.avgULAbit
				  port map (
						  A => entradaA(29),
						  B => entradaB(29),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_28,
						  cOut => cOut_29,
						  saida => saida(29));

		bit30 : entity work.avgULAbit
				  port map (
						  A => entradaA(30),
						  B => entradaB(30),
						  SLT => '0',
						  invA => invA,
						  invB => invB,
						  sel => sel_mux,
						  cIn => cOut_29,
						  cOut => cOut_30,
						  saida => saida(30));


		bit31 : entity work.overflowULAbit 
				  port map (
						  A => entradaA(31), 
						  B => entradaB(31), 
						  SLT => '0', 
						  invA => invA, 
						  invB => invB, 
						  sel => sel_mux, 
						  cIn => cOut_30, 
						  overflow => overflow, 
						  saida => saida(31));

		flagZero <= '1' when (saida = zero) else '0';
      
	end architecture;