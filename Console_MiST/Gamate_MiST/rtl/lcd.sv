module lcd
(

	input           clk,
	input           ce,
	input           reset,
	input           lcd_cs,
	input           cpu_rwn,
	input [2:0]     AB,
	input [7:0]     dbus_in,
	output [7:0]    dbus_out,
	output          dbus_oe,
	output          ce_pix,
	output reg [1:0]pixel,
	output          hsync,
	output          vsync,
	output reg      hblank,
	output reg      vblank
);

// frame_len = 72900 cycles at 4.433mhz
localparam H_WIDTH = 9'd282;
localparam V_HEIGHT = 9'd259;
localparam LCD_XSIZE = 9'd160;
localparam LCD_YSIZE = 9'd150;
localparam FRAME_LEN = 72900;

reg [7:0] lcd_ctl, xscroll, yscroll, xpos;
reg [8:0] hblank_start, hblank_end, vblank_start, vblank_end, vpos, hpos;
integer dot_count;
wire [7:0] vram_buf_high, vram_buf_low, vram_high_dout, vram_low_dout;

wire [7:0] yscroll_adj = yscroll > 8'hC7 ? 8'h00 : yscroll;

wire ram_write = AB == 7 && ~cpu_rwn && lcd_cs;
wire [12:0] draw_addr;
reg [12:0] vram_addr;
wire plane = xpos[7];

dpram #(.addr_width(13)) vram_high
(
	.clock      (clk),
	.address_a  (vram_addr),
	.data_a     (dbus_in),
	.q_a        (vram_high_dout),
	.wren_a     ((lcd_ctl[4] ? ~plane : plane) & ram_write),

	.address_b  (draw_addr),
	.q_b        (vram_buf_high)
);

dpram #(.addr_width(13)) vram_low
(
	.clock      (clk),
	.address_a  (vram_addr),
	.data_a     (dbus_in),
	.q_a        (vram_low_dout),
	.wren_a     ((lcd_ctl[4] ? plane : ~plane) & ram_write),

	.address_b  (draw_addr),
	.q_b        (vram_buf_low)
);

assign dbus_out = (lcd_ctl[4] ? ~plane : plane) ? vram_high_dout : vram_low_dout;

wire hblank_im = hpos <= hblank_end || hpos > hblank_end + LCD_XSIZE;
wire vblank_im = vpos < vblank_end || vpos >= vblank_end + LCD_YSIZE;
assign vsync = vpos < 2 || vpos > V_HEIGHT - 1'd1; // Catch the uneven line in vsync to see if it helps
assign hsync = hpos < 16 || hpos > (H_WIDTH - 8'd16);

// There is a complex quirky "mode2" that no games use that is not implemented. There's no software
// with which to test it, so it's really pointless unless someone makes some homebrew or something
// that wants to draw graphics in this way.
wire in_window = lcd_ctl[5] && (vpos - vblank_end) < 16; // Account for window mode
wire [8:0] vpos_off = (vpos - vblank_end) + (in_window ? 8'hD0 : yscroll_adj);
wire [8:0] hpos_off = (hpos - hblank_end) + (in_window ? 8'h00 : xscroll);

wire [8:0] vpos_wrap = vpos_off > 199 && ~in_window ? vpos_off - 8'd200 : vpos_off;

assign draw_addr = (vpos_wrap * 8'h20) + (hpos_off >> 3);
assign ce_pix = ce;
assign dbus_oe = AB == 6;

always_ff @(posedge clk) begin
	if (ce) begin
		hblank <= hblank_im;
		vblank <= vblank_im;
		pixel <= lcd_ctl[7] ? 2'b00 : {vram_buf_high[~hpos_off[2:0]], vram_buf_low[~hpos_off[2:0]]};
		dot_count <= dot_count + 1'd1;
		hpos <= hpos + 1'd1;

		if (hpos == (H_WIDTH - 1'd1)) begin
			hpos <= 0;
			vpos <= vpos + 1'd1;
		end

		// Synchronize with real frame, we'll see how it goes. This assumes 160x160.
		if (dot_count == FRAME_LEN) begin
			hpos <= 0;
			vpos <= 0;
			dot_count <= 0;
			hblank_end <= (H_WIDTH - LCD_XSIZE) >> 1'd1;
			vblank_end <= (V_HEIGHT - LCD_YSIZE) >> 1'd1;
		end
		
		if (lcd_cs) begin
			if (~cpu_rwn) begin
				case(AB)
					6'h01: lcd_ctl <= dbus_in;
					6'h02: xscroll <= dbus_in;
					6'h03: yscroll <= dbus_in;
					6'h04: begin xpos <= dbus_in; vram_addr[4:0] <= dbus_in[4:0]; end
					6'h05: begin vram_addr[12:5] <= dbus_in; end
					6'h07: vram_addr <= vram_addr + (lcd_ctl[6] ? 6'd32 : 1'd1);
				endcase
			end else begin
				if (AB == 6'h06)
					vram_addr <= vram_addr + (lcd_ctl[6] ? 6'd32 : 1'd1);
			end
		end
	end

	if (reset) begin
		xscroll <= 0;
		yscroll <= 0;
		vram_addr <= 0;
		xpos <= 0;
		hblank_end <= (H_WIDTH - LCD_XSIZE) >> 1'd1;
		vblank_end <= (V_HEIGHT - LCD_YSIZE) >> 1'd1;
		lcd_ctl <= 0;
	end
end

endmodule