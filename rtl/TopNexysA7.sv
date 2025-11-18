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
	input var logic i_set_standard,		// P17 (Left Button)
	input var logic i_co2_sensor_data, 	// Pin AD10N
	input var logic i_flame_sensor,		// Pin AD11P
	input var logic i_change_mode,		// M18 (Up Button)

	inout tri        TMP_SDA,          // i2c sda on temp sensor - bidirectional
	inout tri b_inout_data_temperature_sensor, // Pin AD2P

    output var logic       TMP_SCL,          // i2c scl on temp sensor
	output var logic [6:0]  SEG,              // 7 segments of each display
    output var logic [7:0]  AN,               // 8 anodes of 8 displays
	output var logic [15:0] o_leds,
	output var logic o_pin_sound // Pin AD3P
);

logic sound;
logic buzzer_sound;
SoundBuzzer u_soundBuzzer (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_sound(sound),
	.o_pin_sound(buzzer_sound)
);

TemperatureHumidity u_temperatureHumidity(.i_clock(i_clock));

logic fire_signal;
FireController #(.SECONDS(10)) u_fireController (
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

wire w_200KHz;                  // 200kHz SCL
wire [7:0] c_data;              // 8 bits of Celsius temperature data
wire [7:0] f_data;              // 8 bits of Fahrenheit temperature data
wire [11:0] c_extended_data;

// Instantiate i2c master
I2cMaster i2cmaster(
	.clk_200KHz(w_200KHz),
	.temp_data(c_data),
	.temp_data_full_precision(c_extended_data),
	.SDA(TMP_SDA),
	.SCL(TMP_SCL)
);

// Instantiate 200kHz clock generator
Clkgen_200KHz clkgen(
	.clk_100MHz(i_clock),
	.clk_200KHz(w_200KHz)
);

Seg7c segcontrol(
	.clk_100MHz(i_clock),
	.c_data((u_temperatureHumidity.temperature[9:0])), // 10 bits Celsius temperature data
	.SEG(SEG),
	.AN(AN)
);


logic change_mode_edge;
EdgeDetector u_edgeDetector (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_din(i_change_mode),
	.o_rising(change_mode_edge)
);

logic set_temperature_edge;
EdgeDetector u_edgeDetector2 (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_din(i_set_standard),
	.o_rising(set_temperature_edge)
);

TemperatureMetrics #(.SECONDS(3)) u_temperatureMetrics (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_set_standard_temperature(set_temperature_edge),
	.i_temperature(c_extended_data),
	.provider(u_temperatureHumidity)
);

integer mode;
always_ff @(posedge i_clock, posedge i_reset) begin
	if (i_reset) begin
		o_leds <= 'b0101010101010101;
		sound <= 0;
		mode <= 0;
	end else begin

		if (change_mode_edge) begin
			o_leds <= 'b0000000000000000;
			mode <= (mode + 1) % 4;
		end else begin

		// LEDS AND SOUND MODE
		if (mode == 0) begin
			o_leds [15:0] <= fire_signal ? 8'b1111_1111_1111_1111 : 8'b0000_0000_0000_0000;
			sound <= co2_signal;
		end else if (mode == 1) begin
			sound <= 0;
		end else if (mode == 2) begin
			// TEMPERATURE
			o_leds [15:0] <= u_temperatureHumidity.get_temperature();
			sound <= 0;
		end else if (mode == 3) begin
			// Humidity
		  	sound <= 0;
		end
		o_pin_sound <= buzzer_sound;
	end
	end
end

endmodule: TopNexysA7
