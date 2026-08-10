`timescale 1ns/1ps

module fft_buffer_tb;

    //------------------------------------------------
    // Parameters
    //------------------------------------------------

    parameter FFT_SIZE   = 16;
    parameter DATA_WIDTH = 12;

    //------------------------------------------------
    // DUT Signals
    //------------------------------------------------

    reg clk;
    reg rst_n;

    reg [DATA_WIDTH-1:0] filtered_data;
    reg                  filtered_valid;

    wire fft_frame_valid;

    //------------------------------------------------
    // Test Variables
    //------------------------------------------------

    integer i;
    integer errors;

    //------------------------------------------------
    // DUT
    //------------------------------------------------

    fft_buffer #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),

        .filtered_data(filtered_data),
        .filtered_valid(filtered_valid),

        .fft_frame_valid(fft_frame_valid)
    );

    //------------------------------------------------
    // 100 MHz Clock
    //------------------------------------------------

    initial
        clk = 1'b0;

    always #5 clk = ~clk;

    //------------------------------------------------
    // Send one sample
    //------------------------------------------------

    task send_sample;

        input [DATA_WIDTH-1:0] data;

        begin

            // Set data before sampling edge
            @(negedge clk);

            filtered_data  = data;
            filtered_valid = 1'b1;

            // DUT captures data here
            @(posedge clk);

            #1;

            //------------------------------------------------
            // Check fft_frame_valid
            //------------------------------------------------

            if (data == FFT_SIZE)
            begin

                if (fft_frame_valid !== 1'b1)
                begin
                    $display(
                        "ERROR: fft_frame_valid not asserted for last sample"
                    );

                    errors = errors + 1;
                end
                else
                begin
                    $display(
                        "PASS: fft_frame_valid asserted after sample %0d",
                        data
                    );
                end

            end
            else
            begin

                if (fft_frame_valid !== 1'b0)
                begin
                    $display(
                        "ERROR: fft_frame_valid asserted too early at sample %0d",
                        data
                    );

                    errors = errors + 1;
                end

            end

            //------------------------------------------------
            // Remove valid
            //------------------------------------------------

            @(negedge clk);

            filtered_valid = 1'b0;

        end

    endtask

    //------------------------------------------------
    // Main Test
    //------------------------------------------------

    initial
    begin

        errors = 0;

        filtered_data  = 0;
        filtered_valid = 0;

        //------------------------------------------------
        // Reset
        //------------------------------------------------

        rst_n = 1'b0;

        #100;

        rst_n = 1'b1;

        $display("");
        $display("----------------------------------------");
        $display("       FFT BUFFER TEST STARTED");
        $display("----------------------------------------");
        $display("");

        //------------------------------------------------
        // Send 16 samples
        //------------------------------------------------

        for (i = 0; i < FFT_SIZE; i = i + 1)
        begin

            send_sample(i + 1);

            $display(
                "Sample %0d sent = %0d",
                i,
                i + 1
            );

        end

        //------------------------------------------------
        // Check complete buffer
        //------------------------------------------------

        $display("");
        $display("----------------------------------------");
        $display("Checking FFT Buffer");
        $display("----------------------------------------");

        for (i = 0; i < FFT_SIZE; i = i + 1)
        begin

            if (uut.fft_buffer[i] !== (i + 1))
            begin

                $display(
                    "ERROR: Buffer[%0d] = %0d, Expected = %0d",
                    i,
                    uut.fft_buffer[i],
                    i + 1
                );

                errors = errors + 1;

            end
            else
            begin

                $display(
                    "PASS: Buffer[%0d] = %0d",
                    i,
                    uut.fft_buffer[i]
                );

            end

        end

        //------------------------------------------------
        // Final Result
        //------------------------------------------------

        #20;

        $display("");
        $display("========================================");

        if (errors == 0)
        begin

            $display("       FFT BUFFER TEST PASSED");
            $display("       NO ERRORS");

        end
        else
        begin

            $display("       FFT BUFFER TEST FAILED");
            $display("       ERRORS = %0d", errors);

        end

        $display("========================================");
        $display("");

        $finish;

    end

    //------------------------------------------------
    // Waveform
    //------------------------------------------------

    initial
    begin

        $dumpfile("fft_buffer.vcd");
        $dumpvars(0, fft_buffer_tb);

    end

endmodule