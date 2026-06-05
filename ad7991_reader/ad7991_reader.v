
`timescale 1ns / 1ps

module ad7991_reader (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i2c_clk_en,
    input  wire        sample_tick,
    output reg  [11:0] adc_data,
    output reg         adc_data_valid,
    
    input  wire        scl_i, 
    output reg         scl_o, 
    output reg         scl_t,
    input  wire        sda_i, 
    output reg         sda_o, 
    output reg         sda_t
);

    localparam IDLE        = 4'd0,
               START       = 4'd1,
               SEND_ADDR   = 4'd2,
               GET_ACK1    = 4'd3,
               READ_MSB    = 4'd4,
               GET_ACK2    = 4'd5,
               READ_LSB    = 4'd6,
               GET_ACK3    = 4'd7,
               STOP        = 4'd8;

    reg [3:0] state;
    reg [6:0] dev_addr;
    reg [2:0] bit_cnt;
    reg [7:0] i2c_shifter;
    reg [3:0] phase_cnt; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= IDLE;
            dev_addr       <= 7'h28; 
            bit_cnt        <= 3'd0;
            phase_cnt      <= 4'd0;
            adc_data       <= 12'd0;
            adc_data_valid <= 1'b0;
            scl_o <= 1'b0; scl_t <= 1'b1;
            sda_o <= 1'b0; sda_t <= 1'b1;
        end else if (i2c_clk_en) begin
            case (state)
                IDLE: begin
                    adc_data_valid <= 1'b0;
                    scl_t <= 1'b1; 
                    sda_t <= 1'b1; 
                    if (sample_tick) begin
                        state     <= START;
                        phase_cnt <= 4'd0;
                    end
                end

                START: begin
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end 
                    if (phase_cnt == 4'd2) begin scl_t <= 1'b0; scl_o <= 1'b0;     
                        state       <= SEND_ADDR;
                        i2c_shifter <= {dev_addr, 1'b1}; 
                        bit_cnt     <= 3'd7;
                        phase_cnt   <= 4'd0;
                    end
                end

                SEND_ADDR: begin
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) begin
                        if (i2c_shifter[bit_cnt]) begin
                            sda_t <= 1'b1; 
                        end else begin
                            sda_t <= 1'b0;
                            sda_o <= 1'b0;
                        end
                    end
                    if (phase_cnt == 4'd1) scl_t <= 1'b1; 
                    if (phase_cnt == 4'd3) begin
                        scl_t <= 1'b0; scl_o <= 1'b0;
                        phase_cnt <= 4'd0;
                        if (bit_cnt == 3'd0) state <= GET_ACK1;
                        else bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                GET_ACK1: begin
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) sda_t <= 1'b1; 
                    if (phase_cnt == 4'd1) begin
                        scl_t <= 1'b1;
                        if (sda_i == 1'b1) begin 
                            dev_addr <= (dev_addr == 7'h28) ? 7'h29 : 7'h28;
                            state    <= STOP;
                            phase_cnt <= 4'd0;
                        end
                    end
                    if (phase_cnt == 4'd3) begin
                        scl_t <= 1'b0; scl_o <= 1'b0;
                        if (state != STOP) begin
                            state   <= READ_MSB;
                            bit_cnt <= 3'd7;
                        end
                        phase_cnt <= 4'd0;
                    end
                end

                READ_MSB: begin
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) sda_t <= 1'b1;
                    if (phase_cnt == 4'd1) begin
                        scl_t <= 1'b1;
                        i2c_shifter[bit_cnt] <= sda_i;
                    end
                    if (phase_cnt == 4'd3) begin
                        scl_t <= 1'b0; scl_o <= 1'b0;
                        phase_cnt <= 4'd0;
                        if (bit_cnt == 3'd0) begin
                            adc_data[11:8] <= i2c_shifter[3:0]; 
                            state          <= GET_ACK2;
                        end else bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                GET_ACK2: begin 
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end
                    if (phase_cnt == 4'd1) scl_t <= 1'b1;
                    if (phase_cnt == 4'd3) begin
                        scl_t <= 1'b0; scl_o <= 1'b0;
                        state     <= READ_LSB;
                        bit_cnt   <= 3'd7;
                        phase_cnt <= 4'd0;
                    end
                end

                READ_LSB: begin
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) sda_t <= 1'b1;
                    if (phase_cnt == 4'd1) begin
                        scl_t <= 1'b1;
                        i2c_shifter[bit_cnt] <= sda_i;
                    end
                    if (phase_cnt == 4'd3) begin
                        scl_t <= 1'b0; scl_o <= 1'b0;
                        phase_cnt <= 4'd0;
                        if (bit_cnt == 3'd0) begin
                            adc_data[7:0] <= i2c_shifter;
                            state         <= GET_ACK3; 
                        end else bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                GET_ACK3: begin 
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) sda_t <= 1'b1; 
                    if (phase_cnt == 4'd1) scl_t <= 1'b1;
                    if (phase_cnt == 4'd3) begin
                        scl_t <= 1'b0; scl_o <= 1'b0;
                        state     <= STOP;
                        phase_cnt <= 4'd0;
                        adc_data_valid <= 1'b1; 
                    end
                end

                STOP: begin
                    phase_cnt <= phase_cnt + 1'b1;
                    if (phase_cnt == 4'd0) begin sda_t <= 1'b0; sda_o <= 1'b0; end
                    if (phase_cnt == 4'd1) scl_t <= 1'b1;
                    if (phase_cnt == 4'd2) sda_t <= 1'b1; 
                    if (phase_cnt == 4'd3) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
