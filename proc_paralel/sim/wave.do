onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label clock /ProcessorTb/u_processor_dut/i_clock
add wave -noupdate -label reset /ProcessorTb/u_processor_dut/i_reset
add wave -noupdate -label PC /ProcessorTb/u_processor_dut/PC
add wave -noupdate -label stall /ProcessorTb/u_processor_dut/stall
add wave -noupdate -label stall_signal /ProcessorTb/u_processor_dut/stall_signal
add wave -noupdate -label B3 /ProcessorTb/u_processor_dut/barreira3
add wave -noupdate -label B1 /ProcessorTb/u_processor_dut/barreira1
add wave -noupdate -label B2 /ProcessorTb/u_processor_dut/barreira2
add wave -noupdate /ProcessorTb/u_processor_dut/alu_counter_in
add wave -noupdate /ProcessorTb/u_processor_dut/alu_packet_out
add wave -noupdate /ProcessorTb/u_processor_dut/alu_counter_out
add wave -noupdate -label alu_op /ProcessorTb/u_processor_dut/alu_op
add wave -noupdate /ProcessorTb/u_processor_dut/current_state
add wave -noupdate /ProcessorTb/u_processor_dut/next_state
add wave -noupdate /ProcessorTb/u_processor_dut/spi_signal
add wave -noupdate /ProcessorTb/u_processor_dut/first_execute
add wave -noupdate /ProcessorTb/u_processor_dut/resultado
add wave -noupdate /ProcessorTb/u_processor_dut/resultado_in
add wave -noupdate /ProcessorTb/u_processor_dut/writeback
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {278 ns} 0}
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
WaveRestoreZoom {22 ns} {534 ns}
