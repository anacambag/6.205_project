`timescale 1ns / 1ps
`default_nettype none

module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
  logic [8:0] q_m;
  logic [4:0] tally;
  logic [5:0] ones; // check bits
  logic [5:0] zeros;

  //you can assume a functioning (version of tm_choice for you.)
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));

  //your code here.
  always_comb begin
    ones = 0;
    zeros = 0;
    for (int i = 0; i < 8; i++) begin
      if(q_m[i] == 0) begin
        zeros = zeros +1;
      end
      else begin
        ones = ones + 1;
      end
    end
  end

  always_ff @(posedge clk_in) begin
    if(rst_in) begin
      tally <= 0;
      tmds_out <= 10'b0;
    end 
    else if (!ve_in) begin
      tally <= 0;
      case (control_in)
        2'b00: tmds_out <= 10'b1101010100;
        2'b01: tmds_out <= 10'b0010101011;
        2'b10: tmds_out <= 10'b0101010100;
        2'b11: tmds_out <= 10'b1010101011;
      endcase
    end

    else begin // algorithm

      if (tally == 0 || zeros == ones) begin // TRUE BRANCH

        tmds_out[9] <= ~q_m[8];
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= (q_m[8])? q_m[7:0]: ~q_m[7:0];

        if(q_m[8] == 0) begin // TRUE
          tally <= tally + (zeros - ones); 
        end

        else begin // FALSE
          tally <= tally + (ones - zeros); 
        end

      end

      else begin // FALSE BRANCH

        if(((tally[4] == 0) && (ones > zeros)) || ((tally[4] == 1) && (zeros > ones))) begin // TRUE
          tmds_out[9] <= 1;
          tmds_out[8] <= q_m[8];
          tmds_out[7:0] <= ~q_m[7:0];
          tally <= tally + (q_m[8] ? 2 : 0) + (zeros - ones);
        end

        else begin // FALSE
          tmds_out[9] <= 0;
          tmds_out[8] <= q_m[8]; 
          tmds_out[7:0] <= q_m[7:0];
          tally <= tally - ((!q_m[8]) ? 2:0) + (ones - zeros);
        end
      end   
    end
  end
endmodule //end tmds_encoder 
`default_nettype wire
