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
    input rst,
    input BTNC, // shoot btn
    input left, right,       
    input [31:0] h_pos, // current pixel x from vga.v
    input [31:0] v_pos, // current pixel y from vga.v
    input frame_tick, // one pulse per scanline, for game logic updates
    output reg [3:0] R_out,
    output reg [3:0] G_out,
    output reg [3:0] B_out,
    output [2:0] led
    );
    
    //lives
    wire gameover;
    reg [1:0] lives;
    assign gameover = (lives == 0);
    assign led[0] = (lives > 0);
    assign led[1] = (lives > 1);
    assign led[2] = (lives > 2'b10);
    
    
    //ship movement
    reg [31:0] ship_x_reg;
    localparam SHIP_Y = 450;
    localparam SHIP_SPEED = 4;
    localparam SHIP_MIN_X = 160;
    localparam SHIP_MAX_X = 464;  
    
    reg [9:0] scanline_count;
    
    // enemy positions size=3
    reg [31:0] enemy_x [0:2];
    reg [31:0] enemy_y [0:2];
    reg enemy_alive [0:2];
    
    // bullet 
    reg bullet_active;
    reg [31:0] bullet_x, bullet_y;
    reg btnc_prev;

    // ship sprite rgb wires
    wire [3:0] ship_R, ship_G, ship_B;
    wire ship_active;
    
    ship ship_inst(
        .h_pos(h_pos),
        .v_pos(v_pos),
        .ship_x(ship_x_reg),
        .ship_y(SHIP_Y),
        .R_out(ship_R),
        .G_out(ship_G),
        .B_out(ship_B),
        .active(ship_active)
    );
 

// enemy sprite wires
    wire [3:0] enemy_R [0:2];
    wire [3:0] enemy_G [0:2];
    wire [3:0] enemy_B [0:2];
    wire       enemy_active [0:2];
 
    enemy enemy0(
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x[0]), .enemy_y(enemy_y[0]),
        .enemy_alive(enemy_alive[0]),
        .R_out(enemy_R[0]), .G_out(enemy_G[0]), .B_out(enemy_B[0]),
        .active(enemy_active[0])
    );
 
    enemy enemy1(
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x[1]), .enemy_y(enemy_y[1]),
        .enemy_alive(enemy_alive[1]),
        .R_out(enemy_R[1]), .G_out(enemy_G[1]), .B_out(enemy_B[1]),
        .active(enemy_active[1])
    );
 
    enemy enemy2(
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x[2]), .enemy_y(enemy_y[2]),
        .enemy_alive(enemy_alive[2]),
        .R_out(enemy_R[2]), .G_out(enemy_G[2]), .B_out(enemy_B[2]),
        .active(enemy_active[2])
    );
 
    // bullet pixel wires 
    wire in_bullet_x = bullet_active && (h_pos >= bullet_x) && (h_pos < bullet_x + 4);
    wire in_bullet_y = bullet_active && (v_pos >= bullet_y) && (v_pos < bullet_y + 8);
    


    initial begin
        lives = 2'b11;
    
        bullet_active = 0;
        bullet_x = 0;
        bullet_y = 0;
        btnc_prev = 0;
        
        // initial ship position
        ship_x_reg = 312;
        scanline_count = 0;
 
        enemy_x[0] = 220; enemy_y[0] = 50; enemy_alive[0] = 1;
        enemy_x[1] = 276; enemy_y[1] = 50; enemy_alive[1] = 1;
        enemy_x[2] = 332; enemy_y[2] = 50; enemy_alive[2] = 1;
    end
 
    // runs once per scanline on frametick 
    always @(posedge frame_tick)
    begin
        if (rst) begin
            lives = 2'b11;
    
            bullet_active = 0;
            bullet_x = 0;
            bullet_y = 0;
            btnc_prev = 0;
            
            // initial ship position
            ship_x_reg = 312;
            scanline_count = 0;
     
            enemy_x[0] = 220; enemy_y[0] = 50; enemy_alive[0] = 1;
            enemy_x[1] = 276; enemy_y[1] = 50; enemy_alive[1] = 1;
            enemy_x[2] = 332; enemy_y[2] = 50; enemy_alive[2] = 1;
        end
        else if (!gameover) begin
            // prevents left right trigger from firing once per scanline
            // should only fire once per frame
            if (scanline_count < 524) begin
                scanline_count <= scanline_count + 1;
            end else begin
                scanline_count <= 0;
                // ship movement L/R
                if (left && ship_x_reg >= SHIP_MIN_X)
                    ship_x_reg <= ship_x_reg - SHIP_SPEED;
                if (right && ship_x_reg <= SHIP_MAX_X - SHIP_SPEED)
                    ship_x_reg <= ship_x_reg + SHIP_SPEED;
              
                // shoot on rising edge of BTNC, only if no bullet already active
                if (BTNC && !btnc_prev && !bullet_active) begin
                    bullet_active <= 1;
                    bullet_x <= ship_x_reg + 6; // horizontally centered on ship
                    bullet_y <= SHIP_Y - 8; // just above ship
                end
                
                btnc_prev <= BTNC;
            end
     
            // move bullet upward each scanline tick
            if (bullet_active) begin
                if (bullet_y <= 4) begin
                    bullet_active <= 0; // reached top of screen
                end else begin
                    bullet_y <= bullet_y - 4; // speed is 4px per scanline
                end
            end
            
            // collision detection 
            if (bullet_active) begin
                if (enemy_alive[0] &&
                    bullet_x >= enemy_x[0] && bullet_x < enemy_x[0] + 16 &&
                    bullet_y >= enemy_y[0] && bullet_y < enemy_y[0] + 16) begin
                    enemy_alive[0] <= 0;
                    bullet_active  <= 0;
                end
                if (enemy_alive[1] &&
                    bullet_x >= enemy_x[1] && bullet_x < enemy_x[1] + 16 &&
                    bullet_y >= enemy_y[1] && bullet_y < enemy_y[1] + 16) begin
                    enemy_alive[1] <= 0;
                    bullet_active  <= 0;
                end
                if (enemy_alive[2] &&
                    bullet_x >= enemy_x[2] && bullet_x < enemy_x[2] + 16 &&
                    bullet_y >= enemy_y[2] && bullet_y < enemy_y[2] + 16) begin
                    enemy_alive[2] <= 0;
                    bullet_active  <= 0;
                end
            end
        end
    end
 
    // render the pixels
    always @(*)
    begin
        // bullet (white for now)
        if (in_bullet_x && in_bullet_y) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'hF;
        // enemies
        end else if (enemy_active[0]) begin
            R_out = enemy_R[0]; G_out = enemy_G[0]; B_out = enemy_B[0];
        end else if (enemy_active[1]) begin
            R_out = enemy_R[1]; G_out = enemy_G[1]; B_out = enemy_B[1];
        end else if (enemy_active[2]) begin
            R_out = enemy_R[2]; G_out = enemy_G[2]; B_out = enemy_B[2];
        // ship
        end else if (ship_active) begin
            R_out = ship_R; G_out = ship_G; B_out = ship_B;
        // black background
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
        end
    end
 
endmodule
