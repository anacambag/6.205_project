`timescale 1ns / 1ps
`default_nettype none


`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module before_sprite #(
 parameter WIDTH=211, HEIGHT=15) ( // 211 16x16 width 15 16x16 height
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [12:0]  hcount_in, 
 input wire [9:0]  vcount_in, 
 input wire [10:0] x_center_mass,
 input wire new_frame,
 input wire collision_output, // ADDED FOR COLLISION 
 input wire [11:0] offset,
 output wire [5:0] unique_image_index_out
 //output wire [11:0] offset_out
 );


 // calculate rom address
 logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;


logic [11:0] hcount_offset;
logic [9:4] vcount_offset;

assign hcount_offset = hcount_in + offset;
assign vcount_offset = vcount_in[9:4];

// assign image_addr = (hcount_in_pipe[1]+ offset)[10:4] + ((vcount_in_pipe[1])[9:4] * WIDTH);

assign image_addr = hcount_offset[11:4] + (vcount_offset * WIDTH);


logic [5:0] unique_image_index;

 //  Xilinx Single Port Read First RAM
 // image
  xilinx_single_port_ram_read_first #(
   .RAM_WIDTH(8),                       // Specify RAM data width //8bits?
   .RAM_DEPTH(3165),                     // Specify RAM depth (number of entries)
   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
   .INIT_FILE(`FPATH(guide_2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_BRUM (
   .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
   .dina(0),       // RAM input data, width determined from RAM_WIDTH
   .clka(pixel_clk_in),       // Clock
   .wea(0),         // Write enable
   .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
   .rsta(rst_in),       // Output reset (does not affect memory contents)
   .regcea(1),   // Output register enable
   .douta(unique_image_index)       // RAM output data, width determined from RAM_WIDTH
);

// pipeline collision_output

logic collision_output_pipe [3:0]; 
//logic [11:0] offset_pipe [3:0];

always_ff @(posedge pixel_clk_in)begin 
    collision_output_pipe[0] <= collision_output;
    //offset_pipe[0] <= offset > 2800 ? 2800: offset;
    //offset_pipe[0] <= offset;

    
    for (int i=1; i<4; i = i+1)begin
    collision_output_pipe[i] <= collision_output_pipe[i-1];
    //offset_pipe[i] <= offset_pipe[i-1];
    end
end


assign unique_image_index_out = unique_image_index + collision_output_pipe[1];
//assign offset_out = offset_pipe[1];

endmodule


`default_nettype none