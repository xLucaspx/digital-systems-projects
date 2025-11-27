`default_nettype none
`timescale 1ns/1ps

module TopNexysA7Tb;

logic clock = 0;
initial forever #1 clock = ~clock;

logic reset = 1;

logic co2_sensor_data;
logic co2_signal;

logic sound = 0;
logic buzzer_sound;

logic fire_signal;
logic flame_senor = 1;
logic reset_fire = 1;

logic set_temperature_edge = 0;
logic [11:0] c_extended_data = 12'h100;

Co2Sensor #(.Frequency(1)) u_co2_sensor (
	.i_clock(clock),
	.i_reset(reset),
	.i_sensor_data(co2_sensor_data),
	.o_gas_detected(co2_signal)
);

SoundBuzzer #(.Frequency(10)) u_sound_buzzer (
	.i_clock(clock),
	.i_reset(reset),
	.i_sound(sound),
	.o_pin_sound(buzzer_sound)
);

TemperatureHumidity u_temperature_humidity( .i_clock(clock) );

FireController #(.Frequency(100)) u_fire_controller (
	.i_clock(clock),
	.i_reset(reset_fire),
	.o_fire(fire_signal),
	.i_flame_sensor(flame_senor),
	.costumer(u_temperature_humidity)
);

TemperatureMetrics #(.Frequency(100)) u_temperature_metrics (
	.i_clock(clock),
	.i_reset(reset),
	.i_simulation('0),
	.i_fire_on(set_temperature_edge),
	.i_temperature(c_extended_data),
	.provider(u_temperature_humidity)
);

initial begin
	repeat (5) @(posedge clock);
	reset = 0;

	$display ("================================");
	$display ("Testing CO2 Sensor");
	$display ("================================");
	
	repeat (3) begin
		co2_sensor_data = 0;
		#20;
		if (co2_signal == 1) begin
			$display ("[PASSED] CO2 detected as expected");
		end else begin
			$display ("[FAILED] CO2 not detected when it should be");
		end
		co2_sensor_data = 1;
	end

	$display ("================================");
	$display ("Testing Buzzer");
	$display ("================================");

	sound = 1;
	repeat (3) begin
		@(posedge buzzer_sound);
		@(negedge buzzer_sound);
		$display ("Buzzer is making sound");
	end

	sound = 0;
	if (buzzer_sound == 0) begin
		$display ("Buzzer stopped");
	end else begin
		$display ("Buzzer did not stop");
	end

	$display ("================================");
	$display ("Testing Fire Controller");
	$display ("================================");
	
	reset_fire= 0;
	flame_senor =1;
	#2;
	if (fire_signal == 1) begin
		$display ("[PASSED] Flame detected as expected");
	end else begin
		$display ("[FAILED] Flame not detected when it should be");
	end

	flame_senor = 0;
	set_temperature_edge = 1;
	#2;
	set_temperature_edge = 0;
	#10;
	c_extended_data = 12'h110; // Simulate temperature increase
	wait (fire_signal == 1);
	repeat (10) begin
		@(posedge clock)
		$display ("Current Temperature: %0d", u_temperature_humidity.temperature);
	end
	$display ("[PASSED] Fire detected due to temperature rise");

	$finish;
end

endmodule: TopNexysA7Tb
