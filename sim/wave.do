onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider TestBench
add wave -noupdate -label clock                       /ProcessorTb/clock
add wave -noupdate -label reset                       /ProcessorTb/reset
add wave -noupdate -label instruction -radix unsigned /ProcessorTb/instruction

add wave -noupdate -divider SPI
add wave -noupdate -label sclk /ProcessorTb/u_processor_dut/u_spi/sclk
add wave -noupdate -label miso /ProcessorTb/u_processor_dut/u_spi/miso
add wave -noupdate -label mosi /ProcessorTb/u_processor_dut/u_spi/mosi
add wave -noupdate -label nss  /ProcessorTb/u_processor_dut/u_spi/nss

add wave -noupdate -divider Processor
add wave -noupdate -label i_clock                            /ProcessorTb/u_processor_dut/i_clock
add wave -noupdate -label i_reset                            /ProcessorTb/u_processor_dut/i_reset
add wave -noupdate -label current_state                      /ProcessorTb/u_processor_dut/current_state
add wave -noupdate -label next_state                         /ProcessorTb/u_processor_dut/next_state
add wave -noupdate -label i_instruction   -radix unsigned    /ProcessorTb/u_processor_dut/i_instruction
add wave -noupdate -label operation                          /ProcessorTb/u_processor_dut/operation
add wave -noupdate -label rs_1            -radix unsigned    /ProcessorTb/u_processor_dut/rs_1
add wave -noupdate -label rs_2            -radix unsigned    /ProcessorTb/u_processor_dut/rs_2
add wave -noupdate -label rd              -radix unsigned    /ProcessorTb/u_processor_dut/rd
add wave -noupdate -label packet_in       -radix hexadecimal /ProcessorTb/u_processor_dut/packet_in
add wave -noupdate -label counter_in      -radix decimal     /ProcessorTb/u_processor_dut/counter_in
add wave -noupdate -label alu_packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/alu_packet_out
add wave -noupdate -label alu_counter_out -radix decimal     /ProcessorTb/u_processor_dut/alu_counter_out

add wave -noupdate -divider ALU
add wave -noupdate -label i_clock                        /ProcessorTb/u_processor_dut/u_alu/i_clock
add wave -noupdate -label i_reset                        /ProcessorTb/u_processor_dut/u_alu/i_reset
add wave -noupdate -label current_state                  /ProcessorTb/u_processor_dut/u_alu/current_state
add wave -noupdate -label next_state                     /ProcessorTb/u_processor_dut/u_alu/next_state
add wave -noupdate -label packet_in   -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/packet_in
add wave -noupdate -label counter_in  -radix decimal     /ProcessorTb/u_processor_dut/u_alu/counter_in
add wave -noupdate -label operation                      /ProcessorTb/u_processor_dut/u_alu/op_code
add wave -noupdate -label op_1        -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/op_1
add wave -noupdate -label op_2        -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/op_2
add wave -noupdate -label packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/packet_out
add wave -noupdate -label counter_out -radix decimal     /ProcessorTb/u_processor_dut/u_alu/counter_out

add wave -noupdate -divider Shifter
add wave -noupdate -label i_clock                             /ProcessorTb/u_processor_dut/u_bas/i_clock
add wave -noupdate -label i_reset                             /ProcessorTb/u_processor_dut/u_bas/i_reset
add wave -noupdate -label current_state                       /ProcessorTb/u_processor_dut/u_bas/current_state
add wave -noupdate -label next_state                          /ProcessorTb/u_processor_dut/u_bas/next_state
add wave -noupdate -label packet_in        -radix hexadecimal /ProcessorTb/u_processor_dut/u_bas/packet_in
add wave -noupdate -label counter_in       -radix decimal     /ProcessorTb/u_processor_dut/u_bas/counter_in
add wave -noupdate -label shift_amount_raw -radix decimal     /ProcessorTb/u_processor_dut/u_bas/shift_amount_raw
add wave -noupdate -label shift_amount     -radix decimal     /ProcessorTb/u_processor_dut/u_bas/shift_amount
add wave -noupdate -label op               -radix hexadecimal /ProcessorTb/u_processor_dut/u_bas/op
add wave -noupdate -label operation                           /ProcessorTb/u_processor_dut/u_bas/op_code
add wave -noupdate -label packet_out       -radix hexadecimal /ProcessorTb/u_processor_dut/u_bas/packet_out
add wave -noupdate -label counter_out      -radix decimal     /ProcessorTb/u_processor_dut/u_bas/counter_out

add wave -noupdate -divider Multiplier
add wave -noupdate -label i_clock                        /ProcessorTb/u_processor_dut/u_mul/i_clock
add wave -noupdate -label i_reset                        /ProcessorTb/u_processor_dut/u_mul/i_reset
add wave -noupdate -label current_state                  /ProcessorTb/u_processor_dut/u_mul/current_state
add wave -noupdate -label next_state                     /ProcessorTb/u_processor_dut/u_mul/next_state
add wave -noupdate -label packet_in   -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/packet_in
add wave -noupdate -label counter_in  -radix decimal     /ProcessorTb/u_processor_dut/u_mul/counter_in
add wave -noupdate -label op_1        -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/op_1
add wave -noupdate -label op_2        -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/op_2
add wave -noupdate -label packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/packet_out
add wave -noupdate -label counter_out -radix decimal     /ProcessorTb/u_processor_dut/u_mul/counter_out

add wave -noupdate -divider Registers
add wave -noupdate -label registers -radix hexadecimal /ProcessorTb/u_processor_dut/registers

TreeUpdate [SetDefaultTree]
WaveRestoreCursors \
	{{Cursor 1} {1150 ps} 1} \
	{{Cursor 2} {2170 ps} 1} \
	{{Cursor 3} {3220 ps} 1} \
	{{Cursor 4} {4270 ps} 1} \
	{{Cursor 5} {5050 ps} 1} \
	{{Cursor 6} {5830 ps} 1} \
	{{Cursor 7} {6980 ps} 1} \
	{{Cursor 8} {0 ps} 0}
quietly wave cursor active 8

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

configure wave -background "Gray80"
configure wave -cursorcolor "Medium Sea Green"
configure wave -cursordeltacolor "Forest Green"
configure wave -foreground "Black"
configure wave -gridcolor "Sea Green"
configure wave -selectbackground "Pale Green"
configure wave -selectforeground "Black"
configure wave -textcolor "Black"
configure wave -timecolor "Cornflower Blue"
configure wave -vectorcolor "Medium Slate Blue"
configure wave -wavebackground "White"

update
WaveRestoreZoom {0 ns} {30 ns}
