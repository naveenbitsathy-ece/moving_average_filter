`timescale 1ns/1ps

module system_top_tb;

    //------------------------------------------
    // Clock & Reset
    //------------------------------------------

    reg clk;
    reg rst_n;

    //------------------------------------------
    // I2C Bus
    //------------------------------------------

    tri1 sda_bus;
    tri1 scl_bus;

    wire sda_o;
    wire sda_t;

    wire scl_o;
    wire scl_t;

    //------------------------------------------
    // SPI Outputs
    //------------------------------------------

    wire spi_sclk;
    wire spi_sync;
    wire spi_din;

    //------------------------------------------
    // Open-Drain I2C Bus
    //------------------------------------------

    assign sda_bus = (sda_t) ? 1'bz : sda_o;
    assign scl_bus = (scl_t) ? 1'bz : scl_o;

    //------------------------------------------
    // DUT
    //------------------------------------------

    system_top DUT(

        .clk(clk),
        .rst_n(rst_n),

        .sda_i(sda_bus),
        .sda_o(sda_o),
        .sda_t(sda_t),

        .scl_i(scl_bus),
        .scl_o(scl_o),
        .scl_t(scl_t),

        .spi_sclk(spi_sclk),
        .spi_sync(spi_sync),
        .spi_din(spi_din)

    );

    //------------------------------------------
    // AD7991 Slave Model
    //------------------------------------------

    ad7991_slave slave(

        .sda(sda_bus),
        .scl(scl_bus)

    );

    //------------------------------------------
    // 100 MHz Clock
    //------------------------------------------

    initial
        clk = 1'b0;

    always #5 clk = ~clk;

    //------------------------------------------
    // Reset
    //------------------------------------------

    initial
    begin

        rst_n = 1'b0;

        #100;

        rst_n = 1'b1;

    end

    //------------------------------------------
    // Simulation Time
    //------------------------------------------

    initial
    begin

        #10000000;

        $finish;

    end

    //------------------------------------------
    // Waveform
    //------------------------------------------

    initial
    begin

        $dumpfile("system_top.vcd");
        $dumpvars(0,system_top_tb);

    end

endmodule