`default_nettype none
`timescale 1ns/1ps

module TopNexysA7Tb;

logic clock = 0;
initial forever #1 clock = ~clock;

logic reset = 1;

logic co2_sensor_data;
logic co2_signal;
Co2Sensor u_Co2Sensor (
	.i_clock(clock),
	.i_reset(reset),
	.i_sensor_data(co2_sensor_data),
	.o_gas_detected(co2_signal)
);

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
logic [39:0] data_array [0:4] = '{40'b0000_0010_1000_1100_0000_0001_0101_1111_1110_1110, // RH: 652 → 65.2%RH T: 351 → 35.1°C
                                40'b0000_0010_1000_1100_0000_0001_0101_1111_1110_1110, // RH: 652 → 65.2%RH T: 351 → 35.1°C
                                40'b0000_0001_1100_0010_0000_0000_1101_1111_1010_0010,// RH: 450 → 45.0%RH T: 223 → 22.3°C
                                40'b0000_0000_0111_1011_1000_0000_0011_0010_0010_1101, // RH: 123 → 12.3%RH T: 50 → -5.0°C
                                40'b0000_0011_1110_1000_0000_0000_0000_0000_1110_1011}; // RH: 1000 → 100.0%RH T: 0 → 0.0°C
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

logic fire_signal;
logic reset_fire = 1;
FireController #(
    .FREQUENCY(100)
) u_fireController (
	.i_clock(clock),
	.i_reset(reset_fire),
	.o_fire(fire_signal),
    .costumer(u_temperatureHumidity)
);
logic [39:0] data_array_fire [0:4] = '{40'b0000_0001_1100_0010_0000_0000_1101_1111_1010_0010,// RH: 450 → 45.0%RH T: 223 → 22.3°C
                                        40'b0000_0010_1000_1100_0000_0001_0101_1111_1110_1110,  // RH: 652 → 65.2%RH T: 351 → 35.1°C
                                        40'b0000_0010_10001100_00000001_01101101_11111100, // T: 361 → 36.5°C
                                        40'b0000_0010_10001100_00000001_01111100_00001011,// T: 380 → 38.0°C
                                        40'b0000_0010_10001100_00000001_10000001_00010000 // T: 385 → 38.5°C
                                        };
