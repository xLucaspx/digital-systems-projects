`default_nettype none

import Isa::*;

/**
 * Barrel shifter block for the mini serial processor. The communication with the processor occurs through an SPI, with
 * the shifter acting as a slave. Should receive an `ShifterPacket` from the processor and return the `REGISTER_SIZE`
 * result of the operation.
 *
 * - i_clock: System clock;
 * - i_reset: Reset signal;
 * - spi:     SlaveSpi interface for communication with the processor.
 */
module BarrelShifter#(parameter int NssPosition = 0)(
	input var logic i_clock,
	input var logic i_reset,

	Spi.SlaveSpi spi
);

	typedef enum logic [2:0] { RECEIVE, RECEIVING, OPERATE, SEND, SENDING } state_t;

	state_t current_state;
	state_t next_state;

	logic is_active;

	ShifterPacket packet_in;
	int counter_in;

	logic [REGISTER_SIZE - 1 : 0] packet_out;
	int counter_out;

	Operation op_code;
	logic [REGISTER_SIZE - 1 : 0] op;
	logic [$clog2(REGISTER_SIZE) - 1 : 0] shift_amount;

	assign { shift_amount, op, op_code } = packet_in;

	assign is_active = !spi.nss[NssPosition];
	assign spi.miso = !is_active ? 1'bz
		              : (current_state == SEND)    ? 1'b1
		              : (current_state == SENDING) ? packet_out[counter_out]
		              : 1'b0;

	always_comb
		if (!i_reset) next_state = RECEIVE;
		else case(current_state)
			RECEIVE:   next_state = (is_active && spi.mosi && !spi.miso) ? RECEIVING : RECEIVE;
			RECEIVING: next_state = (counter_in == $bits(packet_in) - 1) ? OPERATE : RECEIVING;
			OPERATE:   next_state = SEND;
			SEND:      next_state = (is_active && !spi.mosi && spi.miso) ? SENDING : SEND;
			SENDING:   next_state = (counter_out == $bits(packet_out) - 1) ? RECEIVE : SENDING;
			default:   next_state = RECEIVE;
		endcase

	always_ff @(posedge i_clock, negedge i_reset) begin: state_machine
		if (!i_reset) begin
			counter_in  <= 0;
			counter_out <= 0;
			packet_in   <= 0;
			packet_out  <= 0;
		end
		else case (current_state)
			RECEIVING: begin
				packet_in[counter_in] <= spi.mosi;
				counter_in <= (counter_in == $bits(packet_in) - 1) ? 0 : counter_in + 1;
			end
			OPERATE: begin
				case (op_code)
					SHL:     packet_out <= (op << shift_amount) | (op >> (REGISTER_SIZE - shift_amount));
					SHR:     packet_out <= (op >> shift_amount) | (op << (REGISTER_SIZE - shift_amount));
					default: packet_out <= '0;
				endcase
			end
			SENDING: counter_out <= (counter_out == $bits(packet_out) - 1) ? 0 : counter_out + 1;
		endcase

		current_state <= next_state;
	end: state_machine

endmodule: BarrelShifter
