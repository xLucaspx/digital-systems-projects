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
	input var logic i_reset, 			// N17 (Mid Button)
	input var logic i_co2_sensor_data, 	// Pin AD10N
	input var logic i_change_mode,		// M18 (Up Button)

	inout tri b_inout_data_temperature_sensor, // Pin AD3N

	output var logic [15:0] o_leds,
	output var logic o_pin_sound // Pin AD3P
);

logic sound;
logic buzzer_sound;
SoundBuzzer #(.FREQUENCY(10)) u_soundBuzzer (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_sound(sound),
	.o_pin_sound(buzzer_sound)
);

TemperatureHumidity u_temperatureHumidity(.i_clock(i_clock));

TemperatureHumiditySensor #(
	.SIZE_OF_DATA(40)
) u_temperatureHumiditySensor (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.b_data(b_inout_data_temperature_sensor),
	.provider(u_temperatureHumidity)
);

logic fire_signal;
FireController #(.SECONDS(5)) u_fireController (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.o_fire(fire_signal),
	.costumer(u_temperatureHumidity)
);

logic co2_signal;
Co2Sensor u_Co2Sensor (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_sensor_data(i_co2_sensor_data),
	.o_gas_detected(co2_signal)
);


integer mode;
always_ff @(posedge i_clock, posedge i_reset) begin
	if (i_reset) begin
		o_leds <= 'b0101010101010101;
		sound <= 0;
		mode <= 0;
	end else begin
		// LEDS AND SOUND MODE
		if (mode == 0) begin
			o_leds [15:8] <= fire_signal ? 8'b1111_1111 : 8'b0000_0000;
			o_leds [7:0] <= co2_signal ? 8'b1111_1111 : 8'b0000_0000;
			sound <= fire_signal | co2_signal;
		end else if (mode == 1) begin
			// TEMPERATURE
			o_leds [15:0] <= u_temperatureHumidity.get_temperature();
			sound <= 0;
		end else if (mode == 2) begin
			// Humidity
			o_leds [15:0] <= u_temperatureHumidity.get_humidity();
			sound <= 0;
		end
		o_pin_sound <= buzzer_sound;
	end
end

logic change_mode_edge;
logic changed;
EdgeDetector u_edgeDetector (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_din(i_change_mode),
	.o_rising(change_mode_edge)
);

always_ff @(posedge i_clock, posedge i_reset) begin
	if (i_reset) begin
		changed <= 0;
	end else begin
		// Change mode logic
		if (change_mode_edge && changed == 1'b0) begin
			mode <= (mode + 1) % 3;
			changed <= 1;
		end else if (!change_mode_edge) begin
			changed <= 0;
		end

	end
end

endmodule: TopNexysA7
