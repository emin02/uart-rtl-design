`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2025 22:19:15
// Design Name: 
// Module Name: uart_tx_tb
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


module uart_tx_tb;

    // Parameters
    parameter [16:0] freq = 115200;

    // Testbench Signals
    reg        clk  = 1'b0;
    reg        rst  = 1'b0;
    reg [7:0]  d_in = 8'h00;
    reg        tx_en = 1'b0;

    // Outputs from DUT
    wire seri_out;
    wire done;
    wire start;
    wire busy;

    // ----------------------------
    // Baud_gen interface for revised uart_tx
    // ----------------------------
    wire tx_count_baud_ready;
    wire tx_count_8x_ready_unused;
    wire tx_baud_en;

    // File I/O
    integer file, r;
    reg [7:0] stimulus_data;
    integer i;

    // 100 MHz clock (10ns period)
    always #5 clk = ~clk;

    // Baud generator instance (drives tx_count_baud_ready)
    baud_gen #(
        .freq(freq)
    ) u_baud_tx (
        .clk              (clk),
        .rst              (rst),
        .baud_en          (tx_baud_en),
        .count_8x_ready   (tx_count_8x_ready_unused), // not used in TX
        .count_baud_ready (tx_count_baud_ready)
    );

    // DUT: revised uart_tx (NO internal baud_gen)
    uart_tx #(
        .freq(freq)
    ) uut (
        .clk                 (clk),
        .rst                 (rst),
        .d_in                (d_in),
        .tx_en               (tx_en),

        .tx_count_baud_ready (tx_count_baud_ready),
        .tx_baud_en          (tx_baud_en),

        .seri_out            (seri_out),
        .start               (start),
        .busy                (busy),
        .done                (done)
    );

    initial begin
        // 1) Open the stimulus file
        // IMPORTANT: Put stimulus.txt into the simulation run directory
        // (or add it as a simulation source with "copy to run dir")
        file = $fopen("stimulus.txt", "r");
        if (file == 0) begin
            $display("ERROR: Cannot open stimulus.txt");
            $finish;
        end

        // 2) Reset
        rst  = 1'b1;
        d_in = 8'h00;
        tx_en = 1'b0;
        #8000;      // 8 us reset (same style as your example)
        rst  = 1'b0;

        // 3) Read 4 lines and transmit
        for (i = 0; i < 4; i = i + 1) begin
            r = $fscanf(file, "%b\n", stimulus_data);
            if (r == 1) begin
                // Apply data
                d_in = stimulus_data;

                // 1-clock enable pulse
                tx_en = 1'b1;
                #10;
                tx_en = 1'b0;

                // Wait until transmission completes
                wait (done == 1'b1);

                // (Optional) print what was sent
                $display("TX Sent[%0d] = %b (0x%0h)", i, stimulus_data, stimulus_data);

                // Wait before next byte
                #15000;
            end
        end

        // 4) Cleanup
        $fclose(file);
        $display("UART TX file-based test completed.");
        $finish;
    end

endmodule
