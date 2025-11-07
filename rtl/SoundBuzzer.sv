module SoundBuzzer#()(
    input var logic i_clock,
    input var logic i_reset,
    input var logic i_sound,
    output var logic o_pin_sound
);

integer frequency =0;
always @(posedge i_clock, negedge i_reset) begin
    if (~i_reset) begin
        frequency <= 0;
        o_pin_sound <= 0;

    end else begin
        // Make sound with period(10ns)*frequency = 0.1s
        if (i_sound && frequency == 10_000_000) begin
            o_pin_sound <= ~o_pin_sound;
            frequency <= 0;
        end else if (i_sound) begin
            frequency <= frequency + 1;
        end else begin
            o_pin_sound <= 0;
            frequency <= 0;
        end

    end
end
endmodule