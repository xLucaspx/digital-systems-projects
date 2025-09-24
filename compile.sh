#!/usr/bin/env bash
set -e

if ! command -v vlog >/dev/null 2>&1; then
	SOFT64_PATH="/soft64/source_gaph"

	if [ ! -f "$SOFT64_PATH" ]; then
		printf "\033[0;31m[ERRO]\033[0m ModelSim/Questa não encontrados!\n"
		exit 1
	fi

	source "$SOFT64_PATH"
	module load questa
fi

SOURCES="rtl/Isa.sv interface/Spi.sv rtl/Alu.sv rtl/Processor.sv sim/ProcessorTb.sv"
PATHS=""

for SOURCE in ${SOURCES}; do
	PATHS="${PATHS} ../${SOURCE}"
done

(
	cd ./sim/ || exit 1

	WORK_DIR="./work/"

	if [ -d "$WORK_DIR" ]; then
		printf "Removendo diretório '${WORK_DIR}'...\n"
		rm -rf $WORK_DIR
	fi

	printf "\nCompilando fontes: { ${SOURCES} }\n\n"
	vlog -work work $PATHS
)
