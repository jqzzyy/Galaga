`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 10:21:32 PM
// Design Name: 
// Module Name: game_tb
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


`timescale 1ns / 1ps

module game_tb(

    );
    reg in_clk;
    reg rst;
    reg BTNC;
    reg left, right;
    reg [31:0] h_pos;
    reg [31:0] v_pos;
    reg frame_tick;
    wire [3:0] R_out, G_out, B_out;
    wire [2:0] led;
    wire [15:0] score_out;

    game DUT (
        .in_clk(in_clk),
        .rst(rst),
        .BTNC(BTNC),
        .left(left), .right(right),
        .h_pos(h_pos),
        .v_pos(v_pos),
        .frame_tick(frame_tick),
        .R_out(R_out), .G_out(G_out), .B_out(B_out),
        .led(led),
        .score_out(score_out)
    );
    
    //100 MHz clk 
    initial in_clk = 0;
    always #5 in_clk = ~in_clk;

    task pulse_frame;
        input integer count;
        integer n;
        begin
            for (n = 0; n < count; n = n + 1) begin
                @(negedge in_clk); frame_tick = 1;
                @(negedge in_clk); frame_tick = 0;
            end
        end
    endtask

    integer ei;
    task kill_all_enemies;
        begin
            for (ei = 0; ei < 32; ei = ei + 1)
                DUT.enemy_alive[ei] = 0;
        end
    endtask


    initial begin
        rst = 0; BTNC = 0; left = 0; right = 0;
        h_pos = 319; v_pos = 450; frame_tick = 0;

        @(negedge in_clk); rst = 1;
        pulse_frame(2);
        @(negedge in_clk); rst = 0;
        pulse_frame(2);

        kill_all_enemies();
        #2;
        pulse_frame(2);

        DUT.lives = 2; #2;
        DUT.lives = 1; #2;
        DUT.lives = 0; #2;
        pulse_frame(3);

        #10; $finish;
    end
endmodule