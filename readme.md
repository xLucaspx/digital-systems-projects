# Projeto Tecnosenior: Detector de Fogão Ligado

- Lucas da Paz Oliveira;
- Rodrigo Miotto Slongo.

## Índice

- [Visão geral](#visão-geral);
- [Estrutura do projeto](#estrutura-do-projeto);
- [Equipamentos utilizados](#equipamentos-utilizados);
- [Especificações técnicas](#especificações-técnicas);
- [Detecção e simulação](#detecção-e-simulação);

## Visão geral

Este trabalho tem como objetivo a implementação, em System Verilog, de um sistema para detecção de um fogão ligado. Para
isso serão utilizados sensores conectados a um FPGA (Nexys A7). Deve ser implementada a lógica de comunicação dos
sensores com a placa e a lógica de extração dos dados recebidos de cada sensor, combinando-os para decidir se o fogão
está ou não ligado e realizar uma ação, e.g., acender os leds da placa Nexys.

## Estrutura do projeto

- [docs](./docs/): Documentação e enunciado do trabalho;
- [interface](./interface/): Interfaces;
- [rtl](./rtl/): Descrição de _hardware_;
- [sim](./sim/): _Testbenches_ e _scripts_ de simulação.

## Equipamentos utilizados

- Placa Nexys A7 (FPGA Artix 7);
	- Sensor de temperatura da placa Nexys A7.
- Sensor de gás CO2 (FC-22 + MG811);
- Sensor de chama (KY-026);
- _Buzzer_;
- Conversor de nível lógico (5V <-> 3.3V).

## Especificações técnicas

O _clock_ da placa foi definido com período igual a 10 ns (100 MHz). O sinal de _reset_ é alto (`1`).

Além do sensor de temperatura, LEDs e _displays_, foram utilizados os seguintes recursos da placa Nexys A7:

- `N17`: Botão de _reset_;
- `V10`: _Switch_ para ativar modo de simulação;
- `U11`: _Switch_ para aumentar a temperatura ("ligar o fogão") no modo de simulação;
- `AD10N`: Pino de dados conectado ao sensor de CO2;
- `AD11P`: Pino de dados conectado ao sensor de chama;
- `AD3P`: Pino conectado ao _buzzer_.

## Detecção e simulação

A detecção de fogão ligado ocorre com a combinação de 3 sensores: temperatura, CO2 e chama. Se a temperatura aumenta em
uma taxa predefinida, acima de um _threshold_ é possível inferir que o fogão está ligado. Depois de um certo tempo, a
temperatura pode estabilizar; neste momento os outros sensores servem para aumentar a assertividade da detecção: Se
houver chama e/ou detecção de CO2 acima de uma faixa estabelecida, considera-se que o fogão continua ligado; caso
contrário, ou caso a temperatura comece a decair a uma taxa predefinida, considera-se o fogão desligado.

Foi desenvolvido um modo de simulação para facilitar o teste. Ao ativar a simulação, é possível aumentar a temperatura
ao "ligar o fogão" (ativar um _switch_ da placa) e verificar o comportamento de detecção; do mesmo modo, ao desligar o
_switch_, a temperatura deve cair e isso deve ser refletido no comportamento da placa. Também é possível "forçar" dados
nos sensores (e.g., colocar luz no sensor de chama) para gerar diferentes situações de detecção.

O _testbench_ foi utilizado para verificar se a lógica programada para os sensores estava funcional e se comportando
conforme o esperado. A forma mais tradicional de executar o _testbench_ é acessar o diretório [**sim/**](./sim/) e
executar o comando `vsim` passando o arquivo [`sim.do`](./sim/sim.do):

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
