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
	input var logic i_simulation_switch,// V10 Switch
	input var logic i_fire_on, 			// U11 Switch
	input var logic i_co2_sensor_data, 	// Pin AD10N
	input var logic i_flame_sensor,		// Pin AD11P

	inout tri        TMP_SDA,          			// i2c sda on temp sensor - bidirectional

    output var logic       TMP_SCL,          	// i2c scl on temp sensor
	output var logic [6:0]  SEG,              	// 7 segments of each display
    output var logic [7:0]  AN,              	// 8 anodes of 8 displays
	output var logic [15:0] o_leds,
	output var logic o_led_r,				 	// Red led rgb
	output var logic o_led_g,				 	// Green led rgb
	output var logic o_led_b,				 	// Blue led rgb
	output var logic o_pin_sound 				// Pin AD3P
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
FireController #(.SECONDS(7)) u_fireController (
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


TemperatureMetrics #(.SECONDS(3)) u_temperatureMetrics (
	.i_clock(i_clock),
	.i_reset(i_reset),
	.i_simulation(i_simulation_switch),
	.i_fire_on(i_fire_on),
	.i_temperature(c_extended_data),
	.provider(u_temperatureHumidity)
);

Seg7c segcontrol(
	.clk_100MHz(i_clock),
	.c_data((u_temperatureMetrics.data_array[9:0])), // 10 bits Celsius temperature data
	.SEG(SEG),
	.AN(AN)
);

logic [23:0] counter_leds;
always_ff @(posedge i_clock, posedge i_reset) begin
	if (i_reset) begin
		o_leds <= 4'h0000;
		sound <= 0;
	end else begin
		o_leds [0] <= fire_signal ? 1'b1 : 1'b0;
		o_leds [1] <= i_flame_sensor ? 1'b1 : 1'b0;
		o_leds [2] <= sound ? 1'b1 : 1'b0;
		o_leds [15] <= i_simulation_switch;
		o_leds [14] <= i_fire_on;
		sound <= co2_signal;

		// led RGB only shows when it is simulating
		if (i_simulation_switch && fire_signal) begin
			counter_leds <= counter_leds + 1;
			if (counter_leds[22] == 1'b0) begin
				o_led_r <= 1;
				o_led_g <= 0;
				o_led_b <= 0;
			end else if (counter_leds[23] == 1'b0) begin
				o_led_r <= 0;
				o_led_g <= 1;
				o_led_b <= 0;
			end
			else begin
				o_led_r <= 0;
				o_led_g <= 0;
				o_led_b <= 1;
			end
		end else begin
			o_led_r <= 0;
			o_led_g <= 0;
			o_led_b <= 0;
		end
		o_pin_sound <= buzzer_sound;
	end
end

endmodule: TopNexysA7
