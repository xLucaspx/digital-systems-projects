`default_nettype none

import Isa::*;

/**
 * Mini serial processor. Communicates with the ALU through a SPI.
 *
 * TODO: 106 ciclos (1060ps / 5ps*2) = calculo qtd ciclos para realizar uma operação
 * TODO: finish doc
 *
 * TODO: module regbank (?)
 *
 * TODO: ~reset ou !reset ??????
 *
 * TODO: else/default e setar os bgl em 0 quando não for usado, e.g. imm
 *
 * - i_clock:       System clock;
 * - i_reset:       Reset signal;
 * - i_instruction: Instruction to be executed. TODO: interface memory
 */
module Processor(
	input var logic i_clock,
	input var logic i_reset,

	RamPort.Cpu write_ram,
	RamPort.Memory read_ram
);

	localparam int ALU_NSS_POSITION = 0;
	localparam int BAS_NSS_POSITION = 1;
	localparam int MUL_NSS_POSITION = 2;

	/**
	 * SPI interface for communication with other modules (Alu, Multiplier etc.).
	 */
	Spi #(3) u_spi();

	Alu #(.NssPosition(ALU_NSS_POSITION)) u_alu(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	BarrelShifter #(.NssPosition(BAS_NSS_POSITION)) u_bas(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	Multiplier #(.NssPosition(MUL_NSS_POSITION)) u_mul(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	typedef enum logic [7:0] {
		FETCH      = 'b0000_0001,
		DECODE     = 'b0000_0010,
		EXECUTE    = 'b0000_0100,
		SEND       = 'b0000_1000,
		SENDING    = 'b0001_0000,
		RECEIVE    = 'b0010_0000,
		RECEIVING  = 'b0100_0000,
		WRITE_BACK = 'b1000_0000
	} state_t;

	state_t current_state;
	state_t next_state;

	/**
	 * Register bank. There are REGISTER_BANK_SIZE positions, each with REGISTER_SIZE bits.
	 */
	logic [REGISTER_BANK_SIZE - 1 : 0] [REGISTER_SIZE - 1 : 0] registers;

	/**
	 * Program counter register, stores the address of the instruction being fetched
	 */
	logic [REGISTER_SIZE - 1 : 0] pc;

	/*
	 * Packet that will be received through the SPI.
	 */
	logic [REGISTER_SIZE - 1 : 0] packet_in;

	/**
	 * Counter to keep track of packet_in bits received from the ALU.
	 */
	int counter_in;

	/*
	 * Packet that will be transmitted to the ALU.
	 */
	AluPacket alu_packet_out;

	/**
	 * Counter to keep track of alu_packet_out bits sent to the ALU.
	 */
	int alu_counter_out;

	/*
	 * Packet that will be transmitted to the barrel shifter.
	 */
	ShifterPacket bas_packet_out;

	/**
	 * Counter to keep track of mul_packet_out bits sent to the barrel shifter.
	 */
	int bas_counter_out;

	/*
	 * Packet that will be transmitted to the multiplier.
	 */
	MulPacket mul_packet_out;

	/**
	 * Counter to keep track of mul_packet_out bits sent to the multiplier.
	 */
	int mul_counter_out;

	/**
	 * Temporal barrier register to save the fetched instruction beetween `FETCH` and `DECODE`.
	 */
	logic [INSTRUCTION_SIZE - 1 : 0] instruction_reg;

	/**
	 * Temporal barrier register to save the operation code beetween `DECODE` and `EXECUTE`.
	 */
	Operation opcode_reg;

	/**
	 * Temporal barrier register to save the immediate flag of the instruction format beetween `DECODE` and `EXECUTE`.
	 */
	logic is_immediate_reg;

	/**
	 * Temporal barrier register to save the destination register address beetween `DECODE` and `EXECUTE`.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd_address_reg;

	/**
	 * Temporal barrier register to save the first operand beetween `DECODE` and `EXECUTE`.
	 */
	logic [REGISTER_SIZE - 1 : 0] rs1_value_reg;

	/**
	 * Temporal barrier register to save the second operand beetween `DECODE` and `EXECUTE`.
	 */
	logic [REGISTER_SIZE - 1 : 0] rs2_value_reg;

	/**
	 * Temporal barrier register to save the immediate value beetween `DECODE` and `EXECUTE`.
	 */
	logic [MEMORY_ADDRESS_WIDTH - 1 : 0] immediate_reg;

	/**
	 * Temporal barrier register to save the operation result between `EXECUTE` and `WRITE_BACK`.
	 */
	logic [REGISTER_SIZE - 1 : 0] result_reg; // TODO quebrar FSM em 2, 1 apenas para SPI e que roda dentrod o EXECUTE; armazenar resultado neste reg e add na forma de onda

	/**
	 * Temporal barrier register to save the destination register address between `EXECUTE` and `WRITE_BACK`.
	 */
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] wb_address_reg;

	Operation operation;
	logic is_immediate;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_1;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_2;
	logic [MEMORY_ADDRESS_WIDTH - 1 : 0] immediate;

	logic alu_active;
	logic bas_active;
	logic mul_active;

	assign write_ram.enable = 1;
	assign write_ram.write_data = registers[wb_address_reg];
	assign write_ram.write_enable = (current_state == WRITE_BACK) && (opcode_reg == SW);
	assign write_ram.address = (opcode_reg == LW && current_state == EXECUTE)    ? immediate_reg // LW: precisa apresentar antes
		                       : (opcode_reg == SW && current_state == WRITE_BACK) ? immediate_reg // SW: escreve no WB
		                       : pc; // FETCH: endereço da instrução

	assign u_spi.sclk = i_clock;

	assign alu_active = opcode_reg inside { ADD, AND, OR };
	assign bas_active = opcode_reg inside { SHL, SHR };
	assign mul_active = opcode_reg == MUL;

	// `nss` should be 0 only when transmitting/receiving
	always_comb
		if (current_state inside { SEND, SENDING, RECEIVE, RECEIVING }) begin
			u_spi.nss[ALU_NSS_POSITION] = ~alu_active;
			u_spi.nss[BAS_NSS_POSITION] = ~bas_active;
			u_spi.nss[MUL_NSS_POSITION] = ~mul_active;
		end
		else u_spi.nss = '1;

	// MOSI
	always_comb case (current_state)
			SEND:    u_spi.mosi = 1'b1;
			SENDING: if (alu_active)      u_spi.mosi = alu_packet_out[alu_counter_out];
				       else if (mul_active) u_spi.mosi = mul_packet_out[mul_counter_out];
				       else if (bas_active) u_spi.mosi = bas_packet_out[bas_counter_out];
			default: u_spi.mosi = 1'b0;
	endcase

	// State logic
	always_comb
		if (~i_reset) next_state = FETCH;
		else case (current_state)
			FETCH:      next_state = (instruction_reg != 'b0) ? DECODE : FETCH;
			DECODE:     next_state = EXECUTE;
			EXECUTE:    next_state = is_immediate_reg ? WRITE_BACK : SEND;
			SEND:       next_state = (~u_spi.miso && u_spi.mosi) ? SENDING : SEND;
			SENDING:    if (alu_active)      next_state = (alu_counter_out == $bits(alu_packet_out) - 1) ? RECEIVE : SENDING;
				          else if (mul_active) next_state = (mul_counter_out == $bits(mul_packet_out) - 1) ? RECEIVE : SENDING;
				          else if (bas_active) next_state = (bas_counter_out == $bits(bas_packet_out) - 1) ? RECEIVE : SENDING;
			RECEIVE:    next_state = (u_spi.miso && ~u_spi.mosi) ? RECEIVING : RECEIVE;
			RECEIVING:  next_state = (counter_in == $bits(packet_in) - 1) ? WRITE_BACK : current_state;
			WRITE_BACK: next_state = FETCH;
			default:    next_state = FETCH;
		endcase

	// DECODE logic
	always_comb
		if (~i_reset) { operation, is_immediate, rd, rs_1, rs_2, immediate } = '0;
		else if (instruction_reg[12]) { operation, is_immediate, rd, immediate } = instruction_reg;
		else { operation, is_immediate, rd, rs_1, rs_2 } = instruction_reg;

	// PC increment
	always_ff @(posedge i_clock, negedge i_reset)
		if (~i_reset) pc <= '0;
		else if (current_state == FETCH && instruction_reg != '0) pc <= pc + 1;

	// FETCH -> DECODE barrier
	always_ff @(posedge i_clock, negedge i_reset)
		if (~i_reset) instruction_reg <= '0;
		else if (current_state == FETCH) instruction_reg <= read_ram.read_data;

	// DECODE -> EXECUTE barrier
	always_ff @(posedge i_clock, negedge i_reset)
		if (~i_reset) { opcode_reg , is_immediate_reg, rd_address_reg, rs1_value_reg, rs2_value_reg, immediate_reg } <= '0;
		 else if (current_state == DECODE) begin
			opcode_reg <= operation;
			is_immediate_reg <= is_immediate;
			rd_address_reg <= rd;
			rs1_value_reg <= registers[rs_1];
			rs2_value_reg <= registers[rs_2];
			immediate_reg <= immediate;
		end

	// EXECUTE -> WRITE_BACK barrier
	always_ff @(posedge i_clock, negedge i_reset)
		if (~i_reset) wb_address_reg <= '0;
		else if (current_state == EXECUTE) wb_address_reg <= rd_address_reg;

	always_ff @(posedge i_clock, negedge i_reset) begin: StateMachine
		if (~i_reset) begin
			packet_in       <= '0;
			counter_in      <= '0;
			alu_packet_out  <= '0;
			alu_counter_out <= '0;
			bas_packet_out  <= '0;
			bas_counter_out <= '0;
			mul_packet_out  <= '0;
			mul_counter_out <= '0;
		end
		else case (current_state)
			SEND:       if (alu_active)      alu_packet_out <= { rs2_value_reg, rs1_value_reg, opcode_reg };
				          else if (mul_active) mul_packet_out <= { rs2_value_reg, rs1_value_reg };
				          else if (bas_active) bas_packet_out <= { rs2_value_reg, rs1_value_reg, opcode_reg };

			SENDING:    if (alu_active)      alu_counter_out <= (alu_counter_out == $bits(alu_packet_out) - 1) ? 0 : alu_counter_out + 1;
				          else if (mul_active) mul_counter_out <= (mul_counter_out == $bits(mul_packet_out) - 1) ? 0 : mul_counter_out + 1;
				          else if (bas_active) bas_counter_out <= (bas_counter_out == $bits(bas_packet_out) - 1) ? 0 : bas_counter_out + 1;

			RECEIVING:  begin
				packet_in[counter_in] <= u_spi.miso;
				counter_in <= (counter_in == $bits(packet_in) - 1) ? 0 : counter_in + 1;
			end

			WRITE_BACK: registers[wb_address_reg] <= (opcode_reg == LW) ? read_ram.read_data : packet_in;
		endcase

		current_state <= next_state;
	end: StateMachine

endmodule: Processor
