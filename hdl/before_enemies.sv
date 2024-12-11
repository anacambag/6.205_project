`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module before_enemies #(
 parameter WIDTH = 16, 
 parameter HEIGHT = 48 
) (
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0] hcount_in,
 input wire [9:0]  vcount_in,
 input wire collision_info,
 input wire [12:0] x_in, // Goomba x position
 input wire [9:0]  y_in, // Goomba y position
 input wire [1:0] unique_image_index, // Unique image identifier for animation frame
 input wire [11:0] offset_background,
 input wire no_enemy,
 output wire [$clog2(WIDTH * HEIGHT) - 1:0] image_addr,
 output wire in_sprite
 );

 // Calculate dynamic in_sprite based on Goomba's position and screen coordinates

 assign in_sprite = ((hcount_in + (offset_background)) >= x_in) && ((hcount_in + (offset_background)) < x_in + WIDTH) &&
                    ((vcount_in ) >= y_in) && ((vcount_in) < y_in + 16) && (hcount_in <='d575) && (vcount_in <='d239);

 // Calculate ROM address with animation frame offset
 logic [14:0] offset;
 assign offset = 9'd256 * unique_image_index;
 assign image_addr = no_enemy ? 0: in_sprite ? (hcount_in + (offset_background) - x_in) + ((vcount_in - y_in) * WIDTH) + offset : 0;
 //assign image_addr = (hcount_in + (offset_background) - x_in) + ((vcount_in - y_in) * WIDTH) + offset;


// array with enemy location  
// calculate image_addr for each and output the image_addr 
// check who is in sprite and make selection
// priority encoding 


endmodule

`default_nettype wire