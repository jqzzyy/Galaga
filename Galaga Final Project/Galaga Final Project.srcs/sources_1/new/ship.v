`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2026 09:38:57 PM
// Design Name: 
// Module Name: ship
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


module ship(
    input [31:0] h_pos,
    input [31:0] v_pos,
    input [31:0] ship_x,
    input [31:0] ship_y,
    output reg [3:0] R_out,
    output reg [3:0] G_out,
    output reg [3:0] B_out,
    output reg active  // 1 if this pixel belongs to the ship, 0 otherwise
    );
 
    reg [15:0] ship_white [0:15];
    reg [15:0] ship_red   [0:15];
 
    wire in_ship_x = (h_pos >= ship_x) && (h_pos < ship_x + 16);
    wire in_ship_y = (v_pos >= ship_y)  && (v_pos < ship_y + 16);
    wire [3:0] sprite_col = h_pos - ship_x;
    wire [3:0] sprite_row = v_pos - ship_y;
 
    initial begin
        ship_white[ 0] = 16'b0000000100000000;
        ship_white[ 1] = 16'b0000000100000000;
        ship_white[ 2] = 16'b0000000100000000;
        ship_white[ 3] = 16'b0000001110000000;
        ship_white[ 4] = 16'b0000001110000000;
        ship_white[ 5] = 16'b0000001110000000;
        ship_white[ 6] = 16'b0000001110000000;
        ship_white[ 7] = 16'b0001011011010000;
        ship_white[ 8] = 16'b0001010001010000;
        ship_white[ 9] = 16'b1000110101100010;
        ship_white[10] = 16'b1001111111111010;
        ship_white[11] = 16'b1011111111111010;
        ship_white[12] = 16'b1111101110011110;
        ship_white[13] = 16'b1110001110001110;
        ship_white[14] = 16'b1100000100000110;
        ship_white[15] = 16'b1000000100000010;
 
        ship_red[ 0]   = 16'b0000000000000000;
        ship_red[ 1]   = 16'b0000000000000000;
        ship_red[ 2]   = 16'b0000000000000000;
        ship_red[ 3]   = 16'b0000000000000000;
        ship_red[ 4]   = 16'b0000000000000000;
        ship_red[ 5]   = 16'b0001000000010000;
        ship_red[ 6]   = 16'b0001000000010000;
        ship_red[ 7]   = 16'b1000000100000010;
        ship_red[ 8]   = 16'b1000001110000010;
        ship_red[ 9]   = 16'b0000001010000000;
        ship_red[10]   = 16'b0000000000000000;
        ship_red[11]   = 16'b0000000000000000;
        ship_red[12]   = 16'b0000010001000000;
        ship_red[13]   = 16'b0000110001100000;
        ship_red[14]   = 16'b0000110001100000;
        ship_red[15]   = 16'b0000000000000000;
    end
 
    always @(*) begin
        if (in_ship_x && in_ship_y && ship_red[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'h0; B_out = 4'h0;
            active = 1;
        end else if (in_ship_x && in_ship_y && ship_white[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'hF;
            active = 1;
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
            active = 0;
        end
    end
 
endmodule
