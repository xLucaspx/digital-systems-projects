`default_nettype none
`timescale 1ns/1ps

module TopNexysA7Tb;

logic clock = 0;
always #1 clock = ~clock;

logic reset = 0;
logic sound = 0;
logic buzzer_sound;
 SoundBuzzer u_soundBuzzer (
        .i_clock(clock),
        .i_reset(reset),
        .i_sound(sound),
        .o_pin_sound(buzzer_sound)
    );
initial begin
	repeat (5) @(posedge clock);

	reset = 1;
    // Testing Buzzer
    sound = 1;
    $display ("Testing");
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
    $finish;

end

endmodule: TopNexysA7Tb
