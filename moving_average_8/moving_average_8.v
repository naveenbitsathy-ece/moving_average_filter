`timescale 1ns / 1ps

module moving_average_8 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [11:0] din,
    input  wire        din_valid,
    output reg  [11:0] dout
);

    reg [11:0] shift_reg[0:7];
    reg [14:0] sum; 
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum  <= 15'd0;
            dout <= 12'd0;
            for (i = 0; i < 8; i = i + 1) begin
                shift_reg[i] <= 12'd0;
            end
        end else if (din_valid) begin
            // Track total across moving window array
            sum <= sum - shift_reg[7] + din;

            // Shift history array pipeline
            shift_reg[0] <= din;
            shift_reg[1] <= shift_reg[0];
            shift_reg[2] <= shift_reg[1];
            shift_reg[3] <= shift_reg[2];
            shift_reg[4] <= shift_reg[3];
            shift_reg[5] <= shift_reg[4];
            shift_reg[6] <= shift_reg[5];
            shift_reg[7] <= shift_reg[6];

            // Division by 8 via logical right shift 
            dout <= (sum - shift_reg[7] + din) >> 3;
        end
    end
endmodule
