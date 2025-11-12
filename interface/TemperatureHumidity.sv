`default_nettype none

interface TemperatureHumidity#(
	parameter int BITS_INFO = 16
)(
	input var logic i_clock
);

    logic want_data;
    logic [BITS_INFO -1 :0] temperature;
    logic [BITS_INFO -1 :0] humidity;
    logic valid_info;
    logic request_again;

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

endinterface: TemperatureHumidity