`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2023 08:38:09 AM
// Design Name: 
// Module Name: decoder
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


module decoder(
        input [3:0] number,
        output reg [6:0] cathode
    );
    
    initial begin
        cathode = 7'b0000001;
    end
    
    always @(number)
    begin
        case(number)
            0:cathode<=7'b0000001;
            1:cathode<=7'b1001111;
            2:cathode<=7'b0010010;
            3:cathode<=7'b0000110;
            4:cathode<=7'b1001100;
            5:cathode<=7'b0100100;
            6:cathode<=7'b0100000;
            7:cathode<=7'b0001111;
            8:cathode<=7'b0000000;
            9: cathode<=7'b0000100;
            10:cathode<=7'b0001000;
            11:cathode<=7'b1100000;
            12:cathode<=7'b0110001;
            13:cathode<=7'b1000010;
            14:cathode<=7'b0110000;
            15:cathode<=7'b0111000;
            default: cathode<=7'b1111111;
        endcase
    end
    
endmodule
