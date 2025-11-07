module EdgeDetector(
  input var logic i_clock,
  input var logic i_reset,
  input var logic i_din,
  output var logic o_rising
);

  reg din_reg;

  assign o_rising = (din_reg == 1'b0 && i_din == 1'b1) ? 1'b1 : 1'b0;

  always @(posedge i_clock, negedge i_reset) begin
    if (~i_reset == 1'b1) begin
      din_reg <= 1'b0;
    end
    else begin
      din_reg <= i_din;
    end
  end

endmodule