
`timescale 1ns / 1ps
`default_nettype none

module mario ( 
    input wire clk_pixel,
    input wire sys_rst,
    input wire [12:0] left_boundary_x, // boundaries Mario cannot cross
    input wire [12:0] right_boundary_x, // boundaries Mario cannot cross
    input wire [12:0] x_mario_center, // starting x position
    input wire [9:0] y_mario_center,  // starting y position
    input wire [12:0] x_enemy [13:0], // enemy position x
    input wire [9:0] y_enemy [13:0], // enemy position y
    input wire no_enemy[13:0],
    input wire new_frame,
    input wire left_button_on,
    input wire right_button_on,
    input wire up_button_on,
    input wire offset,
    output wire [2:0] mario_index_image_out, // sprite index
    output wire [12:0] x_array_location_out, // Mario's x-coordinate
    output wire [9:0] y_array_location_out,  // Mario's y-coordinate
    output wire mario_died_out,
    output wire dead_frame_out
);

// Internal signals and variables
logic [12:0] x_array_location;
logic [9:0] y_array_location;
logic [2:0] mario_index_image;
logic is_jumping, is_falling;
logic [4:0] jump_counter;
logic  walk_animation_state;
logic [9:0] ground_y; // ground/platform level

logic left_out;
logic right_out;
logic up_out;
logic mario_died;
logic [2:0] index_counter;

// Parameters for movement
parameter MAX_JUMP_FRAMES = 15;
parameter JUMP_SPEED = 4;
parameter GRAVITY_SPEED = 3;
parameter MOVE_SPEED = 2;

// check next three blocks
logic [5:0] unique_image_index_array[2:0];
logic [4:0] hcount_increment[2:0] = {5'd8, 5'd8, 5'd8}; 
logic [5:0] vcount_increment[2:0] = {6'd0, 6'd16, 6'd32}; 

logic [5:0] down_unique_image_index;
logic is_falling_2;


logic [5:0] left_unique_image_index_array[2:0];
logic [4:0] left_hcount_increment[2:0] = {5'd8, 5'd8, 5'd8}; 
logic [5:0] left_vcount_increment[2:0] = {6'd0, 6'd16, 6'd32}; 

logic [5:0] left_down_unique_image_index;
logic [5:0] up_unique_image_index;

logic mario_enemy_collision [13:0];
logic mario_enemy_collision_out;
logic dead;

logic is_jumping_2_r;
logic is_falling_2_r;
logic [3:0] jump_limit;



  always_comb begin
    for (int h = 0; h < 14; h++) begin

        if (((x_array_location - 6) < x_enemy[h] + 16) &&  // Mario's left overlaps Enemy's right
            ((x_array_location + 6) > x_enemy[h]) &&      // Mario's right overlaps Enemy's left
            ((y_array_location - 16) < y_enemy[h] + 16) && // Mario's top overlaps Enemy's bottom
            ((y_array_location + 8) > y_enemy[h]))       // Mario's bottom overlaps Enemy's top
        begin
            mario_enemy_collision[h] = !no_enemy[h];
        end

        else begin
            mario_enemy_collision[h] = 0;
        end
    end
end

  
  always_comb begin
    mario_enemy_collision_out = mario_enemy_collision[0] | mario_enemy_collision[1] | mario_enemy_collision[2] | mario_enemy_collision[3]|  mario_enemy_collision[4]| mario_enemy_collision[5] | mario_enemy_collision[6] | mario_enemy_collision[7] | mario_enemy_collision[8] | mario_enemy_collision[9]|  mario_enemy_collision[10]| mario_enemy_collision[11] | mario_enemy_collision[12] |  mario_enemy_collision[13];
end


// if the left side of mario touches the enemy or the right side of mario touches the enemy

 

logic move_right;
logic move_left;
logic is_jumping_2;


always_comb begin
    move_left =0;
    move_right = 0; // Default to false
    ground_y = 192;
    is_falling_2 = 0;
    is_jumping_2 = 1;
    jump_limit = MAX_JUMP_FRAMES;
    if (unique_image_index_array[0] == 'h01 || unique_image_index_array[0] == 'h06 ||
        unique_image_index_array[0] == 'h0A || unique_image_index_array[0] == 'h0D ||
        unique_image_index_array[0] == 'h0E || unique_image_index_array[0] == 'h0F ||
        unique_image_index_array[0] == 'h11 || unique_image_index_array[0] == 'h12 ||
        unique_image_index_array[0] == 'h13 || unique_image_index_array[0] == 'h16 ||
        unique_image_index_array[0] == 'h17 || unique_image_index_array[0] == 'h1A ||
        unique_image_index_array[0] == 'h1B || unique_image_index_array[0] == 'h1C ||
        unique_image_index_array[0] == 'h1D || 
        
        unique_image_index_array[1] == 'h01 || unique_image_index_array[1] == 'h06 ||
        unique_image_index_array[1] == 'h0A || unique_image_index_array[1] == 'h0D ||
        unique_image_index_array[1] == 'h0E || unique_image_index_array[1] == 'h0F ||
        unique_image_index_array[1] == 'h11 || unique_image_index_array[1] == 'h12 ||
        unique_image_index_array[1] == 'h13 || unique_image_index_array[1] == 'h16 ||
        unique_image_index_array[1] == 'h17 || unique_image_index_array[1] == 'h1A ||
        unique_image_index_array[1] == 'h1B || unique_image_index_array[1] == 'h1C ||
        unique_image_index_array[1] == 'h1D ||
        
        unique_image_index_array[2] == 'h01 || unique_image_index_array[2] == 'h06 ||
        unique_image_index_array[2] == 'h0A || unique_image_index_array[2] == 'h0D ||
        unique_image_index_array[2] == 'h0E || unique_image_index_array[2] == 'h0F ||
        unique_image_index_array[2] == 'h11 || unique_image_index_array[2] == 'h12 ||
        unique_image_index_array[2] == 'h13 || unique_image_index_array[2] == 'h16 ||
        unique_image_index_array[2] == 'h17 || unique_image_index_array[2] == 'h1A ||
        unique_image_index_array[2] == 'h1B || unique_image_index_array[2] == 'h1C ||
        unique_image_index_array[2] == 'h1D)
    begin
        move_right = 1; // Set to true if any condition matches
    end
    if (left_unique_image_index_array[0] == 'h01 || left_unique_image_index_array[0] == 'h06 ||
        left_unique_image_index_array[0] == 'h0A || left_unique_image_index_array[0] == 'h0D ||
        left_unique_image_index_array[0] == 'h0E || left_unique_image_index_array[0] == 'h0F ||
        left_unique_image_index_array[0] == 'h11 || left_unique_image_index_array[0] == 'h12 ||
        left_unique_image_index_array[0] == 'h13 || left_unique_image_index_array[0] == 'h16 ||
        left_unique_image_index_array[0] == 'h17 || left_unique_image_index_array[0] == 'h1A ||
        left_unique_image_index_array[0] == 'h1B || left_unique_image_index_array[0] == 'h1C ||
        left_unique_image_index_array[0] == 'h1D || 
        
        left_unique_image_index_array[1] == 'h01 || left_unique_image_index_array[1] == 'h06 ||
        left_unique_image_index_array[1] == 'h0A || left_unique_image_index_array[1] == 'h0D ||
        left_unique_image_index_array[1] == 'h0E || left_unique_image_index_array[1] == 'h0F ||
        left_unique_image_index_array[1] == 'h11 || left_unique_image_index_array[1] == 'h12 ||
        left_unique_image_index_array[1] == 'h13 || left_unique_image_index_array[1] == 'h16 ||
        left_unique_image_index_array[1] == 'h17 || left_unique_image_index_array[1] == 'h1A ||
        left_unique_image_index_array[1] == 'h1B || left_unique_image_index_array[1] == 'h1C ||
        left_unique_image_index_array[1] == 'h1D ||
        
        left_unique_image_index_array[2] == 'h01 || left_unique_image_index_array[2] == 'h06 ||
        left_unique_image_index_array[2] == 'h0A || left_unique_image_index_array[2] == 'h0D ||
        left_unique_image_index_array[2] == 'h0E || left_unique_image_index_array[2] == 'h0F ||
        left_unique_image_index_array[2] == 'h11 || left_unique_image_index_array[2] == 'h12 ||
        left_unique_image_index_array[2] == 'h13 || left_unique_image_index_array[2] == 'h16 ||
        left_unique_image_index_array[2] == 'h17 || left_unique_image_index_array[2] == 'h1A ||
        left_unique_image_index_array[2] == 'h1B || left_unique_image_index_array[2] == 'h1C ||
        left_unique_image_index_array[2] == 'h1D)
    begin
        move_left = 1; // Set to true if any condition matches
    end
    if (down_unique_image_index == 'h01 || down_unique_image_index == 'h06 ||
        down_unique_image_index == 'h0A || down_unique_image_index == 'h0D ||
        down_unique_image_index == 'h0E || down_unique_image_index == 'h0F ||
        down_unique_image_index == 'h11 || down_unique_image_index == 'h12 ||
        down_unique_image_index == 'h13 || down_unique_image_index == 'h16 ||
        down_unique_image_index == 'h17 || down_unique_image_index == 'h1A ||
        down_unique_image_index == 'h1B || down_unique_image_index == 'h1C ||
        down_unique_image_index == 'h1D)
        begin 
            ground_y = y_array_location;
        end
    else begin
        is_falling_2 = 1;
        ground_y = 192;
    end
    if (up_unique_image_index == 'h01 || up_unique_image_index == 'h06 ||
        up_unique_image_index == 'h0A || up_unique_image_index == 'h0D ||
        up_unique_image_index == 'h0E || up_unique_image_index == 'h0F ||
        up_unique_image_index == 'h11 || up_unique_image_index == 'h12 ||
        up_unique_image_index == 'h13 || up_unique_image_index == 'h16 ||
        up_unique_image_index == 'h17 || up_unique_image_index == 'h1A ||
        up_unique_image_index == 'h1B || up_unique_image_index == 'h1C ||
        up_unique_image_index == 'h1D)
    begin 
        is_falling_2 = 1;
        ground_y = 192;
        // is_jumping_2 = 0;
        jump_limit = 0;
    end 

end

  genvar i;
  generate;
    for (i = 0; i<3; i++)begin
        before_sprite 
        com_before_sprite_m1 (
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_in(x_array_location + hcount_increment[i]),   // hcount that before will receive will be only when we are in module 16 // Changes [10:4]
        .vcount_in(y_array_location - vcount_increment[i]),   //vcount that before will receive will be only when we are in module 16 // changes [9:4]
        .unique_image_index_out(unique_image_index_array[i]),
        .x_center_mass(0), // no affect
        .new_frame(new_frame),
        .offset(offset),
        .collision_output(0));
      end
  endgenerate

  genvar j;
  generate;
    for (j = 0; j<1; j++)begin
        before_sprite 
        com_before_sprite_m1 (
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_in(x_array_location),   // hcount that before will receive will be only when we are in module 16 // Changes [10:4]
        .vcount_in(y_array_location + 16),   //vcount that before will receive will be only when we are in module 16 // changes [9:4]
        .unique_image_index_out(down_unique_image_index),
        .x_center_mass(0), // no affect
        .new_frame(new_frame),
        .offset(offset),
        .collision_output(0));
      end
  endgenerate

  genvar m;
  generate;
    for (m = 0; m<1; m++)begin
        before_sprite 
        com_before_sprite_m1 (
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_in(x_array_location),   // hcount that before will receive will be only when we are in module 16 // Changes [10:4]
        .vcount_in(y_array_location -16),   //vcount that before will receive will be only when we are in module 16 // changes [9:4]
        .unique_image_index_out(up_unique_image_index),
        .x_center_mass(0), // no affect
        .new_frame(new_frame),
        .offset(offset),
        .collision_output(0));
      end
  endgenerate

  genvar q;
  generate;
    for (q = 0; q<1; q++)begin
        before_sprite 
        com_before_sprite_m1 (
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_in(x_array_location-8),   // hcount that before will receive will be only when we are in module 16 // Changes [10:4]
        .vcount_in(y_array_location + 16),   //vcount that before will receive will be only when we are in module 16 // changes [9:4]
        .unique_image_index_out(left_down_unique_image_index),
        .x_center_mass(0), // no affect
        .new_frame(new_frame),
        .offset(offset),
        .collision_output(0));
      end
  endgenerate

genvar k;
  generate;
    for (k = 0; k<3; k++)begin
        before_sprite 
        com_before_sprite_m1 (
        .pixel_clk_in(clk_pixel),
        .rst_in(sys_rst),
        .hcount_in(x_array_location - left_hcount_increment[k]),   // hcount that before will receive will be only when we are in module 16 // Changes [10:4]
        .vcount_in(y_array_location - left_vcount_increment[k]),   //vcount that before will receive will be only when we are in module 16 // changes [9:4]
        .unique_image_index_out(left_unique_image_index_array[k]),
        .x_center_mass(0), // no affect
        .new_frame(new_frame),
        .offset(offset),
        .collision_output(0));
      end
  endgenerate

logic dead_frame;

// Initialization
always_ff @(posedge clk_pixel) begin
    is_jumping_2_r <= is_jumping_2;
    is_falling_2_r <= is_falling_2;

    if (sys_rst) begin
        x_array_location <= x_mario_center;
        y_array_location <= y_mario_center;
        mario_index_image <= 0; // Idle sprite
        mario_died <= 0;
        is_jumping <= 0;
        is_falling <= 0;
        jump_counter <= 0;
        walk_animation_state <= 0;
        left_out <= 0;
        right_out <= 0;
        up_out <= 0;
        index_counter <= 0;
        // ground_y <= 193;
        walk_animation_state <= 0;
        dead <= 0;  
        dead_frame <= 0;
    end 
    else if(new_frame && (mario_enemy_collision_out || dead) && (index_counter==0))begin 
        if(y_array_location < 208)begin
            y_array_location <= y_array_location +1;
            dead <= 1;
            mario_index_image <= 0;
        end
        else begin 
            dead_frame <=1;
        end 
        index_counter <= index_counter +1;
    end 
    else if(new_frame && (mario_enemy_collision_out || dead))begin 
        if(y_array_location < 208)begin
            dead <= 1;
            mario_index_image <= 0;
        end
        else begin 
            dead_frame <=1;
        end 
        index_counter <= index_counter +1;
    end 
    else if (new_frame && (index_counter==0)) begin
        // Idle Logic

        index_counter <= index_counter +1;

        if (!left_button_on && !right_button_on && !up_button_on) begin
            if (left_out) mario_index_image <= 1; // Facing left idle
            else mario_index_image <= 0; // Facing right idle
        end

        // Walking Left Logic
        if (left_button_on && x_array_location > left_boundary_x && !move_left) begin
            x_array_location <= x_array_location - MOVE_SPEED;
            if (!left_out) begin
                mario_index_image <= 6; // Starting to walk left
            end else begin
                // Alternate between walking left frames
                if (walk_animation_state == 0) mario_index_image <= 6;
                else mario_index_image <= 5;
            end
            walk_animation_state <= ~walk_animation_state; // Toggle animation state
            left_out <= 1;
            right_out <= 0;
        end

        // Walking Right Logic
        if (right_button_on && x_array_location < right_boundary_x && !move_right) begin
            x_array_location <= x_array_location + MOVE_SPEED;
            if (!right_out) begin
                mario_index_image <= 3; // Starting to walk right
            end else begin
                // Alternate between walking right frames
                if (walk_animation_state == 0) mario_index_image <= 3;
                else mario_index_image <= 2;
            end
            walk_animation_state <= ~walk_animation_state; // Toggle animation state
            right_out <= 1;
            left_out <= 0;
        end

        // Jumping Logic
        if (up_button_on && !is_jumping && !is_falling) begin
            is_jumping <= 1;
            jump_counter <= 0;
            up_out <= 1;
            if(left_out)begin 
                mario_index_image <= 7; // Jumping sprite
            end 
            else if (right_out)begin 
                mario_index_image <= 4; // Jumping sprite
            end 
            right_out <= 0;
            left_out <= 0;
        end

        // Jump Movement
        if ((is_jumping) && (!is_falling || !is_falling_2_r)) begin // tiene que dejar de jump cuando toca arriba
            if (jump_counter < jump_limit) begin
                y_array_location <= y_array_location - JUMP_SPEED; // Ascend
                jump_counter <= jump_counter + 1;
            end else begin
                is_jumping <= 0;
                is_falling <= 1; // Start falling after reaching max height
            end
            right_out <= 0;
            left_out <= 0;
        end
        is_jumping_2_r <= is_jumping_2;

        // Falling Logic
        if ((is_falling || is_falling_2_r) && !is_jumping) begin
            if (y_array_location < ground_y) begin
                y_array_location <= y_array_location + GRAVITY_SPEED; // Descend
            end else begin
                y_array_location <= ground_y;
                is_falling <= 0; // Stop falling upon landing
                mario_index_image <= 0; // Reset to idle sprite
            end
            right_out <= 0;
            left_out <= 0;
            up_out <= 0;
        end

        // Jump and Move Left
        if (is_jumping && left_button_on && x_array_location > left_boundary_x && !move_left) begin
            x_array_location <= x_array_location - MOVE_SPEED;
            mario_index_image <= 7; // Jumping left sprite
        end

        // Jump and Move Right
        if (is_jumping && right_button_on && x_array_location < right_boundary_x && !move_right) begin
            x_array_location <= x_array_location + MOVE_SPEED;
            mario_index_image <= 4; // Jumping right sprite
        end
    end
    else if (new_frame) begin
        // Idle Logic
        index_counter <= index_counter +1;

        // Walking Left Logic
        if (left_button_on && x_array_location > left_boundary_x && !move_left) begin
            x_array_location <= x_array_location - MOVE_SPEED;
            left_out <= 1;
            right_out <= 0;
        end

        // Walking Right Logic
        if (right_button_on && x_array_location < right_boundary_x && !move_right) begin
            x_array_location <= x_array_location + MOVE_SPEED;
            right_out <= 1;
            left_out <= 0;
        end

        // Jumping Logic
        if (up_button_on && !is_jumping && !is_falling) begin
            is_jumping <= 1;
            jump_counter <= 0;
            up_out <= 1;
            right_out <= 0;
            left_out <= 0;
        end

        // Jump Movement
        if ((is_jumping) && (!is_falling || !is_falling_2)) begin
            if (jump_counter < jump_limit) begin
                y_array_location <= y_array_location - JUMP_SPEED; // Ascend
                jump_counter <= jump_counter + 1;
            end else begin
                is_jumping <= 0;
                is_falling <= 1; // Start falling after reaching max height
            end
            right_out <= 0;
            left_out <= 0;
        end

        // Falling Logic
        if ((is_falling || is_falling_2)&&(!is_jumping)) begin
            if (y_array_location < ground_y) begin
                y_array_location <= y_array_location + GRAVITY_SPEED; // Descend
            end else begin
                y_array_location <= ground_y;
                is_falling <= 0; // Stop falling upon landing
                //mario_index_image <= 0; // Reset to idle sprite
            end
            right_out <= 0;
            left_out <= 0;
            up_out <= 0;
        end

        // Jump and Move Left
        if (is_jumping && left_button_on && x_array_location > left_boundary_x && !move_left) begin
            x_array_location <= x_array_location - MOVE_SPEED;
            //mario_index_image <= 7; // Jumping left sprite
        end

        // Jump and Move Right
        if (is_jumping && right_button_on && x_array_location < right_boundary_x && !move_right) begin
            x_array_location <= x_array_location + MOVE_SPEED;
            //mario_index_image <= 4; // Jumping right sprite
        end
    end
end

// Output assignments
assign x_array_location_out = x_array_location;
assign y_array_location_out = y_array_location;
assign mario_index_image_out = mario_index_image;
assign mario_died_out = dead;
assign dead_frame_out = dead_frame;

endmodule
`default_nettype none


