library ieee;
use ieee.std_logic_1164.all;

entity Control is
	port ( 
			funct  : in  std_logic_vector (5  downto 0);
			opcode : in  std_logic_vector (5  downto 0);
			saida  : out std_logic_vector (13 downto 0)
		  );
	end entity;

architecture comportamento of Control is
  
	alias JR            : std_logic is saida(13);
	alias smPBJ         : std_logic is saida(12);
	alias smRtRd        : std_logic_vector is saida(11 downto 10);
	alias OriAndi       : std_logic is saida(9);
	alias habEscReg     : std_logic is saida(8);
	alias smRtIm        : std_logic is saida(7);
	alias tipoR         : std_logic is saida(6);
	alias smULAMem      : std_logic_vector is saida(5  downto 4);
	alias BEQ           : std_logic is saida(3);
	alias BNE           : std_logic is saida(2);
	alias habLeituraMEM : std_logic is saida(1);
	alias habEscritaMEM : std_logic is saida(0);

	-- constante 0, opcode Rt
	constant oRt     : std_logic_vector(5 downto 0) := "000000"; -- 0x00

	-- Código das instruções passadas pelo OPCODE e pelo FUNCT
	constant ADDi    : std_logic_vector(5 downto 0) := "001000"; -- 0x08
	constant ADDr    : std_logic_vector(5 downto 0) := "100000"; -- 0x20
	constant ANDi    : std_logic_vector(5 downto 0) := "001100"; -- 0x0c
	constant ANDr    : std_logic_vector(5 downto 0) := "100100"; -- 0x24
	constant BEQ     : std_logic_vector(5 downto 0) := "000100"; -- 0x04
	constant BNE     : std_logic_vector(5 downto 0) := "000101"; -- 0x05
	constant JAL     : std_logic_vector(5 downto 0) := "000011"; -- 0x03
	constant JMP     : std_logic_vector(5 downto 0) := "000010"; -- 0x02
	constant JRinstr : std_logic_vector(5 downto 0) := "001000"; -- 0x08
	constant LUI     : std_logic_vector(5 downto 0) := "001111"; -- 0x0f
	constant LW      : std_logic_vector(5 downto 0) := "100011"; -- 0x23
	constant NORr    : std_logic_vector(5 downto 0) := "100111"; -- 0x27
	constant ORi     : std_logic_vector(5 downto 0) := "001101"; -- 0x0d
	constant ORr     : std_logic_vector(5 downto 0) := "100101"; -- 0x25
	constant SLT     : std_logic_vector(5 downto 0) := "101010"; -- 0x2a
	constant SLTi    : std_logic_vector(5 downto 0) := "001010"; -- 0x0a
	constant SUBr    : std_logic_vector(5 downto 0) := "100010"; -- 0x22
	constant SW      : std_logic_vector(5 downto 0) := "101011"; -- 0x2b

	begin
	
		JR            <= '1'  when funct = JRinstr AND 
											opcode = oRt    else 
							  '0';
							  
		smPBJ         <= '1'  when opcode = JMP    OR 
											opcode = JAL    else 
							  '0';
		
		smRtRd        <= "01" when opcode = oRt    else 
							  "10" when opcode = JAL    else 
							  "00";
							  
		OriAndi       <= '1'  when opcode = ORi    OR
											opcode = ANDi   else 
							  '0'; 
		
		habEscReg     <= '1'  when opcode = ADDi   OR 
											opcode = ANDi   OR
											opcode = JAL    OR
											opcode = LUI    OR 
											opcode = LW     OR
											opcode = ORi    OR 
											opcode = SLTi   OR
										  (opcode = oRt    AND NOT (funct = JRinstr)) else
							  '0';
							 
		smRtIm        <= '1'  when opcode = LW     OR
											opcode = SW	    OR
											opcode = ADDi   OR 
											opcode = ANDi   OR 
											opcode = ORi    OR 
											opcode = SLTi   else 
							  '0';	
							  
		tipoR			  <= '1'  when opcode = oRt    else 
							  '0';
		
		smULAMem   	  <= "01" when opcode = LW     else 
							  "10" when opcode = JAL    else 
							  "11" when opcode = LUI    else 
							  "00";
		
		BEQ			  <= '1'  when opcode = BEQ    else 
		                 '0';
		
		BNE			  <= '1'  when opcode = BNE    else 
							  '0';

		habLeituraMEM <= '1'  when opcode = LW     else 
							  '0';
		
		habEscritaMEM <= '1'  when opcode = SW     else 
							  '0';
										  										 	  
end architecture;