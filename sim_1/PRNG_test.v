`timescale 1ns / 1ps

module PRNG_test(

    );
    
    reg clk, rst, load;
    reg [15:0] seed;
    wire [15:0] out;
    
    PRNG DUT(clk,rst,load,seed,out);
    
    // Clock generator
    always #1 clk = ~clk;
    
    initial begin
        clk = 0;
        rst = 0;
        load = 1;
        seed = 56394;
        #1 rst = 0;
        #1 rst = 1;
        #1 rst = 0;
        #5 load = 0;
    end
    
    initial #100 $finish;
    
    
endmodule
