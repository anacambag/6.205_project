`timescale 1ns / 1ps
`default_nettype none


`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module collision_check #(
 parameter WIDTH=211, HEIGHT=15) ( // 211 16x16 width 15 16x16 height
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0]  hcount_in, 
 input wire [9:0]  vcount_in, 
 input wire new_frame,
 input wire [11:0] offset,
 input wire [12:0] y_bounds_start_coins[5:0],
 input wire [12:0] x_bounds_start_coins[5:0],
 input wire collision_info,
 output wire collision_out, 
 output wire [5:0] coin_effect 
 );


 // calculate rom address
 logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
 logic [5:0] counter;
 logic read_collision;

logic [11:0] hcount_offset;
logic [9:4] vcount_offset;

assign hcount_offset = hcount_in + offset;
assign vcount_offset = vcount_in[9:4];

// assign image_addr = (hcount_in_pipe[1]+ offset)[10:4] + ((vcount_in_pipe[1])[9:4] * WIDTH);

assign image_addr = hcount_offset[11:4] + (vcount_offset * WIDTH);


//assign image_addr = hcount_in + ((vcount_in * WIDTH));

  xilinx_single_port_ram_read_first #(
   .RAM_WIDTH(1),                       // Specify RAM data width //8bits?
   .RAM_DEPTH(3165),                     // Specify RAM depth (number of entries)
   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
   .INIT_FILE(`FPATH(collisions.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) Collisions_BRUM (
   .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
   .dina(collision_info),       // RAM input data. Either 1 if we collided or 0 if we did not
   .clka(pixel_clk_in),       // Clock
   .wea(collision_info),         // Write enable
   .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
   .rsta(rst_in),       // Output reset (does not affect memory contents)
   .regcea(1),   // Output register enable
   .douta(read_collision)      // outputs previous value in place where we are writing to now
);
// pipeline 2 cycles collision_info

logic collision_info_pipe [3:0]; 

always_ff @(posedge pixel_clk_in)begin 
    collision_info_pipe[0] <= collision_info;
    
    for (int i=1; i<3; i = i+1)begin
    collision_info_pipe[i] <= collision_info_pipe[i-1];
    end
end

assign collision_out = collision_info_pipe[1] || read_collision;

// if new_frame coin_effect = 0
logic [5:0] coin_counter; 
logic [5:0] coin_array_out;

always_comb begin 
    for (int i=0; i<6; i = i+1)begin
      if(((hcount_in) == (x_bounds_start_coins[i]-offset+16)) && (vcount_in == y_bounds_start_coins[i])) begin
        coin_array_out[i] = read_collision || (collision_info_pipe[1]);
      end 
    end
end 

// always_ff @(posedge pixel_clk_in) begin
    
//     if(new_frame) begin
//         coin_counter<= 0;
//     end
    
//     else if ((read_collision) || (collision_info_pipe[1])) begin
//         coin_counter <= 1;
//     end
// end


always_ff @(posedge pixel_clk_in) begin
    
    if(new_frame) begin
        coin_counter[0] <= 1'b0;
        coin_counter[1] <= 1'b0;
        coin_counter[2] <= 1'b0;
        coin_counter[3] <= 1'b0;
        coin_counter[4] <= 1'b0;
        coin_counter[5] <= 1'b0;
    end
    
    else if ((read_collision) || (collision_info_pipe[1])) begin
        coin_counter <= coin_array_out;
    end

end
 
assign collision_out = read_collision || (collision_info_pipe[1]);
assign coin_effect = coin_counter;

endmodule


`default_nettype none