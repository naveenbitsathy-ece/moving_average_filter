
`timescale 1ns / 1ps

module dsp_gpio_wrapper (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [16:0] gpio_out,
    output wire [16:0] gpio_in
);

    wire [15:0] sample_in;
    wire        sample_valid;

    wire [15:0] sample_out;
    wire        output_valid;

    assign sample_in    = gpio_out[15:0];
    assign sample_valid = gpio_out[16];

    assign gpio_in[15:0] = sample_out;
    assign gpio_in[16]   = output_valid;

    moving_average #(
        .DATA_WIDTH(100),
        .N(12)
    ) filter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .sample_out(sample_out),
        .output_valid(output_valid)
    );

endmodule
