`timescale 1ns / 1ps

module top (
   input  wire       clk,        // 100 MHz clock from Y9
   input  wire       rst_n,      // Active-low reset from P16
   // PMOD AD2 (I2C)
   inout  wire       scl,        
   inout  wire       sda,        
   // PMOD DA2 (SPI)
   output wire       dac_sync,   // AB11
   output wire       dac_din,    // AB10
   output wire       dac_sclk    // AA8
);

   // Internal Global Signals
   wire        i2c_clk_en;
   wire        sample_tick;
   wire [11:0] adc_data;
   wire        adc_data_valid;
   wire [11:0] filtered_data;
   
   // Tristate control for I2C SDA
   wire sda_i;
   wire sda_o;
   wire sda_t;
   assign sda = (sda_t == 1'b0) ? sda_o : 1'bZ;
   assign sda_i = sda;

   // Tristate control for I2C SCL
   wire scl_i;
   wire scl_o;
   wire scl_t;
   assign scl = (scl_t == 1'b0) ? scl_o : 1'bZ;
   assign scl_i = scl;

   // 1. Clock and Timing Generator
   i2c_clock u_i2c_clock (
       .clk(clk),
       .rst_n(rst_n),
       .i2c_clk_en(i2c_clk_en),
       .sample_tick(sample_tick)
   );

   // 2. AD7991 ADC I2C Reader
   ad7991_reader u_ad7991_reader (
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

   // 3. 8-Point Moving Average Filter
   moving_average_8 u_filter (
       .clk(clk),
       .rst_n(rst_n),
       .din(adc_data),
       .din_valid(adc_data_valid),
       .dout(filtered_data)
   );

   // 4. PMOD DA2 DAC Driver
   dac_driver u_dac_driver (
       .clk(clk),
       .rst_n(rst_n),
       .din(filtered_data),
       .din_valid(adc_data_valid), 
       .dac_sync(dac_sync),
       .dac_sclk(dac_sclk),
       .dac_din(dac_din)
   );

endmodule

