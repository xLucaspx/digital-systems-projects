`default_nettype none

/**
 * Module to control fire detection based on temperature changes.
 */
module FireController#(
    parameter integer BITS_INFO = 16,
    parameter integer SECONDS = 30,
    parameter integer FREQUENCY = 100_000_000)( // 100_000_000 clocks period is 10 ns = 1s
    input var logic i_clock,
    input var logic i_reset,
    input var logic i_flame_sensor,
    output var logic o_fire,

    TemperatureHumidity.Costumer costumer
);
logic [BITS_INFO -1 :0] old_temp;
logic [BITS_INFO -1 :0] actual_temp;

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
assign o_fire = (fire_detected || ~i_flame_sensor) ? 1'b1 : 1'b0;
// Simple logic to detect a change in temperature
always_ff @(posedge i_clock, posedge i_reset) begin
    if (i_reset) begin
        old_temp <= 0;
        actual_temp <= 0;
        state <= WAITING;
        fire_detected <= 0;
    end else begin
        state <= next_state;
        if (state == REQUEST) begin
            costumer.want_data <= 1;
        end else if (state == RECEIVE) begin
            costumer.want_data <= 0;
            if (costumer.valid_info) begin
                actual_temp <= costumer.temperature;
                old_temp <= actual_temp;
            end
        end else if (state == PROCESS) begin
            // The difference between the old temperature and the actual temperature
            // to detect a fire condition is set to 2.0 degrees Celsius.
            if (actual_temp > old_temp + 1) begin
                fire_detected <= 1;
            end else begin
                fire_detected <= 0;
            end
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
        if (clock_counter == FREQUENCY) begin
            timer <= timer + 1;
            clock_counter <= 0;
        end else begin
            clock_counter <= clock_counter + 1;
        end
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
        WAITING: begin
            if (timer != SECONDS) begin
                next_state = WAITING;
            end else begin
                next_state = REQUEST;
            end
        end

        REQUEST: begin
                next_state = RECEIVE;
        end

        RECEIVE: begin
            // The costumer module will inform if the data is valid or if it needs to request again
            if (costumer.valid_info == costumer.request_again) begin
                next_state = RECEIVE;
            end else begin
                next_state = PROCESS;
            end
        end

        PROCESS: begin
                next_state = WAITING;
        end
        default: begin
            next_state = WAITING;
        end
    endcase
end
endmodule: FireController