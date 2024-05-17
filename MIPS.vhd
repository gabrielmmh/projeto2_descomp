library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity MIPS is
    generic   (
		data_width  : natural :=  32;
		addr_width  : natural :=  32;
		simulacao   : boolean := FALSE -- to record on board, use FALSE
    );

	 port   (
		-- Input ports
		CLOCK_50, FPGA_RESET_N : in  std_logic;
		KEY                    : in  std_logic_vector(3 downto 0);
		SW                     : in  std_logic_vector(9 downto 0);

		-- Output ports
		LEDR                   : out std_logic_vector(9 downto 0);
		HEX0                   : out std_logic_vector(6 downto 0);
		HEX1                   : out std_logic_vector(6 downto 0);
		HEX2                   : out std_logic_vector(6 downto 0);
		HEX3                   : out std_logic_vector(6 downto 0);
		HEX4                   : out std_logic_vector(6 downto 0);
		HEX5                   : out std_logic_vector(6 downto 0)
	 );
	end entity;


architecture comportamento of MIPS is
	
	--	Sinais de CLK e RST
	signal CLK               : std_logic;
	signal RESET             : std_logic;
	
	--	Sinais do Instruction Instruction Fetch
	signal pc_out            : std_logic_vector(data_width - 1 downto 0);
	signal pc_out4           : std_logic_vector(data_width - 1 downto 0);
	signal rom_out           : std_logic_vector(data_width - 1 downto 0);
	
	--	Sinais do Instruction Data
	alias opcode             : std_logic_vector(5  downto 0) is rom_out(31 downto 26);
	alias rs                 : std_logic_vector(4  downto 0) is rom_out(25 downto 21);
	alias rt                 : std_logic_vector(4  downto 0) is rom_out(20 downto 16);
	alias rd                 : std_logic_vector(4  downto 0) is rom_out(15 downto 11);
	alias immediate          : std_logic_vector(15 downto 0) is rom_out(15 downto  0);
	alias jmp_address        : std_logic_vector(25 downto 0) is rom_out(25 downto  0);
	alias funct              : std_logic_vector(5  downto 0) is rom_out(5  downto  0);
	alias shamt              : std_logic_vector(4  downto 0) is rom_out(10 downto  6);
	
	
	signal r31               : std_logic_vector(4 downto 0);
	signal control_word      : std_logic_vector(15 downto 0);
	alias sel_mux_lui_sr_sl  : std_logic_vector(1 downto 0) is control_word(15 downto 14);
	alias jr                 : std_logic is control_word(13);
	alias sel_mux_pc4_jmp    : std_logic is control_word(12);
	alias sel_mux_rt_rd      : std_logic_vector(1 downto 0) is control_word(11 downto 10);
	alias sel_ori_andi       : std_logic is control_word(9);
	alias enable_reg_wr      : std_logic is control_word(8);
	alias sel_mux_rt_imm     : std_logic is control_word(7);
	alias sel_type_r         : std_logic is control_word(6);
	alias sel_mux_alu_ram    : std_logic_vector(1 downto 0) is control_word(5 downto 4);
	alias beq                : std_logic is control_word(3);
	alias bne                : std_logic is control_word(2);
	alias enable_ram_rd      : std_logic is control_word(1);
	alias enable_ram_wr      : std_logic is control_word(0);
	signal mux_rt_rd_out     : std_logic_vector(4 downto 0);
	signal rs_data           : std_logic_vector(data_width - 1 downto 0);
	signal rt_data           : std_logic_vector(data_width - 1 downto 0);
	signal im_extend         : std_logic_vector(data_width - 1 downto 0);
	signal mux_rt_imm_out    : std_logic_vector(data_width - 1 downto 0);
	signal control_word_alu  : std_logic_vector(3 downto 0);
	signal alu_out           : std_logic_vector(data_width - 1 downto 0);
	signal flag_zero         : std_logic;
	signal mux_beq_out       : std_logic;
	signal ram_out           : std_logic_vector(data_width - 1 downto 0);
	signal lui_out           : std_logic_vector(data_width - 1 downto 0);
	signal sr_out            : std_logic_vector(data_width - 1 downto 0);
	signal sl_out            : std_logic_vector(data_width - 1 downto 0);
	signal mux_lui_sr_sl_out : std_logic_vector(data_width - 1 downto 0);
	signal mux_alu_ram_out   : std_logic_vector(data_width - 1 downto 0);
	signal im_extend_sl2     : std_logic_vector(data_width - 1 downto 0);
	signal adder_out         : std_logic_vector(data_width - 1 downto 0);
	signal mux_pc4_imm_out   : std_logic_vector(data_width - 1 downto 0);
	signal mux_jmp_out       : std_logic_vector(data_width - 1 downto 0);
	signal mux_prox_pc_out   : std_logic_vector(data_width - 1 downto 0);
	signal mux_hex_out       : std_logic_vector(data_width - 1 downto 0);
	signal display_hex_0     : std_logic_vector(6 downto 0);
	signal display_hex_1     : std_logic_vector(6 downto 0);
	signal display_hex_2     : std_logic_vector(6 downto 0);
	signal display_hex_3     : std_logic_vector(6 downto 0);
	signal display_hex_4     : std_logic_vector(6 downto 0);
	signal display_hex_5     : std_logic_vector(6 downto 0);
	
	begin		

		gravar:  if simulacao generate
		CLK <= KEY(0);
		RESET <= '0';
		else generate
		EDGE_DETECT_CLK   : work.edgeDetector(bordaSubida)
										port map (clk => CLOCK_50, entrada => (not KEY(0)), saida => CLK);

		EDGE_DETECT_RESET : work.edgeDetector(bordaSubida)
										port map (clk => CLOCK_50, entrada => (NOT FPGA_RESET_N), saida => RESET);
		end generate;

		r31 <= "11111";

		PC            : entity work.registradorGenerico 
							 port map (
									  DIN    => mux_prox_pc_out, 
									  DOUT   => pc_out, 
									  ENABLE => '1', 
									  CLK    => CLK, 
									  RST    => RESET);

		INC_PC4       : entity work.somaConstante 
							 port map (
									  entrada => pc_out, 
									  saida   => pc_out4);

		ROM           : entity work.ROMMIPS 
							 port map (
									  Endereco => pc_out, 
									  Dado     => rom_out);

		CTRL_UNIT     : entity work.controlUnit 
							 port map (
									  funct  => funct, 
									  opcode => opcode, 
									  saida  => control_word);

		MUX_RT_RD     : entity work.muxGenerico4x1 
							 generic map (larguraDados => 5) 
							 port map (
									  entradaA => rt, 
									  entradaB => rd, 
									  entradaC => r31, 
									  entradaD => "00000",
									  seletor_MUX => sel_mux_rt_rd, 
									  output => mux_rt_rd_out);

		REG_BANK      : entity work.bancoReg 
							 port map (
									  clk => CLK, 
									  enderecoA => rs, 
									  enderecoB => rt, 
									  enderecoC => mux_rt_rd_out, 
									  dadoEscritaC => mux_alu_ram_out, 
									  escreveC => enable_reg_wr, 
									  saidaA => rs_data, 
									  saidaB => rt_data);

		EXT_SIGNAL    : entity work.estendeSinalGenerico 
							 port map (
									  ORiANDi          => immediate, 
									  estendeSinal_IN  => sel_ori_andi, 
									  estendeSinal_OUT => im_extend);

		MUX_RT_IMM    : entity work.muxGenerico2x1 
							 port map (
									  entradaA => rt_data, 
									  entradaB => im_extend, 
									  sel => sel_mux_rt_imm, 
									  saida_MUX => mux_rt_imm_out);

		ULAcntrl      : entity work.ULAcntrl 
							 port map (
									  opcode => opcode, 
									  funct => funct, 
									  sel_type_r => sel_type_r, 
									  output => control_word_alu);

		ULA           : entity work.ULA 
							 port map (
									  entradaA => rs_data, 
									  entradaB => mux_rt_imm_out, 
									  operation => control_word_alu, 
									  output => alu_out, 
									  flag_zero => flag_zero);

		MUX_BEQ       : entity work.muxGenerico2x1 
							 port map (
									  entradaA => not(flag_zero), 
									  entradaB => flag_zero, 
									  sel => beq, 
									  saida_MUX => mux_beq_out);

		RAM           : entity work.RAMMIPS 
							 port map (
									  address => alu_out, 
									  data => rt_data, 
									  enable_read => enable_ram_rd, 
									  enable_write => enable_ram_wr, 
									  output => ram_out, 
									  CLK => CLK);

		LUI           : entity work.LUI 
							 port map (
									  entrada => immediate, 
									  saida => lui_out);

		MUX_ALU_MEM   : entity work.muxGenerico4x1 
							 port map (
									  entradaA => alu_out, 
									  entradaB => ram_out, 
									  entradaC => pc_out4, 
									  entradaD => lui_out, 
									  sel => sel_mux_alu_ram, 
									  output => mux_alu_ram_out);

		ADD_PC4_IMM   : entity work.adder port map (A => pc_out4, B => im_extend_sl2, output => adder_out);

		MUX_PC4_IMM   : entity work.muxGenerico2x1 
							 port map (
									  entradaA => pc_out4, 
									  entradaB => adder_out, 
									  sel => (mux_beq_out and (beq or bne)), 
									  output => mux_pc4_imm_out);

		MUX_PC4_JMP   : entity work.muxGenerico2x1 
							 port map (
									  entradaA => mux_pc4_imm_out, 
									  entradaB => (pc_out4(31 downto 28) & jmp_address & "00"), 
									  sel => sel_mux_pc4_jmp, 
									  output => mux_jmp_out);

		MUX_PROX_PC   : entity work.muxGenerico2x1 
							 port map (
									  entradaA => mux_jmp_out, 
									  entradaB => rs_data, 
									  sel => jr, 
									  output => mux_prox_pc_out);

		MUX_HEX       : entity work.muxGenerico2x1 
							 port map (
									  entradaA => pc_out, 
									  entradaB => alu_out, 
									  sel => (SW(1) & SW(0)), 
									  output => mux_hex_out);    

		DEC_HEX0      : entity work.hexTo7seg 
							 port map (
									  dadoHex => mux_hex_out(3  downto  0), 
									  apaga => '0', 
									  negativo => '0', 
									  overFlow => '0', 
									  saida7seg => display_hex_0);

		DEC_HEX1      : entity work.hexTo7seg 
							 port map (
									  dadoHex => mux_hex_out(7  downto  4), 
									  apaga => '0', 
									  negativo => '0', 
									  overFlow => '0', 
									  saida7seg => display_hex_1);

		DEC_HEX2      : entity work.hexTo7seg 
							 port map (
									  dadoHex => mux_hex_out(11 downto  8), 
									  apaga => '0', 
									  negativo => '0', 
									  overFlow => '0', 
									  saida7seg => display_hex_2);

		DEC_HEX3      : entity work.hexTo7seg 
							 port map (
									  dadoHex => mux_hex_out(15 downto 12), 
									  apaga => '0', 
									  negativo => '0', 
									  overFlow => '0', 
									  saida7seg => display_hex_3);

		DEC_HEX4      : entity work.hexTo7seg 
							 port map (
									  dadoHex => mux_hex_out(19 downto 16), 
									  apaga => '0', 
									  negativo => '0', 
									  overFlow => '0', 
									  saida7seg => display_hex_4);

		DEC_HEX5      : entity work.hexTo7seg 
							 port map (
										dadoHex => mux_hex_out(23 downto 20), 
										apaga => '0', 
										negativo => '0', 
										overFlow => '0', 
										saida7seg => display_hex_5);

		HEX0 <= display_hex_0;
		HEX1 <= display_hex_1;
		HEX2 <= display_hex_2;
		HEX3 <= display_hex_3;
		HEX4 <= display_hex_4;
		HEX5 <= display_hex_5;
		
		LEDR(3 downto 0) <= mux_hex_out(27 downto 24);
		LEDR(7 downto 4) <= mux_hex_out(31 downto 28);

end architecture;