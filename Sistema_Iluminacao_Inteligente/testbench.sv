// TESTBENCH AUTOMATIZADO: 		Injeção contínua de sinais aleatórios no sistema
// VERIFICAÇÃO DE COBERTURA: 	Monitoramento exato dos 4 estados operacionais
// CRITÉRIO DE TÉRMINO: 		Cobertura 100% atingida combinada com 50 testes executados

// ALUNOS: David Medeiros e João Gabriel Tavares

// ============ MODELO INICIAL DADO PELO PROFESSOR ============

`timescale 1ns/1ps

module tb;

	logic clk, rst;
	logic push_button, infravermelho;
	logic led, saida;

	always #1 clk = ~clk;  // clock de 2ns período (500 MHz)
	
	// Inicialização completa para evitar sinais 'X' no início
	initial begin
		clk = 0;
		rst = 0;
		push_button = 0;
		infravermelho = 0;
	end

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

  	// Retorna a previsão de qual estado deve ir com base no botão
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

  	// Retorna a previsão de qual estado deve ir com base no infravermelho
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
	int quantidade_testes = 0;
  
  	// Gerador de sinais infravermelho
  	int tempo_infra;
  
	initial begin
      	while(!fim_teste) begin
          
      		// Tempo em nível lógico alto
      		tempo_infra = $urandom_range(30, 1000);
			infravermelho = 1;
			repeat(tempo_infra) @(posedge clk);
          	quantidade_testes++;

      		// Tempo em nível lógico baixo
      		tempo_infra = $urandom_range(1, 120000);
			infravermelho = 0;
			repeat(tempo_infra) @(posedge clk);
          	quantidade_testes++;
          
        end
  	end
  
  
  	// Gerador de sinais do botão
  	int tempo_botao;
  
	initial begin
      	while(!fim_teste) begin
          
      		// Tempo em nível lógico alto
      		tempo_botao = $urandom_range(310, 10350);
			push_button = 1;
			repeat(tempo_botao) @(posedge clk);
          	quantidade_testes++;

      		// Tempo em nível lógico baixo
      		tempo_botao = $urandom_range(500, 2000);
			push_button = 0;
      		repeat(tempo_botao) @(posedge clk);	
        
        end
  	end


  
  	// ======================== EXECUÇÃO DOS MONITORAMENTOS E TESTES ========================
  
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
                        (led_ini ? "Manual" : "Automático"), (saida_ini ? "Ligado" : "Desligado"), infravermelho);
              
              	$display("Saida esperada - led: %s | Saída: %s | Infra: %b",
                        (led_esp ? "Manual" : "Automático"), (saida_esp ? "Ligado" : "Desligado"), infravermelho);
              
              	$display("Saida recebida - led: %s | Saída: %s | Infra: %b",
                       	(led ? "Manual" : "Automático"), (saida ? "Ligado" : "Desligado"), infravermelho);

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
  
  
  	// MONITORADOR DE SINAIS DO SENSOR INFRAVERMELHO (Ligado e Desligado)
	initial begin
      
		logic led_ini, saida_ini;	// Visualizar estado inicial do sistema
		logic led_esp, saida_esp;	// Gabarito para saber estado esperado
		int contador_infra;
		
		// Espera a task resetar() terminar
		repeat(15) @(posedge clk); 

		while (!fim_teste) begin
			
			// ================= FASE 1: ATIVADO =================
          
          	// Aguarda até que o infra ative (1)
			if (infravermelho == 1'b0) begin
				@(posedge infravermelho);
			end
			
			// Atualizando estado inicial do sistema
			led_ini = led;
			saida_ini = saida;
			
			// Localiza estado esperado
			{led_esp, saida_esp} = prever_infra(1, 0, led_ini, saida_ini);
			repeat(5) @(posedge clk); // Espera processamento

			$display("\n-------------------------------------------------------------------------------");
			$display("EVENTO: Sensor Infravermelho ATIVADO (Movimento detectado)");
			$display("-------------------------------------------------------------------------------");
			$display("Tempo atual: %0t", $time);
			$display("Estado inicial - led: %s | Saída: %s | Infra: %b", (led_ini ? "Manual" : "Automático"), (saida_ini ? "Ligado" : "Desligado"), 1'b1);
			$display("Saida esperada - led: %s | Saída: %s | Infra: %b", (led_esp ? "Manual" : "Automático"), (saida_esp ? "Ligado" : "Desligado"), 1'b1);
			$display("Saida recebida - led: %s | Saída: %s | Infra: %b", (led ? "Manual" : "Automático"), (saida ? "Ligado" : "Desligado"), 1'b1);

			if ({led, saida} === {led_esp, saida_esp}) begin	
				$display("Resultado do teste: PASSOU");			
			end else begin										
				$display("Resultado do teste: FALHOU\n");		
				$fatal();
			end
			$display("------------------------------- FIM TESTE -------------------------------------\n");

			// ================= FASE 2: INATIVO =================
          
          	// Aguarda até que o infra desative (0)
			if (infravermelho == 1'b1) begin
				@(negedge infravermelho);
			end
			
			led_ini = led;
			saida_ini = saida;
			contador_infra = 0;

			// Conta os clocks enquanto o ambiente estiver vazio
			while (infravermelho == 1'b0) begin
				@(posedge clk);
				contador_infra++;
				
				// Verifica a lâmpada EXATAMENTE no ciclo 30.000
				if (contador_infra == 30000) begin
					{led_esp, saida_esp} = prever_infra(0, contador_infra, led_ini, saida_ini);
					repeat(5) @(posedge clk); 
					
					$display("\n-------------------------------------------------------------------------------");
					$display("EVENTO: Sensor Infravermelho INATIVO por 30s (Contagem atingiu 30000)");
					$display("-------------------------------------------------------------------------------");
					$display("Tempo atual: %0t", $time);
					$display("Estado inicial - led: %s | Saída: %s | Infra: %b", (led_ini ? "Manual" : "Automático"), (saida_ini ? "Ligado" : "Desligado"), 1'b0);
					$display("Saida esperada - led: %s | Saída: %s | Infra: %b", (led_esp ? "Manual" : "Automático"), (saida_esp ? "Ligado" : "Desligado"), 1'b0);
					$display("Saida recebida - led: %s | Saída: %s | Infra: %b", (led ? "Manual" : "Automático"), (saida ? "Ligado" : "Desligado"), 1'b0);

					if ({led, saida} === {led_esp, saida_esp}) begin	
						$display("Resultado do teste: PASSOU");			
					end else begin										
						$display("Resultado do teste: FALHOU\n");		
						$fatal();
					end
					$display("------------------------------- FIM TESTE -------------------------------------\n");
				end
			end 
			// Quando o loop while encerra, significa que o infra subiu para 1 novamente.
			// O outer loop volta pro começo e processa a FASE 1 imediatamente!
		end
	end
  
  
  
  	// ======================== MONITORAMENTO DE COBERTURA ========================
  
	int cobertura_atingida = 0;  
	bit cob_00 = 0, cob_01 = 0, cob_10 = 0, cob_11 = 0;

	// Bloco dedicado para monitorar continuamente os 4 estados atingidos
	always @(posedge clk) begin
		logic led_ini;
		logic saida_ini;
		
		led_ini = led;
		saida_ini = saida;

      	// Estado 00: Modo Automático (0) e Lâmpada Desligada (0)
		if (led_ini == 1'b0 && saida_ini == 1'b0 && cob_00 == 0) begin
			cob_00 = 1;
			cobertura_atingida++;
			$display("\n[COBERTURA] Estado 00 (Automático/Desligado) atingido! Progresso: %0d/4", cobertura_atingida);
		end
		
      // Estado 01: Modo Automático (0) e Lâmpada Ligada (1)
		if (led_ini == 1'b0 && saida_ini == 1'b1 && cob_01 == 0) begin
			cob_01 = 1;
			cobertura_atingida++;
			$display("\n[COBERTURA] Estado 01 (Automático/Ligado) atingido! Progresso: %0d/4", cobertura_atingida);
		end
		
      // Estado 10: Modo Manual (1) e Lâmpada Desligada (0)
		if (led_ini == 1'b1 && saida_ini == 1'b0 && cob_10 == 0) begin
			cob_10 = 1;
			cobertura_atingida++;
			$display("\n[COBERTURA] Estado 10 (Manual/Desligado) atingido! Progresso: %0d/4", cobertura_atingida);
		end
		
      // Estado 11: Modo Manual (1) e Lâmpada Ligada (1)
		if (led_ini == 1'b1 && saida_ini == 1'b1 && cob_11 == 0) begin
			cob_11 = 1;
			cobertura_atingida++;
			$display("\n[COBERTURA] Estado 11 (Manual/Ligado) atingido! Progresso: %0d/4", cobertura_atingida);
		end
	end
  
  
 	
    // ======================== MONITORAMENTO DE TÉRMINO DO PROGRAMA ========================
	initial begin
		// Inicializando sistema da placa
		resetar();
		
		// Finaliza o programa apenas quando atingir os 4 estados
      	wait(cobertura_atingida == 4 && quantidade_testes == 50);
		repeat(100) @(posedge clk); 	// Espera uma pequena margem de segurança
		
		// Teste de cobertura concluído
		fim_teste = 1;
		
		$display("\n===============================================================");
		$display("            SIMULAÇÃO FINALIZADA COM SUCESSO!                  ");
		$display("        Todos os 4 estados de cobertura foram atingidos!       ");
		$display("===============================================================\n");
		$finish;
	end
  
	// BLOCO PARA GERAÇÃO DE ONDAS DO GTKWAVE
    initial begin
        $dumpfile("simulacao.vcd"); // Nome do arquivo que será gerado
        $dumpvars(0, tb);           // Pega todas as variáveis dentro do módulo 'tb'
    end

endmodule