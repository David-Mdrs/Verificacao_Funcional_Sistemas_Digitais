// ALUNOS: David Medeiros e João Gabriel Tavares

`timescale 1ns/1ps

module tb;

  	// Definição dos tempos
    localparam int DEBOUNCE       		= 50;
    localparam int REPETIR_01 			= 2000;
    localparam int REPETIR_02   		= 1000;
  	localparam int ACIONAMENTO_MAXIMO 	= 120;

  	// Declarando variáveis do design
    logic clk;
    logic rst;
    logic enable;

    logic [3:0] col_matriz;
    logic [3:0] lin_matriz;

    senhaPac_t digitos_value;
    logic digitos_valid;

  	// Inicializando clock
    always #1 clk = ~clk;

  	// Instância do DUT
    decodificador_de_teclado dut (
      	.clk           (clk),
        .rst           (rst),
        .enable        (enable),
        .col_matriz    (col_matriz),
      	.lin_matriz    (lin_matriz),
        .digitos_value (digitos_value),
        .digitos_valid (digitos_valid)
    );

  	// ============================ COVERGROUPS ============================

    covergroup c_linhas @(posedge clk);
        coverpoint lin_matriz {
            bins linha_0 = {4'b1110};
            bins linha_1 = {4'b0111};
            bins linha_2 = {4'b1011};
            bins linha_3 = {4'b1101};
        }
    endgroup

  	logic [3:0] barramento0_obs;
    real cobertura_saida;

    covergroup c_saida;
        coverpoint barramento0_obs {
            bins tecla_0 = {4'h0};
            bins tecla_1 = {4'h1};
            bins tecla_2 = {4'h2};
            bins tecla_3 = {4'h3};
            bins tecla_4 = {4'h4};
            bins tecla_5 = {4'h5};
            bins tecla_6 = {4'h6};
            bins tecla_7 = {4'h7};
            bins tecla_8 = {4'h8};
            bins tecla_9 = {4'h9};
        }
    endgroup

    c_linhas  cov_linhas;
    c_saida   cov_saida;

	// ========================== MAPEAMENTO DAS TECLAS ==========================

    logic [3:0] KEY_LIN [12];
    logic [3:0] KEY_COL [12];

  	initial begin
		KEY_LIN[0]  = 4'b1110; KEY_COL[0]  = 4'b1011;
		KEY_LIN[1]  = 4'b0111; KEY_COL[1]  = 4'b0111;
		KEY_LIN[2]  = 4'b0111; KEY_COL[2]  = 4'b1011;
		KEY_LIN[3]  = 4'b0111; KEY_COL[3]  = 4'b1101;
		KEY_LIN[4]  = 4'b1011; KEY_COL[4]  = 4'b0111;
		KEY_LIN[5]  = 4'b1011; KEY_COL[5]  = 4'b1011;
		KEY_LIN[6]  = 4'b1011; KEY_COL[6]  = 4'b1101;
		KEY_LIN[7]  = 4'b1101; KEY_COL[7]  = 4'b0111;
		KEY_LIN[8]  = 4'b1101; KEY_COL[8]  = 4'b1011;
		KEY_LIN[9]  = 4'b1101; KEY_COL[9]  = 4'b1101;
  		KEY_LIN[10] = 4'b1110; KEY_COL[10] = 4'b1101; // Tecla (#)
  		KEY_LIN[11] = 4'b1110; KEY_COL[11] = 4'b0111; // Tecla (*)
    end

	// =========================== CONTROLE DO TECLADO ===========================

    logic key_pressed;
    logic [3:0] active_lin;
    logic [3:0] active_col;

    always_comb begin
        if(key_pressed && lin_matriz == active_lin)
            col_matriz = active_col;
        else
            col_matriz = 4'b1111;
    end

  	// ============================ TASKS AUXILIARES ============================

    task automatic inicializar_tb();
        begin
            clk          = 0;
            rst          = 0;
            enable       = 1;
            key_pressed  = 0;
            active_lin   = 4'b1111;
            active_col   = 4'b1111;
        end
    endtask

    task automatic inicializar_coberturas();
        begin
            cov_linhas = new();
            cov_saida  = new();
        end
    endtask

    task automatic resetar();
        begin
          	$display("\n====================== RESET =======================\n");
            rst = 1;
            key_pressed = 0;
            repeat(10) @(posedge clk);
            rst = 0;
            repeat(10) @(posedge clk);
        end
    endtask

    task automatic acionar_tecla(input logic [3:0] tecla);
        begin
            active_lin  = KEY_LIN[tecla];
            active_col  = KEY_COL[tecla];
            key_pressed = 1;
        end
    endtask

    task automatic soltar_tecla();
        begin
            key_pressed = 0;
            active_lin  = 4'b1111;
            active_col  = 4'b1111;
        end
    endtask

  	task automatic pressionar_tecla(input logic [3:0] tecla, input int ciclos);
        begin
            acionar_tecla(tecla);
            repeat(ciclos) @(posedge clk);
            soltar_tecla();
            repeat(10) @(posedge clk);
        end
    endtask

    function automatic string hex_maiusculo(logic [3:0] v);
        case(v)
            4'h0: return "0";  4'h1: return "1";  4'h2: return "2";  4'h3: return "3";
            4'h4: return "4";  4'h5: return "5";  4'h6: return "6";  4'h7: return "7";
            4'h8: return "8";  4'h9: return "9";  4'hA: return "A";  4'hB: return "B";
            4'hC: return "C";  4'hD: return "D";  4'hE: return "E";  4'hF: return "F";
            default: return "?";
        endcase
    endfunction

    task automatic exibir_barramento();
        begin
            $write("Barramento: [ ");
            for(int i = 19; i >= 0; i--)
                $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");
        end
    endtask

    // ========================== GERADOR RANDÔMICO ==========================

    int tecla_aleatoria;
    int quantidade_testes;
    bit fim_teste;
    bit monitor_pronto;

  	// GERADOR RELEASE 01
    task automatic gerador_release_01();
        begin
            while(!fim_teste) begin
                tecla_aleatoria = $urandom_range(0, 9);
                pressionar_tecla(tecla_aleatoria[3:0], DEBOUNCE + 20);
                repeat($urandom_range(10, 100)) @(posedge clk);
            end
        end
    endtask

  	// GERADOR RELEASE 02
    task automatic gerador_release_02();
        begin
            for(int j = 0; j < 2; j++) begin
                for(int i = 0; i <= 9; i++) begin
                    pressionar_tecla(i[3:0], DEBOUNCE + 20);
                end
            end

            while(!fim_teste) begin
                tecla_aleatoria = $urandom_range(0, 9);
                pressionar_tecla(tecla_aleatoria[3:0], DEBOUNCE + 20);
                repeat($urandom_range(10, 100)) @(posedge clk);
            end
        end
  	endtask

  	// GERADOR RELEASE 03
  	task automatic gerador_release_03();
        begin
            repeat(50) begin
                tecla_aleatoria = $urandom_range(0, 9);
                active_lin = KEY_LIN[tecla_aleatoria[3:0]];
                active_col = KEY_COL[tecla_aleatoria[3:0]];

                repeat(100) begin
                    key_pressed = $urandom_range(0, 1);
                    @(posedge clk);
                end

                key_pressed = 1;
                repeat(DEBOUNCE + 100) @(posedge clk);

                key_pressed = 0;
                soltar_tecla();

                repeat($urandom_range(10, 100)) @(posedge clk);
            end
        end
    endtask

  	// GERADOR RELEASE 04
    logic [3:0] r04_tecla_alvo;
    int         r04_falhas;

    task automatic gerador_release_04();
        begin
            r04_tecla_alvo = $urandom_range(0, 9);

            $display("--------------------------------------------------------");
            $display("RELEASE 04 - Iniciando teste de repeticao automatica");
            $display("Tecla sorteada    : 0x%s (%0d)", hex_maiusculo(r04_tecla_alvo), r04_tecla_alvo);
            $display("Linha varrida     : 0b%04b | Coluna: 0b%04b",
                     KEY_LIN[r04_tecla_alvo], KEY_COL[r04_tecla_alvo]);
            $display("--------------------------------------------------------");

            acionar_tecla(r04_tecla_alvo);
            repeat(DEBOUNCE + REPETIR_01 + (REPETIR_02 * 2) + 200) @(posedge clk);
            soltar_tecla();
            repeat(REPETIR_02 + 200) @(posedge clk);
            fim_teste = 1;
        end
    endtask

    // GERADOR RELEASE 05
    localparam int QTD_MAX_DIGITOS = 20;
    logic [3:0] sequencia_release_05 [QTD_MAX_DIGITOS];
    int qtd_digitos_release_05;

    task automatic gerador_release_05();
        begin
            qtd_digitos_release_05 = $urandom_range(1, QTD_MAX_DIGITOS);

            for (int i = 0; i < qtd_digitos_release_05; i++) begin
                sequencia_release_05[i] = $urandom_range(0, 9);
            end

            for (int i = 0; i < qtd_digitos_release_05; i++) begin
                pressionar_tecla(sequencia_release_05[i], DEBOUNCE + 50);
            end

            $display("Pressionando tecla * para confirmar");
            pressionar_tecla(4'd11, DEBOUNCE + 50);

            wait(fim_teste);
        end
    endtask
  

    // GERADOR RELEASE 08
    localparam int QTD_TESTES_RELEASE_08 = 10;

    task automatic gerador_release_08();
        begin
            // Garante estado limpo antes do teste
            soltar_tecla();
            repeat(20) @(posedge clk);

            // Preenche o barramento com dígitos conhecidos
            for(int i = 0; i <= 9; i++) begin
                pressionar_tecla(i, DEBOUNCE + 20);
            end

            repeat(10) @(posedge clk);

            // Pressiona a tecla #
            acionar_tecla(4'd10);

            // Mantém pressionado tempo suficiente para o DUT gerar o pulso
            repeat(DEBOUNCE + 20) @(posedge clk);

            // Solta a tecla
            soltar_tecla();
        end
  	endtask
  
    // GERADOR RELEASE 09
    int quantidade_testes_release_09;
    int qtd_rodadas_release_09;
    int qtd_digitos_release_09;
    logic [3:0] sequencia_release_09 [20];

    task automatic gerador_release_09();
        begin
            // Garante estado limpo antes do teste
            soltar_tecla();
            repeat(20) @(posedge clk);

            // Gera uma sequência parcial maior
            qtd_digitos_release_09 = $urandom_range(10, 18);

            for(int i = 0; i < qtd_digitos_release_09; i++) begin
                sequencia_release_09[i] = $urandom_range(0, 9);
            end

            // Digita a sequência parcial
            for(int i = 0; i < qtd_digitos_release_09; i++) begin
                pressionar_tecla(sequencia_release_09[i], DEBOUNCE + 20);
            end

            // Tempo suficiente para os 5 segundos
            repeat(5100) @(posedge clk);

            wait(fim_teste);
        end
    endtask

    //  GERADOR RELEASE 10 
    int quantidade_testes_release_10;
    int qtd_rodadas_release_10;
    int qtd_digitos_pre_release_10;
    int qtd_digitos_disable_release_10;
    int qtd_digitos_post_release_10;

    logic [3:0] sequencia_pre_release_10     [20];
    logic [3:0] sequencia_disable_release_10 [20];
    logic [3:0] sequencia_post_release_10    [20];

    bit r10_fase1_concluida;
    bit r10_fase3_concluida;
  
    task automatic gerador_release_10();
        begin
            soltar_tecla();
            enable = 1;
            repeat(20) @(posedge clk);

            // Garante barramento bem preenchido antes do disable
            qtd_digitos_pre_release_10      = $urandom_range(14, 19);
            qtd_digitos_disable_release_10  = $urandom_range(4,  8);
            qtd_digitos_post_release_10     = $urandom_range(14, 19);

            for(int i = 0; i < qtd_digitos_pre_release_10; i++)
                sequencia_pre_release_10[i] = $urandom_range(0, 9);

            for(int i = 0; i < qtd_digitos_disable_release_10; i++)
                sequencia_disable_release_10[i] = $urandom_range(0, 9);

            for(int i = 0; i < qtd_digitos_post_release_10; i++)
                sequencia_post_release_10[i] = $urandom_range(0, 9);

            $display("------------------ RELEASE 10 --------------------------");	

            $display("Sequencia antes de desabilitar o enable com %0d digito(s):", qtd_digitos_pre_release_10);
            $write("[ ");
            for(int i = 19; i >= 0; i--) begin
                if(i < qtd_digitos_pre_release_10)
                    $write("%s ", hex_maiusculo(sequencia_pre_release_10[i]));
                else
                    $write("F ");
            end
          $write("]\n\n");

            for(int i = 0; i < qtd_digitos_pre_release_10; i++)
                pressionar_tecla(sequencia_pre_release_10[i], DEBOUNCE + 20);

            // Avisa monitor que a fase 1 terminou
            r10_fase1_concluida = 1;
            repeat(5) @(posedge clk);

            $display("DESABILITANDO enable = 0");
            enable = 0;
            repeat(10) @(posedge clk);

            $display("Sequencia durante o disable (%0d digitos):", qtd_digitos_disable_release_10);
            for(int i = 0; i < qtd_digitos_disable_release_10; i++)
                $write("%0X ", sequencia_disable_release_10[i]);
            $write("\n");

            for(int i = 0; i < qtd_digitos_disable_release_10; i++)
                pressionar_tecla(sequencia_disable_release_10[i], DEBOUNCE + 20);

            $display(">>> REABILITANDO enable = 1");
            enable = 1;
            repeat(20) @(posedge clk);

            $display("Sequencia apos reabilitar (%0d digitos):", qtd_digitos_post_release_10);
            for(int i = 0; i < qtd_digitos_post_release_10; i++)
                $write("%0X ", sequencia_post_release_10[i]);
            $write("\n");

            for(int i = 0; i < qtd_digitos_post_release_10; i++)
                pressionar_tecla(sequencia_post_release_10[i], DEBOUNCE + 20);

            // Avisa monitor que a fase 3 terminou
            r10_fase3_concluida = 1;
            repeat(40) @(posedge clk);
        end
    endtask
  
	// ======================= MONITORAMENTO =======================

  	// MONITORAMENTO RELEASE 01
    task automatic monitor_release_01();
        logic [3:0] tecla_esperada;
        logic [3:0] tecla_lida;
        begin
            repeat(30) @(posedge clk);
            monitor_pronto = 1;

            while(!fim_teste) begin
                @(posedge key_pressed);
                tecla_esperada = tecla_aleatoria[3:0];
                repeat(DEBOUNCE + 30) @(posedge clk);
                tecla_lida = digitos_value.digits[0];

                barramento0_obs = tecla_lida;
                cov_saida.sample();
				cobertura_saida = cov_saida.get_coverage();

                $display("------------------ RELEASE 01 --------------------------");
                $display("Teste #%0d", quantidade_testes);
              	$display("Tecla esperada : 0x%s", hex_maiusculo(tecla_esperada));
              	$display("Tecla lida    : 0x%s", hex_maiusculo(tecla_lida));
                $display("Cobertura atual   : %0.2f%%", cov_saida.get_coverage());
                exibir_barramento();
              	quantidade_testes++;

                if(tecla_lida === tecla_esperada)
                    $display("RESULTADO: PASSOU");
                else begin
                    $display("RESULTADO: FALHOU");
                  	$fatal();
                end
                $display("--------------------------------------------------------\n");

                if(cobertura_saida >= 100.0)
                    fim_teste = 1;
            end
        end
    endtask

  	// MONITORAMENTO RELEASE 02
    task automatic monitor_release_02();
        begin
            senhaPac_t barramento_esperado;
            senhaPac_t barramento_lido;
            logic [3:0] nova_tecla;
            bit iniciado = 0;

            repeat(30) @(posedge clk);

            for(int i = 0; i < 20; i++)
                barramento_esperado.digits[i] = 4'hF;

            while(!fim_teste) begin
                @(posedge key_pressed);

                nova_tecla = 4'hF;
                for(int k = 0; k < 12; k++) begin
                    if(KEY_LIN[k] === active_lin && KEY_COL[k] === active_col) begin
                        nova_tecla = k[3:0];
                        break;
                    end
                end

                repeat(DEBOUNCE + 15) @(posedge clk);
                barramento_lido = digitos_value;

                barramento0_obs = nova_tecla;
                cov_saida.sample();
                cobertura_saida = cov_saida.get_coverage();

                if(!iniciado) begin
                    barramento_esperado = barramento_lido;
                    iniciado = 1;
                end else begin
                    for(int k = 19; k > 0; k--)
                        barramento_esperado.digits[k] = barramento_esperado.digits[k-1];
                    barramento_esperado.digits[0] = nova_tecla;
                end

                $display("------------------ RELEASE 02 --------------------------");
                $write("Barramento: [ ");
                for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
                $write("]\n");
                exibir_barramento();
                $display("Tecla detectada: %s", hex_maiusculo(nova_tecla));

                for(int i = 0; i < 20; i++) begin
                    if(barramento_lido.digits[i] !== barramento_esperado.digits[i]) begin
                      	$display("STATUS: ERRO DE SHIFT");
                        $fatal();
                    end
                end

                $display("STATUS: OK | Barramento atualizado corretamente.");
                $display("--------------------------------------------------------\n");

                @(negedge key_pressed);
              	quantidade_testes++;
              	if(quantidade_testes >= 50)
                    fim_teste = 1;
            end
        end
    endtask

  	// MONITORAMENTO RELEASE 03
    task automatic monitor_release_03();
        logic [3:0] tecla_esperada;
        logic [3:0] tecla_lida;
        bit tecla_estavel;
        begin
            quantidade_testes = 0;
            repeat(30) @(posedge clk);

            while (quantidade_testes < 50) begin
                @(posedge key_pressed);

                tecla_estavel = 1;
                repeat(DEBOUNCE + 10) begin
                    @(posedge clk);
                    if (!key_pressed) begin
                        tecla_estavel = 0;
                        break;
                    end
                end

                if (!tecla_estavel) continue;

                tecla_esperada = tecla_aleatoria[3:0];
                repeat(5) @(posedge clk);
                tecla_lida = digitos_value.digits[0];

                $display("------------------ RELEASE 03 --------------------------");
                $display("Teste #%0d", quantidade_testes + 1);
                $display("Tecla esperada : 0x%s", hex_maiusculo(tecla_esperada));
                $display("Tecla lida     : 0x%s", hex_maiusculo(tecla_lida));

                if (tecla_lida === tecla_esperada)
                    $display("RESULTADO: PASSOU");
                else begin
                    $display("RESULTADO: FALHOU");
                    $fatal();
                end
                $display("--------------------------------------------------------\n");

                quantidade_testes++;
                wait (!key_pressed);
            end
        end
    endtask

    // MONITORAMENTO RELEASE 04
    task automatic monitor_release_04();
        logic [3:0] tecla_esperada;
        logic [3:0] barramento_copia [20];
        int         falhas_locais;
        begin
            repeat(30) @(posedge clk);
            monitor_pronto = 1;
            @(posedge key_pressed);
            falhas_locais = 0;

            repeat(DEBOUNCE + 20) @(posedge clk);
            tecla_esperada = r04_tecla_alvo;

            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste A: 1a insercao normal (apos %0d ciclos de debounce)", DEBOUNCE);
            $display("Saida esperada    - digits[0]: 0x%s", hex_maiusculo(tecla_esperada));
            $display("Saida recebida    - digits[0]: 0x%s", hex_maiusculo(digitos_value.digits[0]));
            exibir_barramento();
            if(digitos_value.digits[0] === tecla_esperada) $display("RESULTADO: PASSOU");
            else begin $display("RESULTADO: FALHOU"); falhas_locais++; end
            $display("--------------------------------------------------------\n");

            repeat(REPETIR_01) @(posedge clk);
            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste B: 1a repeticao automatica apos %0d ciclos (2 s)", REPETIR_01);
            $display("Saida esperada    - digits[0]: 0x%s | digits[1]: 0x%s", hex_maiusculo(tecla_esperada), hex_maiusculo(tecla_esperada));
            $display("Saida recebida    - digits[0]: 0x%s | digits[1]: 0x%s",
                     hex_maiusculo(digitos_value.digits[0]), hex_maiusculo(digitos_value.digits[1]));
            exibir_barramento();
            if(digitos_value.digits[1] === tecla_esperada && digitos_value.digits[0] === tecla_esperada)
                $display("RESULTADO: PASSOU");
            else begin
                $display("RESULTADO: FALHOU — 1a repeticao nao ocorreu apos 2 s");
                $display("          (Verifique se o DUT implementa auto-repeat no estado HOLD)");
                falhas_locais++;
            end
            $display("--------------------------------------------------------\n");

            repeat(REPETIR_02) @(posedge clk);
            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste C: 2a repeticao automatica apos %0d ciclos (1 s)", REPETIR_02);
            $display("Saida esperada    - digits[2]: 0x%s", hex_maiusculo(tecla_esperada));
            $display("Saida recebida    - digits[2]: 0x%s", hex_maiusculo(digitos_value.digits[2]));
            exibir_barramento();
            if(digitos_value.digits[2] === tecla_esperada) $display("RESULTADO: PASSOU");
            else begin $display("RESULTADO: FALHOU — 2a repeticao nao ocorreu"); falhas_locais++; end
            $display("--------------------------------------------------------\n");

            repeat(REPETIR_02) @(posedge clk);
            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste D: 3a repeticao automatica apos mais %0d ciclos (1 s)", REPETIR_02);
            $display("Saida esperada    - digits[3]: 0x%s", hex_maiusculo(tecla_esperada));
            $display("Saida recebida    - digits[3]: 0x%s", hex_maiusculo(digitos_value.digits[3]));
            exibir_barramento();
            if(digitos_value.digits[3] === tecla_esperada) $display("RESULTADO: PASSOU");
            else begin $display("RESULTADO: FALHOU — 3a repeticao nao ocorreu"); falhas_locais++; end
            $display("--------------------------------------------------------\n");

            @(negedge key_pressed);
            repeat(10) @(posedge clk);
            for(int i = 0; i < 20; i++) barramento_copia[i] = digitos_value.digits[i];

            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste E: Barramento deve congelar apos soltar a tecla");
            $display("Aguardando %0d ciclos sem nova pressao...", REPETIR_02 + 100);
            exibir_barramento();
            repeat(REPETIR_02 + 100) @(posedge clk);

            begin
                int mudancas = 0;
                for(int i = 0; i < 20; i++)
                    if(digitos_value.digits[i] !== barramento_copia[i]) mudancas++;
                $display("Posicoes alteradas: %0d (esperado: 0)", mudancas);
                if(mudancas == 0) $display("RESULTADO: PASSOU — Barramento estavel apos soltar a tecla");
                else begin $display("RESULTADO: FALHOU — Barramento alterado apos soltar a tecla"); falhas_locais++; end
            end
            $display("--------------------------------------------------------\n");

            r04_falhas = falhas_locais;
            quantidade_testes++;
        end
    endtask

  	// MONITORAMENTO RELEASE 05
  	task automatic monitor_release_05();
        bit valid_encontrado;
        int ciclos;
        begin
            repeat(30) @(posedge clk);
            monitor_pronto = 1;

            while(!fim_teste) begin
                $display("------------------ RELEASE 05 --------------------------");
                $display("Teste #%0d", quantidade_testes + 1);

                wait(key_pressed && active_lin == KEY_LIN[11] && active_col == KEY_COL[11]);

                valid_encontrado = 0;
                for(ciclos = 0; ciclos < ACIONAMENTO_MAXIMO; ciclos++) begin
                    @(posedge clk);
                    if(digitos_valid) begin
                        valid_encontrado = 1;
                        break;
                    end
                end

                if(!valid_encontrado) begin
                    $display("RESULTADO: FALHOU");
                    $display("digitos_valid nao ativou");
                    $fatal();
                end

                for(int i = 0; i < qtd_digitos_release_05; i++) begin
                    if(digitos_value.digits[i] !== sequencia_release_05[qtd_digitos_release_05 - 1 - i]) begin
                        $display("RESULTADO: FALHOU");
                        $display("Posicao %0d", i);
                        $display("Esperado : %0d", sequencia_release_05[qtd_digitos_release_05 - 1 - i]);
                        $display("Recebido : %0d", digitos_value.digits[i]);
                        exibir_barramento();
                        $fatal();
                    end
                end

                $display("RESULTADO: PASSOU");
                exibir_barramento();
                $display("--------------------------------------------------------\n");

                quantidade_testes++;
                fim_teste = 1;
            end
        end
	endtask


    // MONITORAMENTO RELEASE 08
    task automatic monitor_release_08();
        senhaPac_t barramento_antes;
        senhaPac_t barramento_no_valid;
        senhaPac_t barramento_depois;
        bit barramento_b_correto;
        bit barramento_f_correto;
        bit valid_encontrado;
        int ciclos;

        begin
            repeat(30) @(posedge clk);

            monitor_pronto = 1;
            valid_encontrado = 0;

            // Espera a tecla # ser acionada
            wait(
                key_pressed &&
                active_lin == KEY_LIN[10] &&
                active_col == KEY_COL[10]
            );

            // Varre até encontrar o ciclo exato em que digitos_valid sobe
            for(ciclos = 0; ciclos < ACIONAMENTO_MAXIMO; ciclos++) begin
                @(posedge clk);

                // Guarda continuamente o último barramento antes do pulso
                if(!digitos_valid)
                    barramento_antes = digitos_value;

                // Ciclo exato do valid
                if(digitos_valid) begin
                    valid_encontrado   = 1;
                    barramento_no_valid = digitos_value;

                    $display("------------------ RELEASE 08 --------------------------");

                  $write("Barramento antes do pulso:    [ ");
                    for(int i = 19; i >= 0; i--)
                        $write("%0X ", barramento_antes.digits[i]);
                    $write("]\n\n");

                    $write("Barramento no ciclo do valid: [ ");
                    for(int i = 19; i >= 0; i--)
                        $write("%0X ", barramento_no_valid.digits[i]);
                    $write("]\n");

                    // Verifica se o barramento ficou completamente em B
                    barramento_b_correto = 1;
                    for(int i = 0; i < 20; i++) begin
                        if(barramento_no_valid.digits[i] !== 4'hB) begin
                            barramento_b_correto = 0;
                            break;
                        end
                    end

                    if(barramento_b_correto) begin
                        $display("STATUS: OK | Barramento preenchido com B corretamente.\n");
                    end
                    else begin
                        $display("STATUS: FALHOU | Barramento nao foi preenchido totalmente com B.\n");
                        exibir_barramento();
                        $fatal();
                    end

                    // No ciclo seguinte, valid deve cair
                    @(posedge clk);

                    // Captura o barramento após o pulso
                    barramento_depois = digitos_value;

                  $write("Barramento apos o pulso:      [ ");
                    for(int i = 19; i >= 0; i--)
                        $write("%0X ", barramento_depois.digits[i]);
                    $write("]\n");

                    // Verifica retorno automático para F
                    barramento_f_correto = 1;
                    for(int i = 0; i < 20; i++) begin
                        if(barramento_depois.digits[i] !== 4'hF) begin
                            barramento_f_correto = 0;
                            break;
                        end
                    end

                    if(barramento_f_correto) begin
                        $display("STATUS: OK | Barramento retornou automaticamente para F.");
                    end
                    else begin
                        $display("STATUS: FALHOU | Barramento nao retornou automaticamente para F.");
                        exibir_barramento();
                        $fatal();
                    end

                    $display("--------------------------------------------------------\n");

                    quantidade_testes++;
                    fim_teste = 1;
                    break;
                end
            end

            if(!valid_encontrado) begin
                $display("RESULTADO: FALHOU");
                $display("digitos_valid nao foi acionado dentro do limite esperado");
                $fatal();
            end
        end
  	endtask
  
    // MONITORAMENTO RELEASE 09
    task automatic monitor_release_09();
        senhaPac_t barramento_antes;
        senhaPac_t barramento_no_timeout;
        senhaPac_t barramento_depois;

        bit barramento_e_correto;
        bit barramento_f_correto;
        bit timeout_encontrado;

        begin
            repeat(30) @(posedge clk);

            monitor_pronto = 1;
            timeout_encontrado = 0;

            while(!fim_teste) begin
                @(posedge clk);

                if(!digitos_valid)
                    barramento_antes = digitos_value;

                if(digitos_valid) begin
                    timeout_encontrado   = 1;
                    barramento_no_timeout = digitos_value;

                    $display("------------------ RELEASE 09 --------------------------");

                    $write("Barramento antes do timeout:    [ ");
                    for(int i = 19; i >= 0; i--)
                        $write("%0X ", barramento_antes.digits[i]);
                    $write("]\n");

                    $write("Barramento no ciclo do timeout: [ ");
                    for(int i = 19; i >= 0; i--)
                        $write("%0X ", barramento_no_timeout.digits[i]);
                    $write("]\n");

                    barramento_e_correto = 1;
                    for(int i = 0; i < 20; i++) begin
                        if(barramento_no_timeout.digits[i] !== 4'hE) begin
                            barramento_e_correto = 0;
                            break;
                        end
                    end

                    if(barramento_e_correto) begin
                        $display("STATUS: OK | Barramento preenchido com E corretamente.\n");
                    end
                    else begin
                        $display("STATUS: FALHOU | Barramento nao foi preenchido totalmente com E.\n");
                        exibir_barramento();
                        $fatal();
                    end

                    @(posedge clk);

                    if(digitos_valid) begin
                        $display("STATUS: FALHOU");
                        $display("digitos_valid permaneceu alto por mais de 1 ciclo");
                        $fatal();
                    end

                    barramento_depois = digitos_value;

                    $write("Barramento apos o pulso: [ ");
                    for(int i = 19; i >= 0; i--)
                        $write("%0X ", barramento_depois.digits[i]);
                    $write("]\n");

                    barramento_f_correto = 1;
                    for(int i = 0; i < 20; i++) begin
                        if(barramento_depois.digits[i] !== 4'hF) begin
                            barramento_f_correto = 0;
                            break;
                        end
                    end

                    if(barramento_f_correto) begin
                        $display("STATUS: OK | Barramento retornou para F.");
                    end
                    else begin
                        $display("STATUS: FALHOU | Barramento nao retornou para F.");
                        exibir_barramento();
                        $fatal();
                    end

                    $display("--------------------------------------------------------\n");

                    quantidade_testes_release_09++;
                    fim_teste = 1;
                    return;
                end
            end

            if(!timeout_encontrado) begin
                $display("RESULTADO: FALHOU");
                $display("digitos_valid nao foi acionado dentro do tempo esperado");
                $fatal();
            end
        end
    endtask
  
  
    //  MONITORAMENTO RELEASE 10

    task automatic monitor_release_10();
        senhaPac_t barramento_esperado;
        senhaPac_t barramento_lido;
        senhaPac_t barramento_congelado;

        bit barramento_ok;

        begin
            repeat(30) @(posedge clk);
            monitor_pronto = 1;

            for(int i = 0; i < 20; i++)
                barramento_esperado.digits[i] = 4'hF;

            // FASE A: OPERAÇÃO NORMAL (enable = 1)

            // Espera gerador terminar toda a fase 1 antes de verificar
            wait(r10_fase1_concluida);
            repeat(5) @(posedge clk);

            // Reconstrói o barramento esperado com todos os dígitos da fase 1
            for(int i = 0; i < qtd_digitos_pre_release_10; i++) begin
                for(int j = 19; j > 0; j--)
                    barramento_esperado.digits[j] = barramento_esperado.digits[j-1];
                barramento_esperado.digits[0] = sequencia_pre_release_10[i];
            end

            barramento_lido = digitos_value;

            $write("Barramento esperado: [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_esperado.digits[j]));
            $write("]\n");

            $write("Barramento recebido: [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_lido.digits[j]));
            $write("]\n");

            barramento_ok = 1;
            for(int j = 0; j < 20; j++) begin
                if(barramento_lido.digits[j] !== barramento_esperado.digits[j]) begin
                    barramento_ok = 0;
                    break;
                end
            end

            if(barramento_ok)
                $display("STATUS: OK | Barramento correto apos fase ativa.");
            else begin
                $display("STATUS: FALHOU | Barramento incorreto na fase ativa.");
                $fatal();
            end
            $display("--------------------------------------------------------\n");

            // FASE B: MÓDULO PAUSADO (enable = 0)
            wait(enable == 0);

            barramento_congelado = barramento_esperado;

            $display("Fase B: enable=0 | modulo pausado");
            $write("Barramento congelado (deve permanecer): [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_congelado.digits[j]));
            $write("]\n");

            while(enable == 0) begin
                @(posedge clk);

                if(digitos_valid) begin
                    $display("STATUS: FALHOU | digitos_valid ativou com enable=0.");
                    $fatal();
                end

                barramento_lido = digitos_value;

                for(int j = 0; j < 20; j++) begin
                    if(barramento_lido.digits[j] !== barramento_congelado.digits[j]) begin
                        $display("STATUS: FALHOU | Barramento alterou com enable=0.");
                        $display("  Posicao %0d: esperado=%s | recebido=%s",
                                 j,
                                 hex_maiusculo(barramento_congelado.digits[j]),
                                 hex_maiusculo(barramento_lido.digits[j]));
                        $fatal();
                    end
                end
            end

            // FASE C: RETOMADA VERIFICADA
            repeat(3) @(posedge clk);

            barramento_lido = digitos_value;

            $display("Fase C: enable voltou para 1");
            $write("Barramento congelado  (referencia): [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_congelado.digits[j]));
            $write("]\n");

            $write("Barramento ao reabilitar (recebido): [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_lido.digits[j]));
            $write("]\n");

            for(int j = 0; j < 20; j++) begin
                if(barramento_lido.digits[j] !== barramento_congelado.digits[j]) begin
                    $display("STATUS: FALHOU | Barramento nao retomou do ponto pausado.");
                    $fatal();
                end
            end

            $display("STATUS: OK | Sistema retomou exatamente do ponto pausado.");
            $display("--------------------------------------------------------\n");

            // FASE D: OPERAÇÃO RETOMADA (enable = 1)

            // Espera gerador terminar toda a fase 3 antes de verificar
            wait(r10_fase3_concluida);
            repeat(5) @(posedge clk);

            // Reconstrói o barramento esperado com todos os dígitos da fase 3
            for(int i = 0; i < qtd_digitos_post_release_10; i++) begin
                for(int j = 19; j > 0; j--)
                    barramento_esperado.digits[j] = barramento_esperado.digits[j-1];
                barramento_esperado.digits[0] = sequencia_post_release_10[i];
            end

            barramento_lido = digitos_value;

            $display("------------------ RELEASE 10 --------------------------");
            $display("Fase D: enable=1 | %0d digito(s) inseridos apos reabilitar",
                     qtd_digitos_post_release_10);

            $write("Barramento esperado: [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_esperado.digits[j]));
            $write("]\n");

            $write("Barramento recebido: [ ");
            for(int j = 19; j >= 0; j--)
                $write("%s ", hex_maiusculo(barramento_lido.digits[j]));
            $write("]\n");

            barramento_ok = 1;
            for(int j = 0; j < 20; j++) begin
                if(barramento_lido.digits[j] !== barramento_esperado.digits[j]) begin
                    barramento_ok = 0;
                    break;
                end
            end

            if(barramento_ok)
                $display("STATUS: OK | Sistema retomou corretamente.");
            else begin
                $display("STATUS: FALHOU | Barramento incorreto apos reabilitar.");
                $fatal();
            end
            $display("--------------------------------------------------------\n");

            quantidade_testes_release_10++;
            fim_teste = 1;
        end
    endtask
  
  
  

    //  RELEASE 06 - Preenchimento com 0xF em posições não utilizadas

    logic [3:0] seq_r06 [QTD_MAX_DIGITOS];
    int         qtd_r06;

    // Gerador Release 06
    // Sorteia comprimento (1-19), gera dígitos aleatórios, digita tudo e pressiona *.
    task automatic gerador_release_06();
        begin
            qtd_r06 = $urandom_range(1, QTD_MAX_DIGITOS - 1); // 1 a 19

            $display("Sequencia gerada (%0d digito(s)): ", qtd_r06);
            for(int i = 0; i < qtd_r06; i++) begin
                seq_r06[i] = $urandom_range(0, 9);
                $write("0x%s ", hex_maiusculo(seq_r06[i]));
            end
            $write("\n");

            for(int i = 0; i < qtd_r06; i++)
                pressionar_tecla(seq_r06[i], DEBOUNCE + 50);

            $display("Pressionando tecla * para confirmar (Release 06)");
            pressionar_tecla(4'd11, DEBOUNCE + 50);

            wait(fim_teste);
        end
    endtask

    // Monitor Release 06
    task automatic monitor_release_06();
        senhaPac_t barramento_esperado;
        senhaPac_t barramento_recebido;
        int        ciclos;
        bit        valid_encontrado;
        int        erros;
        begin
            repeat(30) @(posedge clk);
            monitor_pronto = 1;

            // Aguarda o gerador pressionar *
            wait(key_pressed && active_lin == KEY_LIN[11] && active_col == KEY_COL[11]);

            // Aguarda digitos_valid subir (máx ACIONAMENTO_MAXIMO ciclos)
            valid_encontrado = 0;
            for(ciclos = 0; ciclos < ACIONAMENTO_MAXIMO; ciclos++) begin
                @(posedge clk);
                if(digitos_valid) begin
                    valid_encontrado = 1;
                    break;
                end
            end

            // Captura o barramento exatamente quando valid=1
            barramento_recebido = digitos_value;

            for(int i = 0; i < 20; i++)
                barramento_esperado.digits[i] = 4'hF;
            for(int i = 0; i < qtd_r06; i++)
                barramento_esperado.digits[i] = seq_r06[qtd_r06 - 1 - i];

            // Verificando digitos_valid
            $display("Verificacao do sinal digitos_valid:");
            $display("  Esperado : 1 (dentro de %0d ciclos)", ACIONAMENTO_MAXIMO);
            $display("  Recebido : %0d | Ciclos ate ativar: %0d",
                     valid_encontrado, ciclos + 1);

            if(!valid_encontrado) begin
                $display("RESULTADO: FALHOU — digitos_valid nao ativou");
                $fatal();
            end
            $display("  digitos_valid: PASSOU");

            // Verificando conteúdo do barramento
            $display("\nVerificacao do barramento (%0d digito(s) + 0xF nas demais):", qtd_r06);
            $write("  Barramento esperado: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(barramento_esperado.digits[i]));
            $write("]\n");
            $write("  Barramento recebido: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(barramento_recebido.digits[i]));
            $write("]\n");

            erros = 0;
            // Verifica posições com dígitos
            for(int i = 0; i < qtd_r06; i++) begin
                if(barramento_recebido.digits[i] !== barramento_esperado.digits[i]) begin
                    $display("  >> ERRO digits[%0d]: esperado=0x%s recebido=0x%s",
                             i, hex_maiusculo(barramento_esperado.digits[i]), hex_maiusculo(barramento_recebido.digits[i]));
                    erros++;
                end
            end
            // Verifica posições que devem ser 0xF
            for(int i = qtd_r06; i < 20; i++) begin
                if(barramento_recebido.digits[i] !== 4'hF) begin
                    $display("  >> ERRO digits[%0d]: esperado=0xF recebido=0x%s",
                             i, hex_maiusculo(barramento_recebido.digits[i]));
                    erros++;
                end
            end

            $display("  Posicoes corretas: %0d / 20 | Erros: %0d", 20 - erros, erros);
            if(erros == 0)
                $display("RESULTADO: PASSOU");
            else begin
                $display("RESULTADO: FALHOU");
                $fatal();
            end

            fim_teste = 1;
        end
    endtask

    // Executor Release 06
    task automatic executar_release_06();
        int unsigned semente;
        begin
            $display("\n====================== RELEASE 06 ======================");
            $display(" Cenario : Preenchimento com 0xF em posicoes nao usadas  ");
            $display(" Rodadas : 10 (cada uma com sequencia aleatoria 1-19 dig) ");
            $display("=========================================================\n");

            for(int rodada = 1; rodada <= 10; rodada++) begin
                $display("\n---> RODADA %0d / 10 DA RELEASE 06", rodada);

                semente = ler_semente_urandom() ^ (32'($time) * 31) ^ (rodada * 999_983);
                process::self().srandom(semente);
                $display("[SEED] Rodada %0d — semente: %0d", rodada, semente);

                fim_teste      = 0;
                monitor_pronto = 0;
                soltar_tecla();
                repeat(5) @(posedge clk);

                fork : BLOCO_RELEASE_06
                    monitor_release_06();
                    begin
                        wait(monitor_pronto);
                        gerador_release_06();
                    end
                join_any
                disable BLOCO_RELEASE_06;

                $display("------------------------------- FIM RODADA ---------\n");
                repeat(30) @(posedge clk);
            end

            $display("\n====================================================");
            $display(" RELEASE 06 FINALIZADA — 10 rodadas executadas      ");
            $display("====================================================\n");
        end
    endtask

    //  RELEASE 07 — Limpeza do barramento após leitura válida

    logic [3:0] seq_r07 [QTD_MAX_DIGITOS];
    int         qtd_r07;

    // Gerador Release 07
    task automatic gerador_release_07();
        begin
            qtd_r07 = $urandom_range(1, QTD_MAX_DIGITOS - 1); // 1 a 19

            $display("Sequencia gerada (%0d digito(s)): ", qtd_r07);
            for(int i = 0; i < qtd_r07; i++) begin
                seq_r07[i] = $urandom_range(0, 9);
                $write("0x%s ", hex_maiusculo(seq_r07[i]));
            end
            $write("\n");

            for(int i = 0; i < qtd_r07; i++)
                pressionar_tecla(seq_r07[i], DEBOUNCE + 50);

            $display("Pressionando tecla * para confirmar (Release 07)");
            pressionar_tecla(4'd11, DEBOUNCE + 50);

            wait(fim_teste);
        end
    endtask

    // Monitor Release 07
    task automatic monitor_release_07();
        senhaPac_t barramento_no_valid;   // Capturado quando valid=1
        senhaPac_t barramento_apos_valid; // Capturado 1 ciclo depois (valid=0)
        senhaPac_t barramento_esperado;
        int        ciclos;
        bit        valid_encontrado;
        int        erros_valid;
        int        erros_reset;
        begin
            repeat(30) @(posedge clk);
            monitor_pronto = 1;

            // Aguarda o gerador pressionar *
            wait(key_pressed && active_lin == KEY_LIN[11] && active_col == KEY_COL[11]);

            // Aguarda digitos_valid subir — captura o barramento no mesmo ciclo
            valid_encontrado = 0;
            for(ciclos = 0; ciclos < ACIONAMENTO_MAXIMO; ciclos++) begin
                @(posedge clk);
                if(digitos_valid) begin
                    // Captura AGORA — valid ainda está em 1
                    barramento_no_valid  = digitos_value;
                    valid_encontrado     = 1;
                    // Avança UM ciclo: valid voltou a 0, barramento deve ser 0xF
                    @(posedge clk);
                    barramento_apos_valid = digitos_value;
                    break;
                end
            end

            for(int i = 0; i < 20; i++)
                barramento_esperado.digits[i] = 4'hF;
            for(int i = 0; i < qtd_r07; i++)
                barramento_esperado.digits[i] = seq_r07[qtd_r07 - 1 - i];

            $display("Sub-teste A — digitos_valid ativou dentro da janela:");
            $display("  Esperado : 1 (dentro de %0d ciclos apos *)", ACIONAMENTO_MAXIMO);
            $display("  Recebido : %0d | Ciclos ate ativar: %0d",
                     valid_encontrado, ciclos + 1);

            if(!valid_encontrado) begin
                $display("RESULTADO: FALHOU — digitos_valid nao ativou");
                $fatal();
            end
            $display("  PASSOU\n");

            $display("Sub-teste B — barramento no momento em que digitos_valid=1:");
            $write("  Esperado: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(barramento_esperado.digits[i]));
            $write("]\n");
            $write("  Recebido: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(barramento_no_valid.digits[i]));
            $write("]\n");

            erros_valid = 0;
            for(int i = 0; i < 20; i++) begin
                if(barramento_no_valid.digits[i] !== barramento_esperado.digits[i]) begin
                    $display("  >> ERRO digits[%0d]: esperado=0x%s recebido=0x%s",
                             i, hex_maiusculo(barramento_esperado.digits[i]), hex_maiusculo(barramento_no_valid.digits[i]));
                    erros_valid++;
                end
            end
            if(erros_valid == 0) $display("  PASSOU\n");
            else begin $display("  FALHOU (%0d erro(s))\n", erros_valid); $fatal(); end

            $display("Sub-teste C — barramento resetado para 0xF apos pulso de digitos_valid:");
            $display("  (verificado 1 ciclo apos digitos_valid=1, quando valid ja voltou a 0)");
            $write("  Esperado: [ F F F F F F F F F F F F F F F F F F F F ]\n");
            $write("  Recebido: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(barramento_apos_valid.digits[i]));
            $write("]\n");

            erros_reset = 0;
            for(int i = 0; i < 20; i++) begin
                if(barramento_apos_valid.digits[i] !== 4'hF) begin
                    $display("  >> ERRO digits[%0d]: esperado=0xF recebido=0x%s",
                             i, hex_maiusculo(barramento_apos_valid.digits[i]));
                    erros_reset++;
                end
            end
            if(erros_reset == 0) $display("  PASSOU");
            else begin $display("  FALHOU (%0d posicao(oes) nao resetadas)", erros_reset); $fatal(); end

            fim_teste = 1;
        end
    endtask

    // ---- Executor Release 07 ----
    task automatic executar_release_07();
        int unsigned semente;
        begin
            $display("\n====================== RELEASE 07 ======================");
            $display(" Cenario : Limpeza do barramento apos leitura valida     ");
            $display(" Rodadas : 10 (cada uma com sequencia aleatoria 1-19 dig) ");
            $display("=========================================================\n");

            for(int rodada = 1; rodada <= 10; rodada++) begin
                $display("\n---> RODADA %0d / 10 DA RELEASE 07", rodada);

                semente = ler_semente_urandom() ^ (32'($time) * 37) ^ (rodada * 1_000_033);
                process::self().srandom(semente);
                $display("[SEED] Rodada %0d — semente: %0d", rodada, semente);

                fim_teste      = 0;
                monitor_pronto = 0;
                soltar_tecla();
                repeat(5) @(posedge clk);

                fork : BLOCO_RELEASE_07
                    monitor_release_07();
                    begin
                        wait(monitor_pronto);
                        gerador_release_07();
                    end
                join_any
                disable BLOCO_RELEASE_07;

                $display("------------------------------- FIM RODADA ---------\n");
                repeat(30) @(posedge clk);
            end

            $display("\n====================================================");
            $display(" RELEASE 07 FINALIZADA — 10 rodadas executadas      ");
            $display("====================================================\n");
        end
    endtask


    //  RELEASE 11 — Reset do sistema

    function automatic int checar_estado_reset(string contexto);
        int erros;
        erros = 0;

        if(digitos_valid !== 1'b0) begin
            $display("  >> ERRO [%s] digitos_valid = %0b (esperado 0)", contexto, digitos_valid);
            erros++;
        end
        for(int i = 0; i < 20; i++) begin
            if(digitos_value.digits[i] !== 4'hF) begin
                $display("  >> ERRO [%s] digits[%0d] = 0x%s (esperado 0xF)",
                         contexto, i, hex_maiusculo(digitos_value.digits[i]));
                erros++;
            end
        end
        return erros;
    endfunction

    // Monitor / Executor Release 11
    // Controla tudo diretamente (sem gerador separado).
    task automatic monitor_release_11();
        logic [3:0]  tecla_rand;
        int          erros;
        int          erros_total;
        int unsigned semente_r11;
        begin
            // Renova semente: garante teclas aleatórias diferentes a cada execução
            semente_r11 = ler_semente_urandom() ^ (32'($time) * 1_000_003);
            process::self().srandom(semente_r11);
            $display("[SEED R11] Semente: %0d", semente_r11);

            repeat(30) @(posedge clk);
            monitor_pronto = 1;
            erros_total = 0;

            // ==============================================================
            // Sub-teste A: reset em estado ocioso (nenhuma tecla pressionada)
            // ==============================================================
            $display("------------------ RELEASE 11 --------------------------");
            $display("Sub-teste A: rst em estado ocioso");
            $display("  Acionando rst=1 sem nenhuma tecla pressionada...");

            rst = 1;
            repeat(5) @(posedge clk);

            $write("  Barramento durante rst: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");
            $display("  digitos_valid durante rst: %0b", digitos_valid);
            $display("  Esperado: barramento=[ F F ... F ] | digitos_valid=0");

            erros = checar_estado_reset("R11-Sub-A");

            rst = 0;
            repeat(5) @(posedge clk);

            if(erros == 0) $display("RESULTADO: PASSOU");
            else begin $display("RESULTADO: FALHOU (%0d erro(s))", erros); erros_total += erros; end
            $display("--------------------------------------------------------\n");


            // ==============================================================
            // Sub-teste B: reset durante digitação ativa (tecla mantida)
            // ==============================================================
            $display("------------------ RELEASE 11 --------------------------");
            tecla_rand = $urandom_range(0, 9);
            $display("Sub-teste B: rst com tecla 0x%s mantida pressionada", hex_maiusculo(tecla_rand));
            $display("  Acionando tecla e deixando passar o debounce...");

            acionar_tecla(tecla_rand);
            repeat(DEBOUNCE + 20) @(posedge clk); // DUT registrou a tecla

            $display("  Tecla registrada. Acionando rst=1 enquanto tecla ainda pressionada...");
            rst = 1;
            repeat(5) @(posedge clk);

            $write("  Barramento durante rst: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");
            $display("  digitos_valid durante rst: %0b", digitos_valid);
            $display("  Esperado: barramento=[ F F ... F ] | digitos_valid=0");

            erros = checar_estado_reset("R11-Sub-B-durante");

            $display("  Verificando persistencia: rst permanece ativo por mais 10 ciclos...");
            repeat(10) @(posedge clk);
            erros += checar_estado_reset("R11-Sub-B-persistencia");

            rst = 0;
            soltar_tecla();
            repeat(10) @(posedge clk);

            $display("  Verificando estado apos liberar rst...");
            $write("  Barramento apos rst=0: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");
            erros += checar_estado_reset("R11-Sub-B-apos-rst");

            if(erros == 0) $display("RESULTADO: PASSOU");
            else begin $display("RESULTADO: FALHOU (%0d erro(s))", erros); erros_total += erros; end
            $display("--------------------------------------------------------\n");


            // ==============================================================
            // Sub-teste C: reset após sequência parcial digitada
            // ==============================================================
            $display("------------------ RELEASE 11 --------------------------");
            $display("Sub-teste C: rst apos sequencia parcial de 3 teclas aleatorias");

            for(int i = 0; i < 3; i++) begin
                tecla_rand = $urandom_range(0, 9);
                $display("  Digitando tecla 0x%s...", hex_maiusculo(tecla_rand));
                pressionar_tecla(tecla_rand, DEBOUNCE + 20);
            end

            $write("  Barramento antes do rst: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");

            $display("  Acionando rst=1...");
            rst = 1;
            repeat(5) @(posedge clk);

            $write("  Barramento durante rst: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");
            $display("  digitos_valid durante rst: %0b", digitos_valid);
            $display("  Esperado: barramento=[ F F ... F ] | digitos_valid=0");

            erros = checar_estado_reset("R11-Sub-C-durante");

            rst = 0;
            repeat(10) @(posedge clk);

            $write("  Barramento apos rst=0: [ ");
            for(int i = 19; i >= 0; i--) $write("%s ", hex_maiusculo(digitos_value.digits[i]));
            $write("]\n");
            erros += checar_estado_reset("R11-Sub-C-apos-rst");

            if(erros == 0) $display("RESULTADO: PASSOU");
            else begin $display("RESULTADO: FALHOU (%0d erro(s))", erros); erros_total += erros; end
            $display("--------------------------------------------------------\n");


            // ==============================================================
            // Sub-teste D: rst deve manter barramento em 0xF enquanto ativo
            // ==============================================================
            $display("------------------ RELEASE 11 --------------------------");
            $display("Sub-teste D: barramento permanece em 0xF durante todos os ciclos com rst=1");
            $display("  Mantendo rst=1 por 20 ciclos e verificando a cada ciclo...");

            rst = 1;
            erros = 0;
            repeat(20) begin
                @(posedge clk);
                for(int i = 0; i < 20; i++) begin
                    if(digitos_value.digits[i] !== 4'hF) begin
                        $display("  >> ERRO ciclo %0t: digits[%0d]=0x%s (esperado 0xF)",
                                 $time, i, hex_maiusculo(digitos_value.digits[i]));
                        erros++;
                    end
                end
                if(digitos_valid !== 1'b0) begin
                    $display("  >> ERRO ciclo %0t: digitos_valid=%0b (esperado 0)", $time, digitos_valid);
                    erros++;
                end
            end

            rst = 0;
            repeat(5) @(posedge clk);

            if(erros == 0) $display("RESULTADO: PASSOU — barramento estavel em 0xF durante 20 ciclos de rst");
            else begin $display("RESULTADO: FALHOU (%0d erro(s))", erros); erros_total += erros; end
            $display("--------------------------------------------------------\n");


            // ==============================================================
            // Resumo Release 11
            // ==============================================================
            $display("====================================================");
            $display(" RELEASE 11 — Resumo dos sub-testes");
            $display(" Sub-teste A (ocioso)          : %s", (erros_total == 0) ? "OK" : "ver acima");
            $display(" Sub-teste B (tecla pressionada): %s", (erros_total == 0) ? "OK" : "ver acima");
            $display(" Sub-teste C (seq. parcial)     : %s", (erros_total == 0) ? "OK" : "ver acima");
            $display(" Sub-teste D (persistencia)     : %s", (erros_total == 0) ? "OK" : "ver acima");
            $display(" Total de erros: %0d", erros_total);
            if(erros_total > 0) $fatal(1, "Release 11 falhou com %0d erro(s)", erros_total);

            fim_teste = 1;
        end
    endtask

    // ---- Executor Release 11 ----
    task automatic executar_release_11();
        begin
            $display("\n====================== RELEASE 11 ======================");
            $display(" Cenario : Reset do sistema em diferentes estados         ");
            $display("=========================================================\n");

            fim_teste      = 0;
            monitor_pronto = 0;
            soltar_tecla();
            repeat(5) @(posedge clk);

            fork : BLOCO_RELEASE_11
                monitor_release_11();
            join_any
            disable BLOCO_RELEASE_11;

            $display("\n====================================================");
            $display(" RELEASE 11 FINALIZADA                              ");
            $display("====================================================\n");
        end
    endtask


    // ============================ EXECUÇÃO DAS RELEASES ============================

  	task automatic executar_release_01();
        begin
            $display("\n====================== RELEASE 01 ======================\n");
            fim_teste         = 0;
            monitor_pronto    = 0;
            quantidade_testes = 0;
            cobertura_saida   = 0.0;
            soltar_tecla();

            fork : BLOCO_RELEASE_01
                monitor_release_01();
                begin
                    wait(monitor_pronto);
                    gerador_release_01();
                end
            join_any
            disable BLOCO_RELEASE_01;

            $display("\n====================================================");
            $display(" RELEASE 01 FINALIZADA ");
            $display(" Quantidade de testes: %0d", quantidade_testes);
            $display("====================================================\n");
        end
    endtask

  	task automatic executar_release_02();
        begin
            $display("\n====================== RELEASE 02 ======================\n");
          	fim_teste      = 0;
            monitor_pronto = 0;
            soltar_tecla();
            repeat(5) @(posedge clk);

            fork : R02
                gerador_release_02();
                monitor_release_02();
            join_any
            disable R02;

            $display("\n====================================================");
            $display(" RELEASE 02 FINALIZADA ");
            $display("====================================================\n");
        end
    endtask

	task automatic executar_release_03();
        begin
            $display("\n====================== RELEASE 03: DEBOUNCE (50 TESTES) ======================\n");
            quantidade_testes = 0;
            soltar_tecla();
            repeat(50) @(posedge clk);

            fork
                gerador_release_03();
                monitor_release_03();
            join

            $display("\n====================================================");
            $display(" RELEASE 03 FINALIZADA COM SUCESSO ");
            $display("====================================================\n");
        end
    endtask

  	task automatic executar_release_04();
        begin
            $display("\n====================== RELEASE 04 ======================\n");
            fim_teste      = 0;
            monitor_pronto = 0;
            r04_falhas     = 0;
            soltar_tecla();

            fork : BLOCO_RELEASE_04
                monitor_release_04();
                begin
                    wait(monitor_pronto);
                    gerador_release_04();
                end
            join_any
            disable BLOCO_RELEASE_04;

            $display("\n====================================================");
            $display(" RELEASE 04 FINALIZADA ");
            $display(" Sub-testes executados : 5 (A, B, C, D, E)");
            $display(" Falhas encontradas    : %0d", r04_falhas);
            $display("====================================================\n");
        end
    endtask

  	task automatic executar_release_05();
        begin
            $display("\n====================== RELEASE 05 ======================\n");
            quantidade_testes = 0;

          	for (int rodada = 1; rodada <= 25; rodada++) begin
                fim_teste      = 0;
                monitor_pronto = 0;
                cobertura_saida = 0.0;
                soltar_tecla();

                fork : BLOCO_RELEASE_05
                    monitor_release_05();
                    begin
                        wait(monitor_pronto);
                        gerador_release_05();
                    end
                join_any
                disable BLOCO_RELEASE_05;

                repeat(50) @(posedge clk);
            end

            $display("\n====================================================");
            $display(" RELEASE 05 FINALIZADA ");
            $display(" Quantidade de sequencias testadas: %0d", quantidade_testes);
            $display("====================================================\n");
        end
    endtask

    task automatic executar_release_08();
        begin
            $display("\n====================== RELEASE 08 ======================\n");

            quantidade_testes = 0;

            for(int rodada = 1; rodada <= QTD_TESTES_RELEASE_08; rodada++) begin
                fim_teste      = 0;
                monitor_pronto = 0;

                soltar_tecla();
                repeat(5) @(posedge clk);

                fork : BLOCO_RELEASE_08
                    monitor_release_08();
                    begin
                        wait(monitor_pronto);
                        gerador_release_08();
                    end
                join_any

                disable BLOCO_RELEASE_08;

                repeat(20) @(posedge clk);
            end

            $display("\n====================================================");
            $display(" RELEASE 08 FINALIZADA ");
            $display(" Quantidade de testes: %0d", quantidade_testes);
            $display("====================================================\n");
        end
  	endtask
  
    // EXECUÇÃO RELEASE 09
    task automatic executar_release_09();
        begin
            $display("\n====================== RELEASE 09 ======================\n");

            quantidade_testes_release_09 = 0;
            qtd_rodadas_release_09 = 25;

            for(int rodada = 1; rodada <= qtd_rodadas_release_09; rodada++) begin
                fim_teste      = 0;
                monitor_pronto = 0;

                soltar_tecla();
                repeat(5) @(posedge clk);

                fork : BLOCO_RELEASE_09
                    monitor_release_09();
                    begin
                        wait(monitor_pronto);
                        gerador_release_09();
                    end
                join_any

                disable BLOCO_RELEASE_09;

                repeat(20) @(posedge clk);
            end

            $display("\n====================================================");
            $display(" RELEASE 09 FINALIZADA ");
            $display(" Quantidade de testes: %0d", quantidade_testes_release_09);
            $display("====================================================\n");
        end
    endtask
  
  
    // EXECUÇÃO RELEASE 10

    task automatic executar_release_10();
        begin
            $display("\n====================== RELEASE 10 ======================\n");

            quantidade_testes_release_10 = 0;
            qtd_rodadas_release_10       = 10;

            for(int rodada = 1; rodada <= qtd_rodadas_release_10; rodada++) begin
                fim_teste           = 0;
                monitor_pronto      = 0;
                r10_fase1_concluida = 0;
                r10_fase3_concluida = 0;
                enable              = 1;

                soltar_tecla();
                repeat(10) @(posedge clk);

                fork : BLOCO_RELEASE_10
                    monitor_release_10();
                    begin
                        wait(monitor_pronto);
                        gerador_release_10();
                    end
                join_any

                disable BLOCO_RELEASE_10;

                enable = 1;
                repeat(30) @(posedge clk);
            end

            $display("\n====================================================");
            $display(" RELEASE 10 FINALIZADA ");
            $display(" Quantidade de testes executados: %0d", quantidade_testes_release_10);
            $display("====================================================\n");
        end
    endtask
  
  
  
  
  
  	// ================ EXECUÇÃO DE TODAS AS RELEASES ================
  
    task automatic executar_todas_releases();
        begin
          executar_release_01();
          executar_release_02();
          executar_release_03();
          executar_release_04();
          executar_release_05();
          executar_release_06();
          executar_release_07();
          executar_release_08();
          executar_release_09();
          executar_release_10();
          executar_release_11();
        end
    endtask

    function automatic int unsigned ler_semente_urandom();
        int         fd;
        logic [7:0] b[4];
        int unsigned val;

        fd = $fopen("/dev/urandom", "rb");
        if (fd != 0) begin
            void'($fread(b, fd));
            $fclose(fd);
            val = {b[3], b[2], b[1], b[0]};
        end else begin
            val = $urandom();
            $display("[AVISO] /dev/urandom indisponivel — use +ntb_random_seed_automatic");
        end
        return val;
    endfunction

    initial begin
        int unsigned semente_global;

        semente_global = ler_semente_urandom();
        process::self().srandom(semente_global);
        $display("\n[SEMENTE GLOBAL] %0d — sequencias serao unicas nesta execucao\n",
                 semente_global);

        inicializar_tb();
        inicializar_coberturas();

        resetar();
        executar_todas_releases();

        repeat(20) @(posedge clk);

        $display("\n====================================================");
        $display(" TODAS AS RELEASES FINALIZADAS ");
        $display("====================================================\n");

        $finish;
    end

endmodule