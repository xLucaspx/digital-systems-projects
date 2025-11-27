`default_nettype none

/**
 * Módulo que controla a detecção do fogão ligado com base em variações de temperatura.
 *
 * [Parameters]
 * - BitsInfo: Número de bits da informação.
 * - Seconds:   Número de segundos para checar o sensor.
 * - Frequency: Frequência de operação.
 *
 * [Wires]
 * - i_clock:        Clock do sistema.
 * - i_reset:        `1` se o reset está ativo, `0` caso contrário.
 * - i_flame_sensor: Dados lidos pelo sensor;
 * - o_fire:         `1` se foi detectado fogo, `0` caso contrário;
 * - costumer:       Interface Constumer de TemperatureHumidity para comunicação com o sensor.
 */
module FireController#(
	parameter integer BitsInfo = 16,
	parameter integer Seconds = 30,
	parameter integer Frequency = 100_000_000
)(
	input var logic i_clock,
	input var logic i_reset,
	input var logic i_flame_sensor,
	output var logic o_fire,
	TemperatureHumidity.Costumer costumer
);

	logic [BitsInfo - 1 : 0] old_temp;
	logic [BitsInfo - 1 : 0] actual_temp;

	/**
	 * State machine definition
	 */
	typedef enum logic [1:0] {
		WAITING,
		REQUEST,
		PROCESS,
		RECEIVE
	} state_t;

	state_t state, next_state;
	logic fire_detected;
	assign o_fire = (fire_detected || i_flame_sensor) ? 1'b1 : 1'b0;

	/**
	 * Simple logic to detect a change in temperature.
	 */
	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			old_temp <= 0;
			actual_temp <= 0;
			state <= WAITING;
			fire_detected <= 0;
		end else begin
			state <= next_state;

			if (state == REQUEST) costumer.want_data <= 1;
			else if (state == RECEIVE) begin
				costumer.want_data <= 0;
				if (costumer.valid_info) begin
					actual_temp <= costumer.temperature;
					old_temp <= actual_temp;
				end
			end else if (state == PROCESS) begin
			// The difference between old and actual temperature to detect a fire condition is set to 2.0 degrees Celsius.
				if (actual_temp > old_temp + 1) fire_detected <= 1;
				else fire_detected <= 0;
			end
		end
	end

	/**
	 * Time counter logic
	 */
	integer timer;
	integer clock_counter;

	always_ff @(posedge i_clock, posedge i_reset) begin
		if (i_reset) begin
			timer <= 0;
			clock_counter <= 0;
		end else
		if (state == WAITING) begin
			if (clock_counter == Frequency) begin
				timer <= timer + 1;
				clock_counter <= 0;
			end
			else clock_counter <= clock_counter + 1;
		end else begin
			clock_counter <= 0;
			timer <= 0;
		end
	end

	/**
	 * Next state logic
	 */
	always_comb begin
		case (state)
			WAITING: next_state = (timer != Seconds) ? WAITING : REQUEST;
			REQUEST: next_state = RECEIVE;
			// The costumer module will inform if the data is valid or if it needs to request again
			RECEIVE: next_state = (costumer.valid_info == costumer.request_again) ? RECEIVE : PROCESS;
			PROCESS: next_state = WAITING;
			default: next_state = WAITING;
		endcase
	end

endmodule: FireController
