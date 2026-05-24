// ALUNOS: David Medeiros e João Gabriel Tavares

`timescale 1ns/1ps

module tb;

  	// Definição dos tempos
    localparam int DEBOUNCE     		= 50;	// Leitura da tecla
    localparam int REPETIR_01 			= 2000;	// 2s pressionando tecla
    localparam int REPETIR_02   		= 1000;	// 1s pressionando tecla
  	localparam int ACIONAMENTO_MAXIMO = 120;	// Máximos de pulsos para confirmar

  	// Declarando variáveis do design
    logic clk;
    logic rst;
    logic enable;

    logic [3:0] col_matriz;
    wire  [3:0] lin_matriz;

    digitosPac_t digitos_value;
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
            $display("\n================ RESET ================\n");

            rst = 1;
            key_pressed = 0;

            repeat(10) @(posedge clk);
            rst = 0;
            repeat(10) @(posedge clk);
        end
    endtask

    // PRESSIONAR TECLA
    task automatic pressionar_tecla(input logic [3:0] tecla);
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
            pressionar_tecla(tecla);
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

endmodule