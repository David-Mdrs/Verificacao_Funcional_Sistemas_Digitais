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


  
// ================== TASKS AUXILIARES ===================
  
  	task automatic resetar();
    	begin
          	$display("\n=============================== SISTEMA RESETADO ===============================\n");
          
          	rst = 1;
          	repeat(5) @(posedge clk);
          
            rst = 0;
          	repeat(5) @(posedge clk);	
        end
    endtask
  
  	task automatic pressionar_botao(int tempo);
    	begin
          	push_button = 1;
          	repeat(tempo) @(posedge clk);
         
			push_button = 0;
			repeat(10) @(posedge clk);          
        end
  	endtask

	task automatic preparar_estado_inicial(bit led_alvo, bit saida_alvo);
        begin
			// Analisando modo
			if (led != led_alvo) begin
				infravermelho <= 0; // RETIRANDO BUG
				repeat(5) @(posedge clk);
				pressionar_botao(5305);
			end

			// Analisando lâmpada
			if (saida != saida_alvo) begin

              	if (led_alvo == 1)	// Manual
                  	pressionar_botao(305);
              
				else begin 			// Automático
                  if (saida_alvo == 1) begin	// Alvo: Aceso
						infravermelho <= 1;
						repeat(10) @(posedge clk);
					end 
					else begin					// Alvo: Desligado
						infravermelho <= 0;
						repeat(30005) @(posedge clk);
					end
				end
			end
		end
	endtask
  
// ============ INÍCIO DOS TESTES SOLICITADOS ============

	// Transição do Modo Automático Desligado para Modo Manual
  	task automatic teste_automatico_desligado_para_manual_sucesso();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Modo automático desligado para manual desligado com pushbutton >= 5305 clk (5s)");
            $display("-------------------------------------------------------------------------------");

          	// INPUTS
            preparar_estado_inicial(1'b0, 1'b0);	// Auto, Desl
                      
          	$display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);
          
          	pressionar_botao(5305);

			// OUTPUTS
			$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

			if (led == 1'b1 && saida == 1'b0)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
              
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask

    task automatic teste_automatico_desligado_para_manual_falha();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Modo automático desligado para manual desligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");

            // INPUTS
            preparar_estado_inicial(1'b0, 1'b0);	// Auto, Desl
                      
          	$display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);
          
          	pressionar_botao(4999);

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
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask

	// Transição do Modo Automático Ligado para Modo Manual
    task automatic teste_automatico_ligado_para_manual_sucesso();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Modo automático ligado para manual desligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
          	preparar_estado_inicial(1'b0, 1'b1);	// Auto, Lig
                      
          	$display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);
          
          	pressionar_botao(5305);

			// OUTPUTS
          	$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
			$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);

          	if (led == 1'b1 && saida == 1'b0)
              	$display("Resultado do teste: PASSOU");
			else begin
                $display("\n");
               	$error;
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask
  
    task automatic teste_automatico_ligado_para_manual_falha();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Modo automático ligado para manual desligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
            preparar_estado_inicial(1'b0, 1'b1);	// Auto, Lig
                      
          	$display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);
          
          	pressionar_botao(4999);

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
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask
  
  
  
  	// Transição do Modo Manual Desligado para Modo Automático
    task automatic teste_manual_desligado_para_automatico_sucesso();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
            $display("Modo Manual Desligado para Automatico Ligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");

            // INPUTS
          	preparar_estado_inicial(1'b1, 1'b0);	// Man, Desl
          
            $display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);

            pressionar_botao(5305);

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
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask


  task automatic teste_manual_desligado_para_automatico_falha();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Manual Desligado para Automatico Ligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");
            
          	// INPUTS
            preparar_estado_inicial(1'b1, 1'b0);	// Man, Desl
          
            $display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);

            pressionar_botao(4999);

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
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask
  
  	// Transição do Modo Manual Ligado para Modo Automático
   	task automatic teste_manual_ligado_para_automatico_sucesso();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
            $display("Modo Manual Ligado para Automatico Ligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");

            // INPUTS
          	preparar_estado_inicial(1'b1, 1'b1);	// Man, Lig
          
            $display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);
          
            pressionar_botao(5305);
          
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
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask
  
    task automatic teste_manual_ligado_para_automatico_falha();
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
            $display("Modo Manual Ligado para Automatico Ligado com pushbutton < 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");

            // INPUTS
            preparar_estado_inicial(1'b1, 1'b1);	// Man, Lig
          
            $display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b\n", led, saida);
          
          	pressionar_botao(4999);
          
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
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask

  
	// ============ EXECUÇÃO DOS TESTES ============
	initial begin
		clk = 0;
		repeat(15) @(posedge clk); 

		teste_automatico_desligado_para_manual_sucesso();
		teste_automatico_desligado_para_manual_falha();
		teste_automatico_ligado_para_manual_sucesso();      // Não passou (Bug do Infra)
		teste_automatico_ligado_para_manual_falha();

		teste_manual_desligado_para_automatico_sucesso();
		teste_manual_desligado_para_automatico_falha();
		teste_manual_ligado_para_automatico_sucesso();
		teste_manual_ligado_para_automatico_falha();

		repeat(100) @(posedge clk); 
    
		$finish;
	end

	// ============ BLOCO DE RESETS ALEATÓRIOS ============
  
  	initial begin
    	resetar();	// Reset inicial do sistema

      	repeat(30000) @(posedge clk);	// DEVE SER ALEATÓRIO!
    	resetar();
  	end
  
	// ============ RESUMO DOS PROBLEMAS ENCONTRADOS ============
	// Transição do Automático Desligado para o Manual Desligado 	de forma correta (5s)

endmodule