`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2023 09:05:20 AM
// Design Name: 
// Module Name: counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module counter(
        input in_clk,
        input rst,
        input [15:0] score,
        output [6:0] cathode,
        output [7:0] anode
    );
    wire fsm_clock; // 1 kHz

    // instantiate the faster clock divider to drive the 1 kHz signal
    faster_clock_divider fc(.in_clk(in_clk), .out_clk(fsm_clock));
    // display the score directly on the 7-segment display
    fsm f(.clock(fsm_clock), .sixteen_bit_number(score), .anode(anode), .cathode(cathode));

endmodule