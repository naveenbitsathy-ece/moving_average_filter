`timescale 1ns/1ps

module moving_average_filter(

    input  wire        clk,
    input  wire        rst_n,

    input  wire [11:0] adc_data,
    input  wire        adc_data_valid,

    output reg [11:0] filtered_data,
    output reg        filtered_valid

);

    integer i;

    reg [11:0] sample_buffer [0:11];

    reg [15:0] sum;

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            for(i=0;i<12;i=i+1)
                sample_buffer[i] <= 12'd0;

            sum <= 16'd0;

            filtered_data  <= 12'd0;
            filtered_valid <= 1'b0;

        end

        else
        begin

            filtered_valid <= 1'b0;

            if(adc_data_valid)
            begin

                sum <= sum
                     - sample_buffer[11]
                     + adc_data;

                for(i=11;i>0;i=i-1)
                    sample_buffer[i] <= sample_buffer[i-1];

                sample_buffer[0] <= adc_data;

                filtered_data <= (sum - sample_buffer[11] + adc_data)/12;

                filtered_valid <= 1'b1;

            end

        end

    end

endmodule