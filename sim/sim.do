if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

set SOURCES ""
set TOP_ENTITY "work.TopNexysA7Tb"

# Packages
append SOURCES " "

# Interfaces
append SOURCES " "

# Modules
append SOURCES " ../rtl/TopNexysA7.sv"

# Testbenches
append SOURCES " ./TopNexysA7Tb.sv"

# Compile Verilog (use eval so the SOURCES string is split into words)
eval vlog -work work $SOURCES

# Run testbench
vsim -voptargs=+acc $TOP_ENTITY

# do wave.do TODO generate wave.do
run 6000 ns
