onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ProcessorTb/u_processor_dut/i_clock
add wave -noupdate /ProcessorTb/u_processor_dut/i_reset
add wave -noupdate /ProcessorTb/u_processor_dut/PC
add wave -noupdate /ProcessorTb/u_processor_dut/stall
add wave -noupdate /ProcessorTb/u_processor_dut/stall_signal
add wave -noupdate -label B3 /ProcessorTb/u_processor_dut/barreira3
add wave -noupdate -label B1 /ProcessorTb/u_processor_dut/barreira1
add wave -noupdate -label B2 /ProcessorTb/u_processor_dut/barreira2
add wave -noupdate /ProcessorTb/u_processor_dut/alu_counter_in
add wave -noupdate /ProcessorTb/u_processor_dut/alu_packet_out
add wave -noupdate /ProcessorTb/u_processor_dut/alu_counter_out
add wave -noupdate /ProcessorTb/u_processor_dut/alu_op
add wave -noupdate /ProcessorTb/u_processor_dut/rs_1
add wave -noupdate /ProcessorTb/u_processor_dut/rs_2
add wave -noupdate /ProcessorTb/u_processor_dut/rd
add wave -noupdate /ProcessorTb/u_processor_dut/current_state
add wave -noupdate /ProcessorTb/u_processor_dut/next_state
add wave -noupdate /ProcessorTb/u_processor_dut/resultado
add wave -noupdate /ProcessorTb/u_processor_dut/resultado_in
add wave -noupdate /ProcessorTb/u_processor_dut/first_execute
add wave -noupdate /ProcessorTb/u_processor_dut/spi/sclk
add wave -noupdate /ProcessorTb/u_processor_dut/spi/miso
add wave -noupdate /ProcessorTb/u_processor_dut/spi/mosi
add wave -noupdate /ProcessorTb/u_processor_dut/spi/nss
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 302
configure wave -valuecolwidth 155
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {9 ns} {35 ns}
