`timescale 1ns / 1ps
`default_nettype none


`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module display_logic ( 
 input wire pixel_clk_in,
 input wire rst_in,
 input wire [10:0] hcount_in,
 input wire [9:0] vcount_in, 
 input wire [12:0] x_mario_center, 
 input wire [9:0] y_mario_center,
 input wire  new_frame,
 input wire [11:0] offset,
 output wire collision_info_out 
 );

    logic [5:0] unique_image_index; // To determine the item that we are touching 

    before_sprite 
        com_before_sprite_m (
        .pixel_clk_in(pixel_clk_in),
        .rst_in(rst_in),
        .hcount_in(hcount_in),   // hcount that before will receive will be only when we are in module 16 // Changes [10:4]
        .vcount_in(vcount_in),   //vcount that before will receive will be only when we are in module 16 // changes [9:4]
        .unique_image_index_out(unique_image_index),
        .x_center_mass(0), // no affect
        .new_frame(new_frame),
        .offset(offset),
        .collision_output(0) 
    );

    logic [12:0] hcount_in_pipe [3:0]; 
    logic [9:0] vcount_in_pipe [3:0]; 

    logic [12:0] x_mario_center_pipe [3:0]; 
    logic [9:0] y_mario_center_pipe [3:0]; 
    
    logic [11:0] offset_pipe[3:0]; // maybe is wrong 

    always_ff @(posedge pixel_clk_in)begin 
        hcount_in_pipe[0] <= hcount_in;
        vcount_in_pipe[0] <= vcount_in;
        x_mario_center_pipe[0] <= x_mario_center;
        y_mario_center_pipe[0] <= y_mario_center;
        offset_pipe[0] <= offset;
        for (int i=1; i<4; i = i+1)begin
            hcount_in_pipe[i] <= hcount_in_pipe[i-1];
            vcount_in_pipe[i] <= vcount_in_pipe[i-1];
            x_mario_center_pipe[i] <= x_mario_center_pipe[i-1];
            y_mario_center_pipe[i] <= y_mario_center_pipe[i-1];
            offset_pipe[i] <= offset_pipe[i-1];
        end
    end

    logic [12:0] x_left;
    logic [12:0] x_right;
    logic [9:0] y_up;
    logic [9:0] y_down;


    assign x_left= x_mario_center_pipe[1] - 4 >= 0? x_mario_center_pipe[1] - 4: 0;
    assign x_right = x_mario_center_pipe[1] + 4 <= 3375? x_mario_center_pipe[1] + 4: 3375;
    assign y_up = y_mario_center_pipe[1] - 16 >= 0 ? y_mario_center_pipe[1] - 16: 0;
    assign y_down = y_mario_center_pipe[1] + 16 <= 239? y_mario_center_pipe[1] + 16: 239;    
    logic collision_info;
    always_ff @(posedge pixel_clk_in) begin


        if ((hcount_in_pipe[1] + offset_pipe[1])>= x_left && (hcount_in_pipe[1] + offset_pipe[1])<= x_right && vcount_in_pipe[1] == y_up)begin 

                if (unique_image_index == 'h1 || unique_image_index == 'h12 ) begin
                    collision_info <= 1;
                end
                else begin
                    collision_info <= 0;
                end
        end
        else begin
                    collision_info <= 0;
        end

    end

    assign collision_info_out = collision_info;





endmodule


`default_nettype none