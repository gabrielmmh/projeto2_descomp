library ieee;
use ieee.std_logic_1164.all;

entity Control is
	port ( 
			opcode    : in  std_logic_vector (5  downto 0);
			funct     : in  std_logic_vector (5  downto 0);
			pControle : out std_logic_vector (13 downto 0)
		  );
end entity;

architecture comportamento of Control is

	-- Definição de aliases para os sinais de controle
	alias JR            : std_logic is pControle(13);
	alias smPBJ         : std_logic is pControle(12);
	alias smRtRd31      : std_logic_vector(1 downto 0) is pControle(11 downto 10);
	alias OriAndi       : std_logic is pControle(9);
	alias habEscReg     : std_logic is pControle(8);
	alias smRtIm        : std_logic is pControle(7);
	alias tipoR         : std_logic is pControle(6);
	alias smULAMem      : std_logic_vector(1 downto 0) is pControle(5 downto 4);
	alias BEQ           : std_logic is pControle(3);
	alias BNE           : std_logic is pControle(2);
	alias habLeituraMEM : std_logic is pControle(1);
	alias habEscritaMEM : std_logic is pControle(0);

	-- Definição de constantes para os códigos das instruções
	constant tipoRinstr : std_logic_vector(5 downto 0) := "000000"; -- 0x00
	constant ADDi       : std_logic_vector(5 downto 0) := "001000"; -- 0x08
	constant ADDr       : std_logic_vector(5 downto 0) := "100000"; -- 0x20
	constant ANDi       : std_logic_vector(5 downto 0) := "001100"; -- 0x0c
	constant ANDr       : std_logic_vector(5 downto 0) := "100100"; -- 0x24
	constant BEQinstr   : std_logic_vector(5 downto 0) := "000100"; -- 0x04
	constant BNEinstr   : std_logic_vector(5 downto 0) := "000101"; -- 0x05
	constant JAL        : std_logic_vector(5 downto 0) := "000011"; -- 0x03
	constant JMP        : std_logic_vector(5 downto 0) := "000010"; -- 0x02
	constant JRinstr    : std_logic_vector(5 downto 0) := "001000"; -- 0x08
	constant LUI        : std_logic_vector(5 downto 0) := "001111"; -- 0x0f
	constant LW         : std_logic_vector(5 downto 0) := "100011"; -- 0x23
	constant NORr       : std_logic_vector(5 downto 0) := "100111"; -- 0x27
	constant ORi        : std_logic_vector(5 downto 0) := "001101"; -- 0x0d
	constant ORr        : std_logic_vector(5 downto 0) := "100101"; -- 0x25
	constant SLT        : std_logic_vector(5 downto 0) := "101010"; -- 0x2a
	constant SLTi       : std_logic_vector(5 downto 0) := "001010"; -- 0x0a
	constant SUBr       : std_logic_vector(5 downto 0) := "100010"; -- 0x22
	constant SW         : std_logic_vector(5 downto 0) := "101011"; -- 0x2b

	begin

	-- Atribuição dos sinais de controle com base no opcode e funct
		JR            <= '1'  when (funct  = JRinstr    AND 
											opcode = tipoRinstr) else 
							  '0';
							  
		smPBJ         <= '1'  when (opcode = JMP        OR 
											opcode = JAL)        else 
							  '0';
		
		smRtRd31      <= "01" when opcode = tipoRinstr else 
							  "10" when opcode = JAL        else 
							  "00";
							  
		OriAndi       <= '1'  when opcode = ORi        OR
											opcode = ANDi       else 
							  '0'; 
							  
		habEscReg     <= '1'  when opcode = ADDi       OR
											opcode = ANDi       OR
											opcode = JAL        OR
											opcode = LW         OR
											opcode = ORi        OR
											opcode = SLTi       OR
											opcode = tipoRinstr else
                       '0';
		
		smRtIm        <= '0'  when opcode = tipoRinstr OR
                                 opcode = BEQinstr   OR
                                 opcode = BNEinstr   else 
                       '1';
							  
		tipoR			  <= '1'  when opcode = tipoRinstr else 
							  '0';
		
		smULAMem   	  <= "01" when opcode = LW         else 
							  "10" when opcode = JAL        else 
							  "11" when opcode = LUI        else 
							  "00";
		
		BEQ			  <= '1'  when opcode = BEQinstr   else 
		                 '0';
			
		BNE			  <= '1'  when opcode = BNEinstr   else 
							  '0';

		habLeituraMEM <= '1'  when opcode = LW         else 
							  '0';  
		
		habEscritaMEM <= '1'  when opcode = SW         else 
							  '0';

	end architecture comportamento;
