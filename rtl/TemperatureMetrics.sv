`default_nettype none
/*
* This module controls the logic to read temperature and, send the data to the provider.
*
*/
module TemperatureMetrics #(
    parameter integer SECONDS = 3,
    parameter integer FREQUENCY = 100_000_000
)(
    input var logic i_clock,
    input var logic i_reset,
    input var logic i_simulation,
    input var logic i_fire_on,
    input var logic [11:0] i_temperature,

    TemperatureHumidity.Provider provider
);

/**
* Data array to store the received bits
*/
logic [9 :0] data_array;
logic [7 :0] standard_temperature;

/**
* State machine definition
*/
typedef enum logic [1:0] {
    IDLE,
    SEND
} state_t;

state_t state, next_state;


always_ff @(posedge i_clock , posedge i_reset) begin
    if (i_reset) begin
        state <= IDLE;
        provider.humidity <= 0;
        provider.temperature <= 0;
        provider.valid_info <= 0;
        provider.request_again <= 0;
    end else begin
        state <= next_state;

        if (~i_simulation) begin
            standard_temperature <= get_not_decimal_temperature();
        end else begin
            standard_temperature <= standard_temperature;
        end

        // Wait costumer ask
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

/**
* Time counter logic
*/
integer clock_counter;
integer timer;
always_ff @(posedge i_clock, posedge i_reset) begin
    if (i_reset) begin
        clock_counter <= 0;
        timer <= 0;
        data_array <= 0;
    end else begin
        if (timer == SECONDS) begin
            if (~i_fire_on) begin
                if (data_array > standard_temperature) begin
                    data_array <= data_array - 1;
                end
            end else begin
                if (data_array < 100) begin
                    data_array <= data_array + 3;
                end else if (data_array < 180) begin
                    data_array <= data_array + 2;
                end else if (data_array < 220) begin
                    data_array <= data_array + 1;
                end else begin
                    data_array <= data_array -1;
                end
            end
            timer <= 0;
        end else if (clock_counter == FREQUENCY) begin
            timer <= timer + 1;
            clock_counter <= 0;
        end else if (i_simulation) begin
            clock_counter <= clock_counter + 1;
        end else begin
            clock_counter <= 0;
            data_array <= get_not_decimal_temperature();
        end
    end

end

function logic [7:0] get_not_decimal_temperature();
        return i_temperature[10:3]; // 8 bits
endfunction

/**
* Next state logic
*/
always_comb begin
    case (state)
        IDLE: begin
            if (provider.want_data) begin
                next_state = SEND;
            end else begin
                next_state = IDLE;
            end
        end
        SEND: begin
            next_state = IDLE;
        end
        default: begin
            next_state = IDLE;
        end
    endcase
    
end

endmodule: TemperatureMetrics