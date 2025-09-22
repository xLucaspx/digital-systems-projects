`default_nettype none

import Isa::*;

/**
 * Mini serial processor. Communicates with the ALU through a SPI.
 *
 * TODO: 106 ciclos (1060ps / 5ps*2) = calculo qtd ciclos para realizar uma operação
 * TODO: finish doc
 *
 * TODO: waveform: add and configure cursors
 * TODO: barreiras temporais para instruções, e.g., inst_fetched, inst_decoded, inst_execute etc.
 *         - A primeira barreira temporal se refere apenas ao registro da instrução que será utilizada pelo DECODER;
 *
 * TODO: ALU_STORE vira STORE, guardamos o packet da vez na variável que será armazenada.
 * TODO: SEND, SENDING e RECEIVE em um estado só, controlado pela operação
 * TODO: Add Memory IF and PC; PC+4 logic
 *	input var Instruction i_instruction, // TODO inst can have two formats
 * TODO: check registers sizes
 * TODO: multiline align with spaces
 * TODO: kill m_active and use case nss 'b001, 'b010 ...
 * TODO: nss for each slave as a parameter (?)
 * TODO: waveform groups
 * TODO: module regbank (?)
 *
 * - i_clock:       System clock;
 * - i_reset:       Reset signal;
 * - i_instruction: Instruction to be executed. TODO: interface memory
 */
module Processor(
	input var logic i_clock,
	input var logic i_reset,
	input var Instruction i_instruction
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

	/**
	 * Register bank. There are REGISTER_BANK_SIZE positions, each with REGISTER_SIZE bits.
	 */
	logic [REGISTER_BANK_SIZE - 1 : 0] [REGISTER_SIZE - 1 : 0] registers;

	// logic [REGISTER_SIZE - 1 : 0] pc; // TODO PC

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

	logic alu_active;
	logic bas_active;
	logic mul_active;

	Operation operation;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_1;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_2;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;

	typedef enum logic [6:0] {
		FETCH     = 'b000_0001,
		EXECUTE   = 'b000_0010,
		SEND      = 'b000_0100,
		SENDING   = 'b000_1000,
		RECEIVE   = 'b001_0000,
		RECEIVING = 'b010_0000,
		STORE     = 'b100_0000
	} state_t;

	state_t current_state;
	state_t next_state;

	assign alu_active = operation inside { ADD, AND, OR };
	assign bas_active = operation inside { SHL, SHR };
	assign mul_active = operation == MUL;

	assign u_spi.sclk = i_clock;

	// `nss` deve ser 0 apenas quando quisermos transmitir/receber
	always_comb
		if (current_state inside { SEND, SENDING, RECEIVE, RECEIVING }) begin
			u_spi.nss[ALU_NSS_POSITION] = ~alu_active;
			u_spi.nss[BAS_NSS_POSITION] = ~bas_active;
			u_spi.nss[MUL_NSS_POSITION] = ~mul_active;
		end
		else u_spi.nss = '1;

	// define o MOSI
	always_comb case (current_state)
			SEND:    u_spi.mosi = 1'b1;
			SENDING: if (alu_active)      u_spi.mosi = alu_packet_out[alu_counter_out];
				       else if (mul_active) u_spi.mosi = mul_packet_out[mul_counter_out];
				       else if (bas_active) u_spi.mosi = bas_packet_out[bas_counter_out];
			default: u_spi.mosi = 1'b0;
	endcase

	always_comb
		if (~i_reset) next_state = FETCH;
		else case (current_state)
			FETCH:     next_state = (i_instruction != 'b0) ? EXECUTE : FETCH;
			EXECUTE:   next_state = SEND;
			SEND:      next_state = (~u_spi.miso && u_spi.mosi) ? SENDING : SEND;
			SENDING:   if (alu_active)      next_state = (alu_counter_out == $bits(alu_packet_out) - 1) ? RECEIVE : SENDING;
				         else if (mul_active) next_state = (mul_counter_out == $bits(mul_packet_out) - 1) ? RECEIVE : SENDING;
				         else if (bas_active) next_state = (bas_counter_out == $bits(bas_packet_out) - 1) ? RECEIVE : SENDING;
			RECEIVE:   next_state = (u_spi.miso && ~u_spi.mosi) ? RECEIVING : RECEIVE;
			RECEIVING: next_state = (counter_in == $bits(packet_in) - 1) ? STORE : current_state;
			STORE:     next_state = FETCH;
			default:   next_state = FETCH;
		endcase

	always_ff @(posedge i_clock, negedge i_reset) begin: StateMachine
		if (~i_reset) begin
			// pc              <= '0;
			rs_1            <= '0;
			rs_2            <= '0;
			rd              <= '0;
			packet_in       <= '0;
			counter_in      <= '0;
			alu_packet_out  <= '0;
			alu_counter_out <= '0;
			mul_packet_out  <= '0;
			mul_counter_out <= '0;
		end
		else case (current_state)
			// FETCH:    begin
			// 	ram_port_cpu.address <= pc;
			// 	pc <= pc + 1; // TODO ou + 4?
			// 	{ operation, rs_1, rs_2, rd } <= ram_port_memory.read_data;
			// end
			FETCH:     { operation, rs_1, rs_2, rd } <= i_instruction;

			SEND:      if (alu_active)      alu_packet_out <= { registers[rs_2], registers[rs_1], operation };
				         else if (mul_active) mul_packet_out <= { registers[rs_2], registers[rs_1] };
				         else if (bas_active) bas_packet_out <= { registers[rs_2], registers[rs_1], operation };

			SENDING:   if (alu_active)      alu_counter_out <= (alu_counter_out == $bits(alu_packet_out) - 1) ? 0 : alu_counter_out + 1;
				         else if (mul_active) mul_counter_out <= (mul_counter_out == $bits(mul_packet_out) - 1) ? 0 : mul_counter_out + 1;
				         else if (bas_active) bas_counter_out <= (bas_counter_out == $bits(bas_packet_out) - 1) ? 0 : bas_counter_out + 1;

			RECEIVING: begin
				packet_in[counter_in] <= u_spi.miso;
				counter_in <= (counter_in == $bits(packet_in) - 1) ? 0 : counter_in + 1;
			end

			STORE:     registers[rd] <= packet_in;
		endcase

		current_state <= next_state;
	end: StateMachine

endmodule: Processor
