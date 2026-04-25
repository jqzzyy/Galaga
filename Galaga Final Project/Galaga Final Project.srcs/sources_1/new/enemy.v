`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2026 09:39:46 PM
// Design Name: 
// Module Name: enemy
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



module enemy(
    input [31:0] h_pos,
    input [31:0] v_pos,
    input [31:0] enemy_x,
    input [31:0] enemy_y,
    input        enemy_alive,
    output reg [3:0] R_out,
    output reg [3:0] G_out,
    output reg [3:0] B_out,
    output reg       active
    );

    reg [15:0] enemy_blue   [0:15];
    reg [15:0] enemy_red    [0:15];
    reg [15:0] enemy_yellow [0:15];

    wire in_enemy_x = enemy_alive && (h_pos >= enemy_x) && (h_pos < enemy_x + 16);
    wire in_enemy_y = enemy_alive && (v_pos >= enemy_y)  && (v_pos < enemy_y + 16);
    wire [3:0] sprite_col = (h_pos >= enemy_x) ? h_pos - enemy_x : 4'd0;
    wire [3:0] sprite_row = (v_pos >= enemy_y) ? v_pos - enemy_y : 4'd0;


    initial begin
        enemy_blue[ 0] = 16'b0000000000000000;
        enemy_blue[ 1] = 16'b0000000000000000;
        enemy_blue[ 2] = 16'b0000000000000000;
        enemy_blue[ 3] = 16'b0010000000001000;
        enemy_blue[ 4] = 16'b0001000000010000;
        enemy_blue[ 5] = 16'b0000100000100000;
        enemy_blue[ 6] = 16'b0000000000000000;
        enemy_blue[ 7] = 16'b0000000000000000;
        enemy_blue[ 8] = 16'b0000000000000000;
        enemy_blue[ 9] = 16'b0000000000000000;
        enemy_blue[10] = 16'b0000110001100000;
        enemy_blue[11] = 16'b0001110001110000;
        enemy_blue[12] = 16'b0011100000111000;
        enemy_blue[13] = 16'b0111100000111100;
        enemy_blue[14] = 16'b0111000000011100;
        enemy_blue[15] = 16'b0111000000011100;

        enemy_red[ 0]  = 16'b0000000000000000;
        enemy_red[ 1]  = 16'b0000000000000000;
        enemy_red[ 2]  = 16'b0000000000000000;
        enemy_red[ 3]  = 16'b0000000000000000;
        enemy_red[ 4]  = 16'b0000000000000000;
        enemy_red[ 5]  = 16'b0000001010000000;
        enemy_red[ 6]  = 16'b0000011011000000;
        enemy_red[ 7]  = 16'b0000000000000000;
        enemy_red[ 8]  = 16'b0000000000000000;
        enemy_red[ 9]  = 16'b0000001110000000;
        enemy_red[10]  = 16'b0000001110000000;
        enemy_red[11]  = 16'b0000000000000000;
        enemy_red[12]  = 16'b0000001110000000;
        enemy_red[13]  = 16'b0000000100000000;
        enemy_red[14]  = 16'b0000000000000000;
        enemy_red[15]  = 16'b0000000000000000;

        enemy_yellow[ 0] = 16'b0000000000000000;
        enemy_yellow[ 1] = 16'b0000000000000000;
        enemy_yellow[ 2] = 16'b0000000000000000;
        enemy_yellow[ 3] = 16'b0000000000000000;
        enemy_yellow[ 4] = 16'b0000000100000000;
        enemy_yellow[ 5] = 16'b0000010101000000;
        enemy_yellow[ 6] = 16'b0000000100000000;
        enemy_yellow[ 7] = 16'b0000011111000000;
        enemy_yellow[ 8] = 16'b0000001110000000;
        enemy_yellow[ 9] = 16'b0000000000000000;
        enemy_yellow[10] = 16'b0000000000000000;
        enemy_yellow[11] = 16'b0000001110000000;
        enemy_yellow[12] = 16'b0000000000000000;
        enemy_yellow[13] = 16'b0000000000000000;
        enemy_yellow[14] = 16'b0000000000000000;
        enemy_yellow[15] = 16'b0000000000000000;
    end

    always @(*) begin
        if (in_enemy_x && in_enemy_y && enemy_blue[sprite_row][15 - sprite_col]) begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'hF;
            active = 1;
        end else if (in_enemy_x && in_enemy_y && enemy_red[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'h0; B_out = 4'h0;
            active = 1;
        end else if (in_enemy_x && in_enemy_y && enemy_yellow[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'h0;
            active = 1;
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
            active = 0;
        end
    end

endmodule