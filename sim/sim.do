if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

set SOURCES ""
set TOP_ENTITY "work.ProcessorTb"

# Packages
append SOURCES "../rtl/Isa.sv "

# Interfaces
append SOURCES "../interface/RamPort.sv ../interface/Spi.sv "

# Modules
append SOURCES "../rtl/SinglePortRam.sv ../rtl/Alu.sv ../rtl/BarrelShifter.sv ../rtl/Multiplier.sv ../rtl/Processor.sv "

# Testbenches
append SOURCES "./ProcessorTb.sv "

# Compile Verilog (use eval so the SOURCES string is split into words)
eval vlog -work work $SOURCES

# Run testbench
vsim -voptargs=+acc $TOP_ENTITY

do wave.do
run 6000 ns
