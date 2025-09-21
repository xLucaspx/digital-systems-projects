`default_nettype none

/**
 * Instruction set architecture for the mini serial processor.
 */
package Isa;

	/**
	 * Number of operations that the ALU can perform.
	 */
	localparam int ALU_OPERATION_COUNT = 8;

	/**
	 * Defines the operations that the ALU can perform.
	 */
	typedef enum logic [$clog2(ALU_OPERATION_COUNT) -1: 0] {
		ADD = 'h0,
		AND = 'h1,
		OR  = 'h2,
		MUL = 'h3,
		SHL = 'h4,
		SHR = 'h5,
		LW  = 'h6,
		SW  = 'h7

	} Instruction;

	/**
	 * Defines the number of registers available. Addressing any possible register requires `$clog2(REGISTER_BANK_SIZE)`
	 * bits; this affects the instruction size.
	 */
	localparam int REGISTER_BANK_SIZE = 1024;

	/**
	 * Defines the size (bit width) of each register.
	 */
	localparam int REGISTER_SIZE = 16;

	/**
	 * Packet transmitted to the ALU from the processor. It contains two `REGISTER_SIZE` operands and an `AluOperation`
	 * code in the follwing format:
	 *
	 * | op_2 | op_1 | op_code |
	 *
	 * By convention, the `op_code` should be transmitted first.
	 */
	typedef struct packed {
		logic [REGISTER_SIZE : 0] op_2;
		logic [REGISTER_SIZE : 0] op_1;
		Instruction op_code;
	} AluPacket;


endpackage: Isa
