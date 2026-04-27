`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 10:47:33 PM
// Design Name: 
// Module Name: enemy_tb
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


module enemy_tb;
    reg clk;
    reg [31:0] h_pos;
    reg [31:0] v_pos;
    reg [31:0] enemy_x;
    reg [31:0] enemy_y;
    reg enemy_alive;
    reg shoot_en;
    reg [31:0] ebullet_speed;

    reg frame;
    wire active;
    wire ebullet;
    wire [31:0] ebullet_x;
    wire [31:0] ebullet_y;
 
    enemy #(.PRNG_SEED(16'hA1B2), .INIT_TIMER(32'd10)) 
        DUT (
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x), .enemy_y(enemy_y),
        .enemy_alive(enemy_alive),
        .shoot_en(shoot_en),
        .ebullet_speed(ebullet_speed),
        .clk(clk), .frame(frame),
        .R_out(), .G_out(), .B_out(),
        .active(active),
        .ebullet(ebullet),
        .ebullet_x(ebullet_x),
        .ebullet_y(ebullet_y)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
    //pulse frame high for 1 clk cycle then low again
    //all game logic runs on posedge frame
    task pulse_frame;
        input integer count;
        integer n;
        begin
            for (n = 0; n < count; n = n + 1) begin
                @(negedge clk); frame = 1;
                @(negedge clk); frame = 0;
            end
        end
    endtask
 
 
    initial begin
        enemy_x = 172;
        enemy_y = 40;
        enemy_alive = 1;
        shoot_en = 1;
        ebullet_speed = 4;
        frame = 0;
        h_pos = 180;
        v_pos = 48;
        // advance 20 frames of the game
        #20; pulse_frame(20);
        
        enemy_alive = 0; 
        #10; pulse_frame(5);
 
        enemy_alive = 1;
        #10; pulse_frame(5);
 
        #10; $finish;
    end

endmodule