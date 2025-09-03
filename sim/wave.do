onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider TestBench
add wave -noupdate -label clock /ProcessorTb/clock
add wave -noupdate -label reset /ProcessorTb/reset
add wave -noupdate -radix unsigned -label instruction /ProcessorTb/instruction

add wave -noupdate -divider SPI
add wave -noupdate -label sclk /ProcessorTb/u_spi/sclk
add wave -noupdate -label miso /ProcessorTb/u_spi/miso
add wave -noupdate -label mosi /ProcessorTb/u_spi/mosi
add wave -noupdate -label nss /ProcessorTb/u_spi/nss

add wave -noupdate -divider ALU
add wave -noupdate -label i_clock /ProcessorTb/u_alu_dut/i_clock
add wave -noupdate -label i_reset /ProcessorTb/u_alu_dut/i_reset
add wave -noupdate -label current_state /ProcessorTb/u_alu_dut/current_state
add wave -noupdate -label next_state /ProcessorTb/u_alu_dut/next_state
add wave -noupdate -radix hexadecimal -label packet_in /ProcessorTb/u_alu_dut/packet_in
add wave -noupdate -radix decimal -label counter_in /ProcessorTb/u_alu_dut/counter_in
add wave -noupdate -label alu_op /ProcessorTb/u_alu_dut/op_code
add wave -noupdate -radix hexadecimal -label op_1 /ProcessorTb/u_alu_dut/op_1
add wave -noupdate -radix hexadecimal -label op_2 /ProcessorTb/u_alu_dut/op_2
add wave -noupdate -radix hexadecimal -label packet_out /ProcessorTb/u_alu_dut/packet_out
add wave -noupdate -radix decimal -label counter_out /ProcessorTb/u_alu_dut/counter_out

add wave -noupdate -divider Processor
add wave -noupdate -label i_clock /ProcessorTb/u_processor_dut/i_clock
add wave -noupdate -label i_reset /ProcessorTb/u_processor_dut/i_reset
add wave -noupdate -label current_state /ProcessorTb/u_processor_dut/current_state
add wave -noupdate -label next_state /ProcessorTb/u_processor_dut/next_state
add wave -noupdate -radix unsigned -label i_instruction /ProcessorTb/u_processor_dut/i_instruction
add wave -noupdate -label alu_op /ProcessorTb/u_processor_dut/alu_op
add wave -noupdate -radix unsigned -label rs_1 /ProcessorTb/u_processor_dut/rs_1
add wave -noupdate -radix unsigned -label rs_2 /ProcessorTb/u_processor_dut/rs_2
add wave -noupdate -radix unsigned -label rd /ProcessorTb/u_processor_dut/rd
add wave -noupdate -radix hexadecimal -label alu_packet_in /ProcessorTb/u_processor_dut/alu_packet_in
add wave -noupdate -radix decimal -label alu_counter_in /ProcessorTb/u_processor_dut/alu_counter_in
add wave -noupdate -radix hexadecimal -label alu_packet_out /ProcessorTb/u_processor_dut/alu_packet_out
add wave -noupdate -radix decimal -label alu_counter_out /ProcessorTb/u_processor_dut/alu_counter_out

add wave -noupdate -divider Registers
add wave -noupdate -radix hexadecimal -label registers /ProcessorTb/u_processor_dut/registers

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1

configure wave -namecolwidth 185
configure wave -valuecolwidth 150
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 42
configure wave -timeline 0
configure wave -timelineunits ns

update
WaveRestoreZoom {0 ns} {30 ns}
