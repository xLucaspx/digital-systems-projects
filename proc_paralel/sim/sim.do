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
compileVerilog ../rtl/Spi.sv ../rtl/dual_port_ram_if.sv ../rtl/regbank_if.sv

# Packages
compileVerilog ../rtl/Isa.sv

# Modules
compileVerilog  ../rtl/Alu.sv ../rtl/Shifter.sv ../rtl/Mul.sv ../rtl/dual_port_ram.sv  ../rtl/regbank.sv  ../rtl/Processor.sv

# Testbenches
compileVerilog ./ProcessorTb.sv

vsim -voptargs=+acc ${TOP_ENTITY}

do wave.do
run 400ns
