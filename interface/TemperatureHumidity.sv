`default_nettype none

/**
 * Interface para comunicação com o sensor de temperatura e umidade.
 *
 * [Parameters]
 * - BitsInfo: Número de bits da informação.
 *
 * [Wires]
 * - i_clock:       Clock do sistema.
 * - want_data:     `1` se o `Costumer` deseja receber os dados, `0` caso contrário.
 * - temperature:   Temperatura lida pelo sensor;
 * - humidity:      Umidade lida pelo sensor;
 * - valid_info:    `1` se as informações lidas pelo sensor são válidas, `0` caso contrário.
 * - request_again: `1` se o `Costumer`deseja receber os dados novamente, `0` caso contrário.
 */
interface TemperatureHumidity#(parameter int BitsInfo = 16)(
	input var logic i_clock
);

	var logic want_data;
	var logic [BitsInfo - 1 : 0] temperature;
	var logic [BitsInfo - 1 : 0] humidity;
	var logic valid_info;
	var logic request_again;

	modport Provider (
		input want_data,
		output temperature,
		output humidity,
		output valid_info,
		output request_again
	);

	modport Costumer (
		input temperature,
		input humidity,
		input valid_info,
		input request_again,

		output want_data
	);

	function automatic logic [BitsInfo - 1 : 0] get_temperature();
		return temperature;
	endfunction

	function automatic logic [BitsInfo - 1 : 0] get_humidity();
		return humidity;
	endfunction

endinterface: TemperatureHumidity
