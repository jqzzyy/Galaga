`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2026 05:57:50 PM
// Design Name: 
// Module Name: debouncer
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


module debouncer(
    input clk,
    input noisy,
    output reg clean
    );
    
    reg [19:0] counter;
    
    parameter MAX = 1_000_000; 
    
    initial begin
        clean = 1'b0;
        counter = 4'd0;
    end
    
    always @(posedge clk) begin
        if (noisy == clean) begin
            counter <= 0;
        end else if (counter == MAX) begin
            clean <= noisy;
            counter <= 0;
        end else begin 
            counter <= counter + 1;
        end
    end
endmodule
