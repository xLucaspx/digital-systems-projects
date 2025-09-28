`default_nettype none

/**
 * Interface for Memory-CPU communication.
 *
 * [Parameters]
 * - AddressWidth: Defines the width of the address to access any memory position.
 * - DataWidth:    Defines the size of each memory position.
 *
 * [Wires]
 * - i_clock:      System clock.
 * - enable:       Set to `1` if the memory is enabled; if set to `0`, reading and writing are not possible.
 * - write_enable: Set to `1` when writing in the memory, `0` otherwise.
 * - address:      The memory address in use. If `enable` is set, the contents in this address can be read, and if
 *                 `write_enable` is also set then the writing occurs in this address.
 * - read_data:    If `enable` is set, reflects the data contained inside the memory at `address`.
 * - write_data:   If `enable` and `write_enable` are set, writes the value in this wire inside the memory at `address`.
 */
interface RamPort#(
	parameter int AddressWidth = Isa::MEMORY_ADDRESS_WIDTH,
	parameter int DataWidth    = Isa::MEMORY_DATA_WIDTH
)(
	input var logic i_clock
);

	logic enable;
	logic write_enable;
	logic [AddressWidth - 1 : 0] address;
	logic [DataWidth - 1 : 0] read_data;
	logic [DataWidth - 1 : 0] write_data;

	modport Memory (
		input enable,
		input write_enable,
		input address,
		input write_data,

		output read_data
	);

	modport Cpu (
		input read_data,

		output enable,
		output write_enable,
		output address,
		output write_data
	);

endinterface: RamPort
