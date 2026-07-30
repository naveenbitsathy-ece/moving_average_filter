`timescale 1ns / 1ps

module top_module(

    input  wire clk,          // 100 MHz FPGA Clock
    input  wire rst_n,

    // I2C Physical Pins
    input  wire sda_i,
    output wire sda_o,
    output wire sda_t,

    input  wire scl_i,
    output wire scl_o,
    output wire scl_t,

    // ADC Output
    output wire [11:0] adc_data,
    output wire adc_data_valid
  
);

assign scl_bus = scl_i;
assign sda_bus = sda_i;
    //---------------------------------------------------
    // Internal Signals
    //---------------------------------------------------

    wire i2c_clk_en;
    wire sample_tick;

    //---------------------------------------------------
    // Clock Generator
    //---------------------------------------------------

    i2c_clock clock_gen (

        .clk(clk),
        .rst_n(rst_n),

        .i2c_clk_en(i2c_clk_en),
        .sample_tick(sample_tick)

    );

    //---------------------------------------------------
    // AD7991 Reader FSM
    //---------------------------------------------------

    ad7991_reader adc_reader (

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

    // ad7991_slave slave(
    //     .sda(sda_bus),
    //     .scl(scl_bus)
    // );

endmodule