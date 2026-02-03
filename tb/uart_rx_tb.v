`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2025 23:14:35
// Design Name: 
// Module Name: uart_rx_tb
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

module uart_rx_tb;

    // Parameters
    parameter [16:0] freq = 115200;
    localparam integer CLK_PERIOD = 10;   // 100 MHz
    localparam integer BIT_PERIOD = 8680; // ns @115200 baud
    localparam integer TICK_8X_PERIOD = BIT_PERIOD/8;

    // Testbench Signals
    reg clk = 1'b0;
    reg rst = 1'b0;
    reg d_in = 1'b1;   // RX idle = high
    reg rx_en = 1'b0;

    // "baud_gen" handshake signals (TB generates these)
    reg  rx_count_8x_ready   = 1'b0;
    reg  rx_count_baud_ready = 1'b0;
    wire rx_baud_en;

    // Outputs from DUT
    wire [7:0] d_out;
    wire done;
    wire start;
    wire busy;

    // NEW: compare signals (like your example)
    reg [7:0] test_data;
    reg [7:0] expected_data;

    // File I/O Variables
    integer file, r;
    integer i;

    // Clock Generation (100 MHz)
    always #(CLK_PERIOD/2) clk = ~clk;

    // Instantiate DUT
    uart_rx #(
        .freq(freq)
    ) uut (
        .clk                (clk),
        .rst                (rst),
        .d_in               (d_in),
        .rx_en              (rx_en),
        .rx_count_8x_ready   (rx_count_8x_ready),
        .rx_count_baud_ready (rx_count_baud_ready),
        .rx_baud_en          (rx_baud_en),
        .d_out               (d_out),
        .start               (start),
        .busy                (busy),
        .done                (done)
    );

    // ---------------------------------------------------------
    // Generate rx_count_8x_ready pulses when rx_baud_en is 1
    // Also generate rx_count_baud_ready once every 8 pulses
    // ---------------------------------------------------------
    integer tick8_cnt = 0;

    initial begin
        rx_count_8x_ready = 1'b0;
        rx_count_baud_ready = 1'b0;
        tick8_cnt = 0;

        forever begin
            #(TICK_8X_PERIOD);

            if (rx_baud_en) begin
                // 1-cycle-ish pulse for 8x tick (>= 1 clk so DUT won't miss)
                rx_count_8x_ready = 1'b1;
                #(CLK_PERIOD);
                rx_count_8x_ready = 1'b0;

                if (tick8_cnt == 7) begin
                    tick8_cnt = 0;
                    rx_count_baud_ready = 1'b1;
                    #(CLK_PERIOD);
                    rx_count_baud_ready = 1'b0;
                end else begin
                    tick8_cnt = tick8_cnt + 1;
                end
            end else begin
                tick8_cnt = 0;
                rx_count_8x_ready = 1'b0;
                rx_count_baud_ready = 1'b0;
            end
        end
    end

    // Task to send one UART frame
    task send_uart_byte;
        input [7:0] data;
        begin
            // Start bit
            d_in = 1'b0;
            #(BIT_PERIOD);

            // Data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                d_in = data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            d_in = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    // Test sequence
    initial begin
        // Init
        d_in  = 1'b1;
        rst   = 1'b1;
        rx_en = 1'b0;

        test_data     = 8'h00;
        expected_data = 8'h00;

        #100;
        rst = 1'b0;
        rx_en = 1'b1;

        // Give some idle time before first frame
        #(3*BIT_PERIOD);

        // Open stimulus file
        file = $fopen("stimulus.txt", "r");
        if (file == 0) begin
            $display("ERROR: Cannot open stimulus.txt");
            $finish;
        end

        // Read and send bytes (stimulus.txt binary ise %b)
        while (!$feof(file)) begin
            r = $fscanf(file, "%b\n", test_data);

            if (r == 1) begin
                expected_data = test_data;

                $display("Sending byte: bin=%b hex=%h", test_data, test_data);
                send_uart_byte(test_data);

                #(3*BIT_PERIOD);
            end
        end

        $fclose(file);
        #20000;
        $finish;
    end

    // Monitor received data + compare
    always @(posedge clk) begin
        if (done) begin
            if (d_out == expected_data)
                $display("PASS @%t : d_out=%h matches expected=%h", $time, d_out, expected_data);
            else
                $display("FAIL @%t : d_out=%h expected=%h", $time, d_out, expected_data);
        end
    end

endmodule


