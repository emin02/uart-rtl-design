`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2025 22:16:00
// Design Name: 
// Module Name: uart_tx
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

module uart_tx #(
    parameter [16:0] freq = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] d_in,
    input  wire       tx_en,

    // Baud_gen interface (from/to TOP)
    input  wire       tx_count_baud_ready,
    output reg        tx_baud_en,

    output wire       seri_out,
    output reg        start,
    output reg        busy,
    output wire       done
);

    reg done_reg;
    reg seri_out_reg;
    reg [2:0] bit_in;
    reg [7:0] buffer;

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;

    assign seri_out = seri_out_reg;
    assign done     = done_reg;

    always @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            done_reg     <= 1'b0;
            start        <= 1'b0;
            busy         <= 1'b0;
            seri_out_reg <= 1'b1;  // idle high
            tx_baud_en   <= 1'b0;
            bit_in       <= 3'd0;
            buffer       <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    done_reg     <= 1'b0;
                    seri_out_reg <= 1'b1;
                    tx_baud_en   <= 1'b0;
                    busy         <= 1'b0;
                    start        <= 1'b0;

                    if (tx_en) begin
                        state  <= START;
                        buffer <= d_in;
                        bit_in <= 3'd0;
                    end
                end

                START: begin
                    start        <= 1'b1;
                    busy         <= 1'b1;
                    seri_out_reg <= 1'b0;   // start bit
                    tx_baud_en   <= 1'b1;   // enable baud_gen

                    if (tx_count_baud_ready) begin
                        state <= DATA;
                    end
                end

                DATA: begin
                    start        <= 1'b0;
                    busy         <= 1'b1;
                    seri_out_reg <= buffer[0]; // LSB first

                    if (tx_count_baud_ready) begin
                        if (bit_in == 3'd7) begin
                            state  <= STOP;
                            bit_in <= 3'd0;
                        end else begin
                            buffer <= buffer >> 1;
                            bit_in <= bit_in + 1'b1;
                        end
                    end
                end

                STOP: begin
                    busy         <= 1'b1;
                    seri_out_reg <= 1'b1; // stop bit

                    if (tx_count_baud_ready) begin
                        state      <= IDLE;
                        tx_baud_en <= 1'b0;
                        busy       <= 1'b0;
                        done_reg   <= 1'b1; // 1-cycle pulse
                    end else begin
                        done_reg <= 1'b0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

