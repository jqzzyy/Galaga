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

`timescale 1ns / 1ps

module game(
    input in_clk,
    input rst,             
    input BTNC,
    input left, right,
    input [31:0] h_pos,
    input [31:0] v_pos,
    input frame_tick,
    output reg [3:0] R_out,
    output reg [3:0] G_out,
    output reg [3:0] B_out
    );


    reg [31:0] ship_x_reg;
    localparam SHIP_Y     = 450;
    localparam SHIP_SPEED = 4;
    localparam SHIP_MIN_X = 160;
    localparam SHIP_MAX_X = 464;

    reg [9:0] scanline_count;

    wire [3:0] ship_R, ship_G, ship_B;
    wire ship_active;

    ship ship_inst(
        .h_pos(h_pos), .v_pos(v_pos),
        .ship_x(ship_x_reg), .ship_y(SHIP_Y),
        .R_out(ship_R), .G_out(ship_G), .B_out(ship_B),
        .active(ship_active)
    );


    localparam ENEMY_ROWS      = 4;
    localparam ENEMY_COLS      = 8;
    localparam ENEMY_COUNT     = ENEMY_ROWS * ENEMY_COLS;
    localparam ENEMY_SPACING_X = 40;
    localparam ENEMY_SPACING_Y = 40;
    localparam ENEMY_START_X   = 172;
    localparam ENEMY_START_Y   = 40;

    reg [31:0] enemy_x     [0:ENEMY_COUNT-1];
    reg [31:0] enemy_y     [0:ENEMY_COUNT-1];
    reg        enemy_alive [0:ENEMY_COUNT-1];

    wire [3:0] enemy_R      [0:ENEMY_COUNT-1];
    wire [3:0] enemy_G      [0:ENEMY_COUNT-1];
    wire [3:0] enemy_B      [0:ENEMY_COUNT-1];
    wire       enemy_active [0:ENEMY_COUNT-1];

    genvar gi;
    generate
        for (gi = 0; gi < ENEMY_COUNT; gi = gi + 1) begin : enemy_gen
            enemy enemy_inst (
                .h_pos(h_pos), .v_pos(v_pos),
                .enemy_x(enemy_x[gi]), .enemy_y(enemy_y[gi]),
                .enemy_alive(enemy_alive[gi]),
                .R_out(enemy_R[gi]), .G_out(enemy_G[gi]), .B_out(enemy_B[gi]),
                .active(enemy_active[gi])
            );
        end
    endgenerate

    // Reset enemy arrays via generate (can't loop inside always reset)
    genvar ri;
    generate
        for (ri = 0; ri < ENEMY_COUNT; ri = ri + 1) begin : enemy_rst
            always @(posedge in_clk) begin
                if (rst) begin
                    enemy_x[ri]     <= ENEMY_START_X + (ri % ENEMY_COLS) * ENEMY_SPACING_X;
                    enemy_y[ri]     <= ENEMY_START_Y + (ri / ENEMY_COLS) * ENEMY_SPACING_Y;
                    enemy_alive[ri] <= 1;
                end
            end
        end
    endgenerate


    reg bullet_active;
    reg [31:0] bullet_x, bullet_y;
    reg btnc_prev;

    wire in_bullet_x = bullet_active && (h_pos >= bullet_x) && (h_pos < bullet_x + 3);
    wire in_bullet_y = bullet_active && (v_pos >= bullet_y) && (v_pos < bullet_y + 12);


    reg [3:0] sel_enemy_R, sel_enemy_G, sel_enemy_B;
    reg       sel_enemy_active;
    integer k;
    always @(*) begin
        sel_enemy_R      = 0;
        sel_enemy_G      = 0;
        sel_enemy_B      = 0;
        sel_enemy_active = 0;
        for (k = 0; k < ENEMY_COUNT; k = k + 1) begin
            if (enemy_active[k]) begin
                sel_enemy_R      = enemy_R[k];
                sel_enemy_G      = enemy_G[k];
                sel_enemy_B      = enemy_B[k];
                sel_enemy_active = 1;
            end
        end
    end


    integer c;
    always @(posedge frame_tick) begin
        if (rst) begin
            ship_x_reg     <= 312;
            scanline_count <= 0;
            bullet_active  <= 0;
            bullet_x       <= 0;
            bullet_y       <= 0;
            btnc_prev      <= 0;
        end else begin
            // once per frame
            if (scanline_count < 524) begin
                scanline_count <= scanline_count + 1;
            end else begin
                scanline_count <= 0;

                if (left  && ship_x_reg >= SHIP_MIN_X)
                    ship_x_reg <= ship_x_reg - SHIP_SPEED;
                if (right && ship_x_reg <= SHIP_MAX_X - SHIP_SPEED)
                    ship_x_reg <= ship_x_reg + SHIP_SPEED;

                if (BTNC && !btnc_prev && !bullet_active) begin
                    bullet_active <= 1;
                    bullet_x      <= ship_x_reg + 6;
                    bullet_y      <= SHIP_Y - 8;
                end

                btnc_prev <= BTNC;
            end

            // bullet movement
            if (bullet_active) begin
                if (bullet_y <= 2)
                    bullet_active <= 0;
                else
                    bullet_y <= bullet_y - 2;
            end

            // collision detection
            for (c = 0; c < ENEMY_COUNT; c = c + 1) begin
                if (bullet_active && enemy_alive[c] &&
                    bullet_x >= enemy_x[c] && bullet_x < enemy_x[c] + 16 &&
                    bullet_y >= enemy_y[c] && bullet_y < enemy_y[c] + 16) begin
                    enemy_alive[c] <= 0;
                    bullet_active  <= 0;
                end
            end
        end
    end

    //render
    always @(*) begin
        if (in_bullet_x && in_bullet_y) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'hF;
        end else if (sel_enemy_active) begin
            R_out = sel_enemy_R; G_out = sel_enemy_G; B_out = sel_enemy_B;
        end else if (ship_active) begin
            R_out = ship_R; G_out = ship_G; B_out = ship_B;
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
        end
    end

endmodule
