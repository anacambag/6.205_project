`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */
///////////////////////// ACOMODAR!!!!////////////////
module before_mario #(
 parameter WIDTH = 16, 
 parameter HEIGHT = 256 
) (
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0] hcount_in,
 input wire [9:0]  vcount_in,
 input wire collision_info,
 input wire [12:0] x_in, // Mario x position
 input wire [9:0]  y_in, // Mario y position
 input wire [2:0] unique_image_index, // Unique image identifier for animation frame
 input wire [11:0] offset_background,
//  input wire no_enemy,
 output wire [$clog2(WIDTH * HEIGHT) - 1:0] image_addr,
 output wire in_sprite
 );

 // Calculate dynamic in_sprite based on Goomba's position and screen coordinates

 assign in_sprite = ((hcount_in + (offset_background)) >= (x_in-8)) && ((hcount_in + (offset_background)) < (x_in -8)+ WIDTH) &&
                    ((vcount_in ) >= (y_in-16)) && ((vcount_in) < (y_in-16) + 32) && (hcount_in <='d575) && (vcount_in <='d239);

 // Calculate ROM address with animation frame offset
 logic [14:0] offset;
 assign offset = 10'd512 * unique_image_index;
 assign image_addr = (hcount_in + (offset_background) - (x_in-8)) + ((vcount_in - (y_in-16)) * WIDTH) + offset;


endmodule

`default_nettype wire