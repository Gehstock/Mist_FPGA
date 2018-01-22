`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:06:40 03/19/2011 
// Design Name: 
// Module Name:    jace_on_fpga 
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

module jupiter_ace (
	input wire clk_65,
   input wire clk_cpu,
	input wire reset,
	input wire ear,
	output wire [7:0] filas,
	input wire [4:0] columnas,
	output wire video,
	output wire hsync,
	output wire vsync,
   output wire mic,
   output wire spk,
   output wire sd_addr,
   input wire sd_dout,
   output wire sd_din,
   output wire sd_we,
   output wire sd_rd,
   input wire sd_ready
	);

	wire [7:0] DinZ80;
	wire [7:0] DoutZ80;
	wire [15:0] AZ80;
	

	wire iorq_n, mreq_n, rd_n, wr_n, wait_n, int_n;
   wire rom_enable, sram_enable, cram_enable, uram_enable, xram_enable, eram_enable, data_from_jace_oe;
   wire [7:0] dout_rom, dout_sram, dout_cram, dout_uram, dout_xram, dout_eram, data_from_jace;
   wire [7:0] sram_data, cram_data;
   wire [9:0] sram_addr, cram_addr;
    

   wire enable_write_to_rom;
   wire [7:0] dout_modulo_enable_write;
   wire modulo_enable_write_oe;


   assign filas = AZ80[15:8];

   // Multiplexer
   assign DinZ80 = (rom_enable == 1'b1)?        dout_rom :
                   (sram_enable == 1'b1)?       dout_sram :
                   (cram_enable == 1'b1)?       dout_cram :
                   (uram_enable == 1'b1)?       dout_uram :
                   (xram_enable == 1'b1)?       dout_xram :
                   (eram_enable == 1'b1)?       dout_eram :
                   (modulo_enable_write_oe == 1'b1)? dout_modulo_enable_write :
                   (data_from_jace_oe == 1'b1)? data_from_jace :
                                                sram_data | cram_data;  // By default, this is what the data bus sees

	ram1k_dualport sram (
       .clk(clk_65),
       .ce(sram_enable),
       .a1(AZ80[9:0]),
	   .a2(sram_addr),
	   .din(DoutZ80),
	   .dout1(dout_sram),
       .dout2(sram_data),
	   .we(~wr_n)
		);
		
	ram1k_dualport cram (
       .clk(clk_65),
       .ce(cram_enable),
       .a1(AZ80[9:0]),
	   .a2(cram_addr),
	   .din(DoutZ80),
	   .dout1(dout_cram),
       .dout2(cram_data),
	   .we(~wr_n)
		);
		
	ram1k uram(
		.clk(clk_65),
        .ce(uram_enable),
        .a(AZ80[9:0]),
        .din(DoutZ80),
        .dout(dout_uram),
        .we(~wr_n)
		);
		
	ram16k xram(
		.clk(clk_65),
        .ce(xram_enable),
        .a(AZ80[13:0]),
        .din(DoutZ80),
        .dout(dout_xram),
        .we(~wr_n)
		);
		
assign sd_addr = AZ80[13:0];
//assign sd_dout = dout_eram;
assign sd_din = DoutZ80;
assign sd_we = ~wr_n;
assign sd_rd = eram_enable;


//	ram32k eram(//16k for now//todo 32k
//		.clk(clk_65),
//      .ce(eram_enable),
//      .a(AZ80[13:0]),//14
//      .din(DoutZ80),
//      .dout(dout_eram),
//      .we(~wr_n)
//		);
		
//	rom the_rom(	
//	   .clk(clk_65),
//		.a(AZ80[12:0]),
//		.dout(dout_rom)
//		);
		
	rom2 the_rom(
	   .clk(clk_65),
      .ce(rom_enable),
	   .a(AZ80[12:0]),
      .din(DoutZ80),
	   .dout(dout_rom),
      .we(~wr_n & enable_write_to_rom)
		);

    io_write_to_rom modulo_habilitador_escrituras (
       .clk(clk_65),
        .a(AZ80),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .din(DoutZ80),
        .dout(dout_modulo_enable_write),
        .dout_oe(modulo_enable_write_oe),
        .enable_write_to_rom(enable_write_to_rom)
    );
    
	
	tv80n cpu(
		// Outputs
		.m1_n(), 
		.mreq_n(mreq_n), 
		.iorq_n(iorq_n), 
		.rd_n(rd_n), 
		.wr_n(wr_n), 
		.rfsh_n(), 
		.halt_n(), 
		.busak_n(), 
		.A(AZ80), 
		.dout(DoutZ80),
		// Inputs
		.di(DinZ80), 
		.reset_n(reset), 
		.clk(clk_cpu), 
		.wait_n(wait_n), 
		.int_n(int_n), 
		.nmi_n(1'b1), 
		.busrq_n(1'b1)
        );
        
    glue glogic (
        .clk(clk_65),
        // CPU interface
        .cpu_addr(AZ80),
        .mreq_n(mreq_n),
        .iorq_n(iorq_n),
        .rd_n(rd_n),
        .wr_n(wr_n),
        .data_from_cpu(DoutZ80),
        .data_to_cpu(data_from_jace),
        .data_to_cpu_oe(data_from_jace_oe),
        .wait_n(wait_n),
        .int_n(int_n),
        // CPU-RAM interface
        .rom_enable(rom_enable),
        .sram_enable(sram_enable),
        .cram_enable(cram_enable),
        .uram_enable(uram_enable),
        .xram_enable(xram_enable),
        .eram_enable(eram_enable),
        // Screen RAM and Char RAM interface
        .screen_addr(sram_addr),
        .screen_data(sram_data),
        .char_addr(cram_addr),
        .char_data(cram_data),
        // Devices
        .kbdcols(columnas),
        .ear(ear),
        .spk(spk),
        .mic(mic),
        .video(video),
        .hsync_pal(hsync),
		  .vsync_pal(vsync)
    );
    

endmodule

