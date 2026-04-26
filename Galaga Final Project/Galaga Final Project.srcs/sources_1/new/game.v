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
    output reg [3:0] B_out,
    output [2:0] led
    );

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------
    localparam SHIP_Y     = 450;
    localparam SHIP_SPEED = 2;
    localparam SHIP_MIN_X = 160;
    localparam SHIP_MAX_X = 464;
    // frame_tick = once per scanline, 525 lines * 60fps = ~31500 ticks/sec
    localparam TICKS_1S   = 32'd31500;
    localparam TICKS_3S   = 32'd94500;

    // -------------------------------------------------------------------------
    // Lives / game over
    // -------------------------------------------------------------------------
    wire gameover;
    reg [1:0] lives;
    assign gameover = (lives == 0);
    assign led[0] = (lives > 0);
    assign led[1] = (lives > 1);
    assign led[2] = (lives > 2'b10);

    // -------------------------------------------------------------------------
    // Ship state
    // -------------------------------------------------------------------------
    reg [31:0] ship_x_reg;
    reg        ship_visible;
    reg [31:0] respawn_timer;
    reg [9:0]  scanline_count;

    // -------------------------------------------------------------------------
    // Shoot block (3s after enemy bullet hits)
    // -------------------------------------------------------------------------
    reg        shoot_en;
    reg [31:0] shoot_block_timer;

    // -------------------------------------------------------------------------
    // Player bullet
    // -------------------------------------------------------------------------
    reg        bullet_active;
    reg [31:0] bullet_x, bullet_y;
    reg        btnc_prev;

    // -------------------------------------------------------------------------
    // Enemy positions
    // -------------------------------------------------------------------------
    reg [31:0] enemy_x [0:2];
    reg [31:0] enemy_y [0:2];
    reg        enemy_alive [0:2];

    // -------------------------------------------------------------------------
    // Ship sprite
    // -------------------------------------------------------------------------
    wire [3:0] ship_R, ship_G, ship_B;
    wire ship_active;

    ship ship_inst(
        .h_pos(h_pos), .v_pos(v_pos),
        .ship_x(ship_x_reg), .ship_y(SHIP_Y),
        .R_out(ship_R), .G_out(ship_G), .B_out(ship_B),
        .active(ship_active)
    );

    // -------------------------------------------------------------------------
    // Enemy instances - each outputs its bullet position for collision in game.v
    // Change seed value in each enemy's PRNG instantiation to stagger timers
    // -------------------------------------------------------------------------
    wire [3:0]  enemy_R      [0:2];
    wire [3:0]  enemy_G      [0:2];
    wire [3:0]  enemy_B      [0:2];
    wire        enemy_active [0:2];
    wire        ebullet      [0:2];
    wire [31:0] ebullet_x    [0:2];
    wire [31:0] ebullet_y    [0:2];

    enemy #(.PRNG_SEED(16'hA1B2), .INIT_TIMER(32'd315000)) enemy0(
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x[0]), .enemy_y(enemy_y[0]),
        .enemy_alive(enemy_alive[0]),
        .shoot_en(shoot_en),
        .clk(in_clk), .frame(frame_tick),
        .R_out(enemy_R[0]), .G_out(enemy_G[0]), .B_out(enemy_B[0]),
        .active(enemy_active[0]),
        .ebullet(ebullet[0]), .ebullet_x(ebullet_x[0]), .ebullet_y(ebullet_y[0])
    );

    enemy #(.PRNG_SEED(16'hC3D4), .INIT_TIMER(32'd472500)) enemy1(
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x[1]), .enemy_y(enemy_y[1]),
        .enemy_alive(enemy_alive[1]),
        .shoot_en(shoot_en),
        .clk(in_clk), .frame(frame_tick),
        .R_out(enemy_R[1]), .G_out(enemy_G[1]), .B_out(enemy_B[1]),
        .active(enemy_active[1]),
        .ebullet(ebullet[1]), .ebullet_x(ebullet_x[1]), .ebullet_y(ebullet_y[1])
    );

    enemy #(.PRNG_SEED(16'hE5F6), .INIT_TIMER(32'd630000)) enemy2(
        .h_pos(h_pos), .v_pos(v_pos),
        .enemy_x(enemy_x[2]), .enemy_y(enemy_y[2]),
        .enemy_alive(enemy_alive[2]),
        .shoot_en(shoot_en),
        .clk(in_clk), .frame(frame_tick),
        .R_out(enemy_R[2]), .G_out(enemy_G[2]), .B_out(enemy_B[2]),
        .active(enemy_active[2]),
        .ebullet(ebullet[2]), .ebullet_x(ebullet_x[2]), .ebullet_y(ebullet_y[2])
    );

    // -------------------------------------------------------------------------
    // Player bullet display wires
    // -------------------------------------------------------------------------
    wire in_bullet_x = bullet_active && (h_pos >= bullet_x) && (h_pos < bullet_x + 2);
    wire in_bullet_y = bullet_active && (v_pos >= bullet_y) && (v_pos < bullet_y + 20);

    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------
    initial begin
        lives             = 2'b11;
        bullet_active     = 0;
        bullet_x          = 0;
        bullet_y          = 0;
        btnc_prev         = 0;
        ship_x_reg        = 312;
        ship_visible      = 1;
        respawn_timer     = 0;
        shoot_en          = 1;
        shoot_block_timer = 0;
        scanline_count    = 0;

        enemy_x[0] = 220; enemy_y[0] = 50; enemy_alive[0] = 1;
        enemy_x[1] = 276; enemy_y[1] = 50; enemy_alive[1] = 1;
        enemy_x[2] = 332; enemy_y[2] = 50; enemy_alive[2] = 1;
    end

    // -------------------------------------------------------------------------
    // Game logic - runs once per scanline tick
    // -------------------------------------------------------------------------
    always @(posedge frame_tick) begin
        if (rst) begin
            lives             = 2'b11;
            bullet_active     = 0;
            bullet_x          = 0;
            bullet_y          = 0;
            btnc_prev         = 0;
            ship_x_reg        = 312;
            ship_visible      = 1;
            respawn_timer     = 0;
            shoot_en          = 1;
            shoot_block_timer = 0;
            scanline_count    = 0;

            enemy_x[0] = 220; enemy_y[0] = 50; enemy_alive[0] = 1;
            enemy_x[1] = 276; enemy_y[1] = 50; enemy_alive[1] = 1;
            enemy_x[2] = 332; enemy_y[2] = 50; enemy_alive[2] = 1;
        end
        else if (!gameover) begin

            // -- Enemy bullet collision with ship --
            // Check all 3 enemy bullets; if any hit the ship, lose a life,
            // hide ship for 1s, block enemy shooting for 3s
            if (ship_visible) begin : hit_check
                integer i;
                for (i = 0; i < 3; i = i + 1) begin
                    if (ebullet[i] &&
                        ebullet_x[i] >= ship_x_reg && ebullet_x[i] < ship_x_reg + 16 &&
                        ebullet_y[i] >= SHIP_Y      && ebullet_y[i] < SHIP_Y + 16) begin
                        if (lives > 0) lives <= lives - 1;
                        ship_visible      <= 0;
                        respawn_timer     <= TICKS_1S;
                        shoot_en          <= 0;
                        shoot_block_timer <= TICKS_3S;
                    end
                end
            end

            // -- Respawn timer --
            if (respawn_timer > 0) begin
                respawn_timer <= respawn_timer - 1;
                if (respawn_timer == 1) begin
                    ship_visible <= 1;
                    ship_x_reg   <= 312;
                end
            end

            // -- Shoot block timer --
            if (shoot_block_timer > 0) begin
                shoot_block_timer <= shoot_block_timer - 1;
                if (shoot_block_timer == 1)
                    shoot_en <= 1;
            end

            // -- Per-frame ship movement and player bullet --
            if (scanline_count < 524) begin
                scanline_count <= scanline_count + 1;
            end else begin
                scanline_count <= 0;

                if (ship_visible) begin
                    if (left  && ship_x_reg >= SHIP_MIN_X)
                        ship_x_reg <= ship_x_reg - SHIP_SPEED;
                    if (right && ship_x_reg <= SHIP_MAX_X - SHIP_SPEED)
                        ship_x_reg <= ship_x_reg + SHIP_SPEED;
                end

                if (BTNC && !btnc_prev && !bullet_active && ship_visible) begin
                    bullet_active <= 1;
                    bullet_x      <= ship_x_reg + 6;
                    bullet_y      <= SHIP_Y - 8;
                end

                btnc_prev <= BTNC;
            end

            // -- Player bullet movement --
            if (bullet_active) begin
                if (bullet_y <= 4)
                    bullet_active <= 0;
                else
                    bullet_y <= bullet_y - 4;
            end

            // -- Player bullet collision with enemies --
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

    // -------------------------------------------------------------------------
    // Pixel render
    // -------------------------------------------------------------------------
    always @(*) begin
        if (in_bullet_x && in_bullet_y) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'hF;
        end else if (enemy_active[0]) begin
            R_out = enemy_R[0]; G_out = enemy_G[0]; B_out = enemy_B[0];
        end else if (enemy_active[1]) begin
            R_out = enemy_R[1]; G_out = enemy_G[1]; B_out = enemy_B[1];
        end else if (enemy_active[2]) begin
            R_out = enemy_R[2]; G_out = enemy_G[2]; B_out = enemy_B[2];
        end else if (ship_active && ship_visible) begin
            R_out = ship_R; G_out = ship_G; B_out = ship_B;
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
        end
    end

endmodule