`timescale 1ns/1ps

module fft_buffer #(
    parameter FFT_SIZE       = 16,
    parameter DATA_WIDTH     = 12
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire [DATA_WIDTH-1:0] filtered_data,
    input  wire                  filtered_valid,

    output reg                   fft_frame_valid
);

    reg [DATA_WIDTH-1:0] fft_buffer [0:FFT_SIZE-1];

    //counter
    reg [$clog2(FFT_SIZE)-1:0] sample_count;

    integer i;
//buffer 
    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin

            sample_count    <= 0;
            fft_frame_valid <= 1'b0;

            for (i = 0; i < FFT_SIZE; i = i + 1)
                fft_buffer[i] <= 0;
        end

        else
        begin

            // Default: frame is not ready
            fft_frame_valid <= 1'b0;
 $display("fft_frame_valid=%b",fft_frame_valid);
            if (filtered_valid)
            begin

                // Store incoming filtered sample
                fft_buffer[sample_count] <= filtered_data;
                  // Last sample of FFT frame
            

                if (sample_count == FFT_SIZE-1)
                begin
                    sample_count    <= 0;
                    fft_frame_valid <= 1'b1;
                end
               
                else
                begin
                    sample_count <= sample_count + 1'b1;
                end

            end
        end

    end

endmodule