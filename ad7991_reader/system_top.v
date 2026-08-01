`timescale 1ns / 1ps

module system_top(

    //-------------------------------------------------
    // FPGA Inputs
    //-------------------------------------------------
    input  wire clk,
    input  wire rst_n,

    //-------------------------------------------------
    // AD7991 (PMOD AD2)
    //-------------------------------------------------
    input  wire sda_i,
    output wire sda_o,
    output wire sda_t,

    input  wire scl_i,
    output wire scl_o,
    output wire scl_t,

    //-------------------------------------------------
    // DAC121S101 (PMOD DA2)
    //-------------------------------------------------
    output wire spi_sclk,
    output wire spi_sync,
    output wire spi_din

);

    //-------------------------------------------------
    // Internal Signals
    //-------------------------------------------------

    wire        i2c_clk_en;
    wire        sample_tick;

    wire [11:0] adc_data;
    wire        adc_data_valid;

    wire [11:0] filtered_data;
    wire        filtered_valid;

    wire        spi_clk_en;
    wire        busy;

    //-------------------------------------------------
    // I2C Clock Generator
    //-------------------------------------------------

    i2c_clock u_i2c_clock(

        .clk(clk),
        .rst_n(rst_n),

        .i2c_clk_en(i2c_clk_en),
        .sample_tick(sample_tick)

    );

    //-------------------------------------------------
    // AD7991 Reader
    //-------------------------------------------------

    ad7991_reader u_ad7991_reader(

        .clk(clk),
        .rst_n(rst_n),

        .i2c_clk_en(i2c_clk_en),
        .sample_tick(sample_tick),

        .adc_data(adc_data),
        .adc_data_valid(adc_data_valid),

        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),

        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t)

    );

    //-------------------------------------------------
    // Moving Average Filter
    //-------------------------------------------------

    moving_average_filter u_maf(

        .clk(clk),
        .rst_n(rst_n),

        .adc_data(adc_data),
        .adc_data_valid(adc_data_valid),

        .filtered_data(filtered_data),
        .filtered_valid(filtered_valid)

    );

    //-------------------------------------------------
    // SPI Clock Generator
    //-------------------------------------------------

    spi_clock u_spi_clock(

        .clk(clk),
        .rst_n(rst_n),

        .spi_clk_en(spi_clk_en)

    );

    //-------------------------------------------------
    // DAC Driver
    //-------------------------------------------------

    dac121s101_driver u_dac(

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