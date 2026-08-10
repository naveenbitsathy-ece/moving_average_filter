`timescale 1ns/1ps

module input_controller #(
    parameter FFT_SIZE   = 16,
    parameter DATA_WIDTH = 12
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // From FFT buffer
    input  wire                  fft_frame_valid,
    input  wire [DATA_WIDTH-1:0] buffer_data,

    // Control signals to FFT buffer
    output reg                   buffer_read_en,
    output reg [3:0]             buffer_addr,

    // Control signals to FFT core
    output reg                   fft_start,
    output reg                   fft_valid
);

    //------------------------------------------------
    // States
    //------------------------------------------------

    localparam IDLE = 2'd0;
    localparam READ = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;

    //------------------------------------------------
    // State Machine
    //------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin
            state          <= IDLE;
            buffer_addr    <= 4'd0;
            buffer_read_en <= 1'b0;
            fft_start      <= 1'b0;
            fft_valid      <= 1'b0;
        end

        else
        begin

            // Default values
            buffer_read_en <= 1'b0;
            fft_start      <= 1'b0;
            fft_valid      <= 1'b0;

            case (state)

                //------------------------------------
                // WAIT FOR COMPLETE FFT FRAME
                //------------------------------------

                IDLE:
                begin

                    buffer_addr <= 4'd0;

                    if (fft_frame_valid)
                    begin
                        state <= READ;
                    end

                end

                //------------------------------------
                // READ 16 SAMPLES
                //------------------------------------

                READ:
                begin

                    buffer_read_en <= 1'b1;
                    fft_valid      <= 1'b1;

                    //--------------------------------
                    // Last sample
                    //--------------------------------

                    if (buffer_addr == FFT_SIZE-1)
                    begin
                        state <= DONE;
                    end

                    else
                    begin
                        buffer_addr <= buffer_addr + 1'b1;
                    end

                end

                //------------------------------------
                // START FFT
                //------------------------------------

                DONE:
                begin

                    buffer_read_en <= 1'b0;
                    fft_valid      <= 1'b0;

                    // Tell FFT core that all
                    // 16 samples have been read
                    fft_start <= 1'b1;

                    buffer_addr <= 4'd0;

                    state <= IDLE;

                end

                default:
                begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule