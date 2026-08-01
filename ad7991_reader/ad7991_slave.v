`timescale 1ns/1ps

module ad7991_slave(

    input  wire scl,
    inout  wire sda

);

    //---------------------------------------------------------
    // Slave Address
    //---------------------------------------------------------
    localparam SLAVE_ADDR = 7'h28;

    //---------------------------------------------------------
    // Open Drain SDA
    //---------------------------------------------------------
    reg sda_drive;

    assign sda = (sda_drive) ? 1'b0 : 1'bz;

    //---------------------------------------------------------
    // Internal Registers
    //---------------------------------------------------------
    reg [7:0] address_byte;
    reg [2:0] bit_count;

    reg start_seen;
    reg stop_seen;

    //---------------------------------------------------------
    // START Detection
    //---------------------------------------------------------

    always @(negedge sda)
    begin
        if(scl)
        begin
            start_seen <= 1'b1;
            stop_seen  <= 1'b0;
            bit_count  <= 3'd7;

            $display("[%0t] START DETECTED",$time);
        end
    end

    //---------------------------------------------------------
    // STOP Detection
    //---------------------------------------------------------

    always @(posedge sda)
    begin
        if(scl)
        begin
            start_seen <= 1'b0;
            stop_seen  <= 1'b1;

            sda_drive <= 1'b0;

            $display("[%0t] STOP DETECTED",$time);
        end
    end

    //---------------------------------------------------------
    // Receive Address Byte
    //---------------------------------------------------------

    always @(posedge scl)
    begin

        if(start_seen)
        begin

            address_byte[bit_count] <= sda;

            if(bit_count==0)
            begin

                $display("Address = %02h",
                          {address_byte[7:1],sda});

                bit_count <= 3'd7;

            end
            else
            begin

                bit_count <= bit_count - 1'b1;

            end

        end

    end

    //---------------------------------------------------------
    // ACK Generation
    //---------------------------------------------------------

    always @(negedge scl)
    begin

        if(start_seen)
        begin

            if(address_byte[7:1]==SLAVE_ADDR)
            begin

                sda_drive <= 1'b1;

                $display("[%0t] ACK",$time);

            end
            else
            begin

                sda_drive <= 1'b0;

                $display("[%0t] ADDRESS MISMATCH",$time);

            end

        end

    end

    //---------------------------------------------------------
    // Release ACK
    //---------------------------------------------------------

    always @(posedge scl)
    begin

        sda_drive <= 1'b0;

    end

endmodule