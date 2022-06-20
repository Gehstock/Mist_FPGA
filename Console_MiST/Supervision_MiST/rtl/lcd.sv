module lcd
(

	input           clk,
	input           ce,
	input           reset,
	input           lcd_cs,
	input           cpu_rwn,
	input           compat60,
	input [5:0]     AB,
	input [7:0]     dbus_in,
	input [7:0]     vram_data,
	input           lcd_off,
	output          ce_pix,
	output reg [1:0]pixel,
	output [13:0]   vram_addr,
	output          hsync,
	output          vsync,
	output reg      hblank,
	output reg      vblank
);

localparam H_WIDTH = 9'd300;
localparam H_WIDTH_COMPAT = 9'd254;
localparam V_HEIGHT = 9'd262;
localparam PHYS_WIDTH = 9'd160;
localparam PHYS_HEIGHT = 9'd160;

wire [8:0] h_w = compat60 ? H_WIDTH_COMPAT : H_WIDTH;

reg [7:0] lcd_xsize, lcd_ysize, lcd_xscroll, lcd_yscroll;
reg lcd_off_latch;
reg wrapped;
reg [9:0] wrap_offset;
reg [8:0] hblank_start, hblank_end, vblank_start, vblank_end, vpos, hpos;
reg [31:0] dot_count, frame_len;

wire [9:0] vpos_off = (vpos - vblank_end) + lcd_yscroll;
wire [9:0] hpos_off = (hpos - hblank_end) + lcd_xscroll;
wire [9:0] vpos_wrap = vpos_off > 169 && lcd_xscroll < 8'h1C ? vpos_off - 10'd170 : vpos_off;
wire [7:0] hpos_div_4 = hpos_off[9:2];
wire [13:0] vram_addr_t = (vpos_wrap * 8'h30) + hpos_div_4;

// The lcd does a weird trunction of any extra bits past the end of it's buffer to make the 192x170
// dimensions work, while the memory is 8kb. This is intentionally truncated to 12 bits.

assign vram_addr = vram_addr_t > 14'h1FE0 ? (vram_addr_t + 8'h40) : vram_addr_t[12:0];

initial begin
	hblank_end = 8'd70;
	vblank_end = 8'd51;
	vpos = 0;
	hpos = 0;
	lcd_xsize = 8'd160;
	lcd_ysize = 8'd160;
	frame_len = 20'd78719;
end

assign ce_pix = ce;

reg [7:0] vb;

wire hblank_im = hpos <= hblank_end || hpos > hblank_end + PHYS_WIDTH;
wire vblank_im = vpos < vblank_end || vpos >= vblank_end + PHYS_HEIGHT;
assign vsync = vpos < 2 || vpos > V_HEIGHT - 1'd1; // Catch the uneven line in vsync to see if it helps
assign hsync = hpos < 16 || hpos > (h_w - 8'd16);


always_ff @(posedge clk) begin
	reg old_compat;
	if (ce) begin
		old_compat <= compat60;
		hblank <= hblank_im;
		vblank <= vblank_im;
		pixel <= lcd_off_latch ? 2'b00 : vram_data[{hpos_off[1:0], 1'b1}-:2];

		if (lcd_off)
			lcd_off_latch <= 1;

		dot_count <= dot_count + 1'd1;
		hpos <= hpos + 1'd1;
		if (hpos == (h_w - 1'd1)) begin
			hpos <= 0;
			vpos <= vpos + 1'd1;
		end

		// Synchronize with real frame, we'll see how it goes.
		if ((compat60 ?
			(hpos == (h_w - 1'd1) && vpos == (V_HEIGHT - 1'd1)) :
			(dot_count >= frame_len)
			) || (old_compat != compat60)) begin
			hpos <= 0;
			vpos <= 0;
			dot_count <= 0;
			hblank_end <= (h_w - PHYS_WIDTH) >> 1'd1;
			vblank_end <= (V_HEIGHT - PHYS_HEIGHT) >> 1'd1;
			lcd_off_latch <= lcd_off;
			frame_len <= ((lcd_xsize[7:2] + 1'd1) * lcd_ysize * 12) - 1'd1;
		end

		if (lcd_cs && ~cpu_rwn) begin
			case(AB)
				6'h00, 6'h04: lcd_xsize <= dbus_in;
				6'h01, 6'h05: lcd_ysize <= dbus_in;
				6'h02, 6'h06: lcd_xscroll <= dbus_in;
				6'h03, 6'h07: lcd_yscroll <= dbus_in;
			endcase
		end
	end

	if (reset) begin
		lcd_xscroll <= 0;
		lcd_yscroll <= 0;
		hblank_end <= (h_w - lcd_xsize) >> 1'd1;
		vblank_end <= (V_HEIGHT - lcd_ysize) >> 1'd1;
		lcd_off_latch <= 1;
		// Do not reset these registers intentionally
		// lcd_xsize <= 8'd160;
		// lcd_ysize <= 8'd160;
	end
end

endmodule