if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

set TOP_ENTITY {work.ProcessorTb}

proc compileVerilog {args} {
	foreach filename $args {
		vlog -work work $filename
	}
}

# Interfaces
compileVerilog ../interface/Spi.sv

# Packages
compileVerilog ../rtl/Isa.sv

# Modules
compileVerilog  ../rtl/Alu.sv ../rtl/Processor.sv

# Testbenches
compileVerilog ./ProcessorTb.sv

vsim -voptargs=+acc ${TOP_ENTITY}

do wave.do
run 30ns
