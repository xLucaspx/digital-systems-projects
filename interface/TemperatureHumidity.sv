`default_nettype none

interface TemperatureHumidity#(
	parameter int BITS_INFO = 16
)(
	input var logic i_clock
);

    var logic want_data;
    var logic [BITS_INFO -1 :0] temperature;
    var logic [BITS_INFO -1 :0] humidity;
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

    function logic [BITS_INFO -1:0] get_temperature();
        return temperature;
    endfunction

    function logic [BITS_INFO -1:0] get_humidity();
        return humidity;
    endfunction


endinterface: TemperatureHumidity