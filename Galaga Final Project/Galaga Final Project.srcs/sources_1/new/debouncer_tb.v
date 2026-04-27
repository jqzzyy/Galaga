`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2026 06:12:47 PM
// Design Name: 
// Module Name: debouncer_tb
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


module debouncer_tb(

    );
    
    reg clk, noisy;
    wire clean;
    
    debouncer #(.MAX(10)) debounce(.clk(clk), .noisy(noisy), .clean(clean));
    
    initial clk = 0;
    
    initial begin
        noisy = 0;
        #100;

        noisy = 1; #20;
        noisy = 0; #10;
        noisy = 1; #15;
        noisy = 0; #5;
        noisy = 1;
        #200;

        noisy = 0; #10;
        noisy = 1; #5;
        noisy = 0;
        #200;

        #20 $finish;
    end
    always begin
        #5 clk = ~clk;
    end
    
endmodule
