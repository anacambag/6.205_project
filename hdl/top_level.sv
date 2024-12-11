`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives)
  output logic hdmi_clk_p, hdmi_clk_n, //differential hdmi clock

  output logic [6:0] ss0_c,
  output logic [6:0] ss1_c,
  output logic [3:0] ss0_an,
  output logic [3:0] ss1_an,

  input wire [7:0] pmoda,
  input wire [2:0] pmodb
  // output logic pmodbclk,
  // output logic pmodblock
  );

  assign led = sw;
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];

  //Clocking Variables:
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)

  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (.clk_pixel(clk_pixel),.clk_tmds(clk_5x),
          .reset(0), .locked(locked), .clk_ref(clk_100mhz));

  //signals related to driving the video pipeline
  logic [10:0] hcount;
  logic [9:0] vcount;
  logic vert_sync;
  logic hor_sync;
  logic active_draw;
  logic new_frame;
  logic [5:0] frame_count;

  logic [10:0] hcount_pipe [11:0]; 
  logic [9:0] vcount_pipe [11:0]; 
  logic [5:0] unique_image_index_pipe [6:0];
  logic [11:0] offset_pipe [16:0];
  logic vert_sync_pipe [11:0];
  logic hor_sync_pipe [11:0];
  logic active_draw_pipe [11:0];

  always_ff @(posedge clk_pixel)begin 
      hcount_pipe[0] <= hcount;
      vcount_pipe[0] <= vcount;
      unique_image_index_pipe[0] <= unique_image_index;
      offset_pipe[0] <= offset;
      vert_sync_pipe[0] <= vert_sync;
      hor_sync_pipe[0] <= hor_sync;
      active_draw_pipe[0] <= active_draw;
      
      
      for (int i=1; i<17; i = i+1)begin
        hcount_pipe[i] <= hcount_pipe[i-1];
        vcount_pipe[i] <= vcount_pipe[i-1];
        unique_image_index_pipe[i] <= unique_image_index_pipe [i-1];
        offset_pipe[i] <= offset_pipe[i-1];
        vert_sync_pipe[i] <= vert_sync_pipe[i-1];
        hor_sync_pipe[i] <= hor_sync_pipe[i-1];
        active_draw_pipe[i] <= active_draw_pipe[i-1];
      end
  end

  //from week 04! (make sure you include in your hdl)
  video_sig_gen mvg(
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount), // output
      .vcount_out(vcount), // output
      .vs_out(vert_sync), // output
      .hs_out(hor_sync), //output
      .ad_out(active_draw), //output
      .nf_out(new_frame), // output
      .fc_out(frame_count));// output

  logic [7:0] img_red_enemies, img_green_enemies, img_blue_enemies;
  logic [7:0] img_red_background, img_green_background, img_blue_background;

  //x_com and y_com are the image sprite locations
  //use this in the first part of checkoff 01:
  //instance of image sprite.

logic [5:0] unique_image_index;
logic in_sprite;

always_comb begin
    if(vcount_pipe[2]>239 || hcount_pipe[2]>575)begin
      in_sprite = 0;
    end 
    else begin 
      in_sprite = 1;
    end 
end

logic collision_info_out;
logic collision_out;

///////////////

// NEW OFFSET LOGIC//
 logic [11:0] offset;
 logic  counter;

// always_ff @(posedge clk_pixel) begin
//    if (sys_rst) begin
//       counter <= 0;
//       offset <= 0;
//    end else begin
//       if (new_frame) begin
//          counter <= counter + 1;
//          if (offset< 2800)begin
//             offset <= offset + (counter==0);
//          end 
//          else begin 
//             offset <= 2800;
//          end 
          
//       end 
//       //  offset <= offset + 0;
//       // end
   
//    end
// end


always_ff @(posedge clk_pixel) begin
   if (sys_rst) begin
      counter <= 0;
      offset <= 0;
   end else begin
      if (new_frame) begin
         //counter <= counter + 1;
         if(mario_x_array_location-offset <288)begin 
            offset <= offset;
         end 
         else if (offset< 2800 && (mario_x_array_location-offset >= 288))begin
            offset <= offset + 1;
         end 
         else begin 
            offset <= 2800;
         end 
          
      end 
      //  offset <= offset + 0;
      // end
   
   end
end



logic [5:0] coin_effect_out;

  display_logic mydisplay (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[0]),
    .vcount_in(vcount_pipe[0]), 
    .x_mario_center(mario_x_array_location), // 376
    .y_mario_center(mario_y_array_location), //173
    .offset(offset_pipe[0]),
    .new_frame(new_frame),
    .collision_info_out(collision_info_out) 
  );

  collision_check to_know_collision(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[3]), 
    .vcount_in(vcount_pipe[3]), 
    .offset(offset_pipe[3]),
    .x_bounds_start_coins(x_bounds_start_coins),
    .y_bounds_start_coins(y_bounds_start_coins),
    .new_frame(new_frame),
    .collision_info(collision_info_out),
    .collision_out(collision_out),
    .coin_effect(coin_effect_out) // 1 if we have logic to draw a coin went from 0 to 1
  );

////////////////// BACKGROUND //////////////////////////////////////////////////////////////////
  before_sprite 
    com_before_sprite_m (
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_in(hcount_pipe[5]),  //[10:4] // hcount that before will receive will be only when we are in module 16 
      .vcount_in(vcount_pipe[5]),   // [9:4] vcount that before will receive will be only when we are in module 16 
      .new_frame(new_frame),
      .collision_output(collision_out), // PUT IT LATER FROM COLLISION_CHECK
      .x_center_mass(0),
      .unique_image_index_out(unique_image_index),
      .offset(offset_pipe[5])
    );

  image_sprite2 #(
    .WIDTH(16),
    .HEIGHT(592))
    com_sprite_m (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[7]),   
    .vcount_in(vcount_pipe[7]),   
    .unique_image_index(unique_image_index),
    .offset_out(offset_pipe[7]),
    .in_sprite(in_sprite),
    .red_out(img_red_background),
    .green_out(img_green_background),
    .blue_out(img_blue_background));

////////////////// END OF BACKGROUND //////////////////////////////////////////////////////


////////////////////////// ENEMIESSS ////////////////////////////////////////////////////////////////////////////////
  // 14 enemies in total
  logic [12:0] x_array_location [13:0]; 
  logic [9:0] y_array_location [13:0];
  logic [1:0] enemies_index_image [13:0];
    
  logic [12:0] x_bounds_left[13:0] = {13'd640, 13'd768, 13'd784, 13'd2640, 13'd2656, 13'd1408, 13'd1408, 13'd1408, 13'd1408, 13'd1408, 13'd1408, 13'd1408, 13'd1408, 13'd0}; 
  logic [12:0] x_bounds_start[13:0] = {13'd640, 13'd768, 13'd784, 13'd2640, 13'd2656, 13'd1552, 13'd1576,  13'd1824,  13'd1847,  13'd1984,  13'd2007,  13'd2048, 13'd2071, 13'd352}; 
  logic [12:0] x_bounds_right[13:0] = {13'd720, 13'd880, 13'd896, 13'd2832, 13'd2848, 13'd0, 13'd0, 13'd0, 13'd0, 13'd0, 13'd0, 13'd0, 13'd0, 13'd0}; 
  logic [9:0] y_bounds[13:0] = {10'd193, 10'd193, 10'd193, 10'd193, 10'd193, 10'd193, 10'd193, 10'd193,10'd193,10'd193,10'd193,10'd193,10'd193, 10'd193}; 
  logic [1:0] direction[13:0] = {1,1,1,1,1,0,0,0,0,0,0,0,0,2};
  logic [$clog2(48* 16) - 1:0] enemie_address_draw;
  logic final_in_sprite;
  logic [$clog2(48* 16)-1:0] enemie_address_draw_array[13:0]; // Array for each generate instance
  logic final_in_sprite_array[13:0]; // Array for each generate instance
  logic died_array [13:0];
  logic no_enemy_array [13:0];

  genvar i;
  generate;
    for (i = 0; i<14; i++)begin
      enemies boundary_enemies(
      .clk_pixel(clk_pixel),
      .sys_rst(sys_rst),
      .left_boundary_x(x_bounds_left[i]),
      .right_boundary_x(x_bounds_right[i]),
      .start_x_location(x_bounds_start[i]),
      .direction(direction[i]),
      .boundary_y('d193),
      .new_frame(new_frame),
      .offset_in(offset_pipe[7]),
      .x_mario_center(mario_x_array_location), // 231+offset_pipe[7]
      .y_mario_center(mario_y_array_location), //177
      .no_enemy_out(no_enemy_array[i]),
      .died_out(died_array[i]),
      .enemies_index_image_out(enemies_index_image[i]), // output
      .x_array_location_out(x_array_location[i]), // output
      .y_array_location_out(y_array_location[i]) // output
    );
    before_enemies 
    enemies_address_1(
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_in(hcount_pipe[7]),
      .vcount_in(vcount_pipe[7]),
      .collision_info(0),
      .unique_image_index(died_array[i]? 2 : enemies_index_image[i][0]),
      .no_enemy(no_enemy_array[i]),
      .x_in(x_array_location[i]),
      .y_in(y_array_location[i]),
      .offset_background(offset_pipe[7]),
      .image_addr(enemie_address_draw_array[i]),
      .in_sprite(final_in_sprite_array[i]) // do logic for this
    );
  end
  endgenerate

always_comb begin
    enemie_address_draw = enemie_address_draw_array[0] | enemie_address_draw_array[1] | enemie_address_draw_array[2] | enemie_address_draw_array[3]|  enemie_address_draw_array[4]| enemie_address_draw_array[5] | enemie_address_draw_array[6] | enemie_address_draw_array[7] | enemie_address_draw_array[8] | enemie_address_draw_array[9]|  enemie_address_draw_array[10]| enemie_address_draw_array[11] | enemie_address_draw_array[12] |  enemie_address_draw_array[13];
    final_in_sprite = final_in_sprite_array[0] | final_in_sprite_array[1] | final_in_sprite_array[2] | final_in_sprite_array[3] | final_in_sprite_array[4] | final_in_sprite_array[5] | final_in_sprite_array[6] | final_in_sprite_array[7] | final_in_sprite_array[8] | final_in_sprite_array[9]| final_in_sprite_array[10]| final_in_sprite_array[11]| final_in_sprite_array[12] | final_in_sprite_array[13];
end

  image_sprite_enemies 
  enemies_sprite(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[7][3:0]),
    .vcount_in(vcount_pipe[7][3:0]),
    .in_sprite(final_in_sprite),
    .image_addr(enemie_address_draw),
    .red_out(img_red_enemies), 
    .green_out(img_green_enemies),
    .blue_out(img_blue_enemies));

//////////////////////// END OF ENEMIESSS ///////////////////////////////////////////////////

//////////////////// COINSSSS ////////////////////////////////////////////////////////////////

  logic [5:0] coin_effect_pipe [3:0];
  logic mario_dead_pipe[3:0];

  always_ff @(posedge clk_pixel)begin 
      coin_effect_pipe[0] <= coin_effect_out;  
      mario_dead_pipe[0] <= mario_dead;    
      for (int i=1; i<4; i = i+1)begin
      coin_effect_pipe[i] <= coin_effect_pipe[i-1];
      mario_dead_pipe[i] <= mario_dead_pipe[i-1];
      end
  end

  logic [12:0] x_array_location_coins [5:0]; 
  logic [9:0] y_array_location_coins [5:0];
  logic [1:0] coin_index_image [5:0];
  logic [2:0] rotation_counter;

  logic [12:0] y_bounds_start_coins[5:0] = {13'd144, 13'd144, 13'd144, 13'd144, 13'd80, 13'd80}; 
  logic [12:0] x_bounds_start_coins[5:0] = {13'd384, 13'd320, 13'd1248, 13'd1504, 13'd1744, 13'd2064}; 
  logic [12:0] y_bounds_top_coins[5:0] ={13'd96, 13'd96, 13'd96, 13'd96, 13'd32, 13'd32};

  logic [$clog2(64* 16) - 1:0] coin_address_draw;
  logic [$clog2(64* 16)-1:0] coins_address_draw_array[5:0]; // Array for each generate instance
  
  logic final_coins_in_sprite;
  logic final_coins_in_sprite_array[5:0]; // Array for each generate instance
  // logic died_array [13:0];
  // logic no_enemy_array [13:0];

  logic up_array [5:0];
  logic down_array [5:0];
  logic reset_array [5:0];


  genvar j;
  generate;
    for (j = 0; j<6; j++)begin
      coins boundary_coins(
      .clk_pixel(clk_pixel),
      .sys_rst(sys_rst),
      .y_start(y_bounds_start_coins[j]),
      .x_start(x_bounds_start_coins[j]),
      .y_end(y_bounds_top_coins[j]),
      .new_frame(new_frame),
      .offset_in(offset_pipe[7]),
      .coin_effect(coin_effect_pipe[1][j]), //coin_effect_pipe[j][1
      // .no_enemy_out(no_enemy_array[i]),
      // .died_out(died_array[i]),
      .coins_index_image_out(coin_index_image[j]), // output
      .x_array_location_coins_out(x_array_location_coins[j]), // output
      .y_array_location_coins_out(y_array_location_coins[j]),// output
      .up(up_array[j]),
      .down(down_array[j]),
      .reset_signal(reset_array[j])
    );
    before_coins 
    coins_address(
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_in(hcount_pipe[7]),
      .vcount_in(vcount_pipe[7]),
      .collision_info(0),
      .up(up_array[j]),
      .down(down_array[j]),
      .reset_signal(reset_array[j]),
      .unique_image_index(coin_index_image[j]),
      .x_in(x_array_location_coins[j]),
      .y_in(y_array_location_coins[j]),
      .coin_effect(coin_effect_pipe[1][j]), // coin_effect_pipe[1]
      .offset_background(offset_pipe[7]),
      .image_addr(coins_address_draw_array[j]),
      .in_sprite(final_coins_in_sprite_array[j]) // do logic for this
    );
  end
  endgenerate

always_comb begin
    coin_address_draw = coins_address_draw_array[0] | coins_address_draw_array[1] | coins_address_draw_array[2] | coins_address_draw_array[3] | coins_address_draw_array[4] | coins_address_draw_array[5];
    final_coins_in_sprite = final_coins_in_sprite_array[0] | final_coins_in_sprite_array[1] | final_coins_in_sprite_array[2] | final_coins_in_sprite_array[3]| final_coins_in_sprite_array[4]| final_coins_in_sprite_array[5];
end

  logic [7:0] img_red_coins, img_green_coins, img_blue_coins;

  image_sprite_coins 
  coins_sprite(
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[7][3:0]),
    .vcount_in(vcount_pipe[7][3:0]),
    .in_sprite(final_coins_in_sprite),
    .image_addr(coin_address_draw),
    .red_out(img_red_coins), 
    .green_out(img_green_coins),
    .blue_out(img_blue_coins));

// x: 384-400 Y: 144-160
// x: 352-368 Y: 80-96
// x: 1248-1264 Y: 144-160
// x: 1504 - 1520 Y: 144-160
// x: 1504 - 1520 Y: 80-96
// x: 1616-1632 Y: 144-160
// x: 1744 - 1760 Y: 80-96
// x: 



/////////////////// END OF COINSSS //////////////////////////////////////////////////////////////

/////////////////////////////// MARIOOOOO //////////////////////////////////////////////////////////////////////////////
logic [2:0] mario_index_image;
logic [12:0] mario_x_array_location;
logic [9:0] mario_y_array_location;
logic mario_dead;
logic mario_in_sprite;
logic [$clog2(256* 16) - 1:0] mario_address_draw;
logic [7:0] img_red_mario;
logic [7:0] img_green_mario;
logic [7:0] img_blue_mario;
logic dead_frame;


mario mario_module(
  .clk_pixel(clk_pixel),
  .sys_rst(sys_rst),
  .left_boundary_x(0),
  .right_boundary_x(3360), // check this
  .x_mario_center(127),
  .y_mario_center(192), // at 177 kills the enemies 192 normal
  .new_frame(new_frame),
  .left_button_on(btn[3]),
  .right_button_on(btn[2]),
  .up_button_on(btn[1]),
  .offset(0),
  .x_enemy(x_array_location), // NEW enemies array location
  .y_enemy(y_array_location), // NEW 
  .no_enemy(died_array),
  .mario_index_image_out(mario_index_image),
  .x_array_location_out(mario_x_array_location),
  .y_array_location_out(mario_y_array_location),
  .mario_died_out(mario_dead),
  .dead_frame_out(dead_frame)
);


before_mario mario_address(
  .pixel_clk_in(clk_pixel),
  .rst_in(sys_rst),
  .hcount_in(hcount_pipe[7]),
  .vcount_in(vcount_pipe[7]),
  .collision_info(0),
  .x_in(mario_x_array_location),
  .y_in(mario_y_array_location),
  .unique_image_index(mario_index_image),
  .offset_background(offset_pipe[7]),
  .image_addr(mario_address_draw),
  .in_sprite(mario_in_sprite)
);


  mario_sprite 
    com_sprite_mario (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[7]),   
    .vcount_in(vcount_pipe[7]),   
    .in_sprite(mario_in_sprite),
    .red_out(img_red_mario),
    .image_addr(mario_address_draw),
    .green_out(img_green_mario),
    .blue_out(img_blue_mario));



/////////////////////////////////////// END OF MARIO ///////////////////////////////////////////////////////

/////////////////////////// GAME OVER ////////////////////////////////////////////////////////


logic game_over_in_sprite;

logic [7:0] img_red_game_over;
logic [7:0] img_green_game_over;
logic [7:0] img_blue_game_over;

logic [$clog2(73*9) - 1:0] game_over_address_draw;

before_game_over game_over_addr(
  .pixel_clk_in(clk_pixel),
  .rst_in(sys_rst),
  .hcount_in(hcount_pipe[7]),
  .vcount_in(vcount_pipe[7]),
  .collision_info(0),
  .x_in(252),
  .y_in(120),
  .unique_image_index(0),
  .offset_background(0),
  .image_addr(game_over_address_draw),
  .in_sprite(game_over_in_sprite)
);


game_over_sprite 
    com_sprite_game_over (
    .pixel_clk_in(clk_pixel),
    .rst_in(sys_rst),
    .hcount_in(hcount_pipe[7]),   
    .vcount_in(vcount_pipe[7]),   
    .in_sprite(game_over_in_sprite),
    .image_addr(game_over_address_draw),
    .red_out(img_red_game_over),
    .green_out(img_green_game_over),
    .blue_out(img_blue_game_over));



///////////////////////////// END OF GAME OVER //////////////////////////////////////////////////////////

///////////////////// //////////////INTEGRATION OF EVERYTHING /////////////////////////////////////////////////////////////
  // if red, green and blue of the enemy sprite is purple, then write the pixels of image_sprite2 instead
  // logic [7:0] red, green, blue;
  // always_comb begin
  //   if (img_red_enemies == 'h92 && img_green_enemies == 'h90 && img_blue_enemies== 'hff)begin // if enemie is purple use background pixel instead
  //         red = img_red_background;
  //         green = img_green_background;
  //         blue = img_blue_background;
  //   end 
  //   else begin 
  //        red = img_red_enemies;
  //        green = img_green_enemies;
  //        blue = img_blue_enemies;
  //   end 
  // end

  //// integration with coins /////
logic [7:0] red, green, blue;
logic [2:0] mario_dead_counter;

always_ff @(posedge clk_pixel) begin 
  if (sys_rst) begin
    mario_dead_counter <= 0;
  end 
  else if (mario_dead)begin 
    mario_dead_counter <= mario_dead_counter +1;
  end 

end 


  
  always_comb begin
    if (dead_frame) begin
      red = img_red_game_over;
      green = img_green_game_over;
      blue = img_blue_game_over;
    end

    else begin
      if ((img_red_enemies == 'h92 && img_green_enemies == 'h90 && img_blue_enemies== 'hff) && (img_red_coins == 'h92 && img_green_coins == 'h90 && img_blue_coins== 'hff) && (img_red_mario == 'h92 && img_green_mario == 'h90 && img_blue_mario == 'hff))begin // if enemie is purple use background pixel instead
            red = img_red_background;
            green = img_green_background;
            blue = img_blue_background;
      end 
      else if((img_red_coins == 'h92 && img_green_coins == 'h90 && img_blue_coins== 'hff) && (img_red_mario == 'h92 && img_green_mario == 'h90 && img_blue_mario == 'hff)) begin 
          red = img_red_enemies;
          green = img_green_enemies;
          blue = img_blue_enemies;
      end 
      else if (img_red_mario == 'h92 && img_green_mario == 'h90 && img_blue_mario == 'hff)begin
          red = img_red_coins;
          green = img_green_coins;
          blue = img_blue_coins;
      end 
      else begin 
          red = img_red_mario;
          green = img_green_mario;
          blue = img_blue_mario;
      end 
    end
  end



  /////

  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!

  //three tmds_encoders (blue, green, red)
  //blue should have {vert_sync and hor_sync for control signals)
  //red and green have nothing
  tmds_encoder tmds_red(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(red),
    .control_in(2'b0),
    .ve_in(active_draw_pipe[11]),
    .tmds_out(tmds_10b[2]));

  tmds_encoder tmds_green(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(green),
    .control_in(2'b0),
    .ve_in(active_draw_pipe[11]),
    .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .data_in(blue),
    .control_in({vert_sync_pipe[11],hor_sync_pipe[11]}),
    .ve_in(active_draw_pipe[11]),
    .tmds_out(tmds_10b[0]));

  //four tmds_serializers (blue, green, red, and clock)
  tmds_serializer red_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[2]),
    .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[1]),
    .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
    .clk_pixel_in(clk_pixel),
    .clk_5x_in(clk_5x),
    .rst_in(sys_rst),
    .tmds_in(tmds_10b[0]),
    .tmds_out(tmds_signal[0]));

  //output buffers generating differential signal:
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

  assign ss0_c = 0; //ss_c; //control upper four digit's cathodes!
  assign ss1_c = 0; //ss_c; //same as above but for lower four digits!

endmodule // top_level


`default_nettype wire