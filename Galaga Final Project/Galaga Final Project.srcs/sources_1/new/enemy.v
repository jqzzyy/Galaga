`timescale 1ns / 1ps

module enemy #(
    parameter PRNG_SEED    = 16'hA1B2,  // override per instance in game.v
    parameter INIT_TIMER   = 32'd472500 // stagger first shot per instance
)(
    input [31:0] h_pos,
    input [31:0] v_pos,
    input [31:0] enemy_x,
    input [31:0] enemy_y,
    input        enemy_alive,
    input        shoot_en,
    input        clk,
    input        frame,
    output reg [3:0]  R_out,
    output reg [3:0]  G_out,
    output reg [3:0]  B_out,
    output reg        active,
    output reg        ebullet,
    output reg [31:0] ebullet_x,
    output reg [31:0] ebullet_y
    );

    // -------------------------------------------------------------------------
    // Sprite bitmaps
    // -------------------------------------------------------------------------
    reg [15:0] enemy_blue   [0:15];
    reg [15:0] enemy_red    [0:15];
    reg [15:0] enemy_yellow [0:15];

    wire in_enemy_x = enemy_alive && (h_pos >= enemy_x) && (h_pos < enemy_x + 16);
    wire in_enemy_y = enemy_alive && (v_pos >= enemy_y)  && (v_pos < enemy_y + 16);
    wire [3:0] sprite_col = (h_pos >= enemy_x) ? h_pos - enemy_x : 4'd0;
    wire [3:0] sprite_row = (v_pos >= enemy_y) ? v_pos - enemy_y : 4'd0;

    // -------------------------------------------------------------------------
    // Bullet state
    // drift_mode: 2'b00 = straight down, 2'b01 = drift right, 2'b10 = drift left
    // chosen once at fire time from PRNG, fixed for bullet's lifetime
    // -------------------------------------------------------------------------
    reg [1:0]  drift_mode;
    reg [1:0]  drift_count;
    reg [31:0] shoot_timer;
    reg [9:0]  escanline_count;

    // -------------------------------------------------------------------------
    // PRNG - seeded uniquely per instance via parameter
    // -------------------------------------------------------------------------
    reg        prng_rst;
    reg        prng_load;
    wire [15:0] prng_out;

    PRNG prng_inst(
        .clk(clk),
        .rst(prng_rst),
        .load(prng_load),
        .seed(PRNG_SEED),
        .out(prng_out)
    );

    // -------------------------------------------------------------------------
    // Bullet render wires - 3px wide, 8px tall
    // -------------------------------------------------------------------------
    wire in_ebullet_x = ebullet && (h_pos >= ebullet_x) && (h_pos < ebullet_x + 3);
    wire in_ebullet_y = ebullet && (v_pos >= ebullet_y) && (v_pos < ebullet_y + 8);

    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------
    initial begin
        ebullet         = 0;
        ebullet_x       = 0;
        ebullet_y       = 0;
        drift_mode      = 0;
        drift_count     = 0;
        shoot_timer     = INIT_TIMER;
        escanline_count = 0;
        prng_rst        = 1;
        prng_load       = 0;

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

        // yellow pixels cleared on row 5 where they overlap red (bits 6,8)
        enemy_yellow[ 0] = 16'b0000000000000000;
        enemy_yellow[ 1] = 16'b0000000000000000;
        enemy_yellow[ 2] = 16'b0000000000000000;
        enemy_yellow[ 3] = 16'b0000000000000000;
        enemy_yellow[ 4] = 16'b0000000100000000;
        enemy_yellow[ 5] = 16'b0000000101000000; // removed bits 6,8 (overlap with red)
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

        #2 prng_rst = 0;
    end

    // -------------------------------------------------------------------------
    // Game logic - runs on frame tick
    // -------------------------------------------------------------------------
    always @(posedge frame) begin

        // shoot timer countdown every scanline tick
        if (enemy_alive) begin
            if (shoot_timer > 0) begin
                shoot_timer <= shoot_timer - 1;
            end else if (shoot_en && !ebullet) begin
                ebullet     <= 1;
                ebullet_x   <= enemy_x + 6;
                ebullet_y   <= enemy_y + 16;
                drift_count <= 0;
                // pick drift mode from 2 PRNG bits:
                // 00,01 = straight, 10 = drift right, 11 = drift left
                case (prng_out[1:0])
                    2'b10:   drift_mode <= 2'b01; // right
                    2'b11:   drift_mode <= 2'b10; // left
                    default: drift_mode <= 2'b00; // straight
                endcase
                shoot_timer <= 32'd315000 + {16'd0, prng_out} * 32'd9;
            end
        end

        // bullet movement - once per frame
        if (escanline_count < 524) begin
            escanline_count <= escanline_count + 1;
        end else begin
            escanline_count <= 0;

            if (ebullet) begin
                if (ebullet_y >= 480) begin
                    ebullet <= 0;
                end else begin
                    ebullet_y <= ebullet_y + 4; // 4px/frame downward

                    // apply fixed drift every 3 frames
                    if (drift_count == 2) begin
                        drift_count <= 0;
                        if (drift_mode == 2'b01 && ebullet_x < 624)
                            ebullet_x <= ebullet_x + 1;
                        else if (drift_mode == 2'b10 && ebullet_x > 160)
                            ebullet_x <= ebullet_x - 1;
                        // drift_mode 00: no horizontal movement
                    end else begin
                        drift_count <= drift_count + 1;
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Pixel render - red checked before yellow to avoid conflict
    // -------------------------------------------------------------------------
    always @(*) begin
        if (in_ebullet_x && in_ebullet_y) begin
            R_out = 4'hF; G_out = 4'h4; B_out = 4'h0; active = 1; // orange-red bullet
        end else if (in_enemy_x && in_enemy_y && enemy_red[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'h0; B_out = 4'h0; active = 1;
        end else if (in_enemy_x && in_enemy_y && enemy_yellow[sprite_row][15 - sprite_col]) begin
            R_out = 4'hF; G_out = 4'hF; B_out = 4'h0; active = 1;
        end else if (in_enemy_x && in_enemy_y && enemy_blue[sprite_row][15 - sprite_col]) begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'hF; active = 1;
        end else begin
            R_out = 4'h0; G_out = 4'h0; B_out = 4'h0; active = 0;
        end
    end

endmodule