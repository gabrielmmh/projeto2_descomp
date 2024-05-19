library ieee;
use ieee.std_logic_1164.all;

entity ULAcntrl is
	port ( opcode : in  std_logic_vector(5 downto 0);
			funct   : in  std_logic_vector(5 downto 0);
			tipoR   : in  std_logic;
			saida   : out std_logic_vector(3 downto 0)
	);
end entity;

architecture comportamento of ULAcntrl is
	-- Código das instruções passadas pelo opcode e pelo funct
	constant ADDi : std_logic_vector(5 downto 0) := "001000"; -- 0x08
	constant ADDr : std_logic_vector(5 downto 0) := "100000"; -- 0x20
	constant ANDi : std_logic_vector(5 downto 0) := "001100"; -- 0x0c
	constant ANDr : std_logic_vector(5 downto 0) := "100100"; -- 0x24
	constant BEQ  : std_logic_vector(5 downto 0) := "000100"; -- 0x04
	constant BNE  : std_logic_vector(5 downto 0) := "000101"; -- 0x05
	constant JAL  : std_logic_vector(5 downto 0) := "000011"; -- 0x03
	constant JMP  : std_logic_vector(5 downto 0) := "000010"; -- 0x02
	constant JR   : std_logic_vector(5 downto 0) := "001000"; -- 0x08
	constant LUI  : std_logic_vector(5 downto 0) := "001111"; -- 0x0f
	constant LW   : std_logic_vector(5 downto 0) := "100011"; -- 0x23
	constant NORr : std_logic_vector(5 downto 0) := "100111"; -- 0x27
	constant ORi  : std_logic_vector(5 downto 0) := "001101"; -- 0x0d
	constant ORr  : std_logic_vector(5 downto 0) := "100101"; -- 0x25
	constant SLT  : std_logic_vector(5 downto 0) := "101010"; -- 0x2a
	constant SLTi : std_logic_vector(5 downto 0) := "001010"; -- 0x0a
	constant SUBr : std_logic_vector(5 downto 0) := "100010"; -- 0x22
	constant SW   : std_logic_vector(5 downto 0) := "101011"; -- 0x2b

	-- Seletor de instruções a serem usadas pela ULA
	constant ANDsel : std_logic_vector(3 downto 0) := "0000";
	constant ORsel  : std_logic_vector(3 downto 0) := "0001";
	constant ADDsel : std_logic_vector(3 downto 0) := "0010";
	constant SUBsel : std_logic_vector(3 downto 0) := "0110";
	constant SLTsel : std_logic_vector(3 downto 0) := "0111";
	constant NORsel : std_logic_vector(3 downto 0) := "1110";

	-- Saída Mux que escolhe usar opcode ou funct
	signal mOut : std_logic_vector(5 downto 0);
	
	begin
	
   --	Ao invés de fazer dois decodificadores que definem uma saída diretamente para um MUX que tem como seletor o sinal de tipo R,
	--	realizar qual parte do registrador deve ser lida antes com o MUX_OPCODE_FUNCT e depois interpretar a saída desse mux com um
	--	único decodificador diretamente na saida (seletor da ULA)
	
		MUX_OPCODE_FUNCT  : entity work.muxGenerico2x1 
								  generic map (larguraDados => 6)
								  port map (
										  entradaA_MUX => opcode, 
										  entradaB_MUX => funct, 
										  seletor_MUX  => tipoR, 
										  saida_MUX    => mOut);
									
		saida <=   	ADDsel when (mOut = ADDi) OR
										(mOut = ADDr) OR
										(mOut = LW  ) OR
									   (mOut = SW  ) OR
									   (mOut = ADDr) OR
									   (mOut = ADDi) else
										 
						ANDsel when (mOut = ANDr) OR
										(mOut = ANDi) else
										 
						NORsel when (mOut = NORr) else
										 
						ORsel  when (mOut = ORi ) OR
										(mOut = ORr ) else
										 
						SLTsel when (mOut = SLT ) OR	
									   (mOut = SLTi) else
										 
						SUBsel when (mOut = BEQ ) OR
										(mOut = BNE ) OR
										(mOut = SUBr) else
						
						ADDsel;
						
	end architecture;