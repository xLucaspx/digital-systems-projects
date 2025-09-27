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

	typedef enum logic [3:0] {
		FETCH      = 'b0001,
		DECODE     = 'b0010,
		EXECUTE    = 'b0100,
		WRITE_BACK = 'b1000,
		HALT       = 'b0000
	} state_t;

	typedef enum logic [5:0] {
		IDLE      = 'b00_0001,
		SEND      = 'b00_0010,
		SENDING   = 'b00_0100,
		RECEIVE   = 'b00_1000,
		RECEIVING = 'b01_0000,
		DONE      = 'b10_0000
	} spi_state_t;

	state_t current_state;
	state_t next_state;

	spi_state_t spi_state;

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

	logic [INSTRUCTION_SIZE - 1 : 0] instruction;
	Operation operation;
	logic is_immediate;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_1;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_2;
	logic [MEMORY_ADDRESS_WIDTH - 1 : 0] immediate;

	logic alu_active;
	logic bas_active;
	logic mul_active;

	logic spi_start;
	logic spi_done;

	assign u_spi.sclk = i_clock;

	assign write_ram.enable = 1;
	assign write_ram.write_data = registers[rd_address_reg];
	assign write_ram.write_enable = (current_state == EXECUTE) && (opcode_reg == SW);
	assign write_ram.address = (current_state == EXECUTE && opcode_reg inside { LW, SW }) ? immediate_reg : pc;

	assign alu_active = opcode_reg inside { ADD, AND, OR };
	assign bas_active = opcode_reg inside { SHL, SHR };
	assign mul_active = opcode_reg == MUL;

	// `nss` should be 0 only when transmitting/receiving
	always_comb
		if (spi_state inside { SEND, SENDING, RECEIVE, RECEIVING }) begin
			u_spi.nss[ALU_NSS_POSITION] = ~alu_active;
			u_spi.nss[BAS_NSS_POSITION] = ~bas_active;
			u_spi.nss[MUL_NSS_POSITION] = ~mul_active;
		end
		else u_spi.nss = '1;

	// MOSI
	always_comb case (spi_state)
			SEND:    u_spi.mosi = 1'b1;
			SENDING: if (alu_active)      u_spi.mosi = alu_packet_out[alu_counter_out];
				       else if (mul_active) u_spi.mosi = mul_packet_out[mul_counter_out];
				       else if (bas_active) u_spi.mosi = bas_packet_out[bas_counter_out];
			default: u_spi.mosi = 1'b0;
	endcase

	// Processor state logic
	always_comb
		if (~i_reset) begin
			next_state = FETCH;
			spi_start = 0;
		end else case (current_state)
			FETCH:      next_state = DECODE;
			DECODE:     next_state = instruction_reg == '0 ? HALT : EXECUTE;
			EXECUTE:    begin
				if (is_immediate_reg || spi_done) begin
					spi_start = 0;
					next_state = WRITE_BACK;
				end else begin
					spi_start = 1;
					next_state = EXECUTE;
				end
			end
			WRITE_BACK: next_state = FETCH;
			HALT:       next_state = HALT;
			default:    next_state = FETCH;
		endcase

	// SPI state logic
	always_ff @(posedge i_clock, negedge i_reset)
		if (~i_reset) begin
			spi_state <= IDLE;
			spi_done <= 0;
		end else case (spi_state)
			IDLE:      begin
				spi_state <= spi_start ? SEND : IDLE;
				spi_done <= 0;
			end
			SEND:      spi_state <= (~u_spi.miso && u_spi.mosi) ? SENDING : SEND;
			SENDING:   if (alu_active)      spi_state <= (alu_counter_out == $bits(alu_packet_out) - 1) ? RECEIVE : SENDING;
				         else if (mul_active) spi_state <= (mul_counter_out == $bits(mul_packet_out) - 1) ? RECEIVE : SENDING;
				         else if (bas_active) spi_state <= (bas_counter_out == $bits(bas_packet_out) - 1) ? RECEIVE : SENDING;
			RECEIVE:   spi_state <= (u_spi.miso && ~u_spi.mosi) ? RECEIVING : RECEIVE;
			RECEIVING: spi_state <= (counter_in == $bits(packet_in) - 1) ? DONE : RECEIVING;
			DONE:      begin
				spi_state <= IDLE;
				spi_done <= 1;
			end
		endcase

	// DECODE logic
	always_comb
		if (~i_reset) { operation, is_immediate, rd, rs_1, rs_2, immediate } = '0;
		else if (instruction_reg[12]) { operation, is_immediate, rd, immediate } = instruction_reg;
		else { operation, is_immediate, rd, rs_1, rs_2 } = instruction_reg;

	// PC increment
	always_ff @(posedge i_clock, negedge i_reset)
		if (~i_reset) pc <= '0;
		else if (current_state == FETCH) pc <= pc + 1;

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
		
			EXECUTE: case (spi_state)
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
			endcase

			WRITE_BACK: if (opcode_reg == LW) registers[wb_address_reg] <= read_ram.read_data;
				          else if (opcode_reg inside { ADD, AND, OR, MUL, SHL, SHR }) registers[wb_address_reg] <= packet_in;
		endcase

		current_state <= next_state;
	end: StateMachine

endmodule: Processor
