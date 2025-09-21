if ! command -v vsim -version >/dev/null 2>&1; then
	module load questa
fi

(
	cd ./sim
	vsim -do sim.do
)
