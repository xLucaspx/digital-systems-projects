onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {TestBench and interfaces}

add wave -noupdate -expand -group TestBench -label clock                          /ProcessorTb/clock
add wave -noupdate -expand -group TestBench -label reset                          /ProcessorTb/reset
add wave -noupdate -expand -group TestBench -label instruction -radix hexadecimal /ProcessorTb/instruction

add wave -noupdate -expand -group SPI -label sclk /ProcessorTb/u_processor_dut/u_spi/sclk
add wave -noupdate -expand -group SPI -label miso /ProcessorTb/u_processor_dut/u_spi/miso
add wave -noupdate -expand -group SPI -label mosi /ProcessorTb/u_processor_dut/u_spi/mosi
add wave -noupdate -expand -group SPI -label nss  /ProcessorTb/u_processor_dut/u_spi/nss

add wave -noupdate -expand -group {RAM port} -label enable                          /ProcessorTb/u_ram_port/enable
add wave -noupdate -expand -group {RAM port} -label write_enable                    /ProcessorTb/u_ram_port/write_enable
add wave -noupdate -expand -group {RAM port} -label address      -radix unsigned    /ProcessorTb/u_ram_port/address
add wave -noupdate -expand -group {RAM port} -label read_data    -radix hexadecimal /ProcessorTb/u_ram_port/read_data
add wave -noupdate -expand -group {RAM port} -label write_data   -radix hexadecimal /ProcessorTb/u_ram_port/write_data

add wave -noupdate -divider {Processor and registers}

add wave -noupdate -expand -group Processor -expand -group control     -label i_clock                            /ProcessorTb/u_processor_dut/i_clock
add wave -noupdate -expand -group Processor -expand -group control     -label i_reset                            /ProcessorTb/u_processor_dut/i_reset
add wave -noupdate -expand -group Processor -expand -group control     -label current_state                      /ProcessorTb/u_processor_dut/current_state
add wave -noupdate -expand -group Processor -expand -group control     -label next_state                         /ProcessorTb/u_processor_dut/next_state
add wave -noupdate -expand -group Processor -expand -group control     -label pc              -radix decimal     /ProcessorTb/u_processor_dut/pc

add wave -noupdate -expand -group Processor -expand -group instruction -label instruction     -radix hexadecimal /ProcessorTb/u_processor_dut/instruction
add wave -noupdate -expand -group Processor -expand -group instruction -label operation                          /ProcessorTb/u_processor_dut/operation
add wave -noupdate -expand -group Processor -expand -group instruction -label is_immediate                       /ProcessorTb/u_processor_dut/is_immediate
add wave -noupdate -expand -group Processor -expand -group instruction -label rd              -radix unsigned    /ProcessorTb/u_processor_dut/rd
add wave -noupdate -expand -group Processor -expand -group instruction -label rs_1            -radix unsigned    /ProcessorTb/u_processor_dut/rs_1
add wave -noupdate -expand -group Processor -expand -group instruction -label rs_2            -radix unsigned    /ProcessorTb/u_processor_dut/rs_2
add wave -noupdate -expand -group Processor -expand -group instruction -label immediate       -radix unsigned    /ProcessorTb/u_processor_dut/immediate

add wave -noupdate -expand -group Processor -expand -group spi         -label packet_in       -radix hexadecimal /ProcessorTb/u_processor_dut/packet_in
add wave -noupdate -expand -group Processor -expand -group spi         -label counter_in      -radix decimal     /ProcessorTb/u_processor_dut/counter_in
add wave -noupdate -expand -group Processor -expand -group spi         -label alu_active                         /ProcessorTb/u_processor_dut/alu_active
add wave -noupdate -expand -group Processor -expand -group spi         -label alu_packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/alu_packet_out
add wave -noupdate -expand -group Processor -expand -group spi         -label alu_counter_out -radix decimal     /ProcessorTb/u_processor_dut/alu_counter_out
add wave -noupdate -expand -group Processor -expand -group spi         -label bas_active                         /ProcessorTb/u_processor_dut/bas_active
add wave -noupdate -expand -group Processor -expand -group spi         -label bas_packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/bas_packet_out
add wave -noupdate -expand -group Processor -expand -group spi         -label bas_counter_out -radix decimal     /ProcessorTb/u_processor_dut/bas_counter_out
add wave -noupdate -expand -group Processor -expand -group spi         -label mul_active                         /ProcessorTb/u_processor_dut/bas_active
add wave -noupdate -expand -group Processor -expand -group spi         -label mul_packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/mul_packet_out
add wave -noupdate -expand -group Processor -expand -group spi         -label mul_counter_out -radix decimal     /ProcessorTb/u_processor_dut/mul_counter_out

add wave -noupdate -expand -group Registers -label registers -radix hexadecimal /ProcessorTb/u_processor_dut/registers

add wave -noupdate -divider {Operation blocks}

add wave -noupdate -expand -group ALU -label i_clock                        /ProcessorTb/u_processor_dut/u_alu/i_clock
add wave -noupdate -expand -group ALU -label i_reset                        /ProcessorTb/u_processor_dut/u_alu/i_reset
add wave -noupdate -expand -group ALU -label is_active                      /ProcessorTb/u_processor_dut/u_alu/is_active
add wave -noupdate -expand -group ALU -label current_state                  /ProcessorTb/u_processor_dut/u_alu/current_state
add wave -noupdate -expand -group ALU -label next_state                     /ProcessorTb/u_processor_dut/u_alu/next_state
add wave -noupdate -expand -group ALU -label packet_in   -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/packet_in
add wave -noupdate -expand -group ALU -label counter_in  -radix decimal     /ProcessorTb/u_processor_dut/u_alu/counter_in
add wave -noupdate -expand -group ALU -label operation                      /ProcessorTb/u_processor_dut/u_alu/op_code
add wave -noupdate -expand -group ALU -label op_1        -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/op_1
add wave -noupdate -expand -group ALU -label op_2        -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/op_2
add wave -noupdate -expand -group ALU -label packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/u_alu/packet_out
add wave -noupdate -expand -group ALU -label counter_out -radix decimal     /ProcessorTb/u_processor_dut/u_alu/counter_out

add wave -noupdate -expand -group Shifter -label i_clock                             /ProcessorTb/u_processor_dut/u_bas/i_clock
add wave -noupdate -expand -group Shifter -label i_reset                             /ProcessorTb/u_processor_dut/u_bas/i_reset
add wave -noupdate -expand -group Shifter -label is_active                           /ProcessorTb/u_processor_dut/u_bas/is_active
add wave -noupdate -expand -group Shifter -label current_state                       /ProcessorTb/u_processor_dut/u_bas/current_state
add wave -noupdate -expand -group Shifter -label next_state                          /ProcessorTb/u_processor_dut/u_bas/next_state
add wave -noupdate -expand -group Shifter -label packet_in        -radix hexadecimal /ProcessorTb/u_processor_dut/u_bas/packet_in
add wave -noupdate -expand -group Shifter -label counter_in       -radix decimal     /ProcessorTb/u_processor_dut/u_bas/counter_in
add wave -noupdate -expand -group Shifter -label shift_amount     -radix unsigned    /ProcessorTb/u_processor_dut/u_bas/shift_amount
add wave -noupdate -expand -group Shifter -label operation                           /ProcessorTb/u_processor_dut/u_bas/op_code
add wave -noupdate -expand -group Shifter -label op_1             -radix hexadecimal /ProcessorTb/u_processor_dut/u_bas/op
add wave -noupdate -expand -group Shifter -label packet_out       -radix hexadecimal /ProcessorTb/u_processor_dut/u_bas/packet_out
add wave -noupdate -expand -group Shifter -label counter_out      -radix decimal     /ProcessorTb/u_processor_dut/u_bas/counter_out

add wave -noupdate -expand -group Multiplier -label i_clock                        /ProcessorTb/u_processor_dut/u_mul/i_clock
add wave -noupdate -expand -group Multiplier -label i_reset                        /ProcessorTb/u_processor_dut/u_mul/i_reset
add wave -noupdate -expand -group Multiplier -label is_active                      /ProcessorTb/u_processor_dut/u_mul/is_active
add wave -noupdate -expand -group Multiplier -label current_state                  /ProcessorTb/u_processor_dut/u_mul/current_state
add wave -noupdate -expand -group Multiplier -label next_state                     /ProcessorTb/u_processor_dut/u_mul/next_state
add wave -noupdate -expand -group Multiplier -label packet_in   -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/packet_in
add wave -noupdate -expand -group Multiplier -label counter_in  -radix decimal     /ProcessorTb/u_processor_dut/u_mul/counter_in
add wave -noupdate -expand -group Multiplier -label op_1        -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/op_1
add wave -noupdate -expand -group Multiplier -label op_2        -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/op_2
add wave -noupdate -expand -group Multiplier -label packet_out  -radix hexadecimal /ProcessorTb/u_processor_dut/u_mul/packet_out
add wave -noupdate -expand -group Multiplier -label counter_out -radix decimal     /ProcessorTb/u_processor_dut/u_mul/counter_out

add wave -noupdate -divider {Memory}

add wave -noupdate -expand -group Memory -label i_clock                    /ProcessorTb/u_ram/i_clock
add wave -noupdate -expand -group Memory -label RAM     -radix hexadecimal /ProcessorTb/u_ram/memory

TreeUpdate [SetDefaultTree]
WaveRestoreCursors \
	{{Cursor 1} {50   ps} 1} \
	{{Cursor 2} {90   ps} 1} \
	{{Cursor 3} {1150 ps} 1} \
	{{Cursor 4} {2180 ps} 1} \
	{{Cursor 5} {2970 ps} 1} \
	{{Cursor 6} {4000 ps} 1} \
	{{Cursor 7} {5060 ps} 1} \
	{{Cursor 8} {6120 ps} 1} \
	{{Cursor 9} {0    ps} 0}
quietly wave cursor active 9

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
WaveRestoreZoom {0 ns} {32 ns}
