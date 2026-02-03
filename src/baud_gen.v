`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.12.2025 21:39:25
// Design Name: 
// Module Name: baud_gen
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


module baud_gen #(parameter [16:0]  freq= 115200)   
( 
    input clk, 
    input rst, 
    input baud_en, 
    output count_8x_ready, 
    output count_baud_ready 
); 
    localparam integer clk_freq = 100000000; // Internal clock frequency (100 MHz) 
    reg count_8x_ready_reg,count_baud_ready_reg; 
    reg [13:0] counter_8x; 
    reg [2:0] counter_baud; 
    always @(posedge clk) begin 
        if(rst==1'b1) begin 
            counter_baud <= 3'b0; // baud counter 
            count_baud_ready_reg <= 0; // baud counter result 
            counter_8x <= 13'b0; // 8x counter 
            count_8x_ready_reg <= 0; // 8x counter result  
        end 
        else if (baud_en == 1) begin 
            if(counter_8x ==((clk_freq/(freq*8))-1)) begin  
                counter_8x <= 13'b0; 
                count_8x_ready_reg <= 1; 
                if(counter_baud == 7) begin 
                    counter_baud <= 3'b0; 
                    count_baud_ready_reg <= 1; 
                end 
                else begin  
                    counter_baud <= counter_baud + 1; 
                    count_baud_ready_reg <= 0; 
                end 
            end 
            else begin  
                counter_8x <= counter_8x + 1; 
                count_8x_ready_reg <= 0; 
                count_baud_ready_reg <= 0; 
            end 
        end  
        else begin 
            count_8x_ready_reg <= 0; 
            counter_8x <= 13'b0; 
            counter_baud <= 3'b0; 
            count_baud_ready_reg <= 0; 
        end      
    end 
    assign count_8x_ready = count_8x_ready_reg; 
    assign count_baud_ready = count_baud_ready_reg; 
endmodule   
 
