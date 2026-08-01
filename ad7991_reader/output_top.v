`timescale 1ns/1ps

module output_top(

    input  wire        clk,
    input  wire        rst_n,

    // Test Input
    input  wire [11:0] adc_data,
    input  wire        adc_data_valid,

    // DAC Outputs
    output wire        spi_sclk,
    output wire        spi_sync,
    output wire        spi_din

);

    //--------------------------------------------------
    // Internal Signals
    //--------------------------------------------------

    wire [11:0] filtered_data;
    wire        filtered_valid;

    wire        spi_clk_en;

    wire        busy;

    //--------------------------------------------------
    // Moving Average Filter
    //--------------------------------------------------

    moving_average_filter maf(

        .clk(clk),
        .rst_n(rst_n),

        .adc_data(adc_data),
        .adc_data_valid(adc_data_valid),

        .filtered_data(filtered_data),
        .filtered_valid(filtered_valid)

    );

    //--------------------------------------------------
    // SPI Clock
    //--------------------------------------------------

    spi_clock spi_clk(

        .clk(clk),
        .rst_n(rst_n),

        .spi_clk_en(spi_clk_en)

    );

    //--------------------------------------------------
    // DAC Driver
    //--------------------------------------------------

    dac121s101_driver dac(

        .clk(clk),
        .rst_n(rst_n),

        .spi_clk_en(spi_clk_en),

        .filtered_data(filtered_data),
        .filtered_valid(filtered_valid),

        .spi_sclk(spi_sclk),
        .spi_sync(spi_sync),
        .spi_din(spi_din),

        .busy(busy)

    );

endmodule