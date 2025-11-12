`default_nettype none
`timescale 1ns/1ps

module TopNexysA7Tb;

logic clock = 0;
initial forever #1 clock = ~clock;

logic reset = 1;

logic sound = 0;
logic buzzer_sound;

SoundBuzzer #(.FREQUENCY(10)) u_soundBuzzer (
        .i_clock(clock),
        .i_reset(reset),
        .i_sound(sound),
        .o_pin_sound(buzzer_sound)
    );
// ################################################
parameter integer TIME_CONTROLLER_SIGNAL = 40;
parameter integer TIME_CONTROLLER_RESPONSE = 40;
tri inout_data; // bidirectional data line
logic inout_drive;
logic inout_enable = 0;
assign inout_data = inout_enable ? inout_drive : 1'bz;
logic [39:0] data_array [0:4] = '{40'b0000_0010_1000_1100_0000_0001_0101_1111_1110_1110,
                                40'b0000_0010_1000_1100_0000_0001_0101_1111_1110_1110,
                                40'b0000_0001_1100_0010_0000_0000_1101_1111_1010_0010,
                                40'b0000_0000_0111_1011_1000_0000_0011_0010_0010_1101,
                                40'b0000_0011_1110_1000_0000_0000_0000_0000_1110_1011};
integer count_bits;
// ################################################
TemperatureHumidity u_temperatureHumidity(.i_clock(clock));

TemperatureHumiditySensor #(
    .SIZE_OF_DATA(40),
    .TIME_CONTROLLER_SIGNAL(TIME_CONTROLLER_SIGNAL),
    .TIME_CONTROLLER_RESPONSE(TIME_CONTROLLER_RESPONSE)
) u_temperatureHumiditySensor (
    .i_clock(clock),
    .i_reset(reset),
    .b_data(inout_data),
    .provider(u_temperatureHumidity) 
);
initial begin
	repeat (5) @(posedge clock);
	reset = 0;

    $display ("================================");
    $display ("Testing Buzzer");
    $display ("================================");
    sound = 1;
    repeat (3) begin
        @(posedge buzzer_sound);
        @(negedge buzzer_sound);
        $display ("Buzzer is making sound");
    end
    sound = 0;
    if (buzzer_sound == 0) begin
        $display ("Buzzer stopped");
    end else begin
        $display ("Buzzer did not stop");
    end

    $display ("================================");
    $display ("Testing TemperatureHumiditySensor");
    $display ("================================");
    foreach (data_array[i]) begin
        $display ("********************************");
        $display ("Consumer want");
        $display ("********************************");

        u_temperatureHumidity.Costumer.want_data = 1;
        $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
        $display ("Sensor STATUS");
        @(negedge inout_data);
        $display ("Sensor Received request LOW");
        @(posedge inout_data);
        $display ("Sensor Received HIGH the line is free now");
        $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");

        u_temperatureHumidity.Costumer.want_data = 0;
        #(TIME_CONTROLLER_RESPONSE);

        $display ("********************************");
        $display ("Sensor sends LOW informing that it is going to send data");
        inout_enable = 1;
        inout_drive = 1'b0;
        #(TIME_CONTROLLER_RESPONSE);
        #(TIME_CONTROLLER_RESPONSE);

        $display ("Sensor sends HIGH informing that it is going to send data");

        inout_drive = 1'b1;
        #(TIME_CONTROLLER_RESPONSE);
        #(TIME_CONTROLLER_RESPONSE);
        $display ("********************************");
        

        count_bits = 39;
        repeat (40) begin
            inout_drive = 1'b0; // PUll the line low to start the bit transmission
            #TIME_CONTROLLER_RESPONSE;
            inout_drive = 1'b1;
            if (data_array[i][count_bits]) begin
                #TIME_CONTROLLER_RESPONSE;
                #TIME_CONTROLLER_RESPONSE;
                #TIME_CONTROLLER_RESPONSE;
            end else begin
                #(TIME_CONTROLLER_RESPONSE);
            end
            count_bits = count_bits - 1;
        end
        repeat (5) begin
            @(posedge clock);
            inout_drive = 1'b1;
        end
        inout_enable = 0;

        if ({u_temperatureHumidity.Costumer.humidity, u_temperatureHumidity.Costumer.temperature} == data_array[i][39:8]) begin
            $display ("[PASSED] Sent data: %h == %h", {u_temperatureHumidity.Costumer.humidity, u_temperatureHumidity.Costumer.temperature}, data_array[i][39:8]);
        end else begin
            $display ("[FAILED] Sent data: %h != %h", {u_temperatureHumidity.Costumer.humidity, u_temperatureHumidity.Costumer.temperature}, data_array[i][39:8]);
        end
        $display ("[INFO] Valid info signal: %b, request_again: %b ", u_temperatureHumidity.Costumer.valid_info, u_temperatureHumidity.Costumer.request_again);
    end
    $finish;


end

endmodule: TopNexysA7Tb
