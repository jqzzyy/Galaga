`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 11:25:45 PM
// Design Name: 
// Module Name: ship_tb
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


module ship_tb(

    );
    
    reg [31:0] h_pos;
    reg [31:0] v_pos;
    reg [31:0] ship_x;
    reg [31:0] ship_y;
    wire active;
    
    ship DUT(
        .h_pos(h_pos), .v_pos(v_pos),
        .ship_x(ship_x), .ship_y(ship_y),
        .R_out(), .G_out(), .B_out(),
        .active(active)
    );
    
    initial begin
        ship_x = 312;
        ship_y = 450;
        
        h_pos = 319; v_pos = 455; #10;
 
        h_pos = 0; v_pos = 0; #10; //out of bounds, goes to low in waveform
 
        h_pos = 319; v_pos = 455; #10;//goes back to high, ship in bounds
        
        h_pos = 327; v_pos = 465; #10;//out of bounds 
 
 
        $finish;
    end
endmodule
