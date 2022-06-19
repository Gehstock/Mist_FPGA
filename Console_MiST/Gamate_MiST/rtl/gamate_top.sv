module gamate_top
(
	input           clk,
	input           reset,
	input           biostype,
	input [7:0]     joystick,
	input [7:0]     cart_dout,
	input [21:0]    rom_size,
	output [21:0]   rom_addr,
	output          rom_read,
	output [15:0]   audio_right,
	output [15:0]   audio_left,
	output          hsync,
	output          hblank,
	output          ce_pix,
	output          vsync,
	output          vblank,
	output [1:0]    pixel
);

reg [14:0] irq_timer;
reg [1:0] audio_div;
reg [1:0] sys_div;
reg [7:0] cp_data;
reg [3:0] cp_count;
reg [7:0] cart_bank, four_bank;
reg [1:0] card_present;
reg irq_n = 1;
reg phi_toggle;
reg [7:0] open_bus = 8'h00;
reg [9:0] clear_addr;

wire nmi_n;
wire phi1, phi2;
wire lcd_oe;
wire [7:0] lcd_dout, controller_dout, wram_dout, cpu_dout, audio_dout;
wire cpu_rwn, bus_rwn;
wire [7:0] read_bus, write_bus;
wire [15:0] cpu_addr, AB, AB_minus_6k;
wire [7:0] audio_r, audio_l, audio_c;

wire wram_cs           = AB < 16'h2000;
//wire peripheral_cs     = AB >= 16'h2000 && AB < 16'h4000;

wire audio_cs          = AB >= 16'h4000 && AB < 16'h4400;
wire controller_cs     = AB >= 16'h4400 && AB < 16'h4800;
wire uart_rx_cs        = AB >= 16'h4800 && AB < 16'h4C00;
// wire uart_tx_shift_cs  = AB[15:10] == 6'b0100_11;

wire lcd_cs            = AB >= 16'h5000 && AB < 16'h5400;
//wire ext_cs            = AB >= 16'h5400 && AB < 16'h5800;

// I'm not sure what these are for, but I think they check to see if a
// cart is present. Reading once from 5800 seems to cause 5A00 return 0x03 instead of 0x01.
// Without these, the bios read fails and the system doesn't boot.
wire card_avail_set_cs = AB == 16'h5800; // && AB < 16'h5900;
//wire card_reset_cs     = AB == 16'h5900; // && AB < 16'h5A00;
wire card_avail_ck_cs  = AB == 16'h5A00; // && AB < 16'h5B00;

wire bios_cs           = AB >= 16'hE000;
wire cart_cs           = AB >= 16'h6000 && AB < 16'hE000;
wire bank_cs           = AB >= 16'hA000 && AB < 16'hE000;

assign bus_rwn = cpu_rwn;
assign nmi_n = 1;
assign AB_minus_6k = AB - 16'h6000;
assign AB = cpu_addr;

// input from top: {start, select, a, b, down, up, left, right}
// output to system: {select, start, b, a, right, left, down, up}
assign controller_dout = ~{joystick[6], joystick[7], joystick[4], joystick[5], joystick[0],
	joystick[1], joystick[2], joystick[3]};

// Note this reads excessively, but sdram will decay if not polled often, and some games
// have so long between reads that this can occur. The things you learn the hard way.
assign rom_read = ~phi1;

