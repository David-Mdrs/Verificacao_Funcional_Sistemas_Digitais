// ALUNOS: David Medeiros e João Gabriel Tavares

`timescale 1ns/1ps

module tb;

  	// Definição dos tempos
    localparam int DEBOUNCE     		= 50;	// Leitura da tecla
    localparam int REPETIR_01 			= 2000;	// 2s pressionando tecla
    localparam int REPETIR_02   		= 1000;	// 1s pressionando tecla
  	localparam int ACIONAMENTO_MAXIMO 	= 120;	// Máximos de pulsos para confirmar

  	// Declarando variáveis do design
    logic clk;
    logic rst;
    logic enable;

    logic [3:0] col_matriz;
    logic  [3:0] lin_matriz;

    senhaPac_t digitos_value;
    logic digitos_valid;

  	// Inicializando variáveis
    always #1 clk = ~clk;
  
    initial begin
        clk    = 0;
        rst    = 0;
        enable = 1;
    end

  	// Declarando variáveis do testbench
    decodificador_de_teclado dut (
      	.clk          (clk),			// Input
        .rst          (rst),			// Input
        .enable       (enable),			// Input
        .col_matriz   (col_matriz),		// Input
      	.lin_matriz   (lin_matriz),		// Output
        .digitos_value(digitos_value),	// Output
        .digitos_valid(digitos_valid)	// Output
    );

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
        coverpoint digitos_value.digits[0] {
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

    // Inicialização
    initial begin
        cov_linhas  = new();
        cov_saida   = new();
    end
  
  
    // ========================== GERADOR RANDÔMICO ==========================
  	
  	// RELEASE 01 - TECLAS	
    int tecla_aleatoria;
    int quantidade_testes;
    bit fim_teste;

    initial begin
        while(!fim_teste) begin
          
            // Sorteia tecla de 0 até 9
            tecla_aleatoria = $urandom_range(0, 9);
          
            // Pressiona tecla
            pressionar_tecla(tecla_aleatoria[3:0], DEBOUNCE + 20);

            // Pequeno intervalo entre teclas
            repeat($urandom_range(10, 100)) @(posedge clk);

        end
    end
  
  	

  	// ======================= MONITORAMENTO =======================

    initial begin
        logic [3:0] tecla_esperada;
        logic [3:0] tecla_lida;

        // Espera reset finalizar
        repeat(30) @(posedge clk);

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
            $display("Tecla pressionada : 0x%0X", tecla_esperada);
            $display("Tecla recebida    : 0x%0X", tecla_lida);
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

        end

    end
  
  

    // ============================ FINALIZAÇÃO ============================

    initial begin
        rst          = 0;
        enable       = 1;
        key_pressed  = 0;

        active_lin   = 4'b1111;
        active_col   = 4'b1111;

        fim_teste         = 0;

        resetar();

        // Espera cobertura total
       	wait(cobertura_saida >= 100.0);
		fim_teste = 1;

        repeat(20) @(posedge clk);

        $display("\n====================================================");
        $display(" COBERTURA TOTAL ATINGIDA ");
        $display(" Quantidade de testes: %0d", quantidade_testes);
        $display("====================================================\n");

        $finish;

    end
endmodule