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


  
// ================== FUNÇÕES AUXILIARES ===================
  
	function automatic logic [1:0] estado_atual();
      	return {led, saida};
	endfunction

  	function automatic logic [1:0] prever_botao(int tempo_pressionamento);
			
      	logic led_atual, saida_atual;
      	{led_atual, saida_atual} = estado_atual();
   	
      	// Tempo inválido (<300)
		if (tempo_pressionamento < 300)
          return {led_atual, saida_atual};	// Mantém o estado
      
      	// Tempo de pressionamento longo (>=5300)
      	if (tempo_pressionamento >= 5300) begin
      
          	if (led_atual == 1'b0)		// Automático (0) para:
              	return {1'b1, 1'b0};	// Manual (1) desligado (0)
          
          	else						// Manual (1) para:
              	return {1'b0, 1'b1};	// Automático (0) ligado (1)
      	end

      // Tempo de pressionamento curto (>=300 e <5300)
      	else begin
          	if (led_atual == 1'b1) 					// Se no modo Manual (1)
              	return {led_atual, ~saida_atual}; 	// Inverte a Lâmpada
          
          	else									// Se no modo Automático (0)
              	return {led_atual, saida_atual};  	// Ignora o botão
        end
      
	endfunction
  
  	function automatic logic [1:0] prever_infra(int infra_ativo, int infra_tempo);
		
      	logic led_atual, saida_atual;
      	{led_atual, saida_atual} = estado_atual();

      	// Modo Automático (0)
    	if (led_atual == 1'b0)
          	if (infra_ativo == 1) 		// Se Infra ativar (1)
              	return {1'b0, 1'b1}; 	// Automático (0) ligado (1)
      
      		else begin						// Se Infra desativar (0)
              	if (infra_tempo >= 30000)	// Durante 30s
                  	return {1'b0, 1'b0}; 	// Automático (0) desligado (0)
              
				else							// Menos de 30s
                  return {1'b0, saida_atual}; 	// Automático (0) e mantém Lâmpada
			end
      
      	// Modo Manual (1)
      	return {led_atual, saida_atual};	// Infra não causa efeito
      
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

  
  
  	// ============ SENSOR INFRAVERMELHO E PUSH_BUTTON ALEATÓRIO ============
  
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


  
// ============ EXECUÇÃO DOS TESTES ============
    
 int cobertura_atingida = 0;
	int fim_teste = 0;
  
	initial begin
			resetar();
			
  			// CÓDIGO DE MONITORAMENTO
  
      	$finish;
	end
  
endmodule