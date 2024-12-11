module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20,
  parameter FPS = 60) // never used this parameter (?)
(
  input wire pixel_clk_in, // clock cycle
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out, // Horizontal count on the screen. from 0 to 1649. reset to 0 when a new line
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out, // vertical count on the screen. from 0 to 749. increment 1 when a new line
  output logic vs_out, //vertical sync out // 1 in V_SYNC else 0
  output logic hs_out, //horizontal sync out // 1 in H_SYNC else 0
  output logic ad_out, // 1 in DRAWING, 0 other whise
  output logic nf_out, //SINGLE CYCLE indicator of a new frame // should go when we finish drawing period (1280,720)
  output logic [5:0] fc_out); // number of frame we are at. increments when we finish back_porch_v. 0 TO 59

  localparam TOTAL_PIXELS = (ACTIVE_H_PIXELS+H_FRONT_PORCH+H_SYNC_WIDTH+H_BACK_PORCH) * (ACTIVE_LINES+V_FRONT_PORCH+V_SYNC_WIDTH+V_BACK_PORCH); //figure this out
  localparam TOTAL_LINES = (ACTIVE_LINES+V_FRONT_PORCH+V_SYNC_WIDTH+V_BACK_PORCH); // Sum of all active lines plus the vertical blanking
  localparam TOTAL_PIXELS_H = ACTIVE_H_PIXELS + H_FRONT_PORCH+H_SYNC_WIDTH + H_BACK_PORCH;
  localparam TOTAL_PIXELS_V = (ACTIVE_LINES+V_FRONT_PORCH+V_SYNC_WIDTH+V_BACK_PORCH);


    always_comb begin

        // drawing region flag
        if((hcount_out >= 0) && (hcount_out < ACTIVE_H_PIXELS) && (vcount_out >= 0) && (vcount_out < ACTIVE_LINES)) begin
          ad_out = 1;
        end

        else begin
          ad_out = 0;
        end

        // horizontal sync
        if (hcount_out >= (ACTIVE_H_PIXELS + H_FRONT_PORCH) && hcount_out < (ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH)) begin
          hs_out = 1;
        end

        else begin
          hs_out = 0;
        end

        // next frame signal 
        if (hcount_out == (ACTIVE_H_PIXELS) && vcount_out == (ACTIVE_LINES)) begin
          nf_out = 1;
        end

        else begin
          nf_out = 0;
        end

        // vertical sync
        if (vcount_out >= (ACTIVE_LINES + V_FRONT_PORCH)  && vcount_out < (ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH)) begin 
          vs_out = 1;
        end

        else begin
          vs_out = 0;
        end
    end


    always_ff @(posedge pixel_clk_in) begin

      if(rst_in) begin
          hcount_out <=0;
          vcount_out <= 0;
          fc_out <= 0;
      end

      else begin
          if (hcount_out == (TOTAL_PIXELS_H -1)) begin
            hcount_out <= 0; // resetting horizontal count

            if (vcount_out == (TOTAL_PIXELS_V -1)) begin
              vcount_out <= 0; // resetting vertical count
            end

            else begin
              vcount_out <= vcount_out +1;
            end 
          end

          else begin
            hcount_out <= hcount_out + 1 ;
          end

          if ((hcount_out + 1) == (ACTIVE_H_PIXELS) && vcount_out == (ACTIVE_LINES)) begin
              if (fc_out == (FPS -1)) begin
                  fc_out <= 0;
              end

              else begin
                fc_out <= fc_out + 1;
              end
          end
      end
    end
endmodule
