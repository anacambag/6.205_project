`timescale 1ns / 1ps
`default_nettype none


`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */
// BOUNDRY ENEMY
module enemies ( 
 input wire clk_pixel,
 input wire sys_rst,
 input wire [12:0] left_boundary_x,
 input wire [12:0] right_boundary_x,
 input wire [12:0] start_x_location,
 input wire [9:0] boundary_y, 
 input wire [1:0] direction,
 input wire  new_frame,
 input wire [11:0] offset_in,
 input wire [12:0] x_mario_center,
 input wire [9:0] y_mario_center,
 input wire [12:0] x_enemy,
 input wire [9:0] y_enemy,
 output wire [1:0] enemies_index_image_out,
 output wire [12:0] x_array_location_out,
 output wire [9:0] y_array_location_out,
 output wire died_out,
 output wire no_enemy_out
 );
logic left_flag;
logic [1:0] counter_frame;
logic [2:0] legs_counter;
logic [1:0] enemies_index_image;
logic [12:0] x_array_location;
logic [9:0] y_array_location;

// collision (mario and the enemy, enemy dies)
logic [9:0] y_mario_feet_location;
logic [12:0] x_mario_feet_location_left;
logic [12:0] x_mario_feet_location_right;
logic died; 
logic no_enemy;
logic [3:0] died_counter;

assign y_mario_feet_location = y_mario_center + 16;
assign x_mario_feet_location_left = x_mario_center - 16;
assign x_mario_feet_location_right = x_mario_center + 16; 

  always_ff @(posedge clk_pixel)begin 
    if(sys_rst) begin
      x_array_location<= start_x_location; // moves left and right i will put the boundries now. From 640 to 720
      y_array_location<= boundary_y; 
      enemies_index_image <= 1;
      
      legs_counter <= 0;
      counter_frame <=0;
      left_flag <= 0;
      died <= 0;
      no_enemy <= 0;
      died_counter <= 0;
    end
    else if (legs_counter == 0 && new_frame) begin
      if(died && (died_counter == 8))begin 
        no_enemy <=1;
        y_array_location <= y_array_location + 16;

      end 
      else if((died_counter<=7 && died_counter >=1)|| (y_mario_feet_location == 'd193) &&(x_mario_feet_location_right > x_array_location)&& (x_mario_feet_location_left <x_array_location+16))begin // collision
      
      //(((x_array_location - 8) < x_enemy[h] + 16) && ((x_array_location + 8) > x_enemy[h]) (x_mario_feet_location_right > x_array_location)&& (x_mario_feet_location_left <x_array_location+16)
        
        enemies_index_image <= 1;
        died <= 1;
        died_counter <= died_counter +1;
      end 
      else if(direction==1)begin
        if((x_array_location>= left_boundary_x )&& (x_array_location < right_boundary_x) && (left_flag ==0))begin
          x_array_location <=  x_array_location + (counter_frame ==0);
          enemies_index_image <= enemies_index_image + 1;
          legs_counter <= legs_counter + 1;
          counter_frame <= counter_frame +1;
          if(x_array_location == (right_boundary_x-2))begin
            left_flag <=1;
          end
        end
        if (left_flag && (x_array_location >= left_boundary_x )&& (x_array_location <=right_boundary_x)) begin
          x_array_location <=  x_array_location - (counter_frame ==0);
          enemies_index_image <= enemies_index_image +1;
          legs_counter <= legs_counter + 1;
          counter_frame <= counter_frame +1;
          if(x_array_location == (left_boundary_x + 2))begin
            left_flag <=0;
          end 
         end 
      end
      else if (direction == 0) begin
        //1408 go down
        if (offset_in >= start_x_location - 576) begin
          if ((x_array_location >= left_boundary_x)) begin
            x_array_location <=  x_array_location - (counter_frame ==0);
            enemies_index_image <= enemies_index_image +1;
            legs_counter <= legs_counter + 1;
            counter_frame <= counter_frame +1;
          end 
          else begin 
            y_array_location <= y_array_location + (counter_frame ==0);
            enemies_index_image <= enemies_index_image +1;
            legs_counter <= legs_counter + 1;
            counter_frame <= counter_frame +1;
          end 
        end
      end

      else begin
          if ((x_array_location >= left_boundary_x)) begin
            x_array_location <=  x_array_location - (counter_frame ==0);
            enemies_index_image <= enemies_index_image +1;
            legs_counter <= legs_counter + 1;
            counter_frame <= counter_frame +1;
          end 
      end
    end

    else if (new_frame)begin 
      legs_counter <= legs_counter + 1;
      counter_frame <= counter_frame +1;
      if(died && (died_counter == 8))begin 
        no_enemy <=1;
        y_array_location <= y_array_location + 16;
      end 
      else if((died_counter<=7 && died_counter >=1)|| (y_mario_feet_location == 'd193) && (x_array_location >= x_mario_feet_location_left) && (x_array_location+16 <= x_mario_feet_location_right))begin // collision
        enemies_index_image <= 1;
        died <= 1;
        died_counter <= died_counter +1;
      end 
      else if(direction==1)begin
        if((x_array_location >= left_boundary_x )&& (x_array_location < right_boundary_x) && (left_flag ==0))begin
          x_array_location <=  x_array_location + (counter_frame ==0);
        end 

        if((x_array_location >= left_boundary_x )&& (x_array_location <=right_boundary_x) && (left_flag ==1)) begin
          x_array_location <=  x_array_location - (counter_frame ==0);
        end 
      end 
      else if (direction == 0) begin
        if (offset_in >= start_x_location - 576) begin
          if ((x_array_location >= left_boundary_x)) begin
              x_array_location <=  x_array_location - (counter_frame ==0);
          end 
          else begin 
            y_array_location <= y_array_location + 1;
          end
        end 
      end
      else begin
          if ((x_array_location >= left_boundary_x)) begin
              x_array_location <=  x_array_location - (counter_frame ==0);
          end 
        end 
      end
    end 

  assign enemies_index_image_out = enemies_index_image;
  assign x_array_location_out = x_array_location;
  assign y_array_location_out = y_array_location;
  assign no_enemy_out = no_enemy;
  assign died_out = died;



endmodule


`default_nettype none