`default_nettype none
/*
* This module is based on this datasheet:
* https://cdn-shop.adafruit.com/datasheets/Digital+humidity+and+temperature+sensor+AM2302.pdf
* It implements a state machine to communicate with a Dht22 Am2302 temperature and humidity sensor.
*
*/
module TemperatureHumiditySensor#(
    parameter integer SIZE_OF_DATA = 40,
    parameter integer TIME_CONTROLLER_SIGNAL = 500_000, // 500_0000 clocks period is 10 ns = 5 ms
    parameter integer TIME_CONTROLLER_RESPONSE = 4_000)( // 4_000 clocks period is 10 ns = 40 us
    input var logic i_clock,
    input var logic i_reset,
    inout wire b_data,

    TemperatureHumidity.Provider provider
);

/**
* Data array to store the received bits
*/
logic [SIZE_OF_DATA -1 :0] data_array;
integer bit_counter;

/**
* State machine definition
*/
typedef enum logic [2:0] {
    IDLE,
    REQUEST,
    REQUESTED,
    RECEIVE,
    RECEIVING,
    VALIDATE,
    SEND
} state_t;

state_t state, next_state;

integer time_counter;
integer clock_counter_signal;
logic valid_data;

/**
 * Bidirectional data line control
 */
logic data_drive;
logic data_output_en;
assign b_data = data_output_en ? data_drive : 1'bz;
// ********************************

logic update_data;
always_ff @(posedge i_clock , posedge i_reset) begin
    if (i_reset) begin
        state <= IDLE;
        data_array <= 0;
        data_drive <= 1'b1;
        data_output_en <= 1'b1;
        bit_counter <= 0;
        update_data <= 0;
        clock_counter_signal <= 0;
        provider.humidity <= 0;
        provider.temperature <= 0;
        provider.valid_info <= 0;
        provider.request_again <= 0;
    end else begin
        state <= next_state;
        if (state == IDLE) begin
            // default state, data line is low and different info in valid_info and request_again
            // represent a good state of communication
            provider.valid_info <= 0;
            provider.request_again <= 0;
        end else if (state == REQUEST) begin
            // master pull the line low to request data
            data_drive <= 1'b0;
            data_output_en <= 1'b1;

        end else if (state == REQUESTED) begin
            if (time_counter == 1) begin
                // master pull the line high after certain time
                data_drive <= 1'b1;
                data_output_en <= 1'b1;
            end
        end
        else if (state == RECEIVE) begin
            // release the line to let sensor drive it
            // and wait for it to pull it low and high and low again
            data_output_en <= 1'b0;
            bit_counter <= 0;
            if (next_state == IDLE) begin
                // Timeout case, go back to idle
                data_output_en <= 1'b1;
                data_drive <= 1'b1;
                provider.request_again <= 1;
            end
        end else if (state == RECEIVING) begin
            if (b_data == 1'b1) begin
                clock_counter_signal <= clock_counter_signal + 1;
                update_data <= 1;
            end
            else if (update_data) begin
                if (clock_counter_signal > TIME_CONTROLLER_RESPONSE) begin
                    data_array[SIZE_OF_DATA -1 - bit_counter] <= 1'b1;
                end else begin
                    data_array[SIZE_OF_DATA -1 - bit_counter] <= 1'b0;
                end
                bit_counter <= bit_counter + 1;
                clock_counter_signal <= 0;
                update_data <= 0;
            end

        end else if (state == VALIDATE) begin
            if (data_array[7:0] == (data_array[15:8] + data_array[23:16] + data_array[31:24] + data_array[39:32])) begin
                valid_data <= 1;
            end else begin
                valid_data <= 0;
            end
        end else if (state == SEND) begin
            provider.humidity <= data_array[39:24];
            provider.temperature <= data_array[23:8];
            provider.valid_info <= valid_data;
            provider.request_again <= ~valid_data;
        end
    end
end

/**
* Time counter logic
*/
integer clock_counter;
always_ff @(posedge i_clock, posedge i_reset) begin
    if (i_reset) begin
        clock_counter <= 0;
        time_counter <= 0;
    end else
    if (state == REQUEST && clock_counter == TIME_CONTROLLER_SIGNAL) begin
        time_counter <= 1;
        clock_counter <= 0;
    end else if (state == REQUEST ) begin
        clock_counter <= clock_counter + 1;
    end
    else if (state == RECEIVE) begin
        // Counting the transitions of b_data low-high-low
        if (b_data == 1'b0 && time_counter == 0) begin
            time_counter <= 1;
        end if (b_data == 1'b1 && time_counter == 1) begin
            time_counter <= 2;
        end else if (b_data == 1'b0 && time_counter == 2) begin
            time_counter <= 3;
        end
        clock_counter <= clock_counter + 1;
    end else begin
        clock_counter <= 0;
        time_counter <= 0;
    end

end

/**
* Next state logic
*/
always_comb begin
    case (state)
        IDLE: begin
            if (provider.want_data) begin
                next_state = REQUEST;
            end else begin
                next_state = IDLE;
            end
        end
        REQUEST: begin
            // Requesting b_data from sensor for X time units
            if (time_counter == 1) begin
                next_state = REQUESTED;
            end else begin
                next_state = REQUEST;
            end
        end
        // Sensor should pull the line low
        REQUESTED: begin
            if (b_data == 1'b0) begin
                next_state = RECEIVE;
            end  else begin
                next_state = REQUESTED;
            end
        end
        // Waiting for sensor to pull high and low again
        RECEIVE: begin
            if (time_counter == 3) begin
                next_state = RECEIVING;
            end else if (clock_counter > (TIME_CONTROLLER_RESPONSE * 2) && time_counter == 0) begin
                next_state = IDLE; // Timeout, go back to idle
            end else begin
                next_state = RECEIVE;
            end
        // After receiving each bit, we check if we have received all right bits
        end
        RECEIVING: begin
            if (bit_counter == SIZE_OF_DATA) begin
                next_state = VALIDATE;
            end else begin
                next_state = RECEIVING;
            end
        end
        // Send the b_data to the provider after validating
        VALIDATE: begin
            next_state = SEND;
        end
        // Becomo idle again
        SEND: begin
            next_state = IDLE;
        end
        default: begin
            next_state = IDLE;
        end
    endcase
    
end

endmodule: TemperatureHumiditySensor