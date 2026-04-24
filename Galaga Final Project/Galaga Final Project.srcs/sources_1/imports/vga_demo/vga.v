`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2023 06:21:12 PM
// Design Name: 
// Module Name: vga
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


module vga(
    input in_clk,
    input [3:0] R_in,
    input [3:0] G_in,
    input [3:0] B_in,
    output reg [3:0] VGA_R,
    output reg [3:0] VGA_G,
    output reg [3:0] VGA_B,
    output reg VGA_HS,
    output reg VGA_VS,
    output reg [31:0] h_pos,
    output reg [31:0] v_pos,
    output reg frame_tick,    
    output reg visible 
    );
    
    wire clock;
    Clock_divider CD(in_clk, clock);
    
    reg [31:0] count, vertical_count;
    reg [31:0] vertical_position, horizontal_position;
    reg [1:0] vertical_state, horizontal_state;
    reg vertical_trigger, vertical_blank; // triggers the vertical state machine
    // states: 0 means pre-blanking; 1 means pixels; 2 means post-blanking; 3 means synchronizing
    // pre-blanking: 48 cycles, HS high
    // pixels: 640 cycles, HS high
    // post-blanking: 16 cycles, HS high
    // synchronization: 96 cycles, HS low
    
    initial begin
        // initial block for simulation only
        v_pos = 0;
        h_pos = 0;
        vertical_position = 0;
        count = 1;
        vertical_count = 1;
        horizontal_position = 0;
        vertical_state = 3;
        horizontal_state = 3;
        VGA_HS = 1;
        VGA_VS = 1;
        VGA_R = 0;
        VGA_G = 0;
        VGA_B = 0;
        vertical_trigger = 0;
        vertical_blank = 1; // one means blank line instead of display data
    end
    

    /////////// BEGIN HORIZONTAL STATE MACHINE //////////////
    always @(posedge clock)
    begin
        if (horizontal_state == 0) 
        begin
            // blank for 48 cycles
            visible <= 0;
            if (count == 47) begin
                count <= 1;
                horizontal_state <= 1;
                // vertical_position <= vertical_position + 1;
                vertical_trigger <= 1; // to trigger the veritcal FSM on rising edge
                frame_tick <= 1;

            end
            else
            begin
                vertical_trigger <= 0;
                frame_tick <= 0;

                count <= count + 1;
            end
        end
        else if (horizontal_state == 1)
        begin
            frame_tick <= 0;

            // shift out 640 pixels
            if (h_pos == 640)
            begin
                // reached end of line
                VGA_R <= 0;
                VGA_G <= 0;
                VGA_B <= 0;
                horizontal_position <= 0;
                h_pos <= 0;
                horizontal_state <= 2;
            end
            else
            begin
                if (vertical_blank == 0)
                begin
                
                    // modify this line to read an image from a 2D array
                    // index using vertical_position and horizontal_position
                    // from a 640 by 480 array
                    // 480 is the number of lines
                    // 640 is the number of pixels in a line
                    
                    // As an example, I'm going to make 
                    // the top left quadrant of the output blue
                    // the top right quadrant red 
                    // and the bottom right quadrant green
//                    VGA_B <= (horizontal_position < 320 && vertical_position < 240) ? 8 : 0;  // top left
//                    VGA_G <= (horizontal_position >= 320 && vertical_position >= 240) ? 8 : 0;  // bottom right
//                    VGA_R <= (horizontal_position >= 320 && vertical_position < 240) ? 8 : 0;  // top right
                    // spaceship sprite rendering
                    visible <= 1;
                    VGA_R <= R_in;
                    VGA_G <= G_in;
                    VGA_B <= B_in;
                end else begin
                    visible <= 0;
                    VGA_R <= 0; VGA_G <= 0; VGA_B <= 0;
                end
                h_pos <= h_pos + 1;
            end
        end
        else if (horizontal_state == 2)
        begin
            visible <= 0;
            if (count == 16) begin
                count <= 1;
                VGA_HS <= 0;
                horizontal_state <= 3;
            end else count <= count + 1;
        end
        else // 3
        begin
            // sync for 96 cycles
            if (count == 96) begin
                VGA_HS <= 1;
                count <= 1;
                horizontal_state <= 0;
            end
            else
            begin
                count <= count + 1;
            end
        end
    end
    
    /////////// BEGIN VERTICAL STATE MACHINE //////////////
    always @(posedge vertical_trigger)
    begin
        if (vertical_state == 0) 
        begin
            // blank for 33 lines
            if (vertical_count == 32) begin
                vertical_count <= 1;
                vertical_state <= 1;
            end
            else
            begin
                vertical_count <= vertical_count + 1;
            end
        end
        else if (vertical_state == 1)
        begin
            // shift out 480 lines
            if (v_pos == 480)
            begin
                // reached end of frame
                vertical_position <= 0;
                v_pos <= 0;
                vertical_state <= 2;
                vertical_blank <= 1;
            end
            else
            begin
                vertical_blank <= 0; // start displaying data instead of blanking
                vertical_position <= vertical_position + 1;
                v_pos <= v_pos + 1;
            end
        end
        else if (vertical_state == 2)
        begin
            // blank for 10 lines
            if (vertical_count == 10) begin
                vertical_count <= 1;
                VGA_VS <= 0;
                vertical_state <= 3;
            end
            else
            begin
                vertical_count <= vertical_count + 1;
            end
        end
        else // 3
        begin
            // sync for 2 lines
            if (vertical_count == 2) begin
                VGA_VS <= 1;
                vertical_count <= 1;
                vertical_state <= 0;
            end
            else
            begin
                vertical_count <= vertical_count + 1;
            end
        end
    end
endmodule










