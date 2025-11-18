`default_nettype none

/**
 * Módulo para comunicação com o sensor de gás carbônico (CO2). Identificador do sensor: FC-22 + MG811.
 */
module Co2Sensor#(
	parameter integer SECONDS = 5,
	parameter integer FREQUENCY = 100_000_000 // 100_000_000 clocks period is 10 ns = 1s
	)
(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_sensor_data,

	output var logic o_gas_detected
);
logic gas_detected;
integer clock_counter;
integer count_seconds;
	always_ff @(posedge i_clock, posedge i_reset)
		o_gas_detected <= i_reset ? 1'b0 : gas_detected;

	/**
	* Detect CO2 gas presence logic after a certain period of time
	*/
	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			gas_detected <= 1'b0;
			clock_counter <= 0;
			count_seconds <= 0;
		end
		else begin
			if (count_seconds >= SECONDS) begin
				gas_detected <= 1'b1;
				count_seconds <= 0;
			end
			else if (clock_counter == FREQUENCY -1) begin
				clock_counter <= 1'b0;
				count_seconds <= count_seconds + 1;
			end
			else if (~i_sensor_data) begin
				clock_counter <= clock_counter + 1;
			end
			else begin
				clock_counter <=  1'b0;
				count_seconds <= 0;
				gas_detected <= 1'b0;
			end
		end
	end

endmodule: Co2Sensor
