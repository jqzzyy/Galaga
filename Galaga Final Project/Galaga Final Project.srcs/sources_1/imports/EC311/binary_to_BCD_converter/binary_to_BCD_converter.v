`timescale 1ns / 1ps
// Source: https://verilogcodes.blogspot.com/2015/10/verilog-code-for-8-bit-binary-to-bcd.html
// This module is asynchronous
// input bin is an 8-bit binary number
// output bcd is a 12-bit binary-coded decimal (3 decimal digits)

module binary_to_BCD_converter(
    bin, bcd
    );
     //input ports and their sizes
    input [15:0] bin;
    //output ports and, their size
    output [19:0] bcd;
    //Internal variables
    reg [19 : 0] bcd; 
    integer i;   
     
     //Always block - implement the Double Dabble algorithm
     always @(bin)
        begin
            bcd = 0; //initialize bcd to zero.
            for (i = 0; i < 16; i = i+1) //run for 8 iterations
            begin
                bcd = {bcd[18:0],bin[15-i]}; //concatenation
                    
                //if a hex digit of 'bcd' is more than 4, add 3 to it.  
                if(i < 15 && bcd[3:0]   > 4) 
                    bcd[3:0]   = bcd[3:0] + 3;
                if(i < 15 && bcd[7:4]   > 4) 
                    bcd[7:4]   = bcd[7:4] + 3;
                if(i < 15 && bcd[11:8]  > 4) 
                    bcd[11:8]  = bcd[11:8] + 3;
                if(i < 15 && bcd[15:12] > 4) 
                    bcd[15:12] = bcd[15:12] + 3;
                if(i < 15 && bcd[19:16] > 4) 
                    bcd[19:16] = bcd[19:16] + 3;
            end
        end     
endmodule
