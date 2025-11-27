`default_nettype none

/*
 * Módulo que controla a lógica da leitura de temperatura e envia dados ao provider.
 *
 * [Parameters]
 * - Seconds:   Número de segundos para checar o sensor.
 * - Frequency: Frequência de operação.
 *
 * [Wires]
 * - i_clock:       Sinal de clock da placa.
 * - i_reset:       Sinal de reset mapeado para o botão `N17`.
 * - i_simulation:  `1` quando a simulação está ativo, `0` caso contrário.
 * - i_fire_on:     `1` para aumentar a temperatura quando a simulação está ativa.
 * - i_temperature: Temperatura em graus Celsius.
 * - provider:      Interface Provider de TemperatureHumidity para comunicação com o sensor.
 */
module TemperatureMetrics#(
	parameter integer Seconds = 3,
	parameter integer Frequency = 100_000_000
)(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_simulation,
	input var logic i_fire_on,
	input var logic [11:0] i_temperature,

	TemperatureHumidity.Provider provider
);

	typedef enum logic [1:0] { IDLE, SEND } state_t;

	state_t state;
	state_t next_state;

	logic [9 :0] data_array;
	logic [7 :0] standard_temperature;

	always_ff @(posedge i_clock , posedge i_reset) begin
		if (i_reset) begin
			state <= IDLE;
			provider.humidity <= 0;
			provider.temperature <= 0;
			provider.valid_info <= 0;
			provider.request_again <= 0;
		end else begin
			state <= next_state;
			standard_temperature <= (~i_simulation) ? get_not_decimal_temperature() : standard_temperature;

			if (state == IDLE) begin
				provider.valid_info <= 0;
				provider.request_again <= 0;
			end else begin
				provider.humidity <= 0;
				provider.temperature <= data_array;
				provider.valid_info <= 1;
				provider.request_again <= 0;
			end
		end
	end

	integer clock_counter;
	integer timer;

	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			clock_counter <= 0;
			timer <= 0;
			data_array <= 0;
		end
		else begin
			if (timer == Seconds) begin
				timer <= 0;

				if (~i_fire_on) data_array <= (data_array > standard_temperature) ? data_array - 1 : data_array;
				else begin
					data_array <= (data_array < 100) ? data_array + 3
					            : (data_array < 180) ? data_array + 2
					            : (data_array < 220) ? data_array + 1
					            : data_array - 1;
				end
			end
			else if (clock_counter == Frequency) begin
				timer <= timer + 1;
				clock_counter <= 0;
			end else if (i_simulation) clock_counter <= clock_counter + 1;
			else begin
				clock_counter <= 0;
				data_array <= get_not_decimal_temperature();
			end
		end
	end

function automatic logic [7:0] get_not_decimal_temperature();
	return i_temperature[10:3];
endfunction

	always_comb case (state)
		IDLE:    next_state = (provider.want_data) ? SEND : IDLE;
		SEND:    next_state = IDLE;
		default: next_state = IDLE;
	endcase

endmodule: TemperatureMetrics
