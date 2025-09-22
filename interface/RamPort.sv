`default_nettype none

interface RamPort#(
	parameter int AddressWidth = Isa::MEMORY_ADDRESS_WIDTH,
	parameter int DataWidth = Isa::MEMORY_DATA_WIDTH
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
