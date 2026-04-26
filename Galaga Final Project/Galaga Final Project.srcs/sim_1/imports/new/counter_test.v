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
    wire [6:0] cathode;
    wire [7:0] anode;
    
    counter DUT (
        .in_clk(clock),
        .cathode(cathode),
        .anode(anode)
    ); 
    
    // Clock generator
    always #5 clock = ~clock;
    
    initial begin
        clock = 0;
    end
    initial #1000 $finish;
    
endmodule
