`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.12.2025 14:52:37
// Design Name: 
// Module Name: uart_top_tb
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

module uart_top_tb;

    parameter [16:0] freq = 115200;

    localparam integer CLK_PERIOD = 10;    // 100 MHz
    localparam integer BIT_PERIOD = 8680;  // ns @115200

    reg clk = 1'b0;
    reg rst = 1'b0;

    reg tx_en = 1'b0;
    reg rx_en = 1'b0;
    reg [7:0] tx_d_in = 8'h00;

    wire tx_serial_out;

    // RX input delayed version of TX output
    wire rx_serial_in;
    integer phase_ns;

    // outputs/status
    wire [7:0] rx_d_out;
    wire tx_start, tx_busy, tx_done;
    wire rx_start, rx_busy, rx_done;

    reg [7:0] test_vec [0:3];
    reg [7:0] expected_data;
    integer k;

    // clock
    always #(CLK_PERIOD/2) clk = ~clk;

    // phase delay
    assign #(phase_ns) rx_serial_in = tx_serial_out;

    // DUT
    uart_top #(.freq(freq)) dut (
        .clk          (clk),
        .rst          (rst),
        .tx_en        (tx_en),
        .rx_en        (rx_en),
        .tx_d_in      (tx_d_in),
        .rx_serial_in (rx_serial_in),
        .tx_serial_out(tx_serial_out),
        .rx_d_out     (rx_d_out),
        .tx_start     (tx_start),
        .tx_busy      (tx_busy),
        .tx_done      (tx_done),
        .rx_start     (rx_start),
        .rx_busy      (rx_busy),
        .rx_done      (rx_done)
    );

    // ✅ FIXED: tx_en pulse is aligned to clk and lasts 1 full cycle
    task send_byte;
        input [7:0] b;
        begin
            $display("send_byte called: %h at %t", b, $time);

            // make sure signals are stable BEFORE a posedge
            @(negedge clk);
            tx_d_in <= b;
            tx_en   <= 1'b1;

            // keep it high for a full cycle so uart_tx can't miss it
            @(negedge clk);
            tx_en   <= 1'b0;

            $display("tx_en deasserted at %t", $time);
        end
    endtask

    initial begin
        test_vec[0] = 8'h2B;
        test_vec[1] = 8'hC4;
        test_vec[2] = 8'hF3;
        test_vec[3] = 8'h4E;

        rst = 1'b1;
        tx_en = 1'b0;
        rx_en = 1'b0;
        phase_ns = 0;

        #(20*CLK_PERIOD);
        rst = 1'b0;

        rx_en = 1'b1;

        // small idle gap
        #(5*BIT_PERIOD);

        for (k = 0; k < 4; k = k + 1) begin
            phase_ns = (k * (BIT_PERIOD/4)) % BIT_PERIOD;
            expected_data = test_vec[k];

            $display("---- Frame %0d : sending %h, phase_ns=%0d ----", k, expected_data, phase_ns);

            // start TX
            send_byte(expected_data);

            // wait long enough for TX+RX to finish (baud rounding safe)
            #(15*BIT_PERIOD);

            // compare
            if (rx_d_out == expected_data)
                $display("PASS: rx_d_out=%h matches expected=%h @%t", rx_d_out, expected_data, $time);
            else
                $display("FAIL: rx_d_out=%h expected=%h @%t", rx_d_out, expected_data, $time);

            #(3*BIT_PERIOD);
        end

        #20000;
        $finish;
    end

endmodule

