if ! command -v vlog -version >/dev/null 2>&1; then
	module load questa
fi

SOURCES="rtl/Isa.sv interface/RamPort.sv interface/Spi.sv rtl/SinglePortRam.sv rtl/Alu.sv rtl/BarrelShifter.sv rtl/Multiplier.sv rtl/Processor.sv sim/ProcessorTb.sv"
PATHS=""

for SOURCE in ${SOURCES}; do
	PATHS="${PATHS} ../${SOURCE}"
done

(
	cd ./sim/

	if [ -d ./work ]; then
		printf "Removendo diretório work...\n"
		rm -r ./work/
	fi

	printf "\nCompilando fontes: { ${SOURCES} }\n\n"
	vlog -work work $PATHS
)
