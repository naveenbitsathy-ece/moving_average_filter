`timescale 1ns/1ps

module dac121s101_driver(

    input  wire        clk,
    input  wire        rst_n,

    input  wire        spi_clk_en,

    input  wire [11:0] filtered_data,
    input  wire        filtered_valid,

    output reg         spi_sclk,
    output reg         spi_sync,
    output reg         spi_din,

    output reg         busy

);

localparam IDLE       = 3'd0;
localparam LOAD       = 3'd1;
localparam SYNC_LOW   = 3'd2;
localparam SHIFT_DATA = 3'd3;
localparam SYNC_HIGH  = 3'd4;

reg [2:0] current_state;
reg [2:0] next_state;

    reg [15:0] shift_reg;

    reg [4:0] bit_count;

    wire [15:0] dac_frame;

    assign dac_frame = {4'b0000, filtered_data};

    //--------------------------------------------------------
    // State Register
    //--------------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;

    end

    //--------------------------------------------------------
    // Reset Values
    //--------------------------------------------------------

    always @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            shift_reg <= 16'd0;

            bit_count <= 5'd0;

            spi_sclk <= 1'b0;

            spi_sync <= 1'b1;      // SYNC inactive high

            spi_din  <= 1'b0;

            busy <= 1'b0;

        end

    end

//--------------------------------------------------------
// Next State Logic
//--------------------------------------------------------

always @(*)
begin

    next_state = current_state;

    case(current_state)

        // Wait for new data
        IDLE:
        begin
            if(filtered_valid)
                next_state = LOAD;
        end

        // Load SPI frame
        LOAD:
        begin
            next_state = SYNC_LOW;
        end

        // Start SPI transaction
        SYNC_LOW:
        begin
            next_state = SHIFT_DATA;
        end

        // Shift 16 bits
        SHIFT_DATA:
        begin
            if(bit_count == 5'd16)
                next_state = SYNC_HIGH;
        end

        // Finish transaction
        SYNC_HIGH:
        begin
            next_state = IDLE;
        end
    endcase
end

//--------------------------------------------------------
// FSM Output Logic
//--------------------------------------------------------

always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        shift_reg <= 16'd0;
        bit_count <= 5'd0;

        spi_sync <= 1'b1;
        spi_sclk <= 1'b0;
        spi_din  <= 1'b0;

        busy <= 1'b0;

    end

    else
    begin

       case(current_state)

    // Idle
    IDLE:
    begin

        busy <= 1'b0;
        spi_sync <= 1'b1;
        spi_sclk <= 1'b0;
        bit_count <= 5'd0;

    end

    // Load data
    LOAD:
    begin

        busy <= 1'b1;

        shift_reg <= dac_frame;

        spi_din <= dac_frame[15];

    end

    // Pull SYNC low
    SYNC_LOW:
    begin

        spi_sync <= 1'b0;

        spi_sclk <= 1'b0;

    end

    // Send 16 bits
    SHIFT_DATA:
    begin

        busy <= 1'b1;

        if(spi_clk_en)
        begin

            spi_sclk <= ~spi_sclk;

            if(spi_sclk)
            begin

                shift_reg <= {shift_reg[14:0],1'b0};

                spi_din <= shift_reg[14];

                bit_count <= bit_count + 1'b1;

            end

        end

    end

    // End transfer
    SYNC_HIGH:
    begin

        spi_sync <= 1'b1;

        spi_sclk <= 1'b0;

        busy <= 1'b0;

    end
endcase

    end

end

endmodule