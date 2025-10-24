`default_nettype none

module edge_detector(
	input var logic clock,
	input var logic reset,
	input var logic din,

	output var logic rising
);

reg din_reg;

assign rising = (din_reg == 1'b0 && din == 1'b1);

always @(posedge clock, posedge reset)
	din_reg <= (reset == 1'b1) ? 1'b0 : din;

endmodule: edge_detector
