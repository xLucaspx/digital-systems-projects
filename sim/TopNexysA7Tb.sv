`default_nettype none
`timescale 1ns/1ps

module TopNexysA7Tb;

logic clock = 0;
always #1 clock = ~clock;

logic reset = 0;
initial begin
	repeat (5) @(posedge clock);
	reset = 1;
end

endmodule: TopNexysA7Tb
