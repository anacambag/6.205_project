
module tm_choice (
  input wire [7:0] data_in, // input BYTE
  output logic [8:0] qm_out
);

  logic [7:0] option_1;
  logic [7:0] option_2;
  logic [3:0] counter; 
  logic [8:0] transition;
  logic last_data_in;

  // combinational logic
  always_comb begin

    counter = 0; 
    option_1 = data_in;
    option_2 = data_in;

    for (int i = 0; i < 1; i++) begin
      last_data_in = data_in[i];
    end

    for (int i = 1; i < 8; i++) begin
      option_1[i] = (data_in[i] ^ option_1[i-1]); //  y_n = x_n ^ y_(n-1)
      option_2[i] = ~(data_in[i] ^ option_2[i-1]); // y_n = ~(x_n ^ y_(n-1))
    end


    for (int j = 0; j < 8; j++) begin
      counter = counter + data_in[j]; // count of 1's
    end

    if (counter > 3'd4 || (counter == 3'd4 && !last_data_in)) begin
      transition = {1'b0, option_2}; // chose option 2
    end else begin
      transition = {1'b1, option_1}; // chose option 1
    end

    qm_out = transition; 
  end

endmodule // end tm_choice