initial begin
	repeat (5) @(posedge clock);
	reset = 0;
    $display ("================================");
    $display ("Testing CO2 Sensor");
    $display ("================================");
    
    repeat (3) begin
        co2_sensor_data = 1;
        #10;
        if (co2_signal == 1) begin
            $display ("[PASSED] CO2 detected as expected");
        end else begin
            $display ("[FAILED] CO2 not detected when it should be");
        end
    end

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

    // $display ("================================");
    // $display ("Testing TemperatureHumiditySensor");
    // $display ("================================");
    // foreach (data_array[i]) begin
    //     $display ("********************************");
    //     $display ("Consumer want");
    //     $display ("********************************");

    //     u_temperatureHumidity.Costumer.want_data = 1;
    //     $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
    //     $display ("Sensor STATUS");
    //     @(negedge inout_data);
    //     $display ("Sensor Received request LOW");
    //     @(posedge inout_data);
    //     $display ("Sensor Received HIGH the line is free now");
    //     $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");

    //     u_temperatureHumidity.Costumer.want_data = 0;
    //     #(TIME_CONTROLLER_RESPONSE);

    //     $display ("********************************");
    //     $display ("Sensor sends LOW informing that it is going to send data");
    //     inout_enable = 1;
    //     inout_drive = 1'b0;
    //     #(TIME_CONTROLLER_RESPONSE);
    //     #(TIME_CONTROLLER_RESPONSE);

    //     $display ("Sensor sends HIGH informing that it is going to send data");

    //     inout_drive = 1'b1;
    //     #(TIME_CONTROLLER_RESPONSE);
    //     #(TIME_CONTROLLER_RESPONSE);
    //     $display ("********************************");
        

    //     count_bits = 39;
    //     repeat (40) begin
    //         inout_drive = 1'b0; // PUll the line low to start the bit transmission
    //         #TIME_CONTROLLER_RESPONSE;
    //         inout_drive = 1'b1;
    //         if (data_array[i][count_bits]) begin
    //             #TIME_CONTROLLER_RESPONSE;
    //             #TIME_CONTROLLER_RESPONSE;
    //             #TIME_CONTROLLER_RESPONSE;
    //         end else begin
    //             #(TIME_CONTROLLER_RESPONSE);
    //         end
    //         count_bits = count_bits - 1;
    //     end
    //     repeat (5) begin
    //         @(posedge clock);
    //         inout_drive = 1'b1;
    //     end
    //     inout_enable = 0;
    // repeat (5) begin
    //         @(posedge clock);
    //     end

    //     if ({u_temperatureHumidity.Costumer.humidity, u_temperatureHumidity.Costumer.temperature} == data_array[i][39:8]) begin
    //         $display ("[PASSED] Sent data: %h == %h", {u_temperatureHumidity.Costumer.humidity, u_temperatureHumidity.Costumer.temperature}, data_array[i][39:8]);
    //     end else begin
    //         $display ("[FAILED] Sent data: %h != %h", {u_temperatureHumidity.Costumer.humidity, u_temperatureHumidity.Costumer.temperature}, data_array[i][39:8]);
    //     end
    //     $display ("[INFO] Valid info signal: %b, request_again: %b ", u_temperatureHumidity.Costumer.valid_info, u_temperatureHumidity.Costumer.request_again);
    // end

    $display ("================================");
    $display ("Testing Fire Controller");
    $display ("================================");
    
    reset_fire= 0;
    foreach (data_array_fire[i]) begin
        repeat (1) begin
            @(posedge u_fireController.costumer.want_data);
            $display ("********************************");
            $display ("Consumer want");
            $display ("********************************");
        end
        $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
        $display ("Sensor STATUS");
        @(negedge inout_data);
        $display ("Sensor Received request LOW");
        @(posedge inout_data);
        $display ("Sensor Received HIGH the line is free now");
        $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
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
            if (data_array_fire[i][count_bits]) begin
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

        wait (u_fireController.state == u_fireController.PROCESS);
        wait (u_fireController.state == u_fireController.WAITING);
        if ({u_fireController.actual_temp} == data_array_fire[i][23:8]) begin
            $display ("[PASSED] Sent data: %h == %h", {u_fireController.actual_temp }, data_array_fire[i][23:8]);
        end else begin
            $display ("[FAILED] Sent data: %h != %h", {u_fireController.actual_temp }, data_array_fire[i][23:8]);
        end
        $display ("[INFO] Fire difference: %b, actual temp %h > (old temp %h +10) -> %h ", u_fireController.o_fire, u_fireController.actual_temp, u_fireController.old_temp, (u_fireController.old_temp+10));
    end
    
    $display ("================================");
    $display ("Testing IDLE if sensor does not respond");
    $display ("================================");
    repeat (1) begin
            @(posedge u_fireController.costumer.want_data);
            $display ("********************************");
            $display ("Consumer want");
            $display ("********************************");
    end
    $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");
    $display ("Sensor STATUS");
    @(negedge inout_data);
    $display ("Sensor Received request LOW");
    @(posedge inout_data);
    $display ("Sensor Received HIGH the line is free now");
    $display ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$");

    # TIME_CONTROLLER_RESPONSE;
    # TIME_CONTROLLER_RESPONSE;
    # TIME_CONTROLLER_RESPONSE;
    # TIME_CONTROLLER_RESPONSE;
    # TIME_CONTROLLER_RESPONSE;

    if (u_temperatureHumiditySensor.state == u_temperatureHumiditySensor.IDLE) begin
        $display ("[PASSED] Sensor returned to IDLE state after timeout");        
    end else begin
        $display ("[FAILED] Sensor did not return to IDLE state after timeout, current state: %d, clock_couter: %d", u_temperatureHumiditySensor.state, u_temperatureHumiditySensor.clock_counter);        
    end

        
    
    $finish;


end

endmodule: TopNexysA7Tb
