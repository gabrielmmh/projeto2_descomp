library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MIPS is
    generic (
        largura_dados : natural := 32;
        largura_endereco : natural := 32;
        simulacao : boolean := FALSE -- para gravar na placa, use FALSE
    );
    port (
        -- Portas de entrada
        CLOCK_50, FPGA_RESET_N : in std_logic;
        KEY : in std_logic_vector(3 downto 0);
        SW : in std_logic_vector(9 downto 0);

        -- Portas de saída
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
    signal pc_out : std_logic_vector(largura_dados - 1 downto 0); -- Saída do PC (Program Counter)
    signal pc_out4 : std_logic_vector(largura_dados - 1 downto 0); -- PC + 4
    signal rom_out : std_logic_vector(largura_dados - 1 downto 0); -- Saída da ROM (instrução)

    -- Sinais do Instruction Decode (ID)
    alias opcode : std_logic_vector(5 downto 0) is rom_out(31 downto 26);
    alias rs : std_logic_vector(4 downto 0) is rom_out(25 downto 21);
    alias rt : std_logic_vector(4 downto 0) is rom_out(20 downto 16);
    alias rd : std_logic_vector(4 downto 0) is rom_out(15 downto 11);
    alias imediato : std_logic_vector(15 downto 0) is rom_out(15 downto 0);
    alias endereco_jmp : std_logic_vector(25 downto 0) is rom_out(25 downto 0);
    alias funct : std_logic_vector(5 downto 0) is rom_out(5 downto 0);
    alias shamt : std_logic_vector(4 downto 0) is rom_out(10 downto 6);

    -- Sinais para controle e execução
    signal r31 : std_logic_vector(4 downto 0); -- Registrador $ra
    signal palavra_controle : std_logic_vector(15 downto 0); -- Sinais de controle
    alias sel_mux_lui_sr_sl : std_logic_vector(1 downto 0) is palavra_controle(15 downto 14);
    alias jr : std_logic is palavra_controle(13);
    alias sel_mux_pc4_jmp : std_logic is palavra_controle(12);
    alias sel_mux_rt_rd : std_logic_vector(1 downto 0) is palavra_controle(11 downto 10);
    alias sel_ori_andi : std_logic is palavra_controle(9);
    alias enable_reg_wr : std_logic is palavra_controle(8);
    alias sel_mux_rt_imm : std_logic is palavra_controle(7);
    alias sel_type_r : std_logic is palavra_controle(6);
    alias sel_mux_ula_ram : std_logic_vector(1 downto 0) is palavra_controle(5 downto 4);
    alias beq : std_logic is palavra_controle(3);
    alias bne : std_logic is palavra_controle(2);
    alias enable_ram_rd : std_logic is palavra_controle(1);
    alias enable_ram_wr : std_logic is palavra_controle(0);

    -- Sinais para o banco de registradores
    signal mux_rt_rd_out : std_logic_vector(4 downto 0);
    signal rs_data : std_logic_vector(largura_dados - 1 downto 0);
    signal rt_data : std_logic_vector(largura_dados - 1 downto 0);

    -- Sinais para a ULA (Unidade Lógica e Aritmética)
    signal im_extend : std_logic_vector(largura_dados - 1 downto 0);
    signal mux_rt_imm_out : std_logic_vector(largura_dados - 1 downto 0);
    signal palavra_controle_ula : std_logic_vector(3 downto 0);
    signal ula_out : std_logic_vector(largura_dados - 1 downto 0);
    signal flag_zero : std_logic;

    -- Sinais para memória
    signal mux_beq_out : std_logic;
    signal ram_out : std_logic_vector(largura_dados - 1 downto 0);
    signal lui_out : std_logic_vector(largura_dados - 1 downto 0);
    signal sr_out : std_logic_vector(largura_dados - 1 downto 0);
    signal sl_out : std_logic_vector(largura_dados - 1 downto 0);
    signal mux_lui_sr_sl_out : std_logic_vector(largura_dados - 1 downto 0);
    signal mux_ula_ram_out : std_logic_vector(largura_dados - 1 downto 0);
    signal im_extend_sl2 : std_logic_vector(largura_dados - 1 downto 0);

    -- Sinais para PC e saltos
    signal adder_out : std_logic_vector(largura_dados - 1 downto 0);
    signal mux_pc4_imm_out : std_logic_vector(largura_dados - 1 downto 0);
    signal mux_jmp_out : std_logic_vector(largura_dados - 1 downto 0);
    signal mux_prox_pc_out : std_logic_vector(largura_dados - 1 downto 0);

    -- Sinais para display
    signal mux_hex_out : std_logic_vector(largura_dados - 1 downto 0);
    signal display_hex_0 : std_logic_vector(6 downto 0);
    signal display_hex_1 : std_logic_vector(6 downto 0);
    signal display_hex_2 : std_logic_vector(6 downto 0);
    signal display_hex_3 : std_logic_vector(6 downto 0);
    signal display_hex_4 : std_logic_vector(6 downto 0);
    signal display_hex_5 : std_logic_vector(6 downto 0);

begin

    -- Configuração de CLK e RESET para simulação
    gravar: if simulacao generate
        CLK <= KEY(0);
        RESET <= '0';
    else generate
        EDGE_DETECT_CLK : work.edgeDetector(bordaSubida)
            port map (clk => CLOCK_50, entrada => (not KEY(0)), saida => CLK);

        EDGE_DETECT_RESET : work.edgeDetector(bordaSubida)
            port map (clk => CLOCK_50, entrada => (NOT FPGA_RESET_N), saida => RESET);
    end generate;

    -- Registrador $ra
    r31 <= "11111";

    -- PC: Registrador para o Program Counter
    PC : entity work.registradorGenerico
        port map (
            DIN => mux_prox_pc_out,
            DOUT => pc_out,
            ENABLE => '1',
            CLK => CLK,
            RST => RESET);

    -- Incrementa PC para próxima instrução
    INC_PC4 : entity work.somaConstante
        port map (
            entrada => pc_out,
            saida => pc_out4);

    -- ROM: Memória de instruções
    ROM : entity work.ROMMIPS
        port map (
            Endereco => pc_out,
            Dado => rom_out);

    -- Unidade de Controle: Gera sinais de controle
    UNIDADE_CTRL : entity work.Control
        port map (
            funct => funct,
            opcode => opcode,
            saida => palavra_controle);

    -- MUX para selecionar registrador de destino
    MUX_RT_RD : entity work.muxGenerico4x1
        generic map (larguraDados => 5)
        port map (
            entradaA_MUX => rt,
            entradaB_MUX => rd,
            entradaC_MUX => r31,
            entradaD_MUX => "00000",
            seletor_MUX => sel_mux_rt_rd,
            saida_MUX => mux_rt_rd_out);

    -- Banco de Registradores
    BANCO_REG : entity work.bancoReg
        port map (
            clk => CLK,
            enderecoA => rs,
            enderecoB => rt,
            enderecoC => mux_rt_rd_out,
            dadoEscritaC => mux_ula_ram_out,
            escreveC => enable_reg_wr,
            saidaA => rs_data,
            saidaB => rt_data);

    -- Extensão de sinal para imediatos
    EXT_SIGNAL : entity work.estendeSinalGenerico
        port map (
            ORiANDi => imediato,
            estendeSinal_IN => sel_ori_andi,
            estendeSinal_OUT => im_extend);

    -- MUX para selecionar entre registrador e imediato
    MUX_RT_IMM : entity work.muxGenerico2x1
        port map (
            entradaA_MUX => rt_data,
            entradaB_MUX => im_extend,
            seletor_MUX => sel_mux_rt_imm,
            saida_MUX => mux_rt_imm_out);

    -- Unidade de Controle da ULA
    ULAcntrl : entity work.ULAcntrl
        port map (
            opcode => opcode,
            funct => funct,
            tipoR => sel_type_r,
            saida => palavra_controle_ula);

    -- ULA: Unidade Lógica e Aritmética
    ULA : entity work.ULA
        port map (
            entradaA => rs_data,
            entradaB => mux_rt_imm_out,
            ULACtrl => palavra_controle_ula,
            saida => ula_out,
            flagZero => flag_zero);

    -- MUX para instruções de desvio condicional (BEQ/BNE)
    MUX_BEQ : entity work.muxGenerico2x1
        port map (
            entradaA_MUX => not(flag_zero),
            entradaB_MUX => flag_zero,
            seletor_MUX => beq,
            saida_MUX => mux_beq_out);

    -- RAM: Memória de dados
    RAM : entity work.RAMMIPS
        port map (
            Endereco => ula_out,
            Dado_in => rt_data,
            re => enable_ram_rd,
            we => enable_ram_wr,
            Dado_out => ram_out,
            clk => CLK);

    -- Instrução LUI
    LUI : entity work.LUI
        port map (
            entrada => imediato,
            saida => lui_out);

    -- MUX para selecionar entre ULA e memória
    MUX_ALU_MEM : entity work.muxGenerico4x1
        port map (
            entradaA_MUX => ula_out,
            entradaB_MUX => ram_out,
            entradaC_MUX => pc_out4,
            entradaD_MUX => lui_out,
            seletor_MUX => sel_mux_ula_ram,
            saida_MUX => mux_ula_ram_out);

    -- Somador para calcular endereços de desvio
    adder_out <= std_logic_vector(unsigned(pc_out4) + unsigned(im_extend_sl2));

    -- MUX para selecionar entre PC+4 e endereço de desvio
    MUX_PC4_IMM : entity work.muxGenerico2x1
        port map (
            entradaA_MUX => pc_out4,
            entradaB_MUX => adder_out,
            seletor_MUX => (mux_beq_out and (beq or bne)),
            saida_MUX => mux_pc4_imm_out);

    -- MUX para selecionar entre PC+4/IMM e endereço de salto
    MUX_PC4_JMP : entity work.muxGenerico2x1
        port map (
            entradaA_MUX => mux_pc4_imm_out,
            entradaB_MUX => (pc_out4(31 downto 28) & endereco_jmp & "00"),
            seletor_MUX => sel_mux_pc4_jmp,
            saida_MUX => mux_jmp_out);

    -- MUX para selecionar entre endereço de salto e registrador
    MUX_PROX_PC : entity work.muxGenerico2x1
        port map (
            entradaA_MUX => mux_jmp_out,
            entradaB_MUX => rs_data,
            seletor_MUX => jr,
            saida_MUX => mux_prox_pc_out);

    -- MUX para selecionar entre PC e ULA para display
    MUX_HEX : entity work.muxGenerico2x1
        port map (
            entradaA_MUX => pc_out,
            entradaB_MUX => ula_out,
            seletor_MUX => (SW(1) & SW(0)),
            saida_MUX => mux_hex_out);

    -- Decodificadores para displays de 7 segmentos
    DEC_HEX0 : entity work.hexTo7seg
        port map (
            dadoHex => mux_hex_out(3 downto 0),
            apaga => '0',
            negativo => '0',
            overFlow => '0',
            saida7seg => display_hex_0);

    DEC_HEX1 : entity work.hexTo7seg
        port map (
            dadoHex => mux_hex_out(7 downto 4),
            apaga => '0',
            negativo => '0',
            overFlow => '0',
            saida7seg => display_hex_1);

    DEC_HEX2 : entity work.hexTo7seg
        port map (
            dadoHex => mux_hex_out(11 downto 8),
            apaga => '0',
            negativo => '0',
            overFlow => '0',
            saida7seg => display_hex_2);

    DEC_HEX3 : entity work.hexTo7seg
        port map (
            dadoHex => mux_hex_out(15 downto 12),
            apaga => '0',
            negativo => '0',
            overFlow => '0',
            saida7seg => display_hex_3);

    DEC_HEX4 : entity work.hexTo7seg
        port map (
            dadoHex => mux_hex_out(19 downto 16),
            apaga => '0',
            negativo => '0',
            overFlow => '0',
            saida7seg => display_hex_4);

    DEC_HEX5 : entity work.hexTo7seg
        port map (
            dadoHex => mux_hex_out(23 downto 20),
            apaga => '0',
            negativo => '0',
            overFlow => '0',
            saida7seg => display_hex_5);

    -- Atribuição dos displays HEX
    HEX0 <= display_hex_0;
    HEX1 <= display_hex_1;
    HEX2 <= display_hex_2;
    HEX3 <= display_hex_3;
    HEX4 <= display_hex_4;
    HEX5 <= display_hex_5;

    -- Atribuição dos LEDs
    LEDR(3 downto 0) <= mux_hex_out(27 downto 24);
    LEDR(7 downto 4) <= mux_hex_out(31 downto 28);

end architecture;