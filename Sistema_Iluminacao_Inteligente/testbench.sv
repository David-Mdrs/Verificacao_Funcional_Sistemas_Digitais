// ============ MODELO INICIAL DADO PELO PROFESSOR ============

`timescale 1ns/1ps

module tb;

	logic clk, rst;
	logic push_button, infravermelho;
	logic led, saida;

	always #1 clk = ~clk;  // clock de 2ns período (500 MHz)
  	initial clk = 0;	   // Trecho faltante  

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


  
// ================== FUNÇÕES AUXILIARES ===================

	function automatic logic [1:0] prever_botao(int tempo_pressionamento, logic led_ini, logic saida_ini);
		// Tempo inválido (<300)
		if (tempo_pressionamento < 300)
			return {led_ini, saida_ini};	// Mantém o estado

		// Tempo de pressionamento longo (>=5300)
		if (tempo_pressionamento >= 5300) begin
			if (led_ini == 1'b0)		// Automático (0) para:
				return {1'b1, 1'b0};	// Manual (1) desligado (0)
			else						// Manual (1) para:
				return {1'b0, 1'b1};	// Automático (0) ligado (1)
		end

		// Tempo de pressionamento curto (>=300 e <5300)
		else begin
			if (led_ini == 1'b1) 					// Se no modo Manual (1)
				return {led_ini, ~saida_ini}; 		// Inverte a Lâmpada
			else									// Se no modo Automático (0)
				return {led_ini, saida_ini};  		// Ignora o botão
		end
	endfunction

	function automatic logic [1:0] prever_infra(int infra_ativo, int infra_tempo, logic led_ini, logic saida_ini);

		// Modo Automático (0)
		if (led_ini == 1'b0) begin
			if (infra_ativo == 1) 			// Se Infra ativar (1)
				return {1'b0, 1'b1}; 		// Automático (0) ligado (1)

			else begin						// Se Infra desativar (0)
				if (infra_tempo >= 30000)		// Durante 30s
					return {1'b0, 1'b0}; 		// Automático (0) desligado (0)
				else							// Menos de 30s
					return {1'b0, saida_ini}; 	// Automático (0) e mantém Lâmpada
			end
		end

		// Modo Manual (1)
		return {led_ini, saida_ini};	// Infra não causa efeito

	endfunction



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

  
  
  	// ============ GERADOR DE SINAIS DO INFRAVERMELHO E BOTÃO ALEATORIAMENTE ============
  
  	int fim_teste = 0;
  
  	int tempo_infra;
  
	initial begin
      	while(!fim_teste) begin
          
      		// Tempo em nível lógico alto
      		tempo_infra = $urandom_range(30, 1000);
			infravermelho = 1;
			repeat(tempo_infra) @(posedge clk);

      		// Tempo em nível lógico baixo
      		tempo_infra = $urandom_range(1, 120000);
			infravermelho = 0;
			repeat(tempo_infra) @(posedge clk);	
          
        end
  	end
  
  
  	int tempo_botao;
  
	initial begin
      	while(!fim_teste) begin
          
      		// Tempo em nível lógico alto
      		tempo_botao = $urandom_range(310, 10350);
			push_button = 1;
			repeat(tempo_botao) @(posedge clk);

      		// Tempo em nível lógico baixo
      		tempo_botao = $urandom_range(500, 2000);
			push_button = 0;
      		repeat(tempo_botao) @(posedge clk);	
        
        end
  	end


  
	// ======================== EXECUÇÃO DOS MONITORAMENTOS E TESTES ========================
    
	int cobertura_atingida = 0;  
  
  	// MONITORADOR DE SINAIS DO BOTÃO
	initial begin
      
      	logic led_ini, saida_ini;	// Visualizar estado inicial do sistema
		logic led_esp, saida_esp;	// Gabarito para saber estado esperado
		int contador_btn;
		
      	// Espera a task resetar() terminar
		repeat(15) @(posedge clk); 

		while (!fim_teste) begin
			@(posedge push_button);
			
			// Atualizando estado inicial do sistema
			led_ini = led;
			saida_ini = saida;
			
			contador_btn = 0;

			// Conta os clocks enquanto o botão estiver pressionado
			while (push_button == 1'b1) begin
				@(posedge clk);
				contador_btn++;
			end
			
          	// Localizar estado esperado com base no "tempo do botão" e "estado atual"
          	{led_esp, saida_esp} = prever_botao(contador_btn, led_ini, saida_ini);
			repeat(5) @(posedge clk);

			// Monitoramento de estados
			if (contador_btn >= 300) begin
				$display("\n-------------------------------------------------------------------------------");
				if (contador_btn >= 5300)
					$display("EVENTO: Pushbutton pressionado por tempo LONGO (%0d ciclos)", contador_btn);
				else
					$display("EVENTO: Pushbutton pressionado por tempo CURTO (%0d ciclos)", contador_btn);
				$display("-------------------------------------------------------------------------------");
				
				$display("Tempo atual: %0t", $time);
              	$display("Estado inicial - led: %s | Saída: %s | Infra: %b",
                        (led_ini ? "Manual" : "Automático"), (saida_ini ? "Desligado" : "Ligado"), infravermelho);
              
              	$display("Saida esperada - led: %s | Saída: %s | Infra: %b",
                        (led_esp ? "Manual" : "Automático"), (saida_esp ? "Desligado" : "Ligado"), infravermelho);
              
              	$display("Saida recebida - led: %s | Saída: %s | Infra: %b",
                       	(led ? "Manual" : "Automático"), (saida ? "Desligado" : "Ligado"), infravermelho);

				// Após o sinal do botão
              	if ({led, saida} === {led_esp, saida_esp}) begin	// Restultado igual o esperado
                  	$display("Resultado do teste: PASSOU");			// Passou!
				end else begin										// Restultado diferente do esperado
                  	$display("Resultado do teste: FALHOU\n");		// Falha!
                  	$fatal();
				end
				$display("------------------------------- FIM TESTE -------------------------------------\n");
			end
		end
	end
  
  
    // MONITORADOR DE SINAIS DO SENSOR INFRAVERMELHO
  
  	initial begin
      	// ----- CÓDIGO DE MONITORAMENTO AQUI -----
    end

  
  
	initial begin
		// Inicializando sistema da placa
		resetar();
		
      	// LEMBRAR DE MUDAR PARA (cobertura_atingida == 4) PARA FINALIZAR TESTE
		repeat(1000000) @(posedge clk);
		
		// Teste de cobertura concluído
		fim_teste = 1;
		
		$display("\n===============================================================");
		$display("            SIMULAÇÃO FINALIZADA COM SUCESSO!                  ");
		$display("===============================================================\n");
		$finish;
	end
  
endmodule