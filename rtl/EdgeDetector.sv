`default_nettype none

/**
 * Detector de borda.
 */
module EdgeDetector(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_din,

	output var logic o_rising
);

	logic din_reg;

	always_ff @(posedge i_clock, posedge i_reset)
		din_reg <= i_reset ? 1'b0 : i_din;

	assign o_rising = !din_reg && i_din;

endmodule: EdgeDetector
