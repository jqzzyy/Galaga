`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2023 09:14:50 AM
// Design Name: 
// Module Name: counter_test
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


module counter_test(

    );
    
    reg clock; 
    reg [15:0] score;
    wire [6:0] cathode;
    wire [7:0] anode;
    counter DUT (
        .in_clk(clock),
        .score(score),
        .cathode(cathode),
        .anode(anode)
    ); 
    
    // Clock generator
    always begin
        #1 clock <= ~clock;
        #1 score <= score + 1;
    end
    // Score works but not enough clock cycles to show anode/cathode changing
    initial begin
        clock = 0;
        score = 0;
    end
    initial begin
        #100 $finish;
    end
endmodule
