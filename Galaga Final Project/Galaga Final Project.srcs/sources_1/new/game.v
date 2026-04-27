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
    output [2:0] led,
    output [15:0] score_out
    );

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------
    localparam SHIP_Y        = 450;
    localparam SHIP_SPEED    = 2;
    localparam SHIP_MIN_X    = 160;
    localparam SHIP_MAX_X    = 464;
    localparam TICKS_1S      = 32'd31500;
    localparam TICKS_3S      = 32'd94500;
    localparam BULLET_SPEED  = 16;

    // enemy grid: 8 cols x 4 rows = 32 enemies
    localparam ENEMY_COLS      = 8;
    localparam ENEMY_ROWS      = 4;
    localparam ENEMY_COUNT     = ENEMY_COLS * ENEMY_ROWS;
    localparam ENEMY_SPACING_X = 40;
    localparam ENEMY_SPACING_Y = 36;
    localparam ENEMY_START_X   = 172;
    localparam ENEMY_START_Y   = 40;

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
    // Shoot block
    // -------------------------------------------------------------------------
    reg        shoot_en;
    reg [31:0] shoot_block_timer;

    // -------------------------------------------------------------------------
    // Score
    // -------------------------------------------------------------------------
    reg [15:0] score;
    assign score_out = score;

    // -------------------------------------------------------------------------
    // Player bullet
    // -------------------------------------------------------------------------
    reg        bullet_active;
    reg [31:0] bullet_x, bullet_y;
    reg        btnc_prev;

    // -------------------------------------------------------------------------
    // Enemy positions
    // -------------------------------------------------------------------------
    reg [31:0] enemy_x     [0:ENEMY_COUNT-1];
    reg [31:0] enemy_y     [0:ENEMY_COUNT-1];
    reg        enemy_alive [0:ENEMY_COUNT-1];

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
    // Enemy instances - 32 with unique seeds and staggered timers
    // -------------------------------------------------------------------------
    wire [3:0]  enemy_R      [0:ENEMY_COUNT-1];
    wire [3:0]  enemy_G      [0:ENEMY_COUNT-1];
    wire [3:0]  enemy_B      [0:ENEMY_COUNT-1];
    wire        enemy_active [0:ENEMY_COUNT-1];
    wire        ebullet      [0:ENEMY_COUNT-1];
    wire [31:0] ebullet_x    [0:ENEMY_COUNT-1];
    wire [31:0] ebullet_y    [0:ENEMY_COUNT-1];

    genvar gi;
    generate
        for (gi = 0; gi < ENEMY_COUNT; gi = gi + 1) begin : enemy_gen
            enemy #(
                .PRNG_SEED(16'hA1B2 + gi * 16'h0F13),
                .INIT_TIMER(32'd31500 + gi * 32'd19688)
            ) enemy_inst (
                .h_pos(h_pos), .v_pos(v_pos),
                .enemy_x(enemy_x[gi]), .enemy_y(enemy_y[gi]),
                .enemy_alive(enemy_alive[gi]),
                .shoot_en(shoot_en),
                .clk(in_clk), .frame(frame_tick),
                .R_out(enemy_R[gi]), .G_out(enemy_G[gi]), .B_out(enemy_B[gi]),
                .active(enemy_active[gi]),
                .ebullet(ebullet[gi]),
                .ebullet_x(ebullet_x[gi]),
                .ebullet_y(ebullet_y[gi])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Enemy pixel mux - scan all, last active pixel wins
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // Player bullet display - 3px wide, 8px tall
    // -------------------------------------------------------------------------
    wire in_bullet_x = bullet_active && (h_pos >= bullet_x) && (h_pos < bullet_x + 3);
    wire in_bullet_y = bullet_active && (v_pos >= bullet_y) && (v_pos < bullet_y + 8);

    // -------------------------------------------------------------------------
    // all_dead: combinational check across all enemies
    // -------------------------------------------------------------------------
    reg  all_dead_r;
    integer ad;
    always @(*) begin
        all_dead_r = 1;
        for (ad = 0; ad < ENEMY_COUNT; ad = ad + 1)
            if (enemy_alive[ad]) all_dead_r = 0;
    end
    wire all_dead = all_dead_r;

    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------
    integer j;
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
        score             = 0;
        scanline_count    = 0;

        for (j = 0; j < ENEMY_COUNT; j = j + 1) begin
            enemy_x[j]     = ENEMY_START_X + (j % ENEMY_COLS) * ENEMY_SPACING_X;
            enemy_y[j]     = ENEMY_START_Y + (j / ENEMY_COLS) * ENEMY_SPACING_Y;
            enemy_alive[j] = 1;
        end
    end

    // -------------------------------------------------------------------------
    // Game logic - runs once per scanline tick
    // -------------------------------------------------------------------------
    integer i, c;
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
            score             = 0;
            scanline_count    = 0;

            for (i = 0; i < ENEMY_COUNT; i = i + 1) begin
                enemy_x[i]     = ENEMY_START_X + (i % ENEMY_COLS) * ENEMY_SPACING_X;
                enemy_y[i]     = ENEMY_START_Y + (i / ENEMY_COLS) * ENEMY_SPACING_Y;
                enemy_alive[i] = 1;
            end
        end
        else if (!gameover) begin

            // -- Enemy bullet collision with ship --
            if (ship_visible) begin : hit_check
                integer hi;
                for (hi = 0; hi < ENEMY_COUNT; hi = hi + 1) begin
                    if (ebullet[hi] &&
                        ebullet_x[hi] >= ship_x_reg && ebullet_x[hi] < ship_x_reg + 16 &&
                        ebullet_y[hi] >= SHIP_Y      && ebullet_y[hi] < SHIP_Y + 16) begin
                        if (lives > 0) lives <= lives - 1;
                        ship_visible      <= 0;
                        respawn_timer     <= TICKS_1S;
                        shoot_en          <= 0;
                        shoot_block_timer <= TICKS_3S;
                    end
                end
            end

            // -- Respawn grid when all enemies are dead --
            if (all_dead) begin
                for (i = 0; i < ENEMY_COUNT; i = i + 1)
                    enemy_alive[i] <= 1;
            end

            // -- Ship respawn timer --
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

            // -- Per-frame gate --
            if (scanline_count < 524) begin
                scanline_count <= scanline_count + 1;
            end else begin
                scanline_count <= 0;

                // ship movement
                if (ship_visible) begin
                    if (left  && ship_x_reg >= SHIP_MIN_X)
                        ship_x_reg <= ship_x_reg - SHIP_SPEED;
                    if (right && ship_x_reg <= SHIP_MAX_X - SHIP_SPEED)
                        ship_x_reg <= ship_x_reg + SHIP_SPEED;
                end

                // fire player bullet
                if (BTNC && !btnc_prev && !bullet_active && ship_visible) begin
                    bullet_active <= 1;
                    bullet_x      <= ship_x_reg + 7;
                    bullet_y      <= SHIP_Y - 8;
                end
                btnc_prev <= BTNC;

                // player bullet movement
                if (bullet_active) begin
                    if (bullet_y <= BULLET_SPEED)
                        bullet_active <= 0;
                    else
                        bullet_y <= bullet_y - BULLET_SPEED;
                end

                // player bullet collision with enemies
                // for loop is fine here since bullet goes inactive after first
                // hit - subsequent iterations see bullet_active=0 next cycle
                if (bullet_active) begin
                    for (c = 0; c < ENEMY_COUNT; c = c + 1) begin
                        if (enemy_alive[c] &&
                            bullet_x >= enemy_x[c] && bullet_x < enemy_x[c] + 16 &&
                            bullet_y >= enemy_y[c] && bullet_y < enemy_y[c] + 16) begin
                            enemy_alive[c] <= 0;
                            bullet_active  <= 0;
                            score          <= score + 16'd1;
                        end
                    end
                end

            end // end per-frame gate

        end
    end

    // -------------------------------------------------------------------------
    // Pixel render
    // -------------------------------------------------------------------------
    always @(*) begin
        if (in_bullet_x && in_bullet_y) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'hF;
        end else if (sel_enemy_active) begin
            R_out = sel_enemy_R; G_out = sel_enemy_G; B_out = sel_enemy_B;
        end else if (ship_active && ship_visible) begin
            R_out = ship_R; G_out = ship_G; B_out = ship_B;
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0;
        end
    end

endmodule