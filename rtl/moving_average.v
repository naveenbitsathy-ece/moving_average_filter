
`timescale 1ns / 1ps

module moving_average #(
    parameter DATA_WIDTH = 100,
    parameter N = 12
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] sample_in,
    input  wire                  sample_valid,

    output reg  [DATA_WIDTH-1:0] sample_out,
    output reg                   output_valid
);

    localparam SUM_WIDTH = DATA_WIDTH + $clog2(N);

    // Store the previous N-1 samples
    reg [DATA_WIDTH-1:0] delay_line [0:N-2];

    reg [SUM_WIDTH-1:0] sum;
    reg valid_d;

    integer i;
    integer j;

    // Current sample + previous N-1 samples
    always @(*) begin
        sum = {{(SUM_WIDTH-DATA_WIDTH){1'b0}}, sample_in};

        for (i = 0; i < N-1; i = i+1)
            sum = sum + delay_line[i];
    end

    // Process one sample on each rising edge of sample_valid
   
always @(posedge clk) begin
    if (!rst_n) begin
        for (j = 0; j < N-1; j = j+1)
            delay_line[j] <= 0;

        sample_out   <= 0;
        output_valid <= 0;
    end
    else begin
        // Keep output_valid high until the PS lowers
        // sample_valid to acknowledge the result.
        if (!sample_valid) begin
            output_valid <= 0;
        end
        else if (!output_valid) begin
            sample_out   <= sum / N;
            output_valid <= 1;

            for (j = N-2; j > 0; j = j-1)
                delay_line[j] <= delay_line[j-1];

            delay_line[0] <= sample_in;
        end
    end
end


endmodule
