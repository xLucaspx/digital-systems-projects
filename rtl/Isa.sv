`default_nettype none

/**
 * Instruction set architecture for the mini serial processor.
 */
package Isa;

	localparam int MEMORY_ADDRESS_WIDTH = 8;
	localparam int MEMORY_DATA_WIDTH = 32;
	localparam int MEMORY_DEPTH = 1 << MEMORY_ADDRESS_WIDTH;

	/**
	 * Number of operations that the processor can perform.
	 */
	localparam int OPERATION_COUNT = 8;

	/**
	 * Defines the operations that the processor can perform.
	 */
	typedef enum logic [$clog2(OPERATION_COUNT) - 1 : 0] {
		ADD = 'h0,
		AND = 'h1,
		OR  = 'h2,
		MUL = 'h3,
		SHL = 'h4, // TODO deveria ser ROL
		SHR = 'h5, // TODO deveria ser ROR
		LW  = 'h6,
		SW  = 'h7
	} Operation;

	/**
	 * Defines the number of registers available. Addressing any possible register requires `$clog2(REGISTER_BANK_SIZE)`
	 * bits; this affects the instruction size.
	 */
	localparam int REGISTER_BANK_SIZE = 16;

	/**
	 * Defines the size (bit width) of each register.
	 */
	localparam int REGISTER_SIZE = 32;

	// TODO doc
	localparam int INSTRUCTION_SIZE = 16; // ($clog2(Operation) + 3 * $clog2(REGISTER_BANK_SIZE) + 1);

	/**
	 * Packet transmitted to the ALU from the processor. It contains two `REGISTER_SIZE` operands and an `Operation`
	 * code in the follwing format:
	 *
	 * | op_2 | op_1 | op_code |
	 */
	typedef struct packed {
		logic [REGISTER_SIZE - 1 : 0] op_2;
		logic [REGISTER_SIZE - 1 : 0] op_1;
		Operation op_code;
	} AluPacket;

	/**
	 * Packet transmitted to the multiplier from the processor. It contains two `REGISTER_SIZE` operands, as follows:
	 *
	 * | op_2 | op_1 |
	 *
	 */
	typedef struct packed {
		logic [REGISTER_SIZE - 1 : 0] op_2;
		logic [REGISTER_SIZE - 1 : 0] op_1;
	} MulPacket;

	/**
	 * Packet transmitted to the barrel shifter from the processor. It contains the amount of bits to shift -- a
	 * $clog2(REGISTER_SIZE) wide value --, a `REGISTER_SIZE` operand and an `Operation`, as follows:
	 *
	 * | shift_amount | op | op_code |
	 *
	 */
	typedef struct packed {
		logic [$clog2(REGISTER_SIZE) - 1 : 0] shift_amount;
		logic [REGISTER_SIZE - 1 : 0] op;
		Operation op_code;
	} ShifterPacket;

endpackage: Isa
