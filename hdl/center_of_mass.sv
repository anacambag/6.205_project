`timescale 1ns / 1ps
`default_nettype none
module center_of_mass (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] x_in,
    input wire [9:0]  y_in,
    input wire valid_in,
    input wire tabulate_in,
    output logic [10:0] x_out,
    output logic [9:0] y_out,
    output logic valid_out);


    logic [31:0] x_sum, y_sum;
    logic [31:0] m_total;
    logic [31:0] x_dividend, y_dividend; // Dividends for division
    logic [31:0] x_quotient, y_quotient; // Quotients from division
    logic [31:0] x_remainder_out, y_remainder_out;
    logic x_division_valid, y_division_valid;
    logic x_error_out, y_error_out;
    logic x_busy_out, y_busy_out; // when 0 it is done with result
    logic start_division;
    logic x_done;
    logic y_done;


    // Divider for X coordinate
    divider my_divider_x (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(x_dividend),
        .divisor_in(m_total),  
        .data_valid_in(start_division),
        .quotient_out(x_quotient),
        .remainder_out(x_remainder_out),
        .data_valid_out(x_division_valid),
        .error_out(x_error_out),
        .busy_out(x_busy_out)
    );

    // Divider for Y coordinate
    divider my_divider_y (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(y_dividend),
        .divisor_in(m_total),  
        .data_valid_in(start_division),
        .quotient_out(y_quotient),
        .remainder_out(y_remainder_out),
        .data_valid_out(y_division_valid),
        .error_out(y_error_out),
        .busy_out(y_busy_out)
    );

    enum {IDLE, SUMMATION, DIVISION, START} cm_state;

    always_ff @(posedge clk_in) begin

        if (rst_in) begin
        x_out <= 0;
        y_out <= 0;
        valid_out <= 0;
        m_total <= 0;
        x_sum <= 0;
        y_sum <= 0;
        start_division <= 0;
        cm_state <= IDLE;
    end else begin
        case (cm_state)

            IDLE: begin
                x_out <= 0;
                y_out <= 0;
                valid_out <= 0;
                m_total <= 0;
                x_sum <= 0;
                y_sum <= 0;
                x_done <= 0;
                y_done <= 0;
                start_division <= 0;
                if (!valid_in) begin
                    // Accumulate first valid input immediately
                    x_sum <= x_in;
                    y_sum <= y_in;
                    m_total <= 1;
                    cm_state <= SUMMATION;
                end
            end

            SUMMATION: begin
                if (tabulate_in && m_total > 0) begin
                    cm_state <= DIVISION;
                    x_dividend <= x_sum;
                    y_dividend <= y_sum;
                    start_division <= 1;
                end
                else if (!valid_in) begin
                    x_sum <= x_sum + x_in;
                    y_sum <= y_sum + y_in;
                    m_total <= m_total + 1;
                end
                
            end

            DIVISION: begin
                if (x_division_valid && !x_busy_out ) begin
                    x_out <= x_quotient[10:0]; // Center of mass X
                    x_done <= 1;
                end

                if (y_division_valid && !y_busy_out) begin
                    y_out <= y_quotient[9:0]; // Center of mass Y
                    y_done <= 1;
                end

                if( y_done && x_done) begin
                    start_division <= 0;
                    valid_out <= 1;            // Signal valid output
                    cm_state <= IDLE;
                end
                
            end
        endcase
    end    
end
endmodule



`default_nettype wire
