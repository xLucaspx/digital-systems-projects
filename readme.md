# Projeto Tecnosenior: Detector de Fogão Ligado

- Lucas da Paz Oliveira;
- Rodrigo Miotto Slongo.

## TODO

Adicionando estrutura básica do projeto.

- [ ] **Utilizar apenas `posedge`**.

- [ ] Pesquisar protocolos de comunicação dos sensores;
  - [ ] Se necessário, buscar módulos prontos que implementam os protocolos utilizados.
- [ ] Escrever um módulo para a comunicação com cada sensor;
- [ ] Conectar os módulos dos sensores ao `TopNexysA7` e criar lógica de detecção de fogão ligado;
- [ ] Criar testbench para testar a lógica definida;
- [ ] Gerar bitstream e testar na placa;
- [ ] Ajustar documentação:
  - [ ] Revisar estrutura do projeto e respectivas descrições;
  - [ ] Descrever o testbench;
  - [ ] Adicionar forma de onda.

## Índice

- [Visão Geral](#visão-geral);
- [Estrutura do Projeto](#estrutura-do-projeto);
- [Simulação](#simulação);

## Visão Geral

Este trabalho tem como objetivo a implementação, em System Verilog, de um sistema para detecção de um fogão ligado. Para
isso serão utilizados sensores conectados a um FPGA (Nexys A7). Deve ser implementada a lógica de comunicação dos
sensores com a placa e a lógica de extração dos dados recebidos de cada sensor, combinando-os para decidir se o fogão
está ou não ligado e realizar uma ação, e.g., acender os leds da placa Nexys.

## Estrutura do Projeto

- [docs](./docs/): Documentação e enunciado do trabalho;
- [interface](./interface/): Interfaces;
- [rtl](./rtl/): Descrição de _hardware_;
- [sim](./sim/): _Testbenches_ e _scripts_ de simulação.

## Simulação

A forma mais tradicional de executar a simulação é acessar o diretório [**sim/**](./sim/) e executar o comando `vsim`
passando o arquivo [`sim.do`](./sim/sim.do):

```sh
cd ./sim/
vsim -do sim.do
```

Alternativamente, é possível utilizar os _scripts_ [`compile.sh`](./compile.sh) para compilar os arquivos fonte,
verificando se há erros ou _warnings_, e [`run.sh`](./run.sh) para executar a simulação. Estes _scripts_ devem ser
executados a partir do [**diretório raiz**](./).

> [!important]
> É imprescindível que cada comando seja rodado a partir do diretório especificado nesta documentação; caso contrário,
> o caminho dos códigos fontes e _scripts_ necessários para a execução não será encontrado. Se for executar diretamente
> o comando `vsim -do sim.do`, acesse o diretório [**sim/**](./sim/); caso deseje utilizar os _scripts_
> [`compile.sh`](./compile.sh) ou [`run.sh`](./run.sh), execute-os a partir do [**diretório raiz**](./).