// No roms I could find attempted to set the lower bank that weren't four-in-one, so hopefully it is
// safe to allow four-in-one registers to be active for everything, so no quirk system will be required.
assign rom_addr = {bank_cs ? (~|rom_size[21:15] ? 8'd1 : cart_bank) : four_bank, AB_minus_6k[13:0]};

assign audio_right = {{1'b0, audio_r, 1'b0} + audio_c, 5'd0};
assign audio_left = {{1'b0, audio_l, 1'b0} + audio_c, 5'd0};
assign write_bus = cpu_dout;
assign phi1 = phi_toggle && sys_ce;
assign phi2 = ~phi_toggle && sys_ce;
wire sys_ce = &sys_div;
wire audio_ce = sys_ce & &audio_div;

always_comb begin
	read_bus = open_bus;
	if (~cpu_rwn)
		read_bus = cpu_dout;
	else if (wram_cs)
		read_bus = wram_dout;
	else if (audio_cs)
		read_bus = audio_dout;
	else if (controller_cs)
		read_bus = controller_dout;
	else if (uart_rx_cs)
		read_bus = 8'h00;
	else if (lcd_cs)
		read_bus = lcd_oe ? lcd_dout : open_bus;
	else if (card_avail_ck_cs)
		read_bus = {open_bus[7:2], card_present};
	else if (bios_cs)
		read_bus = bios_dout;
	else if (cart_cs)
		read_bus = cp_count[3] ? cart_dout : {6'd0, cp_data[7], 1'b0};
end

always_ff @(posedge clk) begin
	sys_div <= sys_div + 1'd1;
	clear_addr <= clear_addr + 1'd1;

	if (sys_ce) begin
		audio_div <= audio_div + 1'd1;
		phi_toggle <= ~phi_toggle;

		if (phi1) begin
			// We shift out the data 0x47 one bit at a time as bit 1, for copy protection
			if (~cp_count[3] && cart_cs && AB == 16'h6000) begin
				if (bus_rwn) begin
					cp_count <= cp_count + 1'd1;
					cp_data <= {cp_data[6:0], 1'b0};
				end else begin // Assume previous reads were spurrious and reset the shift
					cp_count <= 0;
					cp_data <= 8'h47;
				end
			end
		end
		if (phi2) begin
			open_bus <= read_bus;
			if (~bus_rwn & cart_cs && cp_count[3]) begin
				if (AB_minus_6k == 16'h6000)
					cart_bank <= write_bus;
				else if (AB_minus_6k == 16'h2000)
					four_bank <= write_bus;
			end
			if (bus_rwn && card_avail_set_cs) begin
				card_present <= 2'b11;
			end
		end

		if (irq_n)
			irq_timer <= irq_timer + 1'd1;

		if (&irq_timer)
			irq_n <= 0;
			
		if (&AB || AB == 16'hFFFD)
			irq_n <= 1;
	end
	
	if (reset) begin
		card_present <= 2'b01;
		cart_bank <= 0;
		four_bank <= 0;
		cp_data <= 8'h47;
		cp_count <= 0;
		irq_n <= 1;
	end
end

spram #(.addr_width(10)) work_ram
(
	.clock      (clk),
	.address    (reset ? clear_addr : AB[9:0]),
	.data       (reset ? 8'hFF : write_bus),
	.wren       (reset || (wram_cs && ~bus_rwn && phi2)),
	.q          (wram_dout)
);

wire [7:0]     bios1_dout;
gamate_bios_umc  bios1(
	.clk			(clk),
	.addr			(AB[11:0]),
	.data			(bios1_dout)
);

wire [7:0]     bios2_dout;
gamate_bios_bit  bios2(
	.clk			(clk),
	.addr			(AB[11:0]),
	.data			(bios2_dout)
);

wire [7:0]     bios_dout = biostype ? bios1_dout :bios2_dout;

lcd lcd
(
	.clk        (clk),
	.ce         (sys_ce),
	.reset      (reset),
	.lcd_cs     (lcd_cs & phi1),
	.cpu_rwn    (bus_rwn),
	.AB         (AB[2:0]),
	.dbus_in    (write_bus),
	.dbus_out   (lcd_dout),
	.dbus_oe    (lcd_oe),
	.ce_pix     (ce_pix),
	.pixel      (pixel),
	.hsync      (hsync),
	.vsync      (vsync),
	.hblank     (hblank),
	.vblank     (vblank)
);

// This is a lightly modified version of this chip which takes address as input
// rather than the normal two-part address latching system.
YM2149 audio
(
	.CLK        (clk),
	.CE         (audio_ce),// Should be sysclk div 4
	.RESET      (reset),
	.BDIR       (~bus_rwn & audio_cs),
	.AI         (AB[3:0]),
	.DI         (write_bus),
	.DO         (audio_dout),
	.CHANNEL_A  (audio_l), // Left
	.CHANNEL_B  (audio_r), // Right
	.CHANNEL_C  (audio_c), // Center
	.SEL        (),
	.MODE       (0),       // AY style envelope mode
	.ACTIVE     (),
	.IOA_in     (),
	.IOA_out    (),
	.IOB_in     (),
	.IOB_out    ()
);

T65 cpu
(
	.Mode       (2'b00),
	.Res_n      (~reset),
	.Enable     (phi1),
	.Clk        (clk),
	.Rdy        (1),
	.Abort_n    (1),
	.IRQ_n      (irq_n),
	.NMI_n      (nmi_n),
	.SO_n       (1),
	.R_W_n      (cpu_rwn),
	.A          (cpu_addr),
	.DI         (read_bus),
	.DO         (cpu_dout)
);

endmodule

