`default_nettype none

/**
 * Device: xc7a100tcsg324-1
 *
 * i_clock: Sinal de clock da placa;
 * i_reset: Sinal de reset mapeado para o botão `n17`;
 * o_leds: Vetor de bits no qual cada posição representa um led da placa.
 */
module TopNexysA7(
	input var logic i_clock,
	input var logic i_reset,

	output var logic [15:0] o_leds
);

	int counter;

	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			o_leds <= 'b0101010101010100;
			counter <= '0;
		end else begin
			if (counter == 100_000_000) begin
				o_leds <= ~o_leds;
				counter <= 0;
			end else counter <= counter + 1;
		end
	end

endmodule: TopNexysA7
