#!/usr/bin/env bash
set -e

if ! command -v vlog >/dev/null 2>&1; then
	SOFT64_PATH="/soft64/source_gaph"

	if [ ! -f "$SOFT64_PATH" ]; then
		printf "\033[0;31mModelSim/Questa não encontrados!\033[0m\n"
		exit 1
	fi

	source "$SOFT64_PATH"
	module load questa
fi

(
	cd ./sim/ || exit 1
	vsim -do sim.do
)
