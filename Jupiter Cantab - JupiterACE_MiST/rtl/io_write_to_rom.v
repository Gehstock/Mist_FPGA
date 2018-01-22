`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:45:40 11/08/2015 
// Design Name: 
// Module Name:    io_write_to_rom 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module io_write_to_rom (
    input wire clk,
    input wire [15:0] a,
    input wire iorq_n,
    input wire rd_n,
    input wire wr_n,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg dout_oe,
    output reg enable_write_to_rom
    );
    
    parameter IOADDR = 127; // Puerto 127 para esta historia
    reg [7:0] magicsequence[0:7];
    initial begin
        enable_write_to_rom = 1'b0;
        magicsequence[0] = "E";
        magicsequence[1] = "N";
        magicsequence[2] = "A";
        magicsequence[3] = "B";
        magicsequence[4] = "L";
        magicsequence[5] = "E";
        magicsequence[6] = "W";
        magicsequence[7] = "R";
    end
    
    reg [2:0] indexseq = 3'd0;
    reg in_io_write = 1'b0;
    reg [7:0] data_from_cpu;
    
    always @(posedge clk) begin
        if (in_io_write == 1'b0 && iorq_n == 1'b0 && wr_n == 1'b0 && a[7:0] == IOADDR) begin
            data_from_cpu <= din;
            in_io_write <= 1'b1;
        end
        else if (in_io_write == 1'b1 && (iorq_n == 1'b1 || wr_n == 1'b1 || a[7:0] != IOADDR)) begin
            in_io_write <= 1'b0;
            if (data_from_cpu == magicsequence[indexseq]) begin
                if (indexseq == 3'd7)
                    enable_write_to_rom <= 1'b1;
                else begin
                    enable_write_to_rom <= 1'b0;
                    indexseq <= indexseq + 3'd1;
                end
            end
            else begin
                enable_write_to_rom <= 1'b0;
                indexseq <= 3'd0;
            end
        end
    end
    
    always @* begin
        dout_oe = 1'b0;
        dout = {7'b0000000,enable_write_to_rom};
        if (iorq_n == 1'b0 && rd_n == 1'b0 && a[7:0] == IOADDR)
            dout_oe = 1'b1;
    end
endmodule
