# Sistema de Iluminação Inteligente - Verificação Funcional

Este projeto consiste na implementação e verificação funcional de um **Sistema de Iluminação Inteligente** utilizando SystemVerilog. O sistema utiliza sensores infravermelhos e botões para alternar entre modos manual e automático, otimizando o consumo de energia.

## 🛠️ Ferramentas Necessárias

* **Icarus Verilog**: Compilador e simulador (Versão estável com suporte a IEEE 1800-2012).
* **GTKWave** (Opcional): Para visualização de formas de onda (vcd).
* **VS Code**: Editor recomendado.

## 📁 Estrutura do Projeto

* `design.sv`: Contém o código do módulo `controladora` (DUT - Device Under Test).
* `testbench.sv`: Testbench automatizado com injeção de sinais aleatórios e monitoramento de cobertura de estados.

## 🚀 Como Executar

Para rodar a simulação no seu terminal (PowerShell ou CMD), siga os passos abaixo:

### 1. Compilar
Gera o executável da simulação ativando os recursos do SystemVerilog:
```powershell
iverilog -g2012 -o simulacao.vvp design.sv testbench.sv
```

### 2. Simular
Roda os testes automatizados, exibe os logs no terminal e gera o arquivo de ondas (simulacao.vcd):

```PowerShell
vvp simulacao.vvp
```

### 3. Visualizar (GTKWave)
Abre o visualizador para análise gráfica do circuito no tempo:

```PowerShell
gtkwave simulacao.vcd
```