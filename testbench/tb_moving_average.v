
`timescale 1ns / 1ps

module tb_moving_average;

    parameter DATA_WIDTH = 100;
    parameter N = 12;

    reg clk;
    reg rst_n;
    reg [DATA_WIDTH-1:0] sample_in;
    reg sample_valid;

    wire [DATA_WIDTH-1:0] sample_out;
    wire output_valid;

    // Instantiate DUT
    moving_average #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .sample_out(sample_out),
        .output_valid(output_valid)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    // Reference model
    integer samples [0:N-1];
    integer expected;
    integer total;
    integer i, k;
    integer pass_count, fail_count;

    // Apply one sample and check its output
    task apply_sample;
        input integer data;
        begin
            // Drive input away from the rising edge
            @(negedge clk);
            sample_in = data;
            sample_valid = 1'b1;

            // Wait for the DUT to assert output_valid
            @(posedge output_valid);
            #1;

            // Calculate expected average:
            // current sample + previous N-1 samples
            total = data;
            for (k = 0; k < N-1; k = k+1)
                total = total + samples[k];

            expected = total / N;

            if (sample_out == expected) begin
                $display(
                    "PASS | Input=%0d | Output=%0d | Expected=%0d",
                    data, sample_out, expected
                );
                pass_count = pass_count + 1;
            end
            else begin
                $display(
                    "FAIL | Input=%0d | Output=%0d | Expected=%0d",
                    data, sample_out, expected
                );
                fail_count = fail_count + 1;
            end

            // Update reference history
            for (k = N-1; k > 0; k = k-1)
                samples[k] = samples[k-1];

            samples[0] = data;

            // Lower valid to acknowledge the result
            @(negedge clk);
            sample_valid = 1'b0;

            // Allow DUT to clear output_valid
            wait (output_valid == 1'b0);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        sample_in = 0;
        sample_valid = 0;
        pass_count = 0;
        fail_count = 0;

        for (i = 0; i < N; i = i+1)
            samples[i] = 0;

        // Apply reset
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        $display("----------------------------------------");
        $display(" Moving Average Filter Testbench");
        $display(" Window size N = %0d", N);
        $display("----------------------------------------");

        // Test 1: Increasing samples
        apply_sample(100);
        apply_sample(200);
        apply_sample(300);
        apply_sample(400);
        apply_sample(500);
        apply_sample(600);
        apply_sample(700);
        apply_sample(800);
        apply_sample(900);
        apply_sample(1000);
        apply_sample(1100);
        apply_sample(1200);
        apply_sample(1300);
        apply_sample(1400);

        // Test 2: Constant samples
        apply_sample(1000);
        apply_sample(1000);
        apply_sample(1000);

        // Test 3: Zero input
        apply_sample(0);
        apply_sample(0);

        // Summary
        $display("----------------------------------------");
        $display(" TEST SUMMARY");
        $display(" Passed : %0d", pass_count);
        $display(" Failed : %0d", fail_count);
        $display("----------------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // Simulation timeout protection
    initial begin
        #100000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
