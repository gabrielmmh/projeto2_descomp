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

	-- Sinais do Instruction Fetch (IF)
	signal pcOut  : std_logic_vector(31 downto 0); -- Saída do PC (Program Counter)
	signal pc4Out : std_logic_vector(31 downto 0); -- PC + 4
	signal romOut : std_logic_vector(31 downto 0); -- Saída da ROM (instrução)

	-- Sinais do Instruction Decode (ID)
	alias opcode      : std_logic_vector(5 downto 0)  is romOut(31 downto 26);
	alias enderecoRs  : std_logic_vector(4 downto 0)  is romOut(25 downto 21);
	alias enderecoRt  : std_logic_vector(4 downto 0)  is romOut(20 downto 16);
	alias enderecoRd  : std_logic_vector(4 downto 0)  is romOut(15 downto 11);
	alias shamt       : std_logic_vector(4 downto 0)  is romOut(10 downto 6);
	alias funct       : std_logic_vector(5 downto 0)  is romOut(5 downto 0);
	alias imediato    : std_logic_vector(15 downto 0) is romOut(15 downto 0);
	alias enderecoJMP : std_logic_vector(25 downto 0) is romOut(25 downto 0);

	-- Registrador 31 (JAL)
	constant r31     : std_logic_vector(4 downto 0) := "11111";
	
	-- Palavra de controle
	signal pControle : std_logic_vector(13 downto 0); 

	-- Aliases da palavra de controle
	alias JR            : std_logic is pControle(13);
	alias smPBJ         : std_logic is pControle(12);
	alias smRtRd        : std_logic_vector(1 downto 0) is pControle(11 downto 10);
	alias OriAndi       : std_logic is pControle(9);
	alias habEscReg     : std_logic is pControle(8);
	alias smRtIm        : std_logic is pControle(7);
	alias tipoR         : std_logic is pControle(6);
	alias smULAMem      : std_logic_vector(1 downto 0) is pControle(5 downto 4);
	alias BEQ           : std_logic is pControle(3);
	alias BNE           : std_logic is pControle(2);
	alias habLeituraMEM : std_logic is pControle(1);
	alias habEscritaMEM : std_logic is pControle(0);

	-- Sinais para o banco de registradores
	signal mOutRtRd31 : std_logic_vector(4 downto 0);
	signal dadoRs     : std_logic_vector(31 downto 0);
	signal dadoRt     : std_logic_vector(31 downto 0);

	-- Sinais para a ULA (Unidade Lógica e Aritmética)
	signal imedEst       : std_logic_vector(31 downto 0);
	signal mOutRtIm      : std_logic_vector(31 downto 0);
	signal saidaULAcntrl : std_logic_vector(3 downto 0);
	signal saidaULA      : std_logic_vector(31 downto 0);
	signal flagZero      : std_logic;

	-- Sinais para memória
	signal mOutBEQ     : std_logic;
	signal ramOut      : std_logic_vector(31 downto 0);
	signal saidaLUI    : std_logic_vector(31 downto 0);
	signal mOutDadoEsc : std_logic_vector(31 downto 0);
	signal imedEstSL2  : std_logic_vector(31 downto 0);

	-- Sinais para PC e saltos
	signal adderOut   : std_logic_vector(31 downto 0);
	signal mOutBranch : std_logic_vector(31 downto 0);
	signal mOutJMP    : std_logic_vector(31 downto 0);
	signal mOutProxPC : std_logic_vector(31 downto 0);

	-- Sinais para display
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

		-- PC: Registrador para o Program Counter
		PC : entity work.registradorGenerico
			  port map (
					  DIN => mOutProxPC,
					  DOUT => pcOut,
					  ENABLE => '1',
					  CLK => CLK,
					  RST => RESET);

		-- Incrementa PC para próxima instrução
		INC_PC4 : entity work.somaConstante
					 port map (
							 entrada => pcOut,
							 saida => pc4Out);

		-- ROM: Memória de instruções
		ROM : entity work.ROMMIPS
		      port map (
						Endereco => pcOut,
						Dado => romOut);

		-- Unidade de Controle: Gera sinais de controle (palavra de controle)
		UNIDADE_CTRL : entity work.Control
						   port map (
									funct => funct,
									opcode => opcode,
									pControle => pControle);

		-- MUX para selecionar registrador de destino
		MUX_Rt_Rd_R31 : entity work.muxGenerico4x1
							 generic map (larguraDados => 5)
							 port map (
									 entradaA_MUX => enderecoRt,
									 entradaB_MUX => enderecoRd,
									 entradaC_MUX => r31,
									 entradaD_MUX => "00000",
									 seletor_MUX => smRtRd,
									 saida_MUX => mOutRtRd31);

		-- Banco de Registradores
		BANCO_REG : entity work.bancoReg
					   port map (
								clk => CLK,
								enderecoA => enderecoRs,
								enderecoB => enderecoRt,
								enderecoC => mOutRtRd31,
								dadoEscritaC => mOutDadoEsc,
								escreveC => habEscReg,
								saidaA => dadoRs,
								saidaB => dadoRt);

		-- Extensão de sinal para imediatos
		EXT_SINAL : entity work.estendeSinalGenerico
						port map (
								ORiANDi => OriAndi,
								estendeSinal_IN => imediato,
								estendeSinal_OUT => imedEst);

		-- MUX para selecionar entre registrador e imediato
		MUX_Rt_IMM : entity work.muxGenerico2x1
						 port map (
								 entradaA_MUX => dadoRt,
								 entradaB_MUX => imedEst,
								 seletor_MUX => smRtIm,
								 saida_MUX => mOutRtIm);

		-- Unidade de Controle da ULA
		ULAcntrl : entity work.ULAcntrl
					  port map (
							  opcode => opcode,
							  funct => funct,
							  tipoR => tipoR,
							  saida => saidaULAcntrl);

		-- ULA: Unidade Lógica e Aritmética
		ULA : entity work.ULA
			   port map (
						entradaA => dadoRs,
						entradaB => mOutRtIm,
						ULACtrl => saidaULAcntrl,
						saida => saidaULA,
						flagZero => flagZero);

		-- MUX para instruções de desvio condicional (BEQ/BNE)
		MUX_BEQ : entity work.mux1Bit2x1
					 port map (
							 entradaA_MUX => not(flagZero),
							 entradaB_MUX => flagZero,
							 seletor_MUX => BEQ,
							 saida_MUX => mOutBEQ);

		-- RAM: Memória de dados
		RAM : entity work.RAMMIPS
			   port map (
						clk => CLK,
						Endereco => saidaULA,
						Dado_in => dadoRt,
						re => habLeituraMEM,
						we => habEscritaMEM,
						Dado_out => ramOut,
						habilita => '1');

		-- Instrução LUI
		LUI : entity work.LUI
				port map (
						entrada => imediato,
						saida => saidaLUI);

		-- MUX para selecionar entre ULA e memória
		MUX_DADO_ESCRITO : entity work.muxGenerico4x1
								 port map (
										 entradaA_MUX => saidaULA,
										 entradaB_MUX => ramOut,
										 entradaC_MUX => pc4Out,
										 entradaD_MUX => saidaLUI,
										 seletor_MUX => smULAMem,
										 saida_MUX => mOutDadoEsc);
										 
		-- Imediato shiftado duas vezes para a esquerda	
		imedEstSL2 <= imedEst(29 downto 0) & "00";

		-- Somador para calcular endereços de desvio
		adderOut <= std_logic_vector(unsigned(pc4Out) + unsigned(imedEstSL2));

		-- MUX para selecionar entre PC+4 e endereço de desvio
		MUX_PC4_IMM : entity work.muxGenerico2x1
						  port map (
								  entradaA_MUX => pc4Out,
								  entradaB_MUX => adderOut,
								  seletor_MUX => (mOutBEQ and (BEQ or BNE)),
								  saida_MUX => mOutBranch);

		-- MUX para selecionar entre (PC+4) + (SigEst(Imediato)<<2) e PC+4
		MUX_BRANCH : entity work.muxGenerico2x1
						 port map (
								 entradaA_MUX => mOutBranch,
								 entradaB_MUX => (pc4Out(31 downto 28) & enderecoJMP & "00"),
								 seletor_MUX => smPBJ,
								 saida_MUX => mOutJMP);

		-- MUX para selecionar entre endereço de salto e registrador
		MUX_PROX_PC : entity work.muxGenerico2x1
						  port map (
								  entradaA_MUX => mOutJMP,
								  entradaB_MUX => dadoRs,
								  seletor_MUX => JR,
								  saida_MUX => mOutProxPC);

		-- MUX para selecionar entre PC e ULA para display
		MUX_HEX : entity work.muxGenerico2x1
					 port map (
							 entradaA_MUX => pcOut,
							 entradaB_MUX => saidaULA,
							 seletor_MUX => SW(0),
							 saida_MUX => mOutHex);

		-- Decodificadores para displays de 7 segmentos
		DEC_HEX0 : entity work.hexTo7seg
					  port map (
							  dadoHex => mOutHex(3 downto 0),
							  apaga => '0',
							  negativo => '0',
							  overFlow => '0',
							  saida7seg => displayHex0);

		DEC_HEX1 : entity work.hexTo7seg
					  port map (
							  dadoHex => mOutHex(7 downto 4),
							  apaga => '0',
							  negativo => '0',
							  overFlow => '0',
							  saida7seg => displayHex1);

		DEC_HEX2 : entity work.hexTo7seg
					  port map (
							  dadoHex => mOutHex(11 downto 8),
							  apaga => '0',
							  negativo => '0',
							  overFlow => '0',
							  saida7seg => displayHex2);

		DEC_HEX3 : entity work.hexTo7seg
					  port map (
							  dadoHex => mOutHex(15 downto 12),
							  apaga => '0',
							  negativo => '0',
							  overFlow => '0',
							  saida7seg => displayHex3);

		DEC_HEX4 : entity work.hexTo7seg
					  port map (
							  dadoHex => mOutHex(19 downto 16),
							  apaga => '0',
							  negativo => '0',
							  overFlow => '0',
							  saida7seg => displayHex4);

		DEC_HEX5 : entity work.hexTo7seg
					  port map (
							  dadoHex => mOutHex(23 downto 20),
							  apaga => '0',
							  negativo => '0',
							  overFlow => '0',
							  saida7seg => displayHex5);

		-- Atribuição dos displays HEX
		HEX0 <= displayHex0;
		HEX1 <= displayHex1;
		HEX2 <= displayHex2;
		HEX3 <= displayHex3;
		HEX4 <= displayHex4;
		HEX5 <= displayHex5;

		-- Atribuição dos LEDs
		LEDR(3 downto 0) <= mOutHex(27 downto 24);
		LEDR(7 downto 4) <= mOutHex(31 downto 28);

	end architecture;