`default_nettype none

/**
 * Single port Random Access Memory (RAM).
 *
 * [Parameters]
 * - DataWidth:    Defines the size of each memory position.
 * - Depth:        Defines the memory size, i.e., the amount of available memory positions.
 *
 * [Wires]
 * - i_clock:  System clock.
 * - ram_port: RamPort Memory interface to interact with the CPU.
 */
module SinglePortRam#(
	parameter int DataWidth = Isa::MEMORY_DATA_WIDTH,
	parameter int Depth     = Isa::MEMORY_DEPTH
)(
	input var logic i_clock,

	RamPort.Memory ram_port
);

	logic [Depth - 1 : 0] [DataWidth - 1 : 0] memory;

	always_ff @(posedge i_clock)
		if (ram_port.enable && ram_port.write_enable) memory[ram_port.address] <= ram_port.write_data;

	always_ff @(posedge i_clock)
		if (ram_port.enable) ram_port.read_data <= memory[ram_port.address];

endmodule: SinglePortRam
