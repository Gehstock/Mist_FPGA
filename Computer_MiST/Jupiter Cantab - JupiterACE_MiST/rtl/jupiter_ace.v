//============================================================================
//  Jupiter Ace main logic
//  Copyright (C) 2018 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module jupiter_ace
(
	input        clk,
	input        ce_pix,
	input        ce_cpu,
	input        no_wait,
	input        reset,

	output [7:0] kbd_row,
	input  [4:0] kbd_col,
	output       video_out,
	output       hsync,
	output       vsync,
	output       hblank,
	output       vblank,
	output reg   mic,
	output reg   spk,

	input        loader_en,
	input [15:0] loader_addr,
	input  [7:0] loader_data,
	input        loader_wr
);

assign kbd_row = cpu_addr[15:8];

wire [15:0]	addr   = loader_en ? loader_addr : cpu_addr;
wire  [7:0] data   = loader_en ? loader_data : cpu_dout;
wire        ram_we = loader_en ? loader_wr   : ~wr_n;

wire rom_enable  = (~mreq_n | loader_en) && (addr[15:13] == 0);       // 0000 - 1FFF 8KB
wire sram_enable = (~mreq_n | loader_en) && (addr[15:11] == 'b00100); // 2000 - 27FF 1KB * 2
wire cram_enable = (~mreq_n | loader_en) && (addr[15:11] == 'b00101); // 2800 - 2FFF 1KB * 2
wire uram_enable = (~mreq_n | loader_en) && (addr[15:12] == 'b0011);  // 3000 - 3FFF 1KB * 4
wire xram_enable = (~mreq_n | loader_en) && (addr[15:14] == 'b01);    // 4000 - 7FFF 16KB
wire eram_enable = (~mreq_n | loader_en) && (addr[15]);               // 8000 - FFFF 32KB

wire wait_n = no_wait | ~(sram_enable | cram_enable) | hblank | vblank | ~addr[10]; // 2400 - 27FF, 2C00 - 2FFF

always @(posedge clk) begin
	if (~iorq_n & ~cpu_addr[0]) begin
		if (~rd_n) spk <= 0;
		if (~wr_n) {spk,mic} <= {1'b1,cpu_dout[3]};
	end
end

wire [7:0] io_dout = {8{iorq_n|rd_n}} | (~cpu_addr[0] ? {3'b110, kbd_col} : (sram_data | cram_data));

wire [9:0] sram_addr;
wire [7:0] sram_data;
wire [7:0] sram_dout;
dpram #(10) sram
(
	.clock(clk),
	.address_a(addr[9:0]),
	.data_a(data),
	.wren_a(ram_we & sram_enable),
	.oe_a_n(~sram_enable),
	.q_a(sram_dout),
	.address_b(sram_addr),
	.q_b(sram_data)
);

wire [9:0] cram_addr;
wire [7:0] cram_data;
dpram #(10) cram
(
	.clock(clk),
	.address_a(addr[9:0]),
	.data_a(data),
	.wren_a(ram_we & cram_enable),
	.address_b(cram_addr),
	.q_b(cram_data)
);

wire [7:0] uram_dout;
dpram #(10) uram
(
	.clock(clk),
	.address_a(addr[9:0]),
	.data_a(data),
	.wren_a(ram_we & uram_enable),
	.oe_a_n(~uram_enable),
	.q_a(uram_dout)
);

wire [7:0] xram_dout;
dpram #(14) xram
(
	.clock(clk),
	.address_a(addr[13:0]),
	.data_a(data),
	.wren_a(ram_we & xram_enable),
	.oe_a_n(~xram_enable),
	.q_a(xram_dout)
);

wire [7:0] eram_dout;
dpram #(14) eram//15
(
	.clock(clk),
	.address_a(addr[13:0]),
	.data_a(data),
	.wren_a(ram_we & eram_enable),
	.oe_a_n(~eram_enable),
	.q_a(eram_dout)
);

wire [7:0] rom_dout;
dpram #(.ADDRWIDTH(13), .MEM_INIT_FILE("ace.mif")) rom
(
	.clock(clk),
	.address_a(cpu_addr[12:0]),
	.oe_a_n(~rom_enable),
	.q_a(rom_dout)
);

wire  [7:0] cpu_dout;
wire [15:0] cpu_addr;
wire        iorq_n, mreq_n, rd_n, wr_n, int_n;
T80pa cpu
(
	.RESET_n(~(reset | loader_reset)),
	.CLK(clk),
	.CEN_p(ce_cpu),

	.WAIT_n(wait_n),
	.INT_n(vsync),
	.MREQ_n(mreq_n),
	.IORQ_n(iorq_n),
	.RD_n(rd_n),
	.WR_n(wr_n),
	.A(cpu_addr),
	.DI(rom_dout & sram_dout & uram_dout & xram_dout & eram_dout & io_dout),
	.DO(cpu_dout),
	.DIRSet(|regset),
	.DIR(REG)
);

reg  [211:0] REG;  // IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
reg    [1:0] regset = 0;
reg          loader_reset;

always @(posedge clk) begin
	reg old_loader;
	reg old_vsync;
	
	old_vsync <= vsync;

	if(loader_en) begin
		loader_reset <= 1;
		regset <= 2'b11;
		if(loader_wr && (loader_addr[15:8] == 8'h21) && !loader_addr[7]) begin
			case(loader_addr[6:0])
				'h00: REG[15:8]    <= loader_data; //f
				'h01: REG[7:0]     <= loader_data; //a
				'h04: REG[87:80]   <= loader_data; //c
				'h05: REG[95:88]   <= loader_data; //b
				'h08: REG[103:96]  <= loader_data; //e
				'h09: REG[111:104] <= loader_data; //d
				'h0C: REG[119:112] <= loader_data; //l
				'h0D: REG[127:120] <= loader_data; //h
				'h10: REG[135:128] <= loader_data; //xl
				'h11: REG[143:136] <= loader_data; //xh
				'h14: REG[199:192] <= loader_data; //yl
				'h15: REG[207:200] <= loader_data; //yh
				'h18: REG[55:48]   <= loader_data; //spl
				'h19: REG[63:56]   <= loader_data; //sph
				'h1C: REG[71:64]   <= loader_data; //pcl
				'h1D: REG[79:72]   <= loader_data; //pch
				'h20: REG[31:24]   <= loader_data; //f'
				'h21: REG[23:16]   <= loader_data; //a'
				'h24: REG[151:144] <= loader_data; //c'
				'h25: REG[159:152] <= loader_data; //b' //EightyOne wrongly restores it to B register
				'h28: REG[167:160] <= loader_data; //e'
				'h29: REG[175:168] <= loader_data; //d'
				'h2C: REG[183:176] <= loader_data; //l'
				'h2D: REG[191:184] <= loader_data; //h'
				'h30: REG[209:208] <= loader_data[1:0]; //im
				'h34: REG[210]     <= loader_data[0];   //iff1
				'h38: REG[211]     <= loader_data[0];   //iff2
				'h3C: REG[39:32]   <= loader_data; //i
				'h40: REG[47:40]   <= loader_data; //r
			endcase
		end
	end
	else begin
		if(~old_vsync & vsync) loader_reset <= 0;
		if(~loader_reset && regset) begin
			regset <= regset - 1'd1;
			if(REG[63:48] > loader_addr) begin
				REG[63:48] <= 16'hFFFE; // bug in dump!
			end
		end
	end
end

video video(
	.clk(clk),
	.ce_pix(ce_pix),
	.sram_addr(sram_addr),
	.sram_data(sram_data),
	.cram_addr(cram_addr),
	.cram_data(cram_data),
	.video_out(video_out),
	.hsync(hsync),
	.vsync(vsync),
	.hblank(hblank),
	.vblank(vblank)
);
endmodule 