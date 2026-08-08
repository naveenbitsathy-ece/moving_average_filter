`timescale 1ns/1ps

module spi_clock(

    input  wire clk,
    input  wire rst_n,

    output reg spi_clk_en

);

    reg [5:0] count;

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            count      <= 6'd0;
            spi_clk_en <= 1'b0;

        end

        else
        begin

            if(count == 6'd49)
            begin

                count <= 6'd0;

                spi_clk_en <= 1'b1;

            end

            else
            begin

                count <= count + 1'b1;

                spi_clk_en <= 1'b0;

            end

        end

    end

endmodule