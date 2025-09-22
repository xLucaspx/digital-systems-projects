`default_nettype none

import Isa::*;

/**
 * Mini serial processor. Communicates with the ALU through an SPI.
 *
 * [wire] i_clock:       System clock;
 * [wire] i_reset:       Reset signal;
 * [wire] i_instruction: Instruction to be executed.
 */
module Processor(
	input var logic i_clock,
	input var logic i_reset,
	input var Instruction i_instruction
);

	/**
	 * SPI interface for communication with the Alu.
	 */
	Spi#(1) u_spi();

	/**
	 * Arithmetic logic unit instance.
	 */
	Alu u_alu(
		.i_clock(i_clock),
		.i_reset(i_reset),
		.spi(u_spi)
	);

	/**
	 * Register bank. There are REGISTER_BANK_SIZE positions, each with REGISTER_SIZE bits.
	 */
	logic [REGISTER_BANK_SIZE - 1 : 0] [REGISTER_SIZE - 1 : 0] registers;

	/*
	 * Packet that will be received from the ALU.
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

	AluOperation operation;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_1;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rs_2;
	logic [$clog2(REGISTER_BANK_SIZE) - 1 : 0] rd;

	typedef enum logic [6:0] {
		FETCH     = 7'b000_0001,
		EXECUTE   = 7'b000_0010,
		SEND      = 7'b000_0100,
		SENDING   = 7'b000_1000,
		RECEIVE   = 7'b001_0000,
		RECEIVING = 7'b010_0000,
		STORE     = 7'b100_0000
	} state_t;

	state_t current_state;
	state_t next_state;

	assign u_spi.sclk = i_clock;

	assign u_spi.nss = ~(current_state inside { SEND, SENDING, RECEIVE, RECEIVING });

	assign u_spi.mosi = (current_state == SEND)    ? 1'b1
		                : (current_state == SENDING) ? alu_packet_out[alu_counter_out]
		                : 1'b0;

	always_comb
		if (~i_reset) next_state = FETCH;
		else case (current_state)
			FETCH:     next_state = (i_instruction == 'b0) ? FETCH : EXECUTE;
			EXECUTE:   next_state = SEND;
			SEND:      next_state = (~u_spi.miso && u_spi.mosi) ? SENDING : SEND;
			SENDING:   next_state = (alu_counter_out == $bits(alu_packet_out) - 1) ? RECEIVE : SENDING;
			RECEIVE:   next_state = (u_spi.miso && ~u_spi.mosi) ? RECEIVING : RECEIVE;
			RECEIVING: next_state = (counter_in == $bits(packet_in) - 1) ? STORE : RECEIVING;
			STORE:     next_state = FETCH;
			default:   next_state = FETCH;
		endcase

	always_ff @(posedge i_clock, negedge i_reset) begin: StateMachine
		if (~i_reset) begin
			rs_1            <= 0;
			rs_2            <= 0;
			rd              <= 0;
			counter_in      <= 0;
			packet_in       <= 0;
			alu_counter_out <= 0;
			alu_packet_out  <= 0;
		end
		else case (current_state)
			EXECUTE: begin
				{ operation, rs_1, rs_2, rd } <= i_instruction;
			end
			SEND: begin
				alu_packet_out <= { registers[rs_2], registers[rs_1], operation };
			end
			SENDING: begin
				alu_counter_out <= (alu_counter_out == $bits(alu_packet_out) - 1) ? 0 : alu_counter_out + 1;
			end
			RECEIVING: begin
				packet_in[counter_in] <= u_spi.miso;
				counter_in <= (counter_in == $bits(packet_in) - 1) ? 0 : counter_in + 1;
			end
			STORE: registers[rd] <= packet_in;
		endcase

		current_state <= next_state;
	end: StateMachine

endmodule: Processor
