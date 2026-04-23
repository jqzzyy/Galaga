`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2026 02:25:32 PM
// Design Name: 
// Module Name: top
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


module top(
    input in_clk,
    input BTNC,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
    );
 
    wire [3:0] R_in, G_in, B_in;
    wire [31:0] h_pos, v_pos;
    wire frame_tick, visible;
 
    vga vga_inst(
        .in_clk(in_clk),
        .R_in(R_in),
        .G_in(G_in),
        .B_in(B_in),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .h_pos(h_pos),
        .v_pos(v_pos),
        .frame_tick(frame_tick),
        .visible(visible)
    );
    
    wire BTNC_clean;
    
    debouncer db(
        .clk(in_clk),
        .noisy(BTNC),
        .clean(BTNC_clean)
    );
 
    game game_inst(
        .in_clk(in_clk),
        .BTNC(BTNC_clean),
        .h_pos(h_pos),
        .v_pos(v_pos),
        .frame_tick(frame_tick),
        .R_out(R_in),
        .G_out(G_in),
        .B_out(B_in)
    );
    

endmodule
