`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module before_coins #(
 parameter WIDTH = 16, 
 parameter HEIGHT = 64 
) (
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0] hcount_in,
 input wire [9:0]  vcount_in,
 input wire collision_info,
 input wire [12:0] x_in, // block coin x position
 input wire [9:0]  y_in, // block coin y position
 input wire [1:0] unique_image_index, // Unique image identifier for animation frame
 input wire [11:0] offset_background,
 input wire coin_effect,
 input wire up,
 input wire down,
 input wire reset_signal,
 output wire [$clog2(WIDTH * HEIGHT) - 1:0] image_addr,
 output wire in_sprite
 );

 // Calculate dynamic in_sprite based on Coin's position and screen coordinates

//  logic [2:0] coin_counter;

//  always_ff @(posedge pixel_clk_in) begin
    
//     if(rst_in) begin
//         coin_counter <= 0;
//     end
    
//     else if (coin_effect) begin
//         coin_counter <= coin_counter + 1;
//     end
//  end

 assign in_sprite = ((hcount_in + (offset_background)) >= x_in ) && ((hcount_in + (offset_background)) < (x_in + WIDTH)) &&
                    ((vcount_in ) >= y_in) && ((vcount_in) < y_in + 16) && (hcount_in <='d575) && (vcount_in <='d239) && (!((vcount_in >= 144 && vcount_in <= 160) || (vcount_in >= 80 && vcount_in <= 96)));

 // Calculate ROM address with animation frame offset
 logic [14:0] offset;
 assign offset = 9'd256 * unique_image_index;


 assign image_addr = ((((up==0 && down)||(down && up)))) ? in_sprite ? (hcount_in + (offset_background) - x_in) + ((vcount_in - y_in) * WIDTH) + offset : 0 : 0;

endmodule

`default_nettype wire