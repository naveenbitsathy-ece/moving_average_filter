`timescale 1ns / 1ps

module ad7991_reader (
    input  wire        clk,             // 100 MHz Main System Clock
    input  wire        rst_n,           // Active-low Master Hardware Reset
    input  wire        i2c_clk_en,      // 100 kHz Strobe Pulse from your Clock Engine
    input  wire        sample_tick,     // 1 kHz Trigger Pulse to start an ADC conversion
    output reg  [11:0] adc_data,        // Cleaned 12-bit filtered ADC core payload output
    output reg         adc_data_valid,  // Pulsed high for exactly 1 'clk' cycle when ready
    
    // I2C Hardware Wire Ports
    input  wire        scl_i, 
    output reg         scl_o, 
    output reg         scl_t,
    input  wire        sda_i, 
    output reg         sda_o, 
    output reg         sda_t
);

reg [80*8:0] state_name;
    // --- ENUMERATED FSM STATES (Explicitly Decoded One-Hot / Gray style safe values) ---
    localparam STATE_BOOT_IDLE  = 4'd0,
               STATE_CONF_START = 4'd1,
               STATE_CONF_ADDR  = 4'd2,
               STATE_CONF_ACK1  = 4'd3,
               STATE_CONF_DATA  = 4'd4,
               STATE_CONF_ACK2  = 4'd5,
               STATE_CONF_STOP  = 4'd6,
               STATE_RUN_IDLE   = 4'd7,
               STATE_READ_START = 4'd8,
               STATE_READ_ADDR  = 4'd9,
               STATE_READ_ACK1  = 4'd10,
               STATE_READ_MSB   = 4'd11,
               STATE_READ_ACK2  = 4'd12,
               STATE_READ_LSB   = 4'd13,
               STATE_READ_ACK3  = 4'd14,
               STATE_READ_STOP  = 4'd15;

    // Internal FSM Tracking Registers
    reg [3:0]  current_state;
    reg [2:0]  bit_counter;
    reg [7:0]  data_shifter;
    reg [1:0]  i2c_sub_phase;
    reg [15:0] adc_raw_frame;
 
    always @(posedge clk or negedge rst_n ) begin
        if (!rst_n) begin
            current_state  <= STATE_BOOT_IDLE;
            bit_counter    <= 3'd0;
            i2c_sub_phase  <= 2'd0;
            adc_data       <= 12'd0;
            adc_data_valid <= 1'b0;
            adc_raw_frame  <= 16'd0;
            data_shifter   <= 8'd0;
            
            // Default 3-State I2C pins to safe high-impedance mode (Z)
            scl_o <= 1'b0; scl_t <= 1'b1;
            sda_o <= 1'b0; sda_t <= 1'b1;
        end else begin
            // Pulse default clearance to avoid latching invalid data flags
            adc_data_valid <= 1'b0;

            if (i2c_clk_en) begin
                case (current_state)

                    // =================================================================
                    // PHASE A: CHIP INITIALIZATION ROUTINE (WRITE CONFIG TO CHIP)
                    // =================================================================
                    
                    STATE_BOOT_IDLE: begin
                        scl_t <= 1'b1; sda_t <= 1'b1; // Hold idle lines high
                        i2c_sub_phase <= 2'd0;
                        current_state <= STATE_CONF_START;
                    end

                    STATE_CONF_START: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end // Assert I2C Start condition
                        if (i2c_sub_phase == 2'd2) begin 
                            scl_t <= 1'b0; scl_o <= 1'b0; // Lock clock low
                            data_shifter <= {7'h28, 1'b0}; // Address 0x28 + Write Bit (0)
                            bit_counter  <= 3'd7;
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_CONF_ADDR;
                        end
                    end

                    STATE_CONF_ADDR: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin
                            sda_t <= data_shifter[bit_counter]; // Drive address bit out
                            sda_o <= 1'b0;
                        end
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1; // Release clock high
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0; // Clamp clock low
                            i2c_sub_phase <= 2'd0;
                            if (bit_counter == 3'd0) current_state <= STATE_CONF_ACK1;
                            else bit_counter <= bit_counter - 1'b1;
                        end
                    end

                    STATE_CONF_ACK1: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) sda_t <= 1'b1; // Open-drain float to receive slave ACK
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
    scl_t <= 1'b0;
    scl_o <= 1'b0;

    if (sda_i == 1'b0) begin       // ACK received
     
        data_shifter <= 8'h10;
        bit_counter  <= 3'd7;
        i2c_sub_phase <= 2'd0;
        current_state <= STATE_CONF_DATA;
    end
    else begin                     // NACK received
        i2c_sub_phase <= 2'd0;
        current_state <= STATE_CONF_STOP; // or ERROR state later
    end
end
                    end

                    STATE_CONF_DATA: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin
                            sda_t <= data_shifter[bit_counter]; // Shift out config data bit
                            sda_o <= 1'b0;
                        end
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            i2c_sub_phase <= 2'd0;
                            if (bit_counter == 3'd0) current_state <= STATE_CONF_ACK2;
                            else bit_counter <= bit_counter - 1'b1;
                        end
                    end

                    STATE_CONF_ACK2: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) sda_t <= 1'b1; // Receive Slave ACK
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_CONF_STOP;
                        end
                    end

                    STATE_CONF_STOP: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1; // Drive SCL high first
                        if (i2c_sub_phase == 2'd2) sda_t <= 1'b1; // Release SDA high last to issue I2C Stop
                        if (i2c_sub_phase == 2'd3) begin
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_RUN_IDLE;
                        end
                    end

                    // =================================================================
                    // PHASE B: RUNTIME DATA EXTRACTION ENGINE (1 kHz LOOPED READS)
                    // =================================================================
                    
                    STATE_RUN_IDLE: begin
                        scl_t <= 1'b1; sda_t <= 1'b1;
                        i2c_sub_phase <= 2'd0;
                        if (sample_tick) begin // Triggered cleanly at 1 kHz intervals
                            current_state <= STATE_READ_START;
                        end
                    end

                    STATE_READ_START: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end // Start Signal
                        if (i2c_sub_phase == 2'd2) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            data_shifter <= {7'h28, 1'b1}; // Address 0x28 + Read Bit (1)
                            bit_counter  <= 3'd7;
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_READ_ADDR;
                        end
                    end

                    STATE_READ_ADDR: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin
                            sda_t <= data_shifter[bit_counter];
                            sda_o <= 1'b0;
                        end
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            i2c_sub_phase <= 2'd0;
                            if (bit_counter == 3'd0) current_state <= STATE_READ_ACK1;
                            else bit_counter <= bit_counter - 1'b1;
                        end
                    end

                    STATE_READ_ACK1: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) sda_t <= 1'b1;
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            bit_counter   <= 3'd7;
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_READ_MSB;
                        end
                    end

                    STATE_READ_MSB: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) 
                        sda_t <= 1'b1; // Ensure pin floats as input
                        if (i2c_sub_phase == 2'd1) 
                        scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd2) 
                        data_shifter[bit_counter] <= sda_i; // Safe isolated data capture quadrant

                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            i2c_sub_phase <= 2'd0;
                            if (bit_counter == 3'd0) begin
                                adc_raw_frame[15:8] <= {data_shifter[7:1], sda_i};

                              
                                bit_counter <= 3'd7;
                                current_state       <= STATE_READ_ACK2;

                            end else 
                            begin
                                bit_counter <= bit_counter - 1'b1;
                            end
                        end
                    end

                    // Send Master ACK down to notify ADC we want the second mandatory byte packet
                    STATE_READ_ACK2: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end // Assert Master ACK
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            bit_counter   <= 3'd7;
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_READ_LSB;
                        end
                    end

             
               STATE_READ_LSB: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) sda_t <= 1'b1; // Float back to input mode
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd2) 
                        data_shifter[bit_counter] <= sda_i; // Latch stable lower bits

                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; 
                            scl_o <= 1'b0;
                            i2c_sub_phase <= 2'd0;
                            if (bit_counter == 3'd0) 
                            begin
                                adc_raw_frame[7:0] <= {data_shifter[7:1], sda_i};

                                current_state      <= STATE_READ_ACK3;


                            end else begin
                                bit_counter <= bit_counter - 1'b1;
                            end
                        end
                    end

                    // Send Master NACK to communicate end of 16-bit packet extraction loop
                    STATE_READ_ACK3: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin sda_t <= 1'b1;end // Master NACK driven
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd3) begin
                            scl_t <= 1'b0; scl_o <= 1'b0;
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_READ_STOP;
                            
                            // CRITICAL RE-ALIGNMENT FIX:
                            // The AD7991 puts out 4 upper flag tag channel identifier bits [D15-D12], 
                            // followed by the real [D11-D0] conversion vector payload.
                            // Combining {adc_raw_frame[11:8], data_shifter} strips the channel header tags and passes out the correct data.
                            adc_data <= {adc_raw_frame[11:8], adc_raw_frame[7:0]};

                           
                            adc_data_valid <= 1'b1; // Notify filter that a fresh data point has arrived
                        end
                    end

                    STATE_READ_STOP: begin
                        i2c_sub_phase <= i2c_sub_phase + 1'b1;
                        if (i2c_sub_phase == 2'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end
                        if (i2c_sub_phase == 2'd1) scl_t <= 1'b1;
                        if (i2c_sub_phase == 2'd2) sda_t <= 1'b1; // Generate read stop
                        if (i2c_sub_phase == 2'd3) begin
                            i2c_sub_phase <= 2'd0;
                            current_state <= STATE_RUN_IDLE; // Loop complete, return to wait for next tick
                        end
                    end

                    default: current_state <= STATE_RUN_IDLE;
                endcase
            end
        end
    end


endmodule