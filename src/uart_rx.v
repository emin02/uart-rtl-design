`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2025 23:11:59
// Design Name: 
// Module Name: uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_rx #(
    parameter [16:0] freq = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       d_in,
    input  wire       rx_en,

    // Baud_gen interface (from/to TOP)
    input  wire       rx_count_8x_ready,
    input  wire       rx_count_baud_ready,
    output reg        rx_baud_en,

    output reg  [7:0] d_out,
    output reg        start,
    output reg        busy,
    output wire       done
);

    reg done_reg;

    // sampling / counters
    reg [2:0] bit_in;         // 0..7
    reg [2:0] sample_cnt;     // 0..7 (8 samples)  (START'ta 1-bit bekleme sayacı olarak da kullanılıyor)
    reg [3:0] ones_cnt;       // 0..8
    reg [2:0] half_cnt;       // count 4 ticks for T/2

    reg [7:0] shift_reg;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;

    assign done = done_reg;

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            d_out      <= 8'h00;
            shift_reg  <= 8'h00;
            start      <= 1'b0;
            busy       <= 1'b0;
            done_reg   <= 1'b0;
            rx_baud_en <= 1'b0;

            bit_in     <= 3'd0;
            sample_cnt <= 3'd0;
            ones_cnt   <= 4'd0;
            half_cnt   <= 3'd0;

        end else begin
            done_reg <= 1'b0; // default pulse behavior

            case (state)
                IDLE: begin
                    start      <= 1'b0;
                    busy       <= 1'b0;
                    rx_baud_en <= 1'b0;

                    bit_in     <= 3'd0;
                    sample_cnt <= 3'd0;
                    ones_cnt   <= 4'd0;
                    half_cnt   <= 3'd0;

                    if (rx_en && (d_in == 1'b0)) begin
                        // start bit detected
                        state      <= START;
                        start      <= 1'b1;
                        busy       <= 1'b1;
                        rx_baud_en <= 1'b1;

                        half_cnt   <= 3'd0;
                        sample_cnt <= 3'd0; // START'ta 1-bit bekleme sayacı olarak kullanılacak
                    end
                end

                START: begin
                    start <= 1'b1;
                    busy  <= 1'b1;
                
                    if (rx_count_8x_ready) begin
                        if (half_cnt < 3'd3) begin
                            half_cnt <= half_cnt + 1'b1;   // T/2 bekle
                        end else begin
                            // T/2 doldu -> start doğrula
                            if (d_in == 1'b0) begin
                                state      <= DATA;
                                start      <= 1'b0;
                                bit_in     <= 3'd0;
                                sample_cnt <= 3'd0;
                            end else begin
                                // false start
                                state      <= IDLE;
                                start      <= 1'b0;
                                busy       <= 1'b0;
                                rx_baud_en <= 1'b0;
                            end
                        end
                    end
                end
                

                DATA: begin
                    busy <= 1'b1;
                
                    if (rx_count_8x_ready) begin
                        if (sample_cnt == 3'd7) begin
                            // 8 tick doldu -> bit ortası, tek sample al
                            shift_reg <= { d_in, shift_reg[7:1] };
                            sample_cnt <= 3'd0;
                
                            if (bit_in == 3'd7) begin
                                state  <= STOP;
                                bit_in <= 3'd0;
                            end else begin
                                bit_in <= bit_in + 1'b1;
                            end
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end
                

                STOP: begin
                    busy <= 1'b1;

                    // wait one baud period boundary (uses baud_ready)
                    if (rx_count_baud_ready) begin
                        d_out      <= shift_reg;
                        done_reg   <= 1'b1;
                        busy       <= 1'b0;
                        rx_baud_en <= 1'b0;
                        state      <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
