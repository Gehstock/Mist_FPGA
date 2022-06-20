module sv_top
(
	input               clk_sys,
	input               reset,
	input [7:0]         joystick,
	input [7:0]         rom_dout,
	input [3:0]         user_in,
	input               large_rom,
	input               compat60,
	output              hsync,
	output              hblank,
	output              vsync,
	output              vblank,
	output [15:0]       audio_r,
	output [15:0]       audio_l,
	output [1:0]        pixel,
	output              pix_ce,
	output [18:0]       addr_bus,
	output              rom_read,
	output reg [7:0]    link_ddr,
	output reg [7:0]    link_data
);

reg [1:0] sys_div = 0;
reg irq_pending = 0;
reg [7:0] open_bus = 8'hFF;
reg [15:0] nmi_clk;
reg irq_timer;
reg old_nmi_clk_15;
reg nmi_latch = 0;

// System Registers
reg [7:0] irq_timer_len;
reg [7:0] sys_ctl;

wire irq_adma_n;
wire [7:0] cpu_dout, wram_dout, vram_dout, sys_dout;
wire dma_en;
wire dma_dir;
wire adma_read;
wire [7:0] lcd_din;
wire [13:0] lcd_addr, vram_addr;
wire [15:0] adma_addr, dma_addr, cpu_addr;
wire [2:0] adma_bank;
wire [5:0] audio_right, audio_left;
wire cpu_rwn;

// Clock divider
wire phi1 = sys_div == 2'b00;
wire phi2 = sys_div == 2'b10;

// Chip Selects
wire wram_cs = AB[15:13] == 3'b000;           // Work ram from 0000 to 1FFF
wire sys_cs  = AB[15:6]  == 10'b0010_0000_00; // System Registers from 2000 to 3FFF (open bus above 202F)
wire vram_cs = AB[15:13] == 3'b010;           // Vram from 4000 to 5FFF
//wire ob_cs   = AB[15:13] == 3'b011;         // Open bus from 6000 to 7FFF
wire rom_cs  = AB[15];                        // Cart ROM at 8000 to FFFF banked from 8000-BFFF, fixed for the rest

// Bank Selection
wire [2:0] b = AB[14] ? 3'b111 : adma_read ? adma_bank : sys_ctl[7:5];
wire [18:0] magnum_addr = {(b[2] ? 4'b1111 : link_data[3:0]), b[0], AB[13:0]};

// IRQ/NMI Masking
wire nmi = old_nmi_clk_15 & ~nmi_clk[15];
wire timer_tap = (sys_ctl[4] ? nmi_clk[13] : nmi_clk[7]);
wire irq_timer_masked = irq_timer & sys_ctl[1];
wire irq_adma_masked = ~irq_adma_n & sys_ctl[2];
wire nmi_masked = (nmi | nmi_latch) & sys_ctl[0]; // the CPU misses nmi's when paused in this implementation so we have to latch it

// (A)DMA bus multiplexing
wire [15:0] AB = adma_read ? adma_addr : (dma_en ? dma_addr : cpu_addr);
wire cpu_rdy = ~dma_en && ~adma_read;
wire [7:0] DO = dma_en ? (dma_dir ? DII : vram_dout) : cpu_dout;
wire cpu_we = adma_read ? 1'b0 : dma_en ? ~dma_dir : ~cpu_rwn;

// Read Data Bus
wire [7:0] DII =
	sys_cs ? sys_dout :
	wram_cs ? wram_dout :
	vram_cs ? vram_dout :
	rom_cs ? rom_dout :
	open_bus;

// Top Level assignments
assign addr_bus = large_rom ? magnum_addr : {2'b11, b, AB[13:0]};
assign rom_read = rom_cs & ~phi1;
assign audio_l = { audio_left, 10'd0 };
assign audio_r = { audio_right, 10'd0 };

// System Register reads
always_comb begin
	sys_dout = open_bus;
	if (~cpu_we) begin
		case (AB[5:0])
			6'h20: sys_dout = ~joystick;
			6'h21: sys_dout = {open_bus[7:4], (user_in[3:0] & link_ddr[3:0]) | (link_data[3:0] & ~link_ddr[3:0])};
			6'h23: sys_dout = irq_timer_len;
			6'h26: sys_dout = sys_ctl;
			6'h27: sys_dout = {open_bus[7:2], ~irq_adma_n, irq_timer};
			default: sys_dout = open_bus;
		endcase
	end
end

always_ff @(posedge clk_sys) begin
	reg old_tap;

	sys_div <= sys_div + 1'd1;

	if (phi1) begin
		if (~cpu_rdy)
			nmi_latch <= nmi_masked | nmi_latch;
		else
			nmi_latch <= 0;
	end

	if (phi2) begin
		old_tap <= timer_tap;
		old_nmi_clk_15 <= nmi_clk[15];
		nmi_clk <= nmi_clk + 16'b1;

		if (~old_tap && timer_tap) begin
			if (irq_timer_len > 0) begin
				irq_timer_len <= irq_timer_len - 8'b1;
				if (irq_timer_len == 1)
						irq_pending <= 1;
			end
		end

		if (irq_pending && ~timer_tap) begin
			irq_pending <= 0;
			irq_timer <= 1;
		end

		open_bus <= ~cpu_we ? DII : DO;

		// System Register writes
		if (sys_cs) begin
			if (AB[5:0] == 6'h24) begin // read or write to ack timer IRQ
				irq_timer <= 0;
			end
			if (cpu_we) begin
				case (AB[5:0])
					6'h21: link_data <= cpu_dout;
					6'h22: link_ddr <= cpu_dout;
					6'h23: begin
						irq_timer_len <= cpu_dout;
						if (cpu_dout == 0) begin
							if (~timer_tap) begin
								irq_timer <= 1;
							end else begin
								irq_pending <= 1;
							end
						end
					end
					6'h26: sys_ctl <= cpu_dout;
				endcase
			end
		end
	end

	if (reset) begin
		irq_timer <= 0;
		irq_pending <= 0;
		irq_timer_len <= 0;
		nmi_clk <= 0;
		sys_ctl <= 0;
		link_ddr <= 0;
		nmi_latch <= 0;
		link_data <= 0;
	end
end

spram #(.addr_width(13)) wram
(
	.clock(clk_sys),
	.address(AB[12:0]),
	.data(DO),
	.wren(cpu_we && wram_cs && phi2),
	.q(wram_dout)
);

dpram #(.addr_width(14)) vram
(
	.clock(clk_sys),
	.address_a(dma_en ? vram_addr : AB[13:0]),
	.data_a(DO),
	.q_a(vram_dout),
	.wren_a((dma_en ? dma_dir : (vram_cs && cpu_we)) && phi2),

	.address_b(lcd_addr),
	.q_b(lcd_din)
);

dma dma
(
	.clk            (clk_sys),
	.ce             (phi1),
	.reset          (reset),
	.AB             (AB[5:0]),
	.cpu_rwn        (~cpu_we),
	.dma_cs         (sys_cs),
	.lcd_en         (sys_ctl[3]),
	.data_in        (cpu_dout),
	.vbus_addr      (vram_addr),
	.cbus_addr      (dma_addr),
	.dma_en         (dma_en),
	.dma_dir        (dma_dir)
);

audio audio
(
	.clk            (clk_sys),
	.ce             (phi1),
	.reset          (reset),
	.cpu_rwn        (~cpu_we),
	.snd_cs         (sys_cs),
	.AB             (AB[5:0]),
	.dbus_in        (adma_read ? DII : cpu_dout),
	.adma_irq_n     (irq_adma_n),
	.prescaler      (nmi_clk),
	.adma_read      (adma_read),
	.adma_bank      (adma_bank),
	.adma_addr      (adma_addr),
	.CH1            (audio_right),
	.CH2            (audio_left)
);

lcd lcd
(
	.clk            (clk_sys),
	.ce             (phi2),
	.compat60       (compat60),
	.reset          (reset),
	.lcd_cs         (sys_cs),
	.cpu_rwn        (~cpu_we),
	.AB             (AB[5:0]),
	.dbus_in        (cpu_dout),
	.ce_pix         (pix_ce),
	.pixel          (pixel),
	.lcd_off        (~sys_ctl[3] || (cpu_we && sys_cs && AB[5:0] == 16'h26)),
	.vram_data      (lcd_din),
	.vram_addr      (lcd_addr),
	.hsync          (hsync),
	.vsync          (vsync),
	.hblank         (hblank),
	.vblank         (vblank)
);

r65c02_tc cpu3
(
	.clk_clk_i      (clk_sys),
	.d_i            (cpu_rwn ? DII : DO),
	.ce             (phi1 && cpu_rdy),
	.irq_n_i        (~(irq_timer_masked | irq_adma_masked)),
	.nmi_n_i        (~nmi_masked),
	.rdy_i          (1), // This system seems to halt the clock for dma rather than use traditional rdy
	.rst_rst_n_i    (~reset),
	.so_n_i         (1),
	.a_o            (cpu_addr),
	.d_o            (cpu_dout),
	.rd_o           (),
	.sync_o         (),
	.wr_n_o         (cpu_rwn),
	.wr_o           ()
);

endmodule 