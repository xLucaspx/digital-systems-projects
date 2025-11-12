`default_nettype none

/**
 * Módulo para comunicação com o sensor de gás carbônico (CO2). Identificador do sensor: FC-22 + MG811.
 */
module Co2Sensor(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_sensor_data,

	output var logic o_gas_detected
);

	always_ff @(posedge i_clock, posedge i_reset)
		o_gas_detected <= i_reset ? 1'b0 : i_sensor_data;

endmodule: Co2Sensor
