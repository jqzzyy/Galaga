`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2026 02:23:36 PM
// Design Name: 
// Module Name: game
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


module game(
    input in_clk,
    input BTNC,           // shoot
    input [31:0] h_pos,   // current pixel x from vga.v
    input [31:0] v_pos,   // current pixel y from vga.v
    input frame_tick,     // one pulse per scanline - use for game logic updates
    output reg [3:0] R_out,
    output reg [3:0] G_out,
    output reg [3:0] B_out
    );
 
    // ---- Ship ----
    parameter SHIP_X = 312;  // fixed for now, add movement later
    parameter SHIP_Y = 450;
 
    // ---- Bullet ----
    reg bullet_active;
    reg [31:0] bullet_x, bullet_y;
    reg btnc_prev;
 
    // ---- Sprite bitmaps ----
    reg [15:0] ship_white [0:15];
    reg [15:0] ship_red   [0:15];
 
    // ---- Sprite pixel wires ----
    wire in_ship_x = (h_pos >= SHIP_X) && (h_pos < SHIP_X + 16);
    wire in_ship_y = (v_pos >= SHIP_Y)  && (v_pos < SHIP_Y + 16);
    wire [3:0] sprite_col = h_pos - SHIP_X;
    wire [3:0] sprite_row = v_pos - SHIP_Y;
 
    // ---- Bullet pixel wires ----
    wire in_bullet_x = bullet_active && (h_pos >= bullet_x) && (h_pos < bullet_x + 4);
    wire in_bullet_y = bullet_active && (v_pos >= bullet_y) && (v_pos < bullet_y + 8);
 
    initial begin
        bullet_active = 0;
        bullet_x = 0;
        bullet_y = 0;
        btnc_prev = 0;
 
        ship_white[ 0] = 16'b0000000100000000;
        ship_white[ 1] = 16'b0000000100000000;
        ship_white[ 2] = 16'b0000000100000000;
        ship_white[ 3] = 16'b0000001110000000;
        ship_white[ 4] = 16'b0000001110000000;
        ship_white[ 5] = 16'b0000001110000000;
        ship_white[ 6] = 16'b0000001110000000;
        ship_white[ 7] = 16'b0001011011101000;
        ship_white[ 8] = 16'b0001010000101000;
        ship_white[ 9] = 16'b1000110100110010;
        ship_white[10] = 16'b1001111111111010;
        ship_white[11] = 16'b1011101111011010;
        ship_white[12] = 16'b1111101110011110;
        ship_white[13] = 16'b1111001110001110;
        ship_white[14] = 16'b1100000100000110;
        ship_white[15] = 16'b1000000100000010;
 
        ship_red[ 0]   = 16'b0000000000000000;
        ship_red[ 1]   = 16'b0000000000000000;
        ship_red[ 2]   = 16'b0000000000000000;
        ship_red[ 3]   = 16'b0000000000000000;
        ship_red[ 4]   = 16'b0000000000000000;
        ship_red[ 5]   = 16'b0001000000001000;
        ship_red[ 6]   = 16'b0000000000001000;
        ship_red[ 7]   = 16'b1000000100000010;
        ship_red[ 8]   = 16'b1000001110000010;
        ship_red[ 9]   = 16'b0000001010000000;
        ship_red[10]   = 16'b0000000000000000;
        ship_red[11]   = 16'b0000000000000000;
        ship_red[12]   = 16'b0000010000100000;
        ship_red[13]   = 16'b0000110000110000;
        ship_red[14]   = 16'b0000110000110000;
        ship_red[15]   = 16'b0000000000000000;
    end
 
    // ---- Game logic: runs once per scanline on frame_tick ----
    always @(posedge frame_tick)
    begin
        btnc_prev <= BTNC;
 
        // Fire on rising edge of BTNC, only if no bullet already active
        if (BTNC && !btnc_prev && !bullet_active) begin
            bullet_active <= 1;
            bullet_x      <= SHIP_X + 6;  // horizontally centered on ship
            bullet_y      <= SHIP_Y - 8;  // just above ship
        end
 
        // Move bullet upward each scanline tick
        if (bullet_active) begin
            if (bullet_y <= 4) begin
                bullet_active <= 0;        // reached top of screen
            end else begin
                bullet_y <= bullet_y - 4;  // speed: 4px per scanline
            end
        end
    end
 
    // ---- Pixel renderer: runs combinationally every pixel ----
    always @(*)
    begin
        // Bullet (yellow)
        if (in_bullet_x && in_bullet_y) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'h0;
        // Ship red pixels
        end else if (in_ship_x && in_ship_y && ship_red[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'h0; B_out = 4'h0;
        // Ship white pixels
        end else if (in_ship_x && in_ship_y && ship_white[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'hF;
        // Black background
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
        end
    end
 
endmodule
