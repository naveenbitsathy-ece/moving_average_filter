`timescale 1ns/1ps

module spi_clock_tb;

    // Inputs
    reg clk;
    reg rst_n;

    // Output
    wire spi_clk_en;

    //-------------------------------------------------------
    // DUT
    //-------------------------------------------------------
    spi_clock DUT
    (
        .clk(clk),
        .rst_n(rst_n),
        .spi_clk_en(spi_clk_en)
    );

    //-------------------------------------------------------
    // Clock Generation (100 MHz)
    //-------------------------------------------------------
    initial
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //-------------------------------------------------------
    // Reset
    //-------------------------------------------------------
    initial
    begin
        rst_n = 0;

        #20;
        rst_n = 1;
    end

    //-------------------------------------------------------
    // Simulation Control
    //-------------------------------------------------------
    initial
    begin
        // Run long enough to observe multiple pulses
        #1200;

        $finish;
    end

    //-------------------------------------------------------
    // Monitor
    //-------------------------------------------------------
    initial
    begin
        $display("-------------------------------------------");
        $display(" Time(ns)   rst_n   spi_clk_en");
        $display("-------------------------------------------");

        $monitor("%8t     %b         %b",
                 $time,
                 rst_n,
                 spi_clk_en);
    end

    //-------------------------------------------------------
    // Waveform Dump
    //-------------------------------------------------------
    initial
    begin
        $dumpfile("spi_clock.vcd");
        $dumpvars(0, spi_clock_tb);
    end

endmodule