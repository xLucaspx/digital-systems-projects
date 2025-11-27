`default_nettype none

/**
 * Módulo que programa a placa Nexys A7, fazendo a integração entre sensores e o mapeamento dos pinos, switches e botões
 * utilizados. Dispositivo: `xc7a100tcsg324-1`.
 *
 * [Wires]
 * - i_clock:             Sinal de clock da placa.
 * - i_reset:             Sinal de reset mapeado para o botão `N17`.
 * - i_simulation_switch: `1` para ativar a simulação, mapeado para o switch `V10`.
 * - i_fire_on:           `1` para aumentar a temperatura quando a simulação está ativa, mapeado para o switch `U11`.
 * - i_co2_sensor_data:   Dados do sensor de CO2, mapeado para o pino `AD10N`.
 * - i_flame_sensor:      Dados do sensor de chama, mapeado para o pino `AD11P`.
 * - b_temperature_sda:   I2C SDA (bidirecional) no sensor de temperatura.
 * - o_temperature_scl:   I2C SCL no sensor de temperatura.
 * - o_seg:               7 segmentos de cada display.
 * - o_an:                8 ânodos de 8 displays.
 * - o_leds:              Vetor de bits no qual cada posição representa um led da placa.
 * - o_led_r:             Led vermelho.
 * - o_led_g:             Led verde.
 * - o_led_b:             Led azul.
 * - o_pin_sound:         `1` para ativar o buzzer, mapeado para o pino `AD3P`.
 */
module TopNexysA7(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_simulation_switch,
	input var logic i_fire_on,
	input var logic i_co2_sensor_data,
	input var logic i_flame_sensor,

	inout tri b_temperature_sda,

	output var logic o_temperature_scl,
	output var logic [6:0] o_seg,
	output var logic [7:0] o_an,
	output var logic [15:0] o_leds,
	output var logic o_led_r,
	output var logic o_led_g,
	output var logic o_led_b,
	output var logic o_pin_sound
);

	logic sound;
	logic buzzer_sound;

	logic fire_signal;

	logic co2_signal;

	logic system_clock_200khz;
	logic [7:0] temperature_celsius;
	logic [11:0] temperature_celsius_extended;

	TemperatureHumidity u_temperature_humidity( .i_clock(i_clock) );

	Clkgen_200KHz u_clock_generator (
		.clk_100MHz(i_clock),
		.clk_200KHz(system_clock_200khz)
	);

	I2cMaster u_i2c_master (
		.clk_200KHz(system_clock_200khz),
		.temp_data(temperature_celsius),
		.temp_data_full_precision(temperature_celsius_extended),
		.SDA(b_temperature_sda),
		.SCL(o_temperature_scl)
	);

	Seg7c u_seg7_control (
		.clk_100MHz(i_clock),
		.c_data((u_temperature_metrics.data_array[9:0])),
		.SEG(o_seg),
		.AN(o_an)
	);

	TemperatureMetrics #(.Seconds(3)) u_temperature_metrics (
		.i_clock(i_clock),
		.i_reset(i_reset),
		.i_simulation(i_simulation_switch),
		.i_fire_on(i_fire_on),
		.i_temperature(temperature_celsius_extended),
		.provider(u_temperature_humidity)
	);

	FireController #(.Seconds(7)) u_fireController (
		.i_clock(i_clock),
		.i_reset(i_reset),
		.i_flame_sensor(i_flame_sensor),
		.o_fire(fire_signal),
		.costumer(u_temperature_humidity)
	);

	Co2Sensor u_Co2Sensor (
		.i_clock(i_clock),
		.i_reset(i_reset),
		.i_sensor_data(i_co2_sensor_data),
		.o_gas_detected(co2_signal)
	);

	SoundBuzzer u_soundBuzzer (
		.i_clock(i_clock),
		.i_reset(i_reset),
		.i_sound(sound),
		.o_pin_sound(buzzer_sound)
	);

	logic [23:0] counter_leds;

	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			o_leds <= 4'h0000;
			sound <= 0;
		end else begin
			o_leds [0] <= fire_signal;
			o_leds [1] <= i_flame_sensor;
			o_leds [2] <= sound;
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
				end
				else if (counter_leds[23] == 1'b0) begin
					o_led_r <= 0;
					o_led_g <= 1;
					o_led_b <= 0;
				end
				else begin
					o_led_r <= 0;
					o_led_g <= 0;
					o_led_b <= 1;
				end
			end
			else begin
				o_led_r <= 0;
				o_led_g <= 0;
				o_led_b <= 0;
			end
			o_pin_sound <= buzzer_sound;
		end
	end

endmodule: TopNexysA7
