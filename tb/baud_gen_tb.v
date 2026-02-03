`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2025 21:40:10
// Design Name: 
// Module Name: baud_gen_tb
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

module baud_gen_tb();

    // Parameters
    // 115200 sayısı 17 bit gerektirir (0x1C200), bu yüzden [16:0] boyutu uygundur.
    parameter [16:0] freq = 115200;

    // Testbench Signals
    reg clk = 1'b0;
    reg rst = 1'b0;
    reg baud_en = 1'b0;      // Enable signal

    // Outputs from DUT
    wire count_8x_ready;     // 8x clock ready
    wire count_baud_ready;   // Baud clock ready

    // Instantiate the DUT (Device Under Test)
    baud_gen #(
        .freq(freq)
    ) uut (
        .clk(clk),
        .rst(rst),
        .baud_en(baud_en),
        .count_8x_ready(count_8x_ready),
        .count_baud_ready(count_baud_ready)
    );

    // Generate a 100 MHz clock (period = 10 ns -> toggle every 5 ns)
    always begin
        #5 clk = ~clk;
    end

    // Stimulus process
    initial begin
        // Başlangıç durumu
        rst = 1;
        baud_en = 0;
        
        // 10ns bekle ve reset'i kaldır
        #10;
        rst = 0;
        
        // Modülü etkinleştir
        baud_en = 1;
        
        // 11000ns (11us) boyunca çalıştır
        #11000;
        
        // Modülü devre dışı bırak
        baud_en = 0;
        
        // Biraz daha bekle ve simülasyonu bitir
        #200;
        $finish;
    end

endmodule