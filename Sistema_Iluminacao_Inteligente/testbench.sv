// ---------- TASKS DE TESTES SENDO CHAMADAS AO FIM DO MÓDULO ----------

// ============ MODELO INICIAL DADO PELO PROFESSOR ============

`timescale 1ns/1ps

module tb;

	logic clk, rst;
	logic push_button, infravermelho;
	logic led, saida;

	always #1 clk = ~clk;  // clock de 2ns período (500 MHz)

	// DUT
	controladora #(
		.DEBOUNCE_P(300),
		.SWITCH_MODE_MIN_T(5300),
		.AUTO_SHUTDOWN_T(30000)
	) dut (
		.clk(clk),
		.rst(rst),
		.infravermelho(infravermelho),
		.push_button(push_button),
		.led(led),
		.saida(saida)
	);

  
  
// ============ INÍCIO DOS TESTES SOLICITADOS ============

	// Transição do Modo Automático Desligado para Modo Manual
  	task teste_automatico_desligado_para_manual_sucesso();
		begin
          	$display("\n-------------------------------------------------------------------------------");
          	$display("Modo automático desligado para manual desligado com pushbutton >= 5305 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 0;
          	push_button = 0;
			#5
          
          	rst = 0; 
			@(posedge clk);
			#1
          
			push_button = 1;
          	repeat(5305) @(posedge clk);
			#1
         
			push_button = 0;
			repeat(10) @(posedge clk);
			#1

			// OUTPUTS
			$display("Tempo atual: %0t", $time);
			$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

			if (led == 1'b1 && saida == 1'b0)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
              
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask

    task teste_automatico_desligado_para_manual_falha();
		begin
          	$display("\n-------------------------------------------------------------------------------");
          	$display("Modo automático desligado para manual desligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 0;
          	push_button = 0;
			#5
          
          	rst = 0; 
			@(posedge clk);
			#1
          
			push_button = 1;
          	repeat(4999) @(posedge clk);
			#1
         
			push_button = 0;
			repeat(10) @(posedge clk);
			#1

			// OUTPUTS
			$display("Tempo atual: %0t", $time);
          	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 0");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

          	if (led == 1'b0 && saida == 1'b0)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask

	// Transição do Modo Automático Ligado para Modo Manual
    task teste_automatico_ligado_para_manual_sucesso();
		begin
          	$display("\n-------------------------------------------------------------------------------");
          	$display("Modo automático ligado para manual desligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 1;
          	push_button = 0;
			#5
          
          	rst = 0; 
			@(posedge clk);
			#1
          
			push_button = 1;
          	repeat(5305) @(posedge clk);
			#1
         
			push_button = 0;
			repeat(10) @(posedge clk);
			#1

			// OUTPUTS
			$display("Tempo atual: %0t", $time);
          	$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

          	if (led == 1'b1 && saida == 1'b0)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask
  
    task teste_automatico_ligado_para_manual_falha();
		begin
          	$display("\n-------------------------------------------------------------------------------");
          	$display("Modo automático ligado para manual desligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 1;
          	push_button = 0;
			#5
          
          	rst = 0; 
			@(posedge clk);
			#1
          
			push_button = 1;
          	repeat(4999) @(posedge clk);
			#1
         
			push_button = 0;
			repeat(10) @(posedge clk);
			#1

			// OUTPUTS
			$display("Tempo atual: %0t", $time);
          	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

          	if (led == 1'b0 && saida == 1'b1)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask
  
  
  
  	// Transição do Modo Manual Desligado para Modo Automático
    task teste_manual_desligado_para_automatico_sucesso();
		begin
          	$display("\n-------------------------------------------------------------------------------");
            $display("Modo Manual Desligado para Automatico Ligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 0;
          	push_button = 0;
			#5
              
          	rst = 0; 
			@(posedge clk);
            #1
              
			push_button = 1;
            repeat(5305) @(posedge clk);
			#1
            push_button = 0;
			repeat(10) @(posedge clk);
			#1
          
          	infravermelho = 1;
          	repeat(10) @(posedge clk);
          	#1
              
			push_button = 1;
            repeat(5305) @(posedge clk);
			#1
         
			push_button = 0;
            repeat(10) @(posedge clk);
			#1

			// OUTPUTS
			$display("Tempo atual: %0t", $time);
            $display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

            if (led == 1'b0 && saida == 1'b1)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask


  task teste_manual_desligado_para_automatico_falha();
		begin
          	$display("\n-------------------------------------------------------------------------------");
          	$display("Manual Desligado para Automatico Ligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 0;
          	push_button = 0;
			#5
              
          	rst = 0; 
			@(posedge clk);
            #1
              
			push_button = 1;
            repeat(5305) @(posedge clk);
			#1
            push_button = 0;
			repeat(10) @(posedge clk);
			#1
          
            infravermelho = 1;
          	repeat(10) @(posedge clk);
          	#1
              
			push_button = 1;
          	repeat(4999) @(posedge clk);
			#1
         
			push_button = 0;
            repeat(10) @(posedge clk);
			#1

			// OUTPUTS
			$display("Tempo atual: %0t", $time);
          	$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 1");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

          	if (led == 1'b1 && saida == 1'b1)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask
  
  	// Transição do Modo Manual Ligado para Modo Automático
   	task teste_manual_ligado_para_automatico_sucesso();
		begin
          	$display("\n-------------------------------------------------------------------------------");
            $display("Modo Manual Ligado para Automatico Ligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 1;
          	push_button = 0;
			#5
          
          	rst = 0; 
			@(posedge clk);
			#1
          
			push_button = 1;
          	repeat(5305) @(posedge clk);
			#1
			push_button = 0;
			repeat(10) @(posedge clk);
			#1
          
			push_button = 1;
          	repeat(305) @(posedge clk);
			#1
			push_button = 0;
            repeat(10) @(posedge clk);
			#1
          
			push_button = 1;
          	repeat(5305) @(posedge clk);
			#1
			push_button = 0;
			repeat(10) @(posedge clk);
			#1
          
			// OUTPUTS
			$display("Tempo atual: %0t", $time);
            $display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

            if (led == 1'b0 && saida == 1'b1)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask
  
    task teste_manual_ligado_para_automatico_falha();
		begin
          	$display("\n-------------------------------------------------------------------------------");
            $display("Modo Manual Ligado para Automatico Ligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
			rst = 1;
          	infravermelho = 0;
          	push_button = 0;
			#5
          
          	rst = 0; 
			@(posedge clk);
			#1
          
			push_button = 1;
          	repeat(5305) @(posedge clk);
			#1
			push_button = 0;
			repeat(10) @(posedge clk);
			#1
          
            infravermelho = 1;
          	repeat(10) @(posedge clk);
          	#1
          
			push_button = 1;
          	repeat(305) @(posedge clk);
			#1
			push_button = 0;
            repeat(10) @(posedge clk);
			#1
          
			push_button = 1;
            repeat(4999) @(posedge clk);
			#1
			push_button = 0;
			repeat(10) @(posedge clk);
			#1
          
			// OUTPUTS
			$display("Tempo atual: %0t", $time);
          	$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

          	if (led == 1'b1 && saida == 1'b0)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n");
		end
	endtask

  
// ============ EXECUÇÃO E ANÁLISE DOS TESTES ============
	initial begin
		clk = 0;

      	teste_automatico_desligado_para_manual_sucesso();
      	teste_automatico_desligado_para_manual_falha();
      	teste_automatico_ligado_para_manual_sucesso();		// Não passou
      	teste_automatico_ligado_para_manual_falha();
      
      	teste_manual_desligado_para_automatico_sucesso();
      	teste_manual_desligado_para_automatico_falha();		// Não passou
      	teste_manual_ligado_para_automatico_sucesso();
        teste_manual_ligado_para_automatico_falha();		// Não passou

		#100 $finish;
	end
  
// ============ RESUMO DOS PROBLEMAS ENCONTRADOS ============
// Transição do Automático Desligado para o Manual Desligado 	de forma correta (5s)
// Transição do Manual Desligado para o Automático Ligado 		de forma incorreta (<5s)
// Transição do Manual Ligado para o Automático Ligado 			de forma incorreta (<5s)
  
endmodule
