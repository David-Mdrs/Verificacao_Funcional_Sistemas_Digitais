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

### 1. Compilação
O Icarus Verilog exige a flag `-g2012` para habilitar os recursos modernos do SystemVerilog utilizados neste projeto.

```powershell
iverilog -g2012 -o simulacao.vvp design.sv testbench.sv
```

### 2. Execução da Simulação

Após a compilação bem-sucedida (que gera o arquivo compilado `simulacao.vvp` na sua pasta), o próximo passo é rodar a simulação de fato. 

Para iniciar o teste, execute o comando abaixo:

```powershell
vvp simulacao.vvp