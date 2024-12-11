`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite_coins #(
 parameter WIDTH = 16, 
 parameter HEIGHT = 64 // 4 coin animations
) (
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0] hcount_in,
 input wire [9:0]  vcount_in,
 input wire [$clog2(WIDTH * HEIGHT) - 1:0] image_addr,
 input wire in_sprite,
 output logic [7:0] red_out,
 output logic [7:0] green_out,
 output logic [7:0] blue_out
 );

 // RAM to store sprite image data
 logic [7:0] image_address_index;
 xilinx_single_port_ram_read_first #(
   .RAM_WIDTH(8),
   .RAM_DEPTH(1024),
   .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
   .INIT_FILE(`FPATH(image_coins.mem))
 ) image_ram (
   .addra(image_addr),
   .dina(0),
   .clka(pixel_clk_in),
   .wea(0),
   .ena(1),
   .rsta(rst_in),
   .regcea(1),
   .douta(image_address_index)
 );

 // Palette RAM to map color indices to RGB values
 logic [23:0] palette_color_output;
 xilinx_single_port_ram_read_first #(
   .RAM_WIDTH(24),
   .RAM_DEPTH(256),
   .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
   .INIT_FILE(`FPATH(palette_coins.mem))
 ) palette_ram (
   .addra(image_address_index),
   .dina(0),
   .clka(pixel_clk_in),
   .wea(0),
   .ena(1),
   .rsta(rst_in),
   .regcea(1),
   .douta(palette_color_output)
 );

 // Pipeline for in_sprite to account for delays in fetching image and palette data
 logic in_sprite_pipe[3:0];
 always_ff @(posedge pixel_clk_in) begin
   in_sprite_pipe[0] <= in_sprite;
   for (int i = 1; i < 4; i = i + 1) begin
     in_sprite_pipe[i] <= in_sprite_pipe[i - 1];
   end
 end

 // Assign output colors with delay compensation
 assign red_out   = in_sprite_pipe[3] ? palette_color_output[23:16] : 'h92;
 assign green_out = in_sprite_pipe[3] ? palette_color_output[15:8]  : 'h90;
 assign blue_out  = in_sprite_pipe[3] ? palette_color_output[7:0]   : 'hff;

endmodule

`default_nettype wire
