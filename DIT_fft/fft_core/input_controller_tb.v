`timescale 1ns/1ps

module input_controller_tb;

    //------------------------------------------------
    // Parameters
    //------------------------------------------------

    parameter FFT_SIZE   = 16;
    parameter DATA_WIDTH = 12;

    //------------------------------------------------
    // DUT Inputs
    //------------------------------------------------

    reg clk;
    reg rst_n;

    reg fft_frame_valid;
    reg [DATA_WIDTH-1:0] buffer_data;

    //------------------------------------------------
    // DUT Outputs
    //------------------------------------------------

    wire buffer_read_en;
    wire [3:0] buffer_addr;
    wire fft_start;
    wire fft_valid;

    //------------------------------------------------
    // Test Buffer
    //------------------------------------------------

    reg [DATA_WIDTH-1:0] test_buffer [0:FFT_SIZE-1];

    integer i;
    integer errors;

    //------------------------------------------------
    // DUT
    //------------------------------------------------

    input_controller #(
        .FFT_SIZE(FFT_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (

        .clk(clk),
        .rst_n(rst_n),

        .fft_frame_valid(fft_frame_valid),
        .buffer_data(buffer_data),

        .buffer_read_en(buffer_read_en),
        .buffer_addr(buffer_addr),

        .fft_start(fft_start),
        .fft_valid(fft_valid)

    );

    //------------------------------------------------
    // 100 MHz Clock
    //------------------------------------------------

    initial
        clk = 1'b0;

    always #5 clk = ~clk;

    //------------------------------------------------
    // Fake FFT Buffer Data
    //------------------------------------------------

    always @(*)
    begin
        buffer_data = test_buffer[buffer_addr];
    end

    //------------------------------------------------
    // Main Test
    //------------------------------------------------

    initial
    begin

        errors = 0;

        fft_frame_valid = 1'b0;

        //------------------------------------------------
        // Fill fake FFT buffer
        //------------------------------------------------

        for (i = 0; i < FFT_SIZE; i = i + 1)
        begin
            test_buffer[i] = 12'd100 + i;
        end

        //------------------------------------------------
        // Reset
        //------------------------------------------------

        rst_n = 1'b0;

        #100;

        rst_n = 1'b1;

        $display("");
        $display("----------------------------------------");
        $display(" INPUT CONTROLLER TEST STARTED");
        $display("----------------------------------------");

        //------------------------------------------------
        // Tell controller that frame is ready
        //------------------------------------------------

        @(posedge clk);

        fft_frame_valid <= 1'b1;

        @(posedge clk);

        fft_frame_valid <= 1'b0;

        //------------------------------------------------
        // Check 16 samples
        //------------------------------------------------

        for (i = 0; i < FFT_SIZE; i = i + 1)
        begin

            @(posedge clk);

            #1;

            //------------------------------------------------
            // Check read enable
            //------------------------------------------------

            if (buffer_read_en !== 1'b1)
            begin

                $display(
                    "ERROR: buffer_read_en not HIGH at address %0d",
                    i
                );

                errors = errors + 1;

            end

            //------------------------------------------------
            // Check address
            //------------------------------------------------
           
            if (buffer_addr !== i)
            begin

                $display(
                    "ERROR: Address = %0d, Expected = %0d",
                    buffer_addr,
                    i
                );

                errors = errors + 1;

            end

            //------------------------------------------------
            // Check FFT valid
            //------------------------------------------------

            if (fft_valid !== 1'b1)
            begin

                $display(
                    "ERROR: fft_valid not HIGH at address %0d",
                    i
                );

                errors = errors + 1;

            end

            //------------------------------------------------
            // Display successful read
            //------------------------------------------------

            $display(
                "PASS: Address=%0d  Data=%0d  Read_EN=%b  FFT_VALID=%b",
                buffer_addr,
                buffer_data,
                buffer_read_en,
                fft_valid
            );

        end

        //------------------------------------------------
        // Check FFT start
        //------------------------------------------------

        @(posedge clk);

        #1;

        if (fft_start !== 1'b1)
        begin

            $display("ERROR: fft_start was not asserted!");

            errors = errors + 1;

        end

        else
        begin

            $display("");
            $display("PASS: fft_start asserted");
        end

        //------------------------------------------------
        // Final result
        //------------------------------------------------

        #20;

        $display("");
        $display("========================================");

        if (errors == 0)
        begin

            $display(" INPUT CONTROLLER TEST PASSED");
            $display(" NO ERRORS");

        end

        else
        begin

            $display(" INPUT CONTROLLER TEST FAILED");
            $display(" ERRORS = %0d", errors);

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

        $dumpfile("input_controller.vcd");
        $dumpvars(0, input_controller_tb);

    end

endmodule