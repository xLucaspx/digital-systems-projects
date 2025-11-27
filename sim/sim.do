if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

set SOURCES {}
set TOP_ENTITY "work.TopNexysA7Tb"

# Interfaces
lappend SOURCES ../interface/TemperatureHumidity.sv

# Modules
lappend SOURCES ../rtl/nexys_fire_sensor/Seg7c.sv
lappend SOURCES ../rtl/nexys_fire_sensor/I2cMaster.sv
lappend SOURCES ../rtl/nexys_fire_sensor/Clkgen_200KHz.sv
lappend SOURCES ../rtl/Co2Sensor.sv
lappend SOURCES ../rtl/SoundBuzzer.sv
lappend SOURCES ../rtl/FireController.sv
lappend SOURCES ../rtl/TemperatureMetrics.sv
lappend SOURCES ../rtl/TopNexysA7.sv

# Testbenches
lappend SOURCES ./TopNexysA7Tb.sv

# Compile Verilog (use eval so the SOURCES string is split into words)
eval vlog -work work $SOURCES

# Run testbench
vsim -voptargs=+acc $TOP_ENTITY

# do wave.do TODO generate wave.do
run -all
