`default_nettype none

/**
 * Instruction set architecture for the mini serial processor.
 */
package Isa;

	localparam int MEMORY_ADDRESS_WIDTH = 8;
	localparam int MEMORY_DATA_WIDTH = 16;
	localparam int MEMORY_DEPTH = 1 << MEMORY_ADDRESS_WIDTH;

	/**
	 * Number of operations that the ALU can perform.
	 */
	localparam int OPERATION_COUNT = 8;

	/**
	 * Defines the operations that the ALU can perform.
	 */
	typedef enum logic [$clog2(OPERATION_COUNT) - 1 : 0] {
		ADD = 'h0,
		AND = 'h1,
		OR  = 'h2,
		MUL = 'h3,
		SHL = 'h4,
		SHR = 'h5,
		LW  = 'h6,
		SW  = 'h7
	} Operation;

	/**
	 * Defines the number of registers available. Addressing any possible register requires `$clog2(REGISTER_BANK_SIZE)`
	 * bits; this affects the instruction size.
	 */
	localparam int REGISTER_BANK_SIZE = 1024; // TODO 16

	/**
	 * Defines the size (bit width) of each register.
	 */
	localparam int REGISTER_SIZE = 32;

	/**
	 * Packet transmitted to the ALU from the processor. It contains two `REGISTER_SIZE` operands and an `Operation`
	 * code in the follwing format:
	 *
	 * | op_2 | op_1 | op_code |
	 *
	 * By convention, the `op_code` should be transmitted first.
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

	/**
	 * Register instruction format to be decoded and executed by the processor. It's detailed below, with the MSB being the
	 * rightmost one:
	 *
	 * | op_code | rs_1 | rs_2 | rd |
	 *
	 * From the instruction format, it's inferred that the instruction size is given by:
	 *
	 * $clog2(OPERATION_COUNT) + (3 * $clog2(REGISTER_BANK_SIZE))
	 *
	 * E.g.: Considering an ALU with 4 operations and a REGISTER_BANK_SIZE of 2 ** 10 (1024), the instruction size would
	 * be 2 + 3 * 10 = 32; decoding the instruction `0x12af7642 = 0001 0010 1010 1111 0111 0110 0100 0010` one would find:
	 *
	 * - op_code: `00 = 0x0`;
	 * - rs_1:    `01 0010 1010 = 0x12a`;
	 * - rs_2:    `11 1101 1101 = 0x3dd`;
	 * - rd:      `10 0100 0010 = 0x242`.
	 *
	 * - op_code: operation code as defined by the set of instructions;
	 * - rs_1:    register source 1, address of the register that contains the first operand;
	 * - rs_2:    register source 2, address of the register that contains the second operand;
	 * - rd:      register destination, address of the register that will receive the result of the operation;
	 */
	typedef struct packed {
		Operation op_code;
		// TODO logic i
		logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_1;
		logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_2;
		logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;
	} Instruction;

	// TODO ImmediateInstruction

endpackage: Isa
