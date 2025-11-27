`default_nettype none
`timescale 1ns / 1ps

/**
 * Gerador de clock.
 *
 * [Wires]
 * - clk_100MHz: Clock de entrada em 100 MHz.
 * - clk_200KHz: Clock de saída em 200 KHz.
 */
module Clkgen_200KHz(
	input var logic clk_100MHz,
	output var logic clk_200KHz
);

	// 100 x 10^6 / 200 x 10^3 / 2 = 250 <-- 8 bit counter
	logic [7:0] counter = 8'h00;
	logic clk_reg = 1'b1;

	always_ff @(posedge clk_100MHz) begin
		if (counter == 249) begin
			counter <= 8'h00;
			clk_reg <= ~clk_reg;
		end else counter <= counter + 1;
	end

	assign clk_200KHz = clk_reg;

endmodule: Clkgen_200KHz
