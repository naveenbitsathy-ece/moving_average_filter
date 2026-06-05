
`timescale 1ns / 1ps

module i2c_clock (
    input  wire clk,
    input  wire rst_n,
    output reg  i2c_clk_en, 
    output reg  sample_tick 
);

    reg [9:0] i2c_div;     
    reg [16:0] sample_div; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c_div     <= 10'd0;
            sample_div  <= 17'd0;
            i2c_clk_en  <= 1'b0;
            sample_tick <= 1'b0;
        end else begin
            // 100 kHz I2C Enable Strobe
            if (i2c_div == 10'd999) begin
                i2c_div    <= 10'd0;
                i2c_clk_en <= 1'b1;
            end else begin
                i2c_div    <= i2c_div + 1'b1;
                i2c_clk_en <= 1'b0;
            end

            // 1 kHz Sampling Tick
            if (sample_div == 17'd99999) begin
                sample_div  <= 17'd0;
                sample_tick <= 1'b1;
            end else begin
                sample_div  <= sample_div + 1'b1;
                sample_tick <= 1'b0;
            end
        end
    end
endmodule
