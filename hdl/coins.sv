`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module coins (
 input wire clk_pixel,
 input wire sys_rst,
 input wire [12:0] x_start,
 input wire [9:0] y_start,
 input wire [9:0] y_end, 
 input wire  new_frame,
 input wire [11:0] offset_in,
 input wire coin_effect,
//  input wire [12:0] x_mario_center,
//  input wire [9:0] y_mario_center,
 output wire [1:0] coins_index_image_out,
 output wire [12:0] x_array_location_coins_out,
 output wire [9:0] y_array_location_coins_out,
 output wire up,
 output wire down,
 output wire reset_signal
//  output wire died_out,
//  output wire no_enemy_out

);

// coin places: 
// x: 384-400 Y: 144-160
// x: 352-368 Y: 80-96
// x: 1248-1264 Y: 144-160
// x: 1504 - 1520 Y: 144-160
// x: 1504 - 1520 Y: 80-96
// x: 1616-1632 Y: 144-160
// x: 1744 - 1760 Y: 80-96
// x: 

logic no_more_coin;
logic  counter_frame;
logic [2:0] effect_counter;
logic [1:0] coins_index_image;
logic [12:0] x_array_location;
logic [9:0] y_array_location;
logic already_up;
logic already_down;
logic reset;

logic [5:0] frame_counter;

  always_ff @(posedge clk_pixel)begin 
    if(sys_rst) begin
        x_array_location <= x_start;
        y_array_location <= y_start;
        counter_frame <= 0;
        effect_counter<= 0;
        coins_index_image <= 0;
        no_more_coin <= 0;
        already_up <= 0;
        already_down <= 1;
        reset <= 0;
    end
      else if(coin_effect)begin
          if (effect_counter == 0 && new_frame) begin
                    if((y_array_location > y_end) && (!already_up))begin
                         y_array_location <= y_array_location - (counter_frame ==0);
                         reset <=1;
                    end 
                    else if (y_array_location == y_end ) begin
                         already_up <= 1;
                         y_array_location <= y_array_location + (counter_frame ==0);
                    end

                    else if (y_array_location < y_start)begin 
                         y_array_location <= y_array_location + (counter_frame ==0);
                    end
                    else if (y_array_location == y_start ) begin
                         already_down <= 1;
                    end
                    coins_index_image <= coins_index_image + 1;
                    effect_counter <= effect_counter + 1;
                    counter_frame <= counter_frame + 1;
               
          end
          else if (new_frame) begin
                    if((y_array_location > y_end) && (!already_up))begin
                         y_array_location <= y_array_location - (counter_frame ==0);
                         reset <=1;
                    end 
                    else if (y_array_location == y_end ) begin
                         already_up <= 1;
                         y_array_location <= y_array_location + (counter_frame ==0);
                    end

                    else if (y_array_location < y_start)begin 
                         y_array_location <= y_array_location + (counter_frame ==0);
                    end
                    else if (y_array_location == y_start ) begin
                         already_down <= 1;
          
                    end
                    
                    effect_counter <= effect_counter + 1;
                    counter_frame <= counter_frame + 1;
               
          end
     end
  end

  assign coins_index_image_out = coins_index_image;
  assign y_array_location_coins_out = y_array_location;
  assign x_array_location_coins_out = x_array_location;
  assign up = already_up;
  assign down = already_down;
  assign reset_signal = reset;


endmodule // top_level


`default_nettype wire