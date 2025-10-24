`default_nettype none

// device: xc7a100tcsg324-1
module top_nexys_a7#()(
	input var logic clock, // clock, from board
	input var logic reset, // button n17 (middle)
	input var logic btn, // button p18 (bottom)

	output var logic[15:0] LED // leds, actual shifting result
);

	int counter;
	logic suvaco;
	logic btn_pressed;

	edge_detector u_ed (.clock(clock), .reset(reset), .din(btn), .rising(btn_pressed) );

	always @(posedge clock, posedge reset) begin
		if (reset) begin
			LED <= 'b0101010101010100;
			counter <= '0;
		end else begin
			if (rising) LED <= '1;
			else if (counter == 100_000_000) begin
				suvaco <= LED[15];
				LED <= LED << 1;
				LED[0] <= suvaco;
				counter <= 0;
			end else counter <= counter + 1;
		end
	end

endmodule: top_nexys_a7
