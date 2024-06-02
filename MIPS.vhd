library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MIPS is
    generic (
		simulacao : boolean := FALSE -- para gravar na placa, use FALSE
    );
    port (
		-- portas de entrada
		CLOCK_50, FPGA_RESET_N : in std_logic;
		KEY : in std_logic_vector(3 downto 0);
		SW : in std_logic_vector(9 downto 0);
		
		-- portas de debug
		PC_OUT             : out std_logic_vector(31 downto 0);
		PC4_OUT            : out std_logic_vector(31 downto 0);
		ULA_OUT            : out std_logic_vector(31 downto 0);
		DadoEsc_OUT        : out std_logic_vector(31 downto 0);

		-- portas de saída
		LEDR : out std_logic_vector(9 downto 0);
		HEX0 : out std_logic_vector(6 downto 0);
		HEX1 : out std_logic_vector(6 downto 0);
		HEX2 : out std_logic_vector(6 downto 0);
		HEX3 : out std_logic_vector(6 downto 0);
		HEX4 : out std_logic_vector(6 downto 0);
		HEX5 : out std_logic_vector(6 downto 0)
    );
end entity;

architecture comportamento of MIPS is
    -- Sinais de CLK e RESET
	signal CLK : std_logic;
	signal RESET : std_logic;

	------------------------------------- Instruction Fetch (IF) Signals  -------------------------------------
	
	signal mOutBranch : std_logic_vector(31 downto 0); -- Saída do MUX MUX que seleciona entre PC+4 e endereço de desvio
	signal mOutJMP    : std_logic_vector(31 downto 0); -- Saída do MUX MUX que seleciona entre (PC+4) + (SinEst(Imediato)<<2) e PC+4
	signal mOutProxPC : std_logic_vector(31 downto 0); -- Saída do MUX MUX que seleciona entre endereço de salto e registrador

	signal pcOut  : std_logic_vector(31 downto 0); -- Saída do PC (Program Counter)
	signal pc4Out : std_logic_vector(31 downto 0); -- PC + 4
	signal romOut : std_logic_vector(31 downto 0); -- Saída da ROM (instrução)

	------------------------------------- IF/ID Register Signals  -------------------------------------

	-- 32 bits para PC+4 e 32 bits para a instrução totalizando 64 bits.
	
	signal inIFID  : std_logic_vector(63 downto 0); -- Entrada do IF/ID Register
	signal outIFID : std_logic_vector(63 downto 0); -- Saída do IF/ID Register

	-- Aliases para facilitar a manipulação dos sinais de entrada do IF/ID Register
	alias inIFID_pc4Out : std_logic_vector(31 downto 0) is inIFID(31 downto 0);
	alias inIFID_romOut : std_logic_vector(31 downto 0) is inIFID(63 downto 32);

	-- Aliases para facilitar a manipulação dos sinais de saída do IF/ID Register
	alias outIFID_pc4Out : std_logic_vector(31 downto 0) is outIFID(31 downto 0);
	alias outIFID_romOut : std_logic_vector(31 downto 0) is outIFID(63 downto 32);

	------------------------------------- Instruction Decode (ID) Signals  -------------------------------------

	alias opcode      : std_logic_vector(5 downto 0)  is outIFID_romOut(31 downto 26);
	alias enderecoRs  : std_logic_vector(4 downto 0)  is outIFID_romOut(25 downto 21);
	alias enderecoRt  : std_logic_vector(4 downto 0)  is outIFID_romOut(20 downto 16);
	alias enderecoRd  : std_logic_vector(4 downto 0)  is outIFID_romOut(15 downto 11);
	alias shamt       : std_logic_vector(4 downto 0)  is outIFID_romOut(10 downto 6);
	alias funct       : std_logic_vector(5 downto 0)  is outIFID_romOut(5 downto 0);
	alias imediato    : std_logic_vector(15 downto 0) is outIFID_romOut(15 downto 0);
	alias enderecoJMP : std_logic_vector(25 downto 0) is outIFID_romOut(25 downto 0);
	
	-- Sinais para o banco de registradores
	signal dadoRs : std_logic_vector(31 downto 0);
	signal dadoRt : std_logic_vector(31 downto 0);
	
	signal imedEst  : std_logic_vector(31 downto 0);
	signal saidaLUI : std_logic_vector(31 downto 0);

	-- Registrador 31 (JAL)
	constant r31 : std_logic_vector(4 downto 0) := "11111";
	
	-- Palavra de controle
	signal pControle : std_logic_vector(13 downto 0); 

	alias JR      : std_logic is pControle(13);
	alias smPBJ   : std_logic is pControle(12);
	alias OriAndi : std_logic is pControle(9);

	------------------------------------- ID/EX Register Signals  -------------------------------------

	-- 32 bits para PC+4, 32 bits o dado de Rs, 32 bits para o dado de Rt, 32 bits para o imediato,
	-- 32 bits para a saída do LUI, 14 bits para a palavra de controle, 6 bits para o opcode, 6 bits para o funct,
	-- 5 bits para o endereço de Rt e 5 bits para o endereço de Rd totalizando 196 bits.

	signal inIDEX  : std_logic_vector(195 downto 0); -- Entrada do ID/EX Register
	signal outIDEX : std_logic_vector(195 downto 0); -- Saída do ID/EX Register

	-- Aliases para facilitar a manipulação dos sinais de entrada do ID/EX Register
	alias inIDEX_pc4Out     : std_logic_vector(31 downto 0) is inIDEX(31 downto 0);
	alias inIDEX_dadoRs     : std_logic_vector(31 downto 0) is inIDEX(63 downto 32);
	alias inIDEX_dadoRt     : std_logic_vector(31 downto 0) is inIDEX(95 downto 64);
	alias inIDEX_imedEst    : std_logic_vector(31 downto 0) is inIDEX(127 downto 96);
	alias inIDEX_saidaLUI   : std_logic_vector(31 downto 0) is inIDEX(159 downto 128);
	alias inIDEX_pControle  : std_logic_vector(13 downto 0) is inIDEX(173 downto 160);
	alias inIDEX_opcode     : std_logic_vector(5 downto 0)  is inIDEX(179 downto 174);
	alias inIDEX_funct      : std_logic_vector(5 downto 0)  is inIDEX(185 downto 180);
	alias inIDEX_enderecoRt : std_logic_vector(4 downto 0)  is inIDEX(190 downto 186);
	alias inIDEX_enderecoRd : std_logic_vector(4 downto 0)  is inIDEX(195 downto 191);

	-- Aliases para facilitar a manipulação dos sinais de saída do ID/EX Register
	alias outIDEX_pc4Out     : std_logic_vector(31 downto 0) is outIDEX(31 downto 0);
	alias outIDEX_dadoRs     : std_logic_vector(31 downto 0) is outIDEX(63 downto 32);
	alias outIDEX_dadoRt     : std_logic_vector(31 downto 0) is outIDEX(95 downto 64);
	alias outIDEX_imedEst    : std_logic_vector(31 downto 0) is outIDEX(127 downto 96);
	alias outIDEX_saidaLUI   : std_logic_vector(31 downto 0) is outIDEX(159 downto 128);
	alias outIDEX_pControle  : std_logic_vector(13 downto 0) is outIDEX(173 downto 160);
	alias outIDEX_opcode     : std_logic_vector(5 downto 0)  is outIDEX(179 downto 174);
	alias outIDEX_funct      : std_logic_vector(5 downto 0)  is outIDEX(185 downto 180);
	alias outIDEX_enderecoRt : std_logic_vector(4 downto 0)  is outIDEX(190 downto 186);
	alias outIDEX_enderecoRd : std_logic_vector(4 downto 0)  is outIDEX(195 downto 191);

	------------------------------------- Execution (EX) Signals  -------------------------------------

	signal mOutRtRd31 : std_logic_vector(4 downto 0); -- Saída do MUX Rt/Rd/R31

	-- Aliases para facilitar manipulação da palavra de controle
	alias smRtRd31      : std_logic_vector(1 downto 0) is outIDEX_pControle(11 downto 10);
	alias habEscReg     : std_logic                    is outIDEX_pControle(8);
	alias smRtIm        : std_logic                    is outIDEX_pControle(7);
	alias tipoR         : std_logic                    is outIDEX_pControle(6);
	alias smULAMem      : std_logic_vector(1 downto 0) is outIDEX_pControle(5 downto 4);
	alias BEQ           : std_logic                    is outIDEX_pControle(3);
	alias BNE           : std_logic                    is outIDEX_pControle(2);
	alias habLeituraMEM : std_logic                    is outIDEX_pControle(1);
	alias habEscritaMEM : std_logic                    is outIDEX_pControle(0);

	signal adderOut   : std_logic_vector(31 downto 0); -- Saída do somador
	signal imedEstSL2 : std_logic_vector(31 downto 0); -- Imediato shiftado duas vezes para a esquerda

	signal mOutRtIm   : std_logic_vector(31 downto 0); -- Saída do MUX Rt/Im

	-- Sinais para a ULA (Unidade Lógica e Aritmética)
	signal saidaULAcntrl : std_logic_vector(3 downto 0);
	signal saidaULA      : std_logic_vector(31 downto 0);
	signal flagZero      : std_logic;
	signal mOutBEQ       : std_logic;

	------------------------------------- EX/MEM Register Signals  -------------------------------------

	-- 32 bits para PC+4, 32 bits para a saída do LUI, 32 bits para o somador, 32 bits para o dado de Rt,
	-- 32 bits para a saída da ULA, 5 bits para a saída do MUX Rt/Rd/R31, 2 bits para o seletor do MUX ULA/Mem,
	-- 1 bit para habilitar escrita no banco de registradores, 1 bit para habilitar leitura na memória, 1 bit para
	-- habilitar escrita na memória, 1 bit para a saída do MUX BEQ, 1 bit para BEQ e 1 bit para BNE totalizando 173 bits.

	signal inEXMEM  : std_logic_vector(172 downto 0); -- Entrada do EX/MEM Register
	signal outEXMEM : std_logic_vector(172 downto 0); -- Saída do EX/MEM Register

	-- Aliases para facilitar a manipulação dos sinais de entrada do EX/MEM Register
	alias inEXMEM_pc4Out        : std_logic_vector(31 downto 0) is inEXMEM(31 downto 0);
	alias inEXMEM_saidaLUI      : std_logic_vector(31 downto 0) is inEXMEM(63 downto 32);
	alias inEXMEM_adderOut      : std_logic_vector(31 downto 0) is inEXMEM(95 downto 64);
	alias inEXMEM_dadoRt        : std_logic_vector(31 downto 0) is inEXMEM(127 downto 96);
	alias inEXMEM_saidaULA      : std_logic_vector(31 downto 0) is inEXMEM(159 downto 128);
	alias inEXMEM_mOutRtRd31    : std_logic_vector(4 downto 0)  is inEXMEM(164 downto 160);
	alias inEXMEM_smULAMem      : std_logic_vector(1 downto 0)  is inEXMEM(166 downto 165);
	alias inEXMEM_habEscReg     : std_logic                     is inEXMEM(167);
	alias inEXMEM_habLeituraMEM : std_logic                     is inEXMEM(168);
	alias inEXMEM_habEscritaMEM : std_logic                     is inEXMEM(169);
	alias inEXMEM_mOutBEQ       : std_logic                     is inEXMEM(170);
	alias inEXMEM_BEQ           : std_logic                     is inEXMEM(171);
	alias inEXMEM_BNE           : std_logic                     is inEXMEM(172);

	-- Aliases para facilitar a manipulação dos sinais de saída do EX/MEM Register
	alias outEXMEM_pc4Out        : std_logic_vector(31 downto 0) is outEXMEM(31 downto 0);
	alias outEXMEM_saidaLUI      : std_logic_vector(31 downto 0) is outEXMEM(63 downto 32);
	alias outEXMEM_adderOut      : std_logic_vector(31 downto 0) is outEXMEM(95 downto 64);
	alias outEXMEM_dadoRt        : std_logic_vector(31 downto 0) is outEXMEM(127 downto 96);
	alias outEXMEM_saidaULA      : std_logic_vector(31 downto 0) is outEXMEM(159 downto 128);
	alias outEXMEM_mOutRtRd31    : std_logic_vector(4 downto 0)  is outEXMEM(164 downto 160);
	alias outEXMEM_smULAMem      : std_logic_vector(1 downto 0)  is outEXMEM(166 downto 165);
	alias outEXMEM_habEscReg     : std_logic                     is outEXMEM(167);
	alias outEXMEM_habLeituraMEM : std_logic                     is outEXMEM(168);
	alias outEXMEM_habEscritaMEM : std_logic                     is outEXMEM(169);
	alias outEXMEM_mOutBEQ       : std_logic                     is outEXMEM(170);
	alias outEXMEM_BEQ           : std_logic                     is outEXMEM(171);
	alias outEXMEM_BNE           : std_logic                     is outEXMEM(172);

	------------------------------------- Memory Access (MEM) Signals  -------------------------------------

	signal ramOut : std_logic_vector(31 downto 0);

	------------------------------------- MEM/WB Register Signals  -------------------------------------

	-- 32 bits para PC+4, 32 bits para a saída do LUI, 32 bits para a saída da ULA, 32 bits para a RAM,
	-- 5 bits para a saída do MUX Rt/Rd/R31, 2 bits para o seletor do MUX ULA/Mem e 1 bit para habilitar
	-- escrita no banco de registradores totalizando 136 bits.

	signal inMEMWB  : std_logic_vector(135 downto 0); -- Entrada do MEM/WB Register
	signal outMEMWB : std_logic_vector(135 downto 0); -- Saída do MEM/WB Register

	-- Aliases para facilitar a manipulação dos sinais de entrada do MEM/WB Register
	alias inMEMWB_pc4Out     : std_logic_vector(31 downto 0) is inMEMWB(31 downto 0);
	alias inMEMWB_saidaLUI   : std_logic_vector(31 downto 0) is inMEMWB(63 downto 32);
	alias inMEMWB_saidaULA   : std_logic_vector(31 downto 0) is inMEMWB(95 downto 64);
	alias inMEMWB_ramOut     : std_logic_vector(31 downto 0) is inMEMWB(127 downto 96);
	alias inMEMWB_mOutRtRd31 : std_logic_vector(4 downto 0)  is inMEMWB(132 downto 128);
	alias inMEMWB_smULAMem   : std_logic_vector(1 downto 0)  is inMEMWB(134 downto 133);
	alias inMEMWB_habEscReg  : std_logic                     is inMEMWB(135);

	-- Aliases para facilitar a manipulação dos sinais de saída do MEM/WB Register
	alias outMEMWB_pc4Out     : std_logic_vector(31 downto 0) is outMEMWB(31 downto 0);
	alias outMEMWB_saidaLUI   : std_logic_vector(31 downto 0) is outMEMWB(63 downto 32);
	alias outMEMWB_saidaULA   : std_logic_vector(31 downto 0) is outMEMWB(95 downto 64);
	alias outMEMWB_ramOut     : std_logic_vector(31 downto 0) is outMEMWB(127 downto 96);
	alias outMEMWB_mOutRtRd31 : std_logic_vector(4 downto 0)  is outMEMWB(132 downto 128);
	alias outMEMWB_smULAMem   : std_logic_vector(1 downto 0)  is outMEMWB(134 downto 133);
	alias outMEMWB_habEscReg  : std_logic is outMEMWB(135);

	------------------------------------- Write Back (WB) Signals  -------------------------------------

	signal mOutDadoEsc : std_logic_vector(31 downto 0);

	------------------------------------- Display Signals  -------------------------------------
 
	signal mOutHex     : std_logic_vector(31 downto 0);
	signal displayHex0 : std_logic_vector(6 downto 0);
	signal displayHex1 : std_logic_vector(6 downto 0);
	signal displayHex2 : std_logic_vector(6 downto 0);
	signal displayHex3 : std_logic_vector(6 downto 0);
	signal displayHex4 : std_logic_vector(6 downto 0);
	signal displayHex5 : std_logic_vector(6 downto 0);

	begin
		
		-- Configuração de CLK e RESET para simulação
		
		gravar:  if simulacao generate
		CLK <= KEY(0);
		RESET <= '0';
		else generate
		EDGE_DETECT_CLK   : work.edgeDetector(bordaSubida)
		port map (clk => CLOCK_50, entrada => (not KEY(0)), saida => CLK);
		 
		 EDGE_DETECT_RESET : work.edgeDetector(bordaSubida)
											port map (clk => CLOCK_50, entrada => (NOT FPGA_RESET_N), saida => RESET);
		end generate;

		------------------------------------- Instruction Fetch (IF) -------------------------------------

		-- MUX para selecionar entre PC+4 e endereço de desvio
		M_PC4_ADD : entity work.muxGenerico2x1
						port map (
								entradaA_MUX => pc4Out,
								entradaB_MUX => outEXMEM_adderOut,
								seletor_MUX => (outEXMEM_mOutBEQ and (outEXMEM_BEQ or outEXMEM_BNE)),
								saida_MUX => mOutBranch);

		-- MUX para selecionar entre (PC+4) + (SinEst(Imediato)<<2) e PC+4
		M_JMP :     entity work.muxGenerico2x1
						port map (
								entradaA_MUX => mOutBranch,
								entradaB_MUX => (pc4Out(31 downto 28) & enderecoJMP & "00"),
								seletor_MUX => smPBJ,
								saida_MUX => mOutJMP);
		
		-- MUX para selecionar entre endereço de salto e registrador
		M_PROX_PC : entity work.muxGenerico2x1
						port map (
								entradaA_MUX => mOutJMP,
								entradaB_MUX => dadoRs,
								seletor_MUX => JR,
								saida_MUX => mOutProxPC);

		-- PC: Registrador para o Program Counter
		PC : 		entity work.registradorGenerico
						port map (
								DIN => mOutProxPC,
								DOUT => pcOut,
								ENABLE => '1',
								CLK => CLK,
								RST => RESET);

		-- Incrementa PC para próxima instrução
		INC_PC4 : 	entity work.somaConstante
						port map (
								entrada => pcOut,
								saida => pc4Out);
						 
		-- ROM: Memória de instruções
		ROM : 		entity work.ROMMIPS
						port map (
								Endereco => pcOut,
								Dado => romOut);

		------------------------------------- IF/ID Register -------------------------------------

		inIFID_pc4Out <= pc4Out;
		inIFID_romOut <= romOut;

		REG_IF_ID : entity work.registradorGenerico
						generic map (larguraDados => 64)
						port map (
								DIN => inIFID,
								DOUT => outIFID,
								ENABLE => '1',
								CLK => CLK,
								RST => RESET);

		------------------------------------- Instruction Decode (ID) -------------------------------------

		-- Banco de Registradores
		B_REG : 	entity work.bancoReg
						port map (
								clk => CLK,
								enderecoA => enderecoRs,
								enderecoB => enderecoRt,
								enderecoC => outMEMWB_mOutRtRd31,
								dadoEscritaC => mOutDadoEsc,
								escreveC => outMEMWB_habEscReg,
								saidaA => dadoRs,
								saidaB => dadoRt);

		-- Unidade de Controle: Gera sinais de controle (palavra de controle)
		UNI_CTRL :  entity work.Control
						port map (
								funct => funct,
								opcode => opcode,
								pControle => pControle);

		-- Extensão de sinal para imediatos
		EXT_SINAL : entity work.estendeSinalGenerico
						port map (
								ORiANDi => OriAndi,
								estendeSinal_IN => imediato,
								estendeSinal_OUT => imedEst);

		-- Instrução LUI
		LUI : 		entity work.LUI
						port map (
							entrada => imediato,
							saida => saidaLUI);

		------------------------------------- ID/EX Register -------------------------------------

		inIDEX_pc4Out     <= outIFID_pc4Out;
		inIDEX_dadoRs     <= dadoRs;
		inIDEX_dadoRt     <= dadoRt;
		inIDEX_imedEst    <= imedEst;
		inIDEX_saidaLUI   <= saidaLUI;
		inIDEX_pControle  <= pControle;
		inIDEX_opcode     <= opcode;
		inIDEX_funct      <= funct;
		inIDEX_enderecoRt <= enderecoRt;
		inIDEX_enderecoRd <= enderecoRd;

		REG_ID_EX : entity work.registradorGenerico
						generic map (larguraDados => 196)
					 	port map (
							 	DIN => inIDEX,
							 	DOUT => outIDEX,
							 	ENABLE => '1',
								CLK => CLK,
								RST => RESET);

		------------------------------------- Execution (EX) -------------------------------------

		-- MUX para selecionar registrador de destino
		M_RtRd31 :  entity work.muxGenerico4x1
						generic map (larguraDados => 5)
						port map (
								entradaA_MUX => outIDEX_enderecoRt,
								entradaB_MUX => outIDEX_enderecoRd,
								entradaC_MUX => r31,
								entradaD_MUX => "00000",
								seletor_MUX => smRtRd31,
								saida_MUX => mOutRtRd31);

		-- MUX para selecionar entre registrador e imediato
		M_Rt_IMM :  entity work.muxGenerico2x1
						port map (
								entradaA_MUX => outIDEX_dadoRt,
								entradaB_MUX => outIDEX_imedEst,
								seletor_MUX => smRtIm,
								saida_MUX => mOutRtIm);

		-- Unidade de Controle da ULA
		ULAcntrl :  entity work.ULAcntrl
					    port map (
							  	opcode => outIDEX_opcode,
							  	funct => outIDEX_funct,
							  	tipoR => tipoR,
							  	saida => saidaULAcntrl);

		-- ULA: Unidade Lógica e Aritmética
		ULA : 		entity work.ULA
						port map (
								entradaA => outIDEX_dadoRs,
								entradaB => mOutRtIm,
								ULACtrl => saidaULAcntrl,
								saida => saidaULA,
								flagZero => flagZero);

		-- MUX para instruções de desvio condicional (BEQ/BNE)
		M_BEQ : 	entity work.mux1Bit2x1
					 	port map (
							 	entradaA_MUX => not(flagZero),
							 	entradaB_MUX => flagZero,
							 	seletor_MUX => BEQ,
							 	saida_MUX => mOutBEQ);
		
		-- Imediato shiftado duas vezes para a esquerda	
		imedEstSL2 <= outIDEX_imedEst(29 downto 0) & "00";

		-- Somador para calcular endereços de desvio
		adderOut   <= std_logic_vector(unsigned(outIDEX_pc4Out) + unsigned(imedEstSL2));

		------------------------------------- EX/MEM Register -------------------------------------
		
		inEXMEM_pc4Out        <= outIDEX_pc4Out;
		inEXMEM_saidaLUI      <= outIDEX_saidaLUI;
		inEXMEM_adderOut      <= adderOut;
		inEXMEM_dadoRt        <= outIDEX_dadoRt;
		inEXMEM_saidaULA      <= saidaULA;
		inEXMEM_mOutRtRd31    <= mOutRtRd31;
		inEXMEM_smULAMem      <= smULAMem;
		inEXMEM_habEscReg     <= habEscReg;
		inEXMEM_habLeituraMEM <= habLeituraMEM;
		inEXMEM_habEscritaMEM <= habEscritaMEM;
		inEXMEM_mOutBEQ       <= mOutBEQ;
		inEXMEM_BEQ           <= BEQ;
		inEXMEM_BNE           <= BNE;

		R_EX_MEM :  entity work.registradorGenerico
					 	generic map (larguraDados => 173)
					 	port map (
								DIN => inEXMEM,
								DOUT => outEXMEM,
								ENABLE => '1',
								CLK => CLK,
								RST => RESET);

		------------------------------------- Memory Access (MEM) -------------------------------------

		-- RAM: Memória de dados
		RAM : 		entity work.RAMMIPS
			   			port map (
								clk => CLK,
								Endereco => outEXMEM_saidaULA,
								Dado_in => outEXMEM_dadoRt,
								re => outEXMEM_habLeituraMEM,
								we => outEXMEM_habEscritaMEM,
								Dado_out => ramOut,
								habilita => '1');

		------------------------------------- MEM/WB Register -------------------------------------

		inMEMWB_pc4Out     <= outEXMEM_pc4Out;
		inMEMWB_saidaLUI   <= outEXMEM_saidaLUI;
		inMEMWB_saidaULA   <= outEXMEM_saidaULA;
		inMEMWB_ramOut     <= ramOut;
		inMEMWB_mOutRtRd31 <= outEXMEM_mOutRtRd31;
		inMEMWB_smULAMem   <= outEXMEM_smULAMem;
		inMEMWB_habEscReg  <= outEXMEM_habEscReg;

		R_MEM_WB :  entity work.registradorGenerico
					 	generic map (larguraDados => 136)
					 	port map (
								DIN => inMEMWB,
								DOUT => outMEMWB,
								ENABLE => '1',
								CLK => CLK,
								RST => RESET);

		------------------------------------- Write Back (WB) -------------------------------------

		-- MUX para selecionar entre saída da ULA, RAM, PC+4 e saída do LUI para escrita no banco de registradores
		M_DD_ESCR : entity work.muxGenerico4x1
						port map (
								entradaA_MUX => outMEMWB_saidaULA,
								entradaB_MUX => outMEMWB_ramOut,
								entradaC_MUX => outMEMWB_pc4Out,
								entradaD_MUX => outMEMWB_saidaLUI,
								seletor_MUX => outMEMWB_smULAMem,
								saida_MUX => mOutDadoEsc);

		-- MUX para selecionar entre PC e ULA para display
		M_HEX : 	entity work.muxGenerico4x1
					 	port map (
								entradaA_MUX => pcOut,
								entradaB_MUX => pc4Out,
								entradaC_MUX => saidaULA,
								entradaD_MUX => mOutDadoEsc,
								seletor_MUX => SW(1) & SW(0),
								saida_MUX => mOutHex);

		-- Decodificadores para displays de 7 segmentos
		DEC_HEX0 : 	entity work.hexTo7seg
					  	port map (
								dadoHex => mOutHex(3 downto 0),
								apaga => '0',
								negativo => '0',
								overFlow => '0',
								saida7seg => displayHex0);

		DEC_HEX1 : 	entity work.hexTo7seg
					  	port map (
								dadoHex => mOutHex(7 downto 4),
								apaga => '0',
								negativo => '0',
								overFlow => '0',
								saida7seg => displayHex1);

		DEC_HEX2 : 	entity work.hexTo7seg
					  	port map (
								dadoHex => mOutHex(11 downto 8),
								apaga => '0',
								negativo => '0',
								overFlow => '0',
								saida7seg => displayHex2);

		DEC_HEX3 : 	entity work.hexTo7seg
					  	port map (
								dadoHex => mOutHex(15 downto 12),
								apaga => '0',
								negativo => '0',
								overFlow => '0',
								saida7seg => displayHex3);

		DEC_HEX4 : 	entity work.hexTo7seg
					  	port map (
								dadoHex => mOutHex(19 downto 16),
								apaga => '0',
								negativo => '0',
								overFlow => '0',
								saida7seg => displayHex4);

		DEC_HEX5 : 	entity work.hexTo7seg
					  	port map (
								dadoHex => mOutHex(23 downto 20),
								apaga => '0',
								negativo => '0',
								overFlow => '0',
								saida7seg => displayHex5);
		
		-- Sinais do Teste da ROM
		PC_OUT      <= pcOut;
		PC4_OUT     <= pc4out;
		ULA_OUT     <= saidaULA;
		DadoEsc_OUT <= mOutDadoEsc;

		-- Atribuição dos displays HEX
		HEX0 <= displayHex0;
		HEX1 <= displayHex1;
		HEX2 <= displayHex2;
		HEX3 <= displayHex3;
		HEX4 <= displayHex4;
		HEX5 <= displayHex5;

		-- Atribuição dos LEDs
		LEDR(9 downto 8) <= flagZero & mOutBEQ;
		LEDR(7 downto 4) <= mOutHex(31 downto 28);
		LEDR(3 downto 0) <= mOutHex(27 downto 24);

	end architecture;