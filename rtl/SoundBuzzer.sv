`default_nettype none

/**
 * Módulo para comunicação com o buzzer.
 */
module SoundBuzzer #(
    /**
	 * Define o frequência de geração de som no buzzer.
	 */
    parameter integer FREQUENCY = 10_000_000
)(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_sound,

	output var logic o_pin_sound
);


	integer counter = 0;

	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			counter <= 0;
			o_pin_sound <= 0;
		end else begin
			if (i_sound && counter == FREQUENCY) begin
				o_pin_sound <= ~o_pin_sound;
				counter <= 0;
			end else if (i_sound) begin
				counter <= counter + 1;
			end else begin
				o_pin_sound <= 0;
				counter <= 0;
			end
		end
	end

endmodule: SoundBuzzer
