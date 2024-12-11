`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module before_game_over #(
 parameter WIDTH = 73, 
 parameter HEIGHT = 9 
) (
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0] hcount_in,
 input wire [9:0]  vcount_in,
 input wire collision_info,
 input wire [12:0] x_in, // Game Over x position
 input wire [9:0]  y_in, // Game Over y position
 input wire unique_image_index, // Unique image identifier for animation frame
 input wire [11:0] offset_background,
//  input wire no_enemy,
 output wire [$clog2(WIDTH * HEIGHT) - 1:0] image_addr,
 output wire in_sprite
 );

 // Calculate dynamic in_sprite based on Goomba's position and screen coordinates

 assign in_sprite = ((hcount_in + (offset_background)) >= (x_in)) && ((hcount_in + (offset_background)) < (x_in)+ WIDTH) &&
                    ((vcount_in ) >= (y_in)) && ((vcount_in) < (y_in) + 9) && (hcount_in <='d575) && (vcount_in <='d239);

 // Calculate ROM address with animation frame offset
 logic [14:0] offset;
 assign offset = 10'd657 * unique_image_index;
 assign image_addr = (hcount_in + (offset_background) - (x_in)) + ((vcount_in - (y_in)) * WIDTH) + offset;


endmodule

`default_nettype wire


`default_nettype none