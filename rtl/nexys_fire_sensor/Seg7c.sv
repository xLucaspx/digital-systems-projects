`timescale 1ns / 1ps
module Seg7c(
    input clk_100MHz,               // Nexys 4 DDR clock
    input [9:0] c_data,             // Temp data from i2c master
    output reg [6:0] SEG,           // 7 Segments of Displays
    output reg [7:0] AN             // 4 Anodes of 8 to display Temp C
    );
    
    // Binary to BCD conversion of temperature data
    wire [3:0] c_hundred, c_tens, c_ones;
    assign c_hundred = c_data / 100;           // Tens value of C temp data
    assign c_tens = (c_data % 100) / 10;;           // Tens value of C temp data
    assign c_ones = c_data % 10;           // Ones value of C temp data

    // Parameters for segment patterns
    parameter ZERO  = 7'b000_0001;  // 0
    parameter ONE   = 7'b100_1111;  // 1
    parameter TWO   = 7'b001_0010;  // 2 
    parameter THREE = 7'b000_0110;  // 3
    parameter FOUR  = 7'b100_1100;  // 4
    parameter FIVE  = 7'b010_0100;  // 5
    parameter SIX   = 7'b010_0000;  // 6
    parameter SEVEN = 7'b000_1111;  // 7
    parameter EIGHT = 7'b000_0000;  // 8
    parameter NINE  = 7'b000_0100;  // 9
    parameter DEG   = 7'b001_1100;  // degrees symbol
    parameter C     = 7'b011_0001;  // C
    parameter F     = 7'b011_1000;  // F
    
    // To select each digit in turn
    reg [2:0] anode_select;         // 2 bit counter for selecting each of 4 digits
    reg [16:0] anode_timer;         // counter for digit refresh
    
    // Logic for controlling digit select and digit timer
    always @(posedge clk_100MHz) begin
        // 1ms x 8 displays = 8ms refresh period
        if(anode_timer == 99_999) begin         // The period of 100MHz clock is 10ns (1/100,000,000 seconds)
            anode_timer <= 0;                   // 10ns x 100,000 = 1ms
            anode_select <=  anode_select + 1;
        end
        else
            anode_timer <=  anode_timer + 1;
    end
    
    // Logic for driving the 8 bit anode output based on digit select
    always @(anode_select) begin
        case(anode_select) 
            3'o0 : AN = 8'b1111_1110;
            3'o1 : AN = 8'b1111_1101;
            3'o2 : AN = 8'b1111_1011;
            3'o3 : AN = 8'b1111_0111;
            3'o4 : AN = 8'b1110_1111;
            3'o5 : AN = 8'b1101_1111;
            3'o6 : AN = 8'b1011_1111;
            3'o7 : AN = 8'b0111_1111;
        endcase
    end
    
    always @*
        case(anode_select)
            3'o0 : SEG = C;    // Set to C for Celsuis
                        
            3'o1 : SEG = DEG;  // Set to degrees symbol
                    
            3'o2 : begin       // C TEMPERATURE ONES DIGIT
                        case(c_ones)
                            4'b0000 : SEG = ZERO;
                            4'b0001 : SEG = ONE;
                            4'b0010 : SEG = TWO;
                            4'b0011 : SEG = THREE;
                            4'b0100 : SEG = FOUR;
                            4'b0101 : SEG = FIVE;
                            4'b0110 : SEG = SIX;
                            4'b0111 : SEG = SEVEN;
                            4'b1000 : SEG = EIGHT;
                            4'b1001 : SEG = NINE;
                        endcase
                    end
                    
            3'o3 : begin       // C TEMPERATURE TENS DIGIT
                        case(c_tens)
                            4'b0000 : SEG = ZERO;
                            4'b0001 : SEG = ONE;
                            4'b0010 : SEG = TWO;
                            4'b0011 : SEG = THREE;
                            4'b0100 : SEG = FOUR;
                            4'b0101 : SEG = FIVE;
                            4'b0110 : SEG = SIX;
                            4'b0111 : SEG = SEVEN;
                            4'b1000 : SEG = EIGHT;
                            4'b1001 : SEG = NINE;
                        endcase
                    end
            
            3'o4 : begin       // C TEMPERATURE HUNDRED DIGIT
                        case(c_tens)
                            4'b0000 : SEG = ZERO;
                            4'b0001 : SEG = ONE;
                            4'b0010 : SEG = TWO;
                            4'b0011 : SEG = THREE;
                            4'b0100 : SEG = FOUR;
                            4'b0101 : SEG = FIVE;
                            4'b0110 : SEG = SIX;
                            4'b0111 : SEG = SEVEN;
                            4'b1000 : SEG = EIGHT;
                            4'b1001 : SEG = NINE;
                        endcase
                    end
            3'o5 : SEG = ZERO;  // Set zero
            3'o6 : SEG = ZERO;  // Set zero
            3'o7 : SEG = ZERO;  // Set zero

        endcase
endmodule