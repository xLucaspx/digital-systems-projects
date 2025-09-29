# Mini Processor SPI

- Lucas da Paz Oliveira;
- Rodrigo Miotto Slongo.

## Índice

- [Visão Geral](#visão-geral);
- [Estrutura do Projeto](#estrutura-do-projeto);
- [Simulação](#simulação);
- [Formas de Onda](#formas-de-onda).

## Visão Geral

Este trabalho tem como objetivo a implementação, em System Verilog, de um mini processador com 4 instruções. A
comunicação do processador com a ALU (_arithmetic logic unit_) deve ser implementada utilizando o protocolo SPI e as
operações só devem ser realizadas após toda a informação ser transmitida.

## Estrutura do Projeto

- [docs](./docs/): Documentação e enunciado do trabalho;
- [interface](./interface/): Interfaces;
- [rtl](./rtl/): Descrição de _hardware_;
- [sim](./sim/): _Testbenches_ e _scripts_ de simulação;

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

O [_testbench_](./sim/ProcessorTb.sv) possui diversas instruções que serão executadas e validadas; utilizou-se
`$display` para mostrar a execução de cada uma. A simulação também executa uma forma de onda, disponível em
[`wave.do`](./sim/wave.do); este _script_ separa os sinais por módulos e realiza as configurações necessárias para a
melhor visualização possível do diagrama de formas de onda gerado pela execução da simulação.

![Diagrama de forma de onda](./docs/waveform.bmp "Exemplo do diagrama de forma de onda esperado após simulação")

## Formas de Onda

Nesta seção serão apresentadas as formas de onda simuladas para cada operação implementada.

### `ADD`

![Forma de onda em interfaces - instrução ADD](./docs/waves/add-0.png "Forma de onda no testbench e nas interfaces para a instrução ADD")
![Forma de onda no processador - instrução ADD](./docs/waves/add-1.png "Forma de onda no processador para a instrução ADD")
![Forma de onda no bloco de operação - instrução ADD](./docs/waves/add-2.png "Forma de onda no bloco ALU para a instrução ADD")

### `AND`

![Forma de onda em interfaces - instrução AND](./docs/waves/and-0.png "Forma de onda no testbench e nas interfaces para a instrução AND")
![Forma de onda no processador - instrução AND](./docs/waves/and-1.png "Forma de onda no processador para a instrução AND")
![Forma de onda no bloco de operação - instrução AND](./docs/waves/and-2.png "Forma de onda no bloco ALU para a instrução AND")

### `OR`

![Forma de onda em interfaces - instrução OR](./docs/waves/or-0.png "Forma de onda no testbench e nas interfaces para a instrução OR")
![Forma de onda no processador - instrução OR](./docs/waves/or-1.png "Forma de onda no processador para a instrução OR")
![Forma de onda no bloco de operação - instrução OR](./docs/waves/or-2.png "Forma de onda no bloco ALU para a instrução OR")

### `MUL`

![Forma de onda em interfaces - instrução MUL](./docs/waves/mul-0.png "Forma de onda no testbench e nas interfaces para a instrução MUL")
![Forma de onda no processador - instrução MUL](./docs/waves/mul-1.png "Forma de onda no processador para a instrução MUL")
![Forma de onda no bloco de operação - instrução MUL](./docs/waves/mul-2.png "Forma de onda no bloco multiplicador para a instrução MUL")

### `SHL`

![Forma de onda em interfaces - instrução SHL](./docs/waves/shl-0.png "Forma de onda no testbench e nas interfaces para a instrução SHL")
![Forma de onda no processador - instrução SHL](./docs/waves/shl-1.png "Forma de onda no processador para a instrução SHL")
![Forma de onda no bloco de operação - instrução SHL](./docs/waves/shl-2.png "Forma de onda no bloco shifter para a instrução SHL")

### `SHR`

![Forma de onda em interfaces - instrução SHR](./docs/waves/shr-0.png "Forma de onda no testbench e nas interfaces para a instrução SHR")
![Forma de onda no processador - instrução SHR](./docs/waves/shr-1.png "Forma de onda no processador para a instrução SHR")
![Forma de onda no bloco de operação - instrução SHR](./docs/waves/shr-2.png "Forma de onda no bloco shifter para a instrução SHR")

### `LW`

![Forma de onda em interfaces - instrução LW](./docs/waves/lw-0.png "Forma de onda no testbench e nas interfaces para a instrução LW")
![Forma de onda no processador - instrução LW](./docs/waves/lw-1.png "Forma de onda no processador e na memória para a instrução LW")

### `SW`

![Forma de onda em interfaces - instrução SW](./docs/waves/sw-0.png "Forma de onda no testbench e nas interfaces para a instrução SW")
![Forma de onda no processador - instrução SW](./docs/waves/sw-1.png "Forma de onda no processador e na memória para a instrução SW")
