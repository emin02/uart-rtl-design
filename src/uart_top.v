`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.12.2025 14:51:34
// Design Name: 
// Module Name: uart_top
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

module uart_top #(
    parameter [16:0] freq = 115200
)(
    input  wire       clk,
    input  wire       rst,

    // Control
    input  wire       tx_en,
    input  wire       rx_en,

    // Parallel TX input
    input  wire [7:0] tx_d_in,

    // Serial lines
    input  wire       rx_serial_in,
    output wire       tx_serial_out,

    // Parallel RX output
    output wire [7:0] rx_d_out,

    // Status - TX
    output wire       tx_start,
    output wire       tx_busy,
    output wire       tx_done,

    // Status - RX
    output wire       rx_start,
    output wire       rx_busy,
    output wire       rx_done
);

    // Baud_gen <-> Tx/Rx wiring
    wire count_8x_ready;
    wire count_baud_ready;

    wire tx_baud_en;
    wire rx_baud_en;

    wire baud_en_top;
    assign baud_en_top = tx_baud_en | rx_baud_en;   // single baud_gen enable

    // One Baud Generator instance (as required)
    baud_gen #(.freq(freq)) u_baud (
        .clk             (clk),
        .rst             (rst),
        .baud_en         (baud_en_top),
        .count_8x_ready  (count_8x_ready),
        .count_baud_ready(count_baud_ready)
    );

    // TX instance
    uart_tx #(.freq(freq)) u_tx (
        .clk               (clk),
        .rst               (rst),
        .d_in              (tx_d_in),
        .tx_en             (tx_en),
        .tx_count_baud_ready(count_baud_ready),
        .tx_baud_en        (tx_baud_en),
        .seri_out          (tx_serial_out),
        .start             (tx_start),
        .busy              (tx_busy),
        .done              (tx_done)
    );

    // RX instance
    uart_rx #(.freq(freq)) u_rx (
        .clk                (clk),
        .rst                (rst),
        .d_in               (rx_serial_in),
        .rx_en              (rx_en),
        .rx_count_8x_ready  (count_8x_ready),
        .rx_count_baud_ready(count_baud_ready),
        .rx_baud_en         (rx_baud_en),
        .d_out              (rx_d_out),
        .start              (rx_start),
        .busy               (rx_busy),
        .done               (rx_done)
    );

endmodule
