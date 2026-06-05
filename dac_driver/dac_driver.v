`timescale 1ns / 1ps

module dac_driver (
    input  wire        clk,        
    input  wire        rst_n,
    input  wire [11:0] din,        
    input  wire        din_valid,  
    output reg         dac_sync,   
    output reg         dac_sclk,   
    output reg         dac_din     
);

    reg [1:0]  clk_div;
    reg [4:0]  bit_index;
    reg [15:0] tx_shift_reg;
    reg        active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div      <= 2'b0;
            dac_sclk     <= 1'b1;
            dac_sync     <= 1'b1;
            dac_din      <= 1'b0;
            bit_index    <= 5'd0;
            tx_shift_reg <= 16'd0;
            active       <= 1'b0;
        end else begin
            clk_div <= clk_div + 1'b1;
            
            if (clk_div == 2'b01) begin
                if (din_valid && !active) begin
                    tx_shift_reg <= {4'b0000, din};
                    dac_sync     <= 1'b0;
                    active       <= 1'b1;
                    bit_index    <= 5'd15;
                    dac_sclk     <= 1'b1;
                end else if (active) begin
                    dac_sclk <= ~dac_sclk; 
                    
                    if (dac_sclk == 1'b1) begin 
                        dac_din <= tx_shift_reg[bit_index];
                        if (bit_index == 5'd0) begin
                            active   <= 1'b0;
                            dac_sync <= 1'b1; 
                        end else begin
                            bit_index <= bit_index - 1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule
