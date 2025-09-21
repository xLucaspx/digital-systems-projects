`default_nettype none

import Isa::*;

module Mul #(parameter NUM_BITS = 16) (
    input wire logic i_clock,
    input wire logic i_reset,
    Spi.SlaveSpi spi
);

	typedef enum logic [2:0] { RECEIVE, RECEIVING, OPERATE, SEND, SENDING } state_t;
	state_t current_state;
	state_t next_state;

	AluPacket packet_in;
	int counter_in;

	logic [REGISTER_SIZE - 1 : 0] packet_out;
	int counter_out;

	Instruction op_code;
	logic [REGISTER_SIZE - 1 : 0] op_1;
	logic [REGISTER_SIZE - 1 : 0] op_2;

	assign { op_2, op_1, op_code } = packet_in;

	assign spi.miso[1] = spi.nss[1] ? 1'b0
									: (current_state == SEND)    ? 1'b1
									: (current_state == SENDING) ? packet_out[counter_out]
									: 1'b0;

	always_comb
		if (~i_reset) next_state = RECEIVE;
		else case(current_state)
				RECEIVE:   next_state = (spi.mosi && ~spi.miso[1] && ~spi.nss[1]) ? RECEIVING : RECEIVE;
				RECEIVING: next_state = (counter_in == $bits(packet_in) - 1) ? OPERATE : RECEIVING;
				OPERATE:   next_state = SEND;
				SEND:      next_state = (~spi.mosi && spi.miso[1]) ? SENDING : SEND;
				SENDING:   next_state = (counter_out == $bits(packet_out) - 1) ? RECEIVE : SENDING;
				default:   next_state = RECEIVE;
		endcase

	always_ff @(posedge i_clock, negedge i_reset) begin: state_machine
		if (~i_reset) begin
			counter_in  <= 0;
			counter_out <= 0;
			packet_in   <= 0;
			packet_out  <= 0;
		end
		else begin
			case (current_state)
				RECEIVING: begin
					packet_in[counter_in] <= spi.mosi;
					counter_in <= (counter_in == $bits(packet_in) - 1) ? 0 : counter_in + 1;
				end
				OPERATE: packet_out <= op_1 * op_2;
				SENDING: counter_out <= (counter_out == $bits(packet_out) - 1) ? 0 : counter_out + 1;
			endcase

			current_state <= next_state;
		end
	end: state_machine

    
endmodule