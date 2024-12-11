`timescale 1ns / 1ps
`default_nettype none


`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */



module image_sprite2 #(
 parameter WIDTH=16, HEIGHT=592) ( // popcat width = 256, height=512
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0]  hcount_in,
 input wire [9:0]  vcount_in,
 input wire [5:0] unique_image_index, 
 input wire in_sprite,
 input wire [11:0] offset_out,
 output logic [7:0] red_out,
 output logic [7:0] green_out,
 output logic [7:0] blue_out
 );

 // calculate rom address
 logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
 logic [14:0] offset;

logic [11:0] hcount_offset;
logic [9:0] vcount_offset;

assign hcount_offset = hcount_in + offset_out;
assign vcount_offset = vcount_in[3:0];

 assign offset = 9'd256 * unique_image_index;
 assign image_addr = hcount_offset[3:0] + (vcount_offset * WIDTH) + offset;

logic [7:0] image_address_index;

  xilinx_single_port_ram_read_first #(
   .RAM_WIDTH(8),                       // Specify RAM data width //8bits?
   .RAM_DEPTH(9472),                     // Specify RAM depth (number of entries)
   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
   .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_BRUM (
   .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
   .dina(0),       // RAM input data, width determined from RAM_WIDTH
   .clka(pixel_clk_in),       // Clock
   .wea(0),         // Write enable
   .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
   .rsta(rst_in),       // Output reset (does not affect memory contents)
   .regcea(1),   // Output register enable
   .douta(image_address_index)      // RAM output data, width determined from RAM_WIDTH
 );


 logic [23:0] palette_color_output;
    xilinx_single_port_ram_read_first #(
   .RAM_WIDTH(24),                       // Specify RAM data width
   .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
   .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) palette_BRUM (
   .addra(image_address_index),     // Address bus, width determined from RAM_DEPTH
   .dina(0),       // RAM input data, width determined from RAM_WIDTH
   .clka(pixel_clk_in),       // Clock
   .wea(0),         // Write enable
   .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
   .rsta(rst_in),       // Output reset (does not affect memory contents)
   .regcea(1),   // Output register enable
   .douta(palette_color_output)      // RAM output data, width determined from RAM_WIDTH
 );

logic in_sprite_pipe[3:0];
always_ff @(posedge pixel_clk_in)begin 
  in_sprite_pipe[0] <= in_sprite;
  for (int i=1; i<4; i = i+1)begin
    in_sprite_pipe[i] <= in_sprite_pipe[i-1];
  end
end 
 assign red_out =  in_sprite_pipe[3] ? palette_color_output[23:16] : 0;
 assign green_out = in_sprite_pipe[3] ? palette_color_output[15:8]: 0;
 assign blue_out =  in_sprite_pipe[3]? palette_color_output[7:0]: 0;
endmodule


`default_nettype none