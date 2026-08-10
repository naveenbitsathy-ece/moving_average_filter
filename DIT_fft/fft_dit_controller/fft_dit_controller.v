`timescale 1ns/1ps

module fft_dit_controller #(
    parameter FFT_SIZE   = 16,
    parameter DATA_WIDTH = 12,
    parameter TW_WIDTH   = 16
)(
    input wire clk,
    input wire rst_n,

    //------------------------------------------------
    // Input from FFT buffer / Input Controller
    //------------------------------------------------

    input wire [DATA_WIDTH-1:0] fft_data,
    input wire                  fft_valid,
    input wire                  fft_frame_valid,

    //------------------------------------------------
    // Data to Butterfly
    //------------------------------------------------

    output reg signed [DATA_WIDTH-1:0] A_real,
    output reg signed [DATA_WIDTH-1:0] A_imag,

    output reg signed [DATA_WIDTH-1:0] B_real,
    output reg signed [DATA_WIDTH-1:0] B_imag,

    //------------------------------------------------
    // Twiddle factor to Butterfly
    //------------------------------------------------

    output reg signed [TW_WIDTH-1:0] W_real,
    output reg signed [TW_WIDTH-1:0] W_imag,

    output reg butterfly_valid,

    //------------------------------------------------
    // FFT complete
    //------------------------------------------------

    output reg fft_done
);

    //------------------------------------------------
    // FFT Memory
    //------------------------------------------------

    reg signed [DATA_WIDTH-1:0] real_mem [0:FFT_SIZE-1];

    reg signed [DATA_WIDTH-1:0] imag_mem [0:FFT_SIZE-1];

    //------------------------------------------------
    // Controller states
    //------------------------------------------------

    localparam IDLE      = 3'd0;
    localparam LOAD      = 3'd1;
    localparam PREPARE   = 3'd2;
    localparam CALCULATE = 3'd3;
    localparam WRITEBACK = 3'd4;
    localparam DONE      = 3'd5;

    reg [2:0] state;

    //------------------------------------------------
    // Counters
    //------------------------------------------------

    reg [4:0] input_count;

    reg [2:0] stage;

    reg [3:0] butterfly_count;

    //------------------------------------------------
    // Address variables
    //------------------------------------------------

    integer half_size;
    integer group_size;

    integer j;
    integer group_start;

    integer addr_a;
    integer addr_b;

    integer twiddle_index;

    //------------------------------------------------
    // Bit reverse function
    //------------------------------------------------

    function [3:0] bit_reverse_4;

        input [3:0] value;

        begin

            bit_reverse_4[3] = value[0];
            bit_reverse_4[2] = value[1];
            bit_reverse_4[1] = value[2];
            bit_reverse_4[0] = value[3];

        end

    endfunction

    //------------------------------------------------
    // Main Controller
    //------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if (!rst_n)
        begin

            state            <= IDLE;

            input_count      <= 0;
            stage             <= 0;
            butterfly_count <= 0;

            A_real <= 0;
            A_imag <= 0;

            B_real <= 0;
            B_imag <= 0;

            W_real <= 0;
            W_imag <= 0;

            butterfly_valid <= 0;
            fft_done        <= 0;

        end

        else
        begin

            butterfly_valid <= 1'b0;
            fft_done        <= 1'b0;

            case(state)

                //------------------------------------------------
                // WAIT
                //------------------------------------------------

                IDLE:
                begin

                    input_count <= 0;

                    if (fft_frame_valid)
                    begin
                        state <= LOAD;
                    end

                end

                //------------------------------------------------
                // LOAD INPUT DATA
                //
                // Store input in bit-reversed order
                //------------------------------------------------

                LOAD:
                begin

                    if (fft_valid)
                    begin

                        real_mem[bit_reverse_4(input_count[3:0])]
                            <= fft_data;

                        imag_mem[bit_reverse_4(input_count[3:0])]
                            <= 0;

                        if (input_count == FFT_SIZE-1)
                        begin

                            input_count <= 0;
                            stage <= 0;
                            butterfly_count <= 0;

                            state <= PREPARE;

                        end

                        else
                        begin
                            input_count <= input_count + 1'b1;
                        end

                    end

                end

                //------------------------------------------------
                // PREPARE BUTTERFLY
                //------------------------------------------------

                PREPARE:
                begin

                    //------------------------------------------------
                    // Stage parameters
                    //------------------------------------------------

                    half_size = (1 << stage);

                    group_size = half_size * 2;

                    //------------------------------------------------
                    // Calculate j and group
                    //------------------------------------------------

                    j = butterfly_count % half_size;

                    group_start =
                        (butterfly_count / half_size) * group_size;

                    //------------------------------------------------
                    // A address
                    //------------------------------------------------

                    addr_a = group_start + j;

                    //------------------------------------------------
                    // B address
                    //------------------------------------------------

                    addr_b = addr_a + half_size;

                    //------------------------------------------------
                    // Read A
                    //------------------------------------------------

                    A_real <= real_mem[addr_a];
                    A_imag <= imag_mem[addr_a];

                    //------------------------------------------------
                    // Read B
                    //------------------------------------------------

                    B_real <= real_mem[addr_b];
                    B_imag <= imag_mem[addr_b];

                    //------------------------------------------------
                    // Twiddle index
                    //------------------------------------------------

                    twiddle_index =
                        j * FFT_SIZE / group_size;

                    //------------------------------------------------
                    // Temporary twiddle generation
                    //
                    // Stage testing values
                    //------------------------------------------------

                    case(twiddle_index)

                        0:
                        begin
                            W_real <= 16'sd1;
                            W_imag <= 16'sd0;
                        end

                        1:
                        begin
                            W_real <= 16'sd0;
                            W_imag <= -16'sd1;
                        end

                        2:
                        begin
                            W_real <= -16'sd1;
                            W_imag <= 16'sd0;
                        end

                        3:
                        begin
                            W_real <= 16'sd0;
                            W_imag <= 16'sd1;
                        end

                        default:
                        begin
                            W_real <= 16'sd1;
                            W_imag <= 16'sd0;
                        end

                    endcase

                    state <= CALCULATE;

                end

                //------------------------------------------------
                // SEND TO BUTTERFLY
                //------------------------------------------------

                CALCULATE:
                begin

                    butterfly_valid <= 1'b1;

                    state <= WRITEBACK;

                end

                //------------------------------------------------
                // WRITE RESULT BACK
                //------------------------------------------------

                WRITEBACK:
                begin

                    /*
                     * The actual X/Y outputs from the butterfly
                     * should be connected here.
                     *
                     * This controller currently only generates
                     * the address/control sequence.
                     */

                    if (butterfly_count ==
                        (FFT_SIZE/2)-1)
                    begin

                        butterfly_count <= 0;

                        if (stage == 3)
                        begin
                            state <= DONE;
                        end

                        else
                        begin
                            stage <= stage + 1'b1;
                            state <= PREPARE;
                        end

                    end

                    else
                    begin

                        butterfly_count <=
                            butterfly_count + 1'b1;

                        state <= PREPARE;

                    end

                end

                //------------------------------------------------
                // FFT COMPLETE
                //------------------------------------------------

                DONE:
                begin

                    fft_done <= 1'b1;

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