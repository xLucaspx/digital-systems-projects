`default_nettype none
`timescale 1ns / 1ps

/**
 * Module for printing the temperature values using a 7 segment display.
 *
 * [Wires]
 * - clk_100MHz: System clock.
 * - c_data:     Temp data from I2cMaster.
 * - SEG:        7 Segments of displays.
 * - AN:         4 Anodes of 8 to display temperature (degrees Celsius).
 */
module Seg7c(
	input clk_100MHz,
	input [9:0] c_data,
	output logic [6:0] SEG,
	output logic [7:0] AN
);

	localparam logic [7:0] ZERO  = 7'b000_0001;
	localparam logic [7:0] ONE   = 7'b100_1111;
	localparam logic [7:0] TWO   = 7'b001_0010;
	localparam logic [7:0] THREE = 7'b000_0110;
	localparam logic [7:0] FOUR  = 7'b100_1100;
	localparam logic [7:0] FIVE  = 7'b010_0100;
	localparam logic [7:0] SIX   = 7'b010_0000;
	localparam logic [7:0] SEVEN = 7'b000_1111;
	localparam logic [7:0] EIGHT = 7'b000_0000;
	localparam logic [7:0] NINE  = 7'b000_0100;
	localparam logic [7:0] DEG   = 7'b001_1100;
	localparam logic [7:0] C	 = 7'b011_0001;
	localparam logic [7:0] F	 = 7'b011_1000;

	logic [3:0] c_hundred;
	logic [3:0] c_tens;
	logic [3:0] c_ones;

	assign c_hundred = c_data / 100;
	assign c_tens = (c_data % 100) / 10;
	assign c_ones = c_data % 10;

	/**
	 * 2 bit counter for selecting each of 4 digits.
	 */
	logic [2:0] anode_select;

	/**
	 * Counter for digit refresh.
	 */
	logic [16:0] anode_timer;

	/**
	 * Logic for controlling digit select and digit timer.
	 */
	always_ff @(posedge clk_100MHz) begin
		// 1ms x 8 displays = 8ms refresh period. The period of 100MHz clock is 10ns (1/100,000,000 seconds)
		if (anode_timer == 99_999) begin
			anode_timer <= 0; // 10ns x 100,000 = 1ms
			anode_select <=  anode_select + 1;
		end
		else anode_timer <=  anode_timer + 1;
	end

	/**
	 * Logic for driving the 8 bit anode output based on digit select.
	 */
	always_ff @(posedge clk_100MHz)
		case (anode_select)
			3'o0: AN <= 8'b1111_1110;
			3'o1: AN <= 8'b1111_1101;
			3'o2: AN <= 8'b1111_1011;
			3'o3: AN <= 8'b1111_0111;
			3'o4: AN <= 8'b1110_1111;
			3'o5: AN <= 8'b1101_1111;
			3'o6: AN <= 8'b1011_1111;
			3'o7: AN <= 8'b0111_1111;
		endcase

	always_ff @(posedge clk_100MHz)
		case (anode_select)
			3'o0: SEG <= C;	// Set to C for Celsuis

			3'o1: SEG <= DEG; // Set to degrees symbol

			3'o2: case (c_ones) // C TEMPERATURE ONES DIGIT
				4'b0000: SEG <= ZERO;
				4'b0001: SEG <= ONE;
				4'b0010: SEG <= TWO;
				4'b0011: SEG <= THREE;
				4'b0100: SEG <= FOUR;
				4'b0101: SEG <= FIVE;
				4'b0110: SEG <= SIX;
				4'b0111: SEG <= SEVEN;
				4'b1000: SEG <= EIGHT;
				4'b1001: SEG <= NINE;
			endcase

			3'o3: case (c_tens) // C TEMPERATURE TENS DIGIT
				4'b0000: SEG <= ZERO;
				4'b0001: SEG <= ONE;
				4'b0010: SEG <= TWO;
				4'b0011: SEG <= THREE;
				4'b0100: SEG <= FOUR;
				4'b0101: SEG <= FIVE;
				4'b0110: SEG <= SIX;
				4'b0111: SEG <= SEVEN;
				4'b1000: SEG <= EIGHT;
				4'b1001: SEG <= NINE;
			endcase

			3'o4: case (c_hundred) // C TEMPERATURE HUNDRED DIGIT
				4'b0000: SEG <= ZERO;
				4'b0001: SEG <= ONE;
				4'b0010: SEG <= TWO;
				4'b0011: SEG <= THREE;
				4'b0100: SEG <= FOUR;
				4'b0101: SEG <= FIVE;
				4'b0110: SEG <= SIX;
				4'b0111: SEG <= SEVEN;
				4'b1000: SEG <= EIGHT;
				4'b1001: SEG <= NINE;
			endcase

			// Set zero:
			3'o5: SEG <= ZERO;
			3'o6: SEG <= ZERO;
			3'o7: SEG <= ZERO;
		endcase

endmodule: Seg7c
