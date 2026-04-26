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
        input in_clk, // 100 MHz clock from the board
        input rst,
        output [6:0] cathode,
        output [7:0] anode
    );
    wire seconds_clock; // 1 Hz
	wire fsm_clock;     // 1 kHz
    reg [15:0] counter; // this is the number we want to display
    reg seconds_prev;
    
    initial
        begin
            counter = 0;
        end
    // instantiate the clock divider to drive the 1 Hz signal
    clock_div c(.in_clk(in_clk), .out_clk(seconds_clock));
    // instantiate the faster clock divider to drive the 1 kHz signal
    faster_clock_divider fc(.in_clk(in_clk), .out_clk(fsm_clock));
	// instantiate the FSM using the fsm_clock signal
    fsm f(.clock(fsm_clock), .sixteen_bit_number(counter), .anode(anode), .cathode(cathode));
    always @(posedge in_clk)
	begin
	   seconds_prev <= seconds_clock;
        // increment counter
        if (rst)
            counter <= 0;
        else if (seconds_clock && !seconds_prev)
            counter <= counter + 1;
	end
	
endmodule
