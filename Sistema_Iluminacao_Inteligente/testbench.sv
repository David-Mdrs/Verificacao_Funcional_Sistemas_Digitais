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

  	task automatic teste_automatico_desligado_para_manual_desligado(int tempo_botao);
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Modo automático desligado para manual desligado com pushbutton >= 5305 clk (5s)");
            $display("-------------------------------------------------------------------------------");

          	// INPUTS
            preparar_estado_inicial(1'b0, 1'b0);	// Auto, Desl
                      
          	$display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b", led, saida);
          	$display("Tempo de pressionamento do botão: %0d\n", tempo_botao);
          
          	pressionar_botao(tempo_botao);
			
          	// Tempo de pressionamento Superado
          	if (tempo_botao >= 5300) begin
				$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
            	if (led == 1'b1 && saida == 1'b0) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	// Tempo de pressionamento Não superado
          	else begin
              	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 0");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
            	if (led == 1'b0 && saida == 1'b0) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
              
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask


  	task automatic teste_automatico_ligado_para_manual_desligado(int tempo_botao);
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
          	$display("Modo automático ligado para manual desligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");


          	// INPUTS
          	preparar_estado_inicial(1'b0, 1'b1);	// Auto, Lig
                      
          	$display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b", led, saida);
            $display("Tempo de pressionamento do botão: %0d\n", tempo_botao);
          
          	pressionar_botao(tempo_botao);

          	// Tempo de pressionamento Superado
          	if (tempo_botao >= 5300) begin
				$display("Saida esperada - led (modo): 1 | Saída (Lâmpada): 0");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
            	if (led == 1'b1 && saida == 1'b0) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	// Tempo de pressionamento Não superado
          	else begin
              	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
              	if (led == 1'b0 && saida == 1'b1) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask
  
  
  task automatic teste_manual_desligado_para_automatico_ligado(int tempo_botao);
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
            $display("Modo Manual Desligado para Automatico Ligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");

            // INPUTS
          	preparar_estado_inicial(1'b1, 1'b0);	// Man, Desl
          
            $display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b", led, saida);
          	$display("Tempo de pressionamento do botão: %0d\n", tempo_botao);

            pressionar_botao(tempo_botao);

          	// Tempo de pressionamento Superado
          	if (tempo_botao >= 5300) begin
              	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
              	if (led == 1'b0 && saida == 1'b1) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	// Tempo de pressionamento Não superado
          	else begin
              	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 0");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
              	if (led == 1'b0 && saida == 1'b0) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask

  
  	task automatic teste_manual_ligado_para_automatico_ligado(int tempo_botao);
		begin
          	$display("----------------------------- INÍCIO DO TESTE ---------------------------------");
            $display("Modo Manual Ligado para Automatico Ligado com pushbutton >= 5300 clk (5s)");
            $display("-------------------------------------------------------------------------------");

            // INPUTS
          	preparar_estado_inicial(1'b1, 1'b1);	// Man, Lig
          
            $display("Estado inicial - led (modo): %b | Saída (Lâmpada): %b", led, saida);
          	$display("Tempo de pressionamento do botão: %0d\n", tempo_botao);
          
          	pressionar_botao(tempo_botao);
          
          	// Tempo de pressionamento Superado
          	if (tempo_botao >= 5300) begin
              	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
              	if (led == 1'b0 && saida == 1'b1) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	// Tempo de pressionamento Não superado
          	else begin
              	$display("Saida esperada - led (modo): 0 | Saída (Lâmpada): 1");
				$display("Saida recebida - led (modo): %b | Saída (Lâmpada): %b", led, saida);
              
              	if (led == 1'b0 && saida == 1'b1) $display("Resultado: PASSOU");
            	else begin
                  	$display("Resultado: FALHOU");
                  	$error;
                end
        	end
          
          	$display("------------------------------- FIM TESTE -------------------------------------\n\n");
		end
	endtask

  
	// ============ EXECUÇÃO DOS TESTES ============
  
  	int tempo_pressionamento_sorteado;
  
	initial begin
		clk = 0;
		repeat(15) @(posedge clk); 
      
      	tempo_pressionamento_sorteado = $urandom_range(310, 10350);

		teste_automatico_desligado_para_manual_desligado(tempo_pressionamento_sorteado);
		teste_automatico_ligado_para_manual_desligado(tempo_pressionamento_sorteado);      // Não passou (Bug do Infra)

      	teste_manual_desligado_para_automatico_ligado(tempo_pressionamento_sorteado);
      	teste_manual_ligado_para_automatico_ligado(tempo_pressionamento_sorteado);

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