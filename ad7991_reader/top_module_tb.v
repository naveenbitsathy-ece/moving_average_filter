`timescale 1ns/1ps

module top_module_tb;

    //------------------------------------------
    // Testbench Signals
    //------------------------------------------

    reg clk;
    reg rst_n;

    reg scl_i;
    reg sda_i;

    wire scl_o;
    wire scl_t;

    wire sda_o;
    wire sda_t;

    wire [11:0] adc_data;
    wire adc_data_valid;

tri1 sda_bus;
tri1 scl_bus;

assign scl_bus = (scl_t) ? 1'bz : scl_o;
assign sda_bus = (sda_t) ? 1'bz : sda_o;

    //------------------------------------------
    // Instantiate DUT
    //------------------------------------------

    top_module DUT(
        .clk(clk),
        .rst_n(rst_n),

        .scl_i(scl_bus),
        .scl_o(scl_o),
        .scl_t(scl_t),

        .sda_i(sda_bus),
        .sda_o(sda_o),
        .sda_t(sda_t),

        .adc_data(adc_data),
        .adc_data_valid(adc_data_valid)
    );

    ad7991_slave slave(
        .sda(sda_bus),
        .scl(scl_bus)
    );

    //------------------------------------------
    // 100 MHz Clock
    //------------------------------------------

    initial
        clk = 0;

    always #5 clk = ~clk;

    initial
    begin

        rst_n = 0;
        scl_i = 1;
        sda_i = 1;
        #100;
        rst_n = 1;
    end

reg [15:0] adc_frame;
integer bit_ptr;

initial
begin

    adc_frame = 16'hABC5;
    bit_ptr   = 15;

  /* forever
    begin

        @(posedge clk);

        case(DUT.adc_reader.current_state)

        //-------------------------------------------------
        // ACK States
        //-------------------------------------------------

        4'd3,
        4'd5,
        4'd10:
        begin
           // sda_i = 1'b0;     C
           
           slave_drive = 1;
        end

        //-------------------------------------------------
        // READ_MSB
        //-------------------------------------------------

        4'd11:
        begin

            if(DUT.adc_reader.i2c_sub_phase==2)
            begin
                sda_i = adc_frame[bit_ptr];
                bit_ptr = bit_ptr - 1;
            end

        end

        //-------------------------------------------------
        // READ_LSB
        //-------------------------------------------------

        4'd13:
        begin

            if(DUT.adc_reader.i2c_sub_phase==2)
            begin
                sda_i = adc_frame[bit_ptr];
                bit_ptr = bit_ptr - 1;
            end

        end

        //-------------------------------------------------
        // READ_STOP
        //-------------------------------------------------

        4'd15:
        begin

            bit_ptr = 15;
            //sda_i = 1'b1;
            slave_drive = 0;

        end

        default:
        begin
           // sda_i = 1'b1;
           slave_drive = 0;
        end

        endcase

    end */

end


    initial
    begin

        #5000000;

        $finish;

    end

initial begin
    $dumpfile("naveen.vcd");
    $dumpvars(0,top_module_tb);
end
endmodule