if {[file isdirectory work]} { vdel -all -lib work }

vlib work
vmap work work

set SOURCES ""
set TOP_ENTITY "work.TopNexysA7Tb"

# Packages
append SOURCES " "

# Interfaces
append SOURCES "../interface/TemperatureHumidity.sv"

# Modules
append SOURCES " ../rtl/nexys_fire_sensor/Seg7c.sv ../rtl/nexys_fire_sensor/I2cMaster.sv ../rtl/nexys_fire_sensor/Clkgen_200KHz.sv ../rtl/EdgeDetector.sv ../rtl/Co2Sensor.sv ../rtl/SoundBuzzer.sv ../rtl/TemperatureHumiditySensor.sv ../rtl/FireController.sv ../rtl/TopNexysA7.sv"

# Testbenches
append SOURCES " ./TopNexysA7Tb.sv"

# Compile Verilog (use eval so the SOURCES string is split into words)
eval vlog -work work $SOURCES

# Run testbench
vsim -voptargs=+acc $TOP_ENTITY

# do wave.do TODO generate wave.do
run -all
