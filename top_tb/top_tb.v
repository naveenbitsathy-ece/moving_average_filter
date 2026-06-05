`timescale 1ns / 1ps

module top_tb;

    // 1. Global Testbench Signals
    reg clk;
    reg rst_n;
    wire scl;
    wire sda;
    wire dac_sync;
    wire dac_din;
    wire dac_sclk;

    // Pull-up resistors emulation for I2C lines (Crucial for open-drain simulation)
    assign (weak1, weak0) scl = 1'b1;
    assign (weak1, weak0) sda = 1'b1;

    // 2. Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .scl(scl),
        .sda(sda),
        .dac_sync(dac_sync),
        .dac_din(dac_din),
        .dac_sclk(dac_sclk)
    );

    // 3. 100 MHz Clock Generator (10ns period)
    always begin
        #5 clk = ~clk;
    end

    // 4. Emulate the AD7991 ADC Slave Behavior
    reg [11:0] mock_adc_value; // The dummy dataset we want to send to the FPGA
    reg [3:0]  i2c_bit_cnt;
    reg        sda_out_en;
    reg        sda_out_val;

    // Drive the bidirectional SDA line based on slave activity
    assign sda = (sda_out_en) ? sda_out_val : 1'bZ;

    // Simple I2C Slave Monitor to respond with standard ACK & Data
    integer state_tracker = 0;
    
    always @(negedge scl or negedge rst_n) begin
        if (!rst_n) begin
            sda_out_en   <= 1'b0;
            sda_out_val  <= 1'b1;
            i2c_bit_cnt  <= 4'd0;
            state_tracker <= 0;
        end else begin
            case (state_tracker)
                0: begin // Waiting for Address Frame to complete
                    i2c_bit_cnt <= i2c_bit_cnt + 1'b1;
                    if (i2c_bit_cnt == 4'd7) begin // Time to send ACK for Device Address
                        sda_out_en  <= 1'b1;
                        sda_out_val <= 1'b0; // Pull down to ACK
                        state_tracker <= 1;
                        i2c_bit_cnt  <= 4'd0;
                    end
                end
                
                1: begin // Master begins reading MSB Byte
                    sda_out_en  <= 1'b1;
                    // Send out the top 4 channel tags (0000) followed by 4 highest bits of data
                    if (i2c_bit_cnt < 4'd4) begin
                        sda_out_val <= 1'b0; // Channel bits = 0
                    end else begin
                        sda_out_val <= mock_adc_value[15 - i2c_bit_cnt]; // MSB Data Bits
                    end
                    
                    i2c_bit_cnt <= i2c_bit_cnt + 1'b1;
                    if (i2c_bit_cnt == 4'd7) begin
                        state_tracker <= 2; // Move to wait for Master ACK
                        sda_out_en    <= 1'b0; // Release bus
                    end
                end
                
                2: begin // Wait for Master ACK, then switch to LSB byte transmission
                    i2c_bit_cnt   <= 4'd0;
                    state_tracker <= 3;
                end
                
                3: begin // Master reads LSB Byte
                    sda_out_en  <= 1'b1;
                    sda_out_val <= mock_adc_value[7 - i2c_bit_cnt]; // Remaining 8 bits
                    
                    i2c_bit_cnt <= i2c_bit_cnt + 1'b1;
                    if (i2c_bit_cnt == 4'd7) begin
                        state_tracker <= 4; // Complete
                        sda_out_en    <= 1'b0; 
                    end
                end
                
                4: begin // Reset mock device back to idle until next frame
                    sda_out_en    <= 1'b0;
                    i2c_bit_cnt   <= 4'd0;
                    state_tracker <= 0;
                end
            endcase
        end
    end

    // 5. Main Test Vector Sequence
    initial begin
        // Initialize Inputs
        clk   = 1'b0;
        rst_n = 1'b0;
        mock_adc_value = 12'd2048; // Baseline mid-scale voltage input (e.g., 1.65V)
        sda_out_en  = 1'b0;
        sda_out_val = 1'b1;

        // Hold Reset for 100ns
        #100;
        rst_n = 1'b1;
        $display("[TB] System Reset Released.");

        // --- SAMPLE 1: Send clean mid-scale data ---
        mock_adc_value = 12'h800; // 2048
        // Wait 1.1 ms for a sample tick sequence to trigger and finish
        #1100000; 
        
        // --- SAMPLE 2: Simulate a sharp high-frequency noise spike ---
        $display("[TB] Injecting Noise Spike into ADC Input.");
        mock_adc_value = 12'hFFF; // Maximum noise jump (4095)
        #1100000;

        // --- SAMPLE 3: Lower noise spike ---
        mock_adc_value = 12'h750; // 1872
        #1100000;

        // --- SAMPLE 4 to 10: Smooth, steady signal ---
        // As you watch this in the simulation waveform window, you will observe 
        // the filter output slowly and smoothly stepping down, taking out the sharp edge of the hFFF spike.
        mock_adc_value = 12'h800; 
        #5000000;

        $display("[TB] Simulation Complete.");
        $finish;
    end

endmodule
