`timescale 1ns / 1ps
`default_nettype none
// 1 PIXEL --> 16 bits. 8 Bits upper and 8 bits lower later
module pixel_reconstruct
	#(
	 parameter HCOUNT_WIDTH = 11,
	 parameter VCOUNT_WIDTH = 10
	 )
	(
	 input wire 										 clk_in,
	 input wire 										 rst_in,
	 input wire 										 camera_pclk_in, // camara data clock, in posededge ALL other camara data wires should be read
	 input wire 										 camera_hs_in, // when 0 a row of pixels completed
	 input wire 										 camera_vs_in, // when 0 a FULL FRAME of pixels has been sent and camara is about to start new frame. TOP LEFT CORNER (0,0)
	 input wire [7:0] 							 		camera_data_in, // 8 parallel wires transmitting pixel data. ONE BYTE at a time. a pixel is 2 BYTE
	 output logic 									 pixel_valid_out, // 1 when full pixel's data has been captured
	 output logic [HCOUNT_WIDTH-1:0] pixel_hcount_out, // horizontal count for pixel being trasmitted
	 output logic [VCOUNT_WIDTH-1:0] pixel_vcount_out,// vertical count for pixel being trasmitted
	 output logic [15:0] 						 pixel_data_out // reconstructed 16 bit pixel
	 );

	 // your code here! and here's a handful of logics that you may find helpful to utilize.
	 
	 // previous value of PCLK
	 logic 													 pclk_prev;

	 // can be assigned combinationally:
	 //  true when pclk transitions from 0 to 1
	 logic 													 camera_sample_valid;

	//  assign camera_sample_valid = 0; // TODO: fix this assign assigned combinationally
	 
	 // previous value of camera data, from last valid sample!
	 // should NOT update on every cycle of clk_in, only
	 // when samples are valid.
	 logic 													 last_sampled_hs;
	 logic 													 last_sampled_vs;
	 logic [7:0] 										 last_sampled_data;

	 // flag indicating whether the last byte has been transmitted or not.
	 logic 													 half_pixel_ready;

	 logic [HCOUNT_WIDTH-1:0] hcount;
	 logic [VCOUNT_WIDTH-1:0] vcount;


	 always_comb begin
		if (pclk_prev == 0 && camera_pclk_in == 1) begin
			camera_sample_valid = 1;
		end
		else begin
			camera_sample_valid = 0;
		end
	 end

	always_ff@(posedge clk_in) begin
			if (rst_in) begin
				pixel_hcount_out <= 0;
				pixel_vcount_out <= 0;
				pixel_data_out <= 0;
				pixel_valid_out <= 0;
				half_pixel_ready <= 0;
				last_sampled_hs <= 0; // check this
				last_sampled_vs <= 0;
				last_sampled_data <= 0; // check this
				hcount <= 0;
				vcount <= 0;
				pclk_prev <= 0;
			end 
			else begin
				pixel_valid_out <= 0;
				pclk_prev <= camera_pclk_in;
				if(camera_sample_valid) begin
					// first check if half_pixel_ready if not it means we are doing the first half
					last_sampled_hs <= camera_hs_in;
					last_sampled_vs <= camera_vs_in;
					
					if (camera_vs_in && camera_hs_in) begin
					
						if(!half_pixel_ready) begin
							 // When both hs and vs are high, the bytes captured are VALID
							last_sampled_data <= camera_data_in;
							// maybe not change sampled_hs just yet
							half_pixel_ready <= 1;
							pixel_valid_out <= 0;
						end

						else if (half_pixel_ready) begin
							pixel_data_out <= {last_sampled_data, camera_data_in}; // putting the byte together from previous and current transmission
							half_pixel_ready <= 0;
							pixel_valid_out <= 1; // how to make this active for one cycle?
							hcount <= hcount + 1;
							pixel_hcount_out <= hcount;
							pixel_vcount_out <= vcount;
						end
					end
					else if (!camera_vs_in) begin
						hcount <= 0;
						vcount <= 0;
						pixel_valid_out <= 0;
						half_pixel_ready <= 0;
					end
							
					else if (!camera_hs_in && last_sampled_hs) begin
						hcount <= 0;
						vcount = vcount + 1;
						pixel_valid_out <= 0;
						half_pixel_ready <= 0;
					end

				end
			end
		end

endmodule

`default_nettype wire
