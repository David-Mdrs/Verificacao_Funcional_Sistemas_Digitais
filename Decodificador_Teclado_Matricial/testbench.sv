// ALUNOS: David Medeiros e João Gabriel Tavares

`timescale 1ns/1ps

module tb;

  	// Definição dos tempos
    localparam int DEBOUNCE       		= 50;	// Leitura da tecla
    localparam int REPETIR_01 			= 2000;	// 2s pressionando tecla
    localparam int REPETIR_02   		= 1000;	// 1s pressionando tecla
  	localparam int ACIONAMENTO_MAXIMO 	= 120;	// Máximos de pulsos para confirmar

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

  	// Declarando variáveis do testbench
    decodificador_de_teclado dut (
      	.clk           (clk),			// Input
        .rst           (rst),			// Input
        .enable        (enable),		// Input
        .col_matriz    (col_matriz),	// Input
      	.lin_matriz    (lin_matriz),	// Output
        .digitos_value (digitos_value),	// Output
        .digitos_valid (digitos_valid)	// Output
    );
  
  	// ============================ COVERGROUPS ============================

    // Cobertura das linhas do teclado
    covergroup c_linhas @(posedge clk);
        coverpoint lin_matriz {
            bins linha_0 = {4'b1110};
            bins linha_1 = {4'b0111};
            bins linha_2 = {4'b1011};
            bins linha_3 = {4'b1101};
        }
    endgroup

    // Cobertura das teclas decodificadas
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

    // Instâncias
    c_linhas  cov_linhas;
    c_saida   cov_saida;

	// ========================== MAPEAMENTO DAS TECLAS ==========================

    logic [3:0] KEY_LIN [12];
    logic [3:0] KEY_COL [12];

  	initial begin
		KEY_LIN[0]  = 4'b1110;
		KEY_COL[0]  = 4'b1011;

		KEY_LIN[1]  = 4'b0111;
		KEY_COL[1]  = 4'b0111;

		KEY_LIN[2]  = 4'b0111;
		KEY_COL[2]  = 4'b1011;

		KEY_LIN[3]  = 4'b0111;
		KEY_COL[3]  = 4'b1101;

		KEY_LIN[4]  = 4'b1011;
		KEY_COL[4]  = 4'b0111;

		KEY_LIN[5]  = 4'b1011;
		KEY_COL[5]  = 4'b1011;

		KEY_LIN[6]  = 4'b1011;
		KEY_COL[6]  = 4'b1101;

		KEY_LIN[7]  = 4'b1101;
		KEY_COL[7]  = 4'b0111;

		KEY_LIN[8]  = 4'b1101;
		KEY_COL[8]  = 4'b1011;

		KEY_LIN[9]  = 4'b1101;
		KEY_COL[9]  = 4'b1101;

  		// Tecla (#)
 		KEY_LIN[10] = 4'b1110;
  		KEY_COL[10] = 4'b1101;

    	// Tecla (*)
  		KEY_LIN[11] = 4'b1110;
  		KEY_COL[11] = 4'b0111;
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

    // INICIALIZAÇÃO GERAL
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

    // INICIALIZAÇÃO DAS COBERTURAS
    task automatic inicializar_coberturas();
        begin
            cov_linhas = new();
            cov_saida   = new();
        end
    endtask

    // RESET
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

    // ACIONAR TECLA
    task automatic acionar_tecla(input logic [3:0] tecla);
        begin
            active_lin  = KEY_LIN[tecla];
            active_col  = KEY_COL[tecla];
            key_pressed = 1;
        end
    endtask

    // SOLTAR TECLA
    task automatic soltar_tecla();
        begin
            key_pressed = 0;
            active_lin  = 4'b1111;
            active_col  = 4'b1111;
        end
    endtask

    // PRESSIONAR TECLA
  	task automatic pressionar_tecla(input logic [3:0] tecla, input int ciclos);
        begin
            acionar_tecla(tecla);
            repeat(ciclos) @(posedge clk);

            soltar_tecla();
            repeat(10) @(posedge clk);
        end
    endtask

    // EXIBIR BARRAMENTO
    task automatic exibir_barramento();
        begin
            $write("Barramento: [ ");

            for(int i = 19; i >= 0; i--)
                $write("%0X ", digitos_value.digits[i]);

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
                // Sorteia tecla de 0 até 9
                tecla_aleatoria = $urandom_range(0, 9);

                // Pressiona tecla
                pressionar_tecla(tecla_aleatoria[3:0], DEBOUNCE + 20);

                // Pequeno intervalo entre teclas
                repeat($urandom_range(10, 100)) @(posedge clk);
            end
        end
    endtask
  
  
  	// GERADOR RELEASE 02
    task automatic gerador_release_02();
        begin
              // Preenchendo barramento duas vezes
            for(int j = 0; j < 2; j++) begin
                for(int i = 0; i <= 9; i++) begin
                    pressionar_tecla(i[3:0], DEBOUNCE + 20);
                end
            end

            // Gerando sequência aleatória
            while(!fim_teste) begin

                // Sorteia tecla de 0 até 9
                tecla_aleatoria = $urandom_range(0, 9);

                // Pressiona tecla
                pressionar_tecla(tecla_aleatoria[3:0], DEBOUNCE + 20);
              
                // Pequeno intervalo entre teclas
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

                // Oscilações no botão
                repeat(100) begin
                    key_pressed = $urandom_range(0, 1);
                    @(posedge clk);
                end

                // Estabilizando botão
                key_pressed = 1;
                repeat(DEBOUNCE + 100) @(posedge clk);

                // Fim do pressionamento
                key_pressed = 0;
                soltar_tecla();

                // Intervalo aleatório entre teclas
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
            $display("Tecla sorteada    : 0x%0X (%0d)", r04_tecla_alvo, r04_tecla_alvo);
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


    // GERADOR DA RELEASE 05
  	// Variáveis auxiliares release 05
  	bit fim_teste;
	bit monitor_pronto;
	int quantidade_testes;
    localparam int QTD_MAX_DIGITOS = 20;
    logic [3:0] sequencia_release_05 [QTD_MAX_DIGITOS];
    int qtd_digitos_release_05;
  
    task automatic gerador_release_05();
        begin
            // Sorteia quantos dígitos serão digitados nesta execução
            qtd_digitos_release_05 = $urandom_range(1, QTD_MAX_DIGITOS);

            for (int i = 0; i < qtd_digitos_release_05; i++) begin
                sequencia_release_05[i] = $urandom_range(0, 9);
            end

            for (int i = 0; i < qtd_digitos_release_05; i++) begin
                pressionar_tecla(sequencia_release_05[i], DEBOUNCE + 50);
            end

            // Confirma com *
            $display("Pressionando tecla * para confirmar");
            pressionar_tecla(4'd11, DEBOUNCE + 50);

            // Espera o monitor finalizar a checagem
            wait(fim_teste);
        end
    endtask

	// ======================= MONITORAMENTO =======================

  	// MONITORAMENTO RELEASE 01
    task automatic monitor_release_01();
        logic [3:0] tecla_esperada;
        logic [3:0] tecla_lida;
        begin
            // Espera reset finalizar
            repeat(30) @(posedge clk);

            // Libera o gerador só depois que o monitor estiver pronto
            monitor_pronto = 1;

            while(!fim_teste) begin
                // Espera uma nova tecla ser pressionada
                @(posedge key_pressed);

                // Guarda tecla esperada
                tecla_esperada = tecla_aleatoria[3:0];

                // Espera debounce/processamento
                repeat(DEBOUNCE + 30) @(posedge clk);

                // Lê barramento
                tecla_lida = digitos_value.digits[0];

                // Atualiza cobertura
                barramento0_obs = tecla_lida;
                cov_saida.sample();
				cobertura_saida = cov_saida.get_coverage();

                // Relatório
                $display("------------------ RELEASE 01 --------------------------");
                $display("Teste #%0d", quantidade_testes);
              	$display("Tecla esperada : 0x%0X", tecla_esperada);
              	$display("Tecla lida    : 0x%0X", tecla_lida);
                $display("Cobertura atual   : %0.2f%%", cov_saida.get_coverage());

                exibir_barramento();
              	quantidade_testes++;

                // Verificação
                if(tecla_lida === tecla_esperada) begin
                    $display("RESULTADO: PASSOU");
                end
                else begin
                    $display("RESULTADO: FALHOU");
                  	$fatal();
                end

                $display("--------------------------------------------------------\n");

                // Finaliza a release quando atingir cobertura total
                if(cobertura_saida >= 100.0) begin
                    fim_teste = 1;
                end
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

            // Inicializa buffer esperado com 'F' (vazio)
            for(int i = 0; i < 20; i++)
                barramento_esperado.digits[i] = 4'hF;

            while(!fim_teste) begin
                // Espera uma nova tecla ser pressionada
                @(posedge key_pressed);

                // Mapeando tecla
                nova_tecla = 4'hF;
                for(int k = 0; k < 12; k++) begin
                    if(KEY_LIN[k] === active_lin && KEY_COL[k] === active_col) begin
                        nova_tecla = k[3:0];
                        break;
                    end
                end

                repeat(DEBOUNCE + 15) @(posedge clk);

              	// Lê barramento
                barramento_lido = digitos_value;

                barramento0_obs = nova_tecla; 
                cov_saida.sample();
                cobertura_saida = cov_saida.get_coverage();

                if(!iniciado) begin
                    barramento_esperado = barramento_lido;
                    iniciado = 1;
                end
                else begin
                    // Shift manual para teste
                    for(int k = 19; k > 0; k--)
                        barramento_esperado.digits[k] = barramento_esperado.digits[k-1];

                    barramento_esperado.digits[0] = nova_tecla;
                end

                $display("------------------ RELEASE 02 --------------------------");

                $write("Barramento: [ ");
                for(int i = 19; i >= 0; i--)
                    $write("%0X ", digitos_value.digits[i]);
                $write("]\n");

                exibir_barramento();
              
                $display("Tecla detectada: %0X", nova_tecla);

              	// Comparando barramento esperado com o real
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
              	if(quantidade_testes >= 50) begin
                    fim_teste = 1;
                end
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

                if (!tecla_estavel)
                    continue;

                tecla_esperada = tecla_aleatoria[3:0];

                repeat(5) @(posedge clk);

                tecla_lida = digitos_value.digits[0];

                $display("------------------ RELEASE 03 --------------------------");
                $display("Teste #%0d", quantidade_testes + 1);
                $display("Tecla esperada : 0x%0X", tecla_esperada);
                $display("Tecla lida     : 0x%0X", tecla_lida);

                if (tecla_lida === tecla_esperada) begin
                    $display("RESULTADO: PASSOU");
                end
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
            $display("Saida esperada    - digits[0]: 0x%0X", tecla_esperada);
            $display("Saida recebida    - digits[0]: 0x%0X", digitos_value.digits[0]);
            exibir_barramento();
            if(digitos_value.digits[0] === tecla_esperada)
                $display("RESULTADO: PASSOU");
            else begin
                $display("RESULTADO: FALHOU");
                falhas_locais++;
            end
            $display("--------------------------------------------------------\n");

            repeat(REPETIR_01) @(posedge clk);
            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste B: 1a repeticao automatica apos %0d ciclos (2 s)", REPETIR_01);
            $display("Saida esperada    - digits[0]: 0x%0X | digits[1]: 0x%0X",
                     tecla_esperada, tecla_esperada);
            $display("Saida recebida    - digits[0]: 0x%0X | digits[1]: 0x%0X",
                     digitos_value.digits[0], digitos_value.digits[1]);
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
            $display("Saida esperada    - digits[2]: 0x%0X", tecla_esperada);
            $display("Saida recebida    - digits[2]: 0x%0X", digitos_value.digits[2]);
            exibir_barramento();
            if(digitos_value.digits[2] === tecla_esperada)
                $display("RESULTADO: PASSOU");
            else begin
                $display("RESULTADO: FALHOU — 2a repeticao nao ocorreu");
                falhas_locais++;
            end
            $display("--------------------------------------------------------\n");

            repeat(REPETIR_02) @(posedge clk);
            $display("------------------ RELEASE 04 --------------------------");
            $display("Sub-teste D: 3a repeticao automatica apos mais %0d ciclos (1 s)", REPETIR_02);
            $display("Saida esperada    - digits[3]: 0x%0X", tecla_esperada);
            $display("Saida recebida    - digits[3]: 0x%0X", digitos_value.digits[3]);
            exibir_barramento();
            if(digitos_value.digits[3] === tecla_esperada)
                $display("RESULTADO: PASSOU");
            else begin
                $display("RESULTADO: FALHOU — 3a repeticao nao ocorreu");
                falhas_locais++;
            end
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
                if(mudancas == 0)
                    $display("RESULTADO: PASSOU — Barramento estavel apos soltar a tecla");
                else begin
                    $display("RESULTADO: FALHOU — Barramento alterado apos soltar a tecla");
                    falhas_locais++;
                end
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

                // Espera tecla * ser pressionada
                wait(
                    key_pressed &&
                    active_lin == KEY_LIN[11] &&
                    active_col == KEY_COL[11]
                );

                valid_encontrado = 0;

                // Espera digitos_valid
                for(ciclos = 0;
                    ciclos < ACIONAMENTO_MAXIMO;
                    ciclos++) begin

                    @(posedge clk);

                    if(digitos_valid) begin
                        valid_encontrado = 1;
                        break;
                    end
                end

                // Timeout
                if(!valid_encontrado) begin
                    $display("RESULTADO: FALHOU");
                    $display("digitos_valid nao ativou");
                    $fatal();
                end

                // Comparação do barramento
                for(int i = 0; i < qtd_digitos_release_05; i++) begin

                    if(
                        digitos_value.digits[i]
                        !==
                        sequencia_release_05[
                            qtd_digitos_release_05 - 1 - i
                        ]
                    ) begin

                        $display("RESULTADO: FALHOU");
                        $display("Posicao %0d", i);

                        $display(
                            "Esperado : %0d",
                            sequencia_release_05[
                                qtd_digitos_release_05 - 1 - i
                            ]
                        );

                        $display(
                            "Recebido : %0d",
                            digitos_value.digits[i]
                        );

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

    // ============================ EXECUÇÃO DAS RELEASES ============================

  	// RELEASE 01
    task automatic executar_release_01();
        begin
            $display("\n====================== RELEASE 01 ======================\n");

            fim_teste       = 0;
            monitor_pronto  = 0;
            quantidade_testes = 0;
            cobertura_saida = 0.0;
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
  
  	// RELEASE 02
    task automatic executar_release_02();
        begin
            $display("\n====================== RELEASE 02 ======================\n");

          	fim_teste       = 0; 
            monitor_pronto  = 0;
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
  
  
  	// RELEASE 03
task automatic executar_release_03();
        begin
            $display("\n====================== RELEASE 03: DEBOUNCE (50 TESTES) ======================\n");
            
            quantidade_testes = 0; 
            soltar_tecla();
            repeat(50) @(posedge clk);

            // Inicia o monitor e gerador
            fork
                gerador_release_03();
                monitor_release_03();
            join

            $display("\n====================================================");
            $display(" RELEASE 03 FINALIZADA COM SUCESSO ");
            $display(" Todos os 50 testes de ruído mecânico passaram.");
            $display("====================================================\n");
        end
    endtask
  
  	// RELEASE 04
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
  
  	// RELEASE 05
    task automatic executar_release_05();
        begin
            $display("\n====================== RELEASE 05 ======================\n");
            
            quantidade_testes = 0;

          
          	for (int rodada = 1; rodada <= 25; rodada++) begin
                fim_teste         = 0;
                monitor_pronto    = 0;
                cobertura_saida   = 0.0;


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
            $display(" Quantidade de sequências testadas: %0d", quantidade_testes);
            $display("====================================================\n");
        end
    endtask
  
    task automatic executar_todas_releases();
        begin
            executar_release_01();
          	executar_release_02();
          	executar_release_03();
          	executar_release_04();
          	executar_release_05();

            // Quando for adicionar novas releases, siga este padrão:
            // executar_release_03();
        end
    endtask

    // ============================ FINALIZAÇÃO ============================

    initial begin
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