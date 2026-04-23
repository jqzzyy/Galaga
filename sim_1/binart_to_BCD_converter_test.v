`timescale 1ns / 1ps
// Source: https://verilogcodes.blogspot.com/2015/10/verilog-code-for-8-bit-binary-to-bcd.html

module binart_to_BCD_converter_test(

    );
    reg [7:0] bin;
    wire [3:0] digit0, digit1, digit2;
    reg [8:0] i;
    
    binary_to_BCD_converter DUT (bin, {digit2, digit1, digit0});
    
    initial begin
        for (i=0;i<256;i=i+1)
        begin
            bin = i;
            #10;
        end
        $finish;
    end
    
endmodule
