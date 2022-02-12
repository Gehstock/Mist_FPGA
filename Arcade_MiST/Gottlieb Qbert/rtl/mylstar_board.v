module mylstar_board
(
  input         clk_sys,
  input         reset,
  input         pause,

  input         CPU_CORE_CLK,
  input         CPU_CLK,
  input         cen_5,
  input         cen_10_p,
  input         cen_10_n,

  output        HBlank,
  output        HSync,
  output        VBlank,
  output        VSync,

  output  [3:0] red,
  output  [3:0] green,
  output  [3:0] blue,

  input   [7:0] IP1710,
  input   [7:0] IP4740,
  input  [15:0] IPA1J2,
  output  [5:0] OP2720,
  output  [4:0] OP3337,
  output  [7:0] OP4740,
  output        trackball_reset, //op1

  input   [7:0] dip_switch,

  input         rom_init,
  input         nvram_init,
  input         nvram_upl,
  input  [17:0] rom_init_address,
  input   [7:0] rom_init_data,
  output  [7:0] nvram_data,
  input         bgram, // E11-12 writeable

  input vflip,
  input hflip,

  output [15:0] cpu_rom_addr,
  input   [7:0] cpu_rom_do,
  output [13:0] bg_rom_addr,
  input  [31:0] bg_rom_do
);


assign VSync = VBLANK;
//assign HSync = HBLANK; //original(?)
assign HSync = (H>270 && H<290);
assign HBlank = ~EXTH_nBLANK;
assign VBlank = VBLANK;
assign red = G13_Q;
assign green = G15_Q;
assign blue = G14_Q;
assign OP2720 = A10[5:0];
assign OP4740 = A9[7:0];
assign OP3337 = A8[4:0];
assign trackball_reset = op1_sel;

reg  CLK5;
wire IOM;
wire RD_n, WR_n;
wire [7:0] cpu_dout, C5_Q, C6_Q, C7_Q, C8_9_Q, C9_10_Q, C10_11_Q;
wire [7:0] C11_12_Q, C12_13_Q, C13_14_Q, C14_15_Q, C16_Q;
wire [3:0] D2_Y, D3_Y, D4_Y, D5_Y, D6_Y, D7_Y, D8_Y, D9_Y, D10_Y;
wire [19:0] addr;
wire J16_co, J17_co, F16_co, H5_co, H6_co;
wire [5:0] G16_Q, G17_Q;
reg [7:0] A8, A9, A10;
wire J13_Q1, J13_Q2, L10_Q1;
wire [7:0] E1_2_Q, E2_3_Q, E4_Q;
wire [3:0] F5_S, E5_S, D16_S, D13_Y;
wire [3:0] G1_Y, G2_Y, G3_Y, G4_Y, G5_Y, G7_Y, G9_Y;
wire [3:0] J1_Q, J2_Q, J3_Q, J4_Q, J5_Q, J6_Q, J10_Q, J11_Q;
wire [3:0] H5_Q, H6_Q, H7_Y, H8_Y, H9_Y, H10_Y, H13_Y;
reg  [3:0] H12_Y;
wire [3:0] K1_Q, K2_Q, K3_Q;
wire [3:0] L12_Q;
wire F5_C4;
wire G8_nQ1, G8_Q1, G8_nQ2;
wire [7:0] K4_D, K5_D, K6_D, K7_8_D;
reg  [7:0] G11_Q;
wire [3:0] K9_Y, K10_Y, K11_Y, G12_Y, G13_Q, G14_Q, G15_Q;
wire [7:0] E7_Q, E8_Ao, E8_Bo, E9_10_Bo, E10_11_Q, D11_Q, D12_Y, E11_12_Q, E13_Q;

wire nCOLSEL = ~(ram_io_ce & addr[12:11] == 2'b10);
wire nBOJRSEL1 = ~(ram_io_ce & ~addr[12]);
wire nBOJRWR = nBOJRSEL1 | WR_n; //F6_8
wire nBRSEL = ~BRSEL;
wire nFRSEL = ~FRSEL;
wire nBRWR = nBRSEL | WR_n; //F6_6
wire nFRWR = nFRSEL | WR_n; //F6_3
wire BANK_SEL = A8[4];
wire VERTFLOP = vflip ? ~A8[2]: A8[2];
wire HORIZFLIP = hflip ? ~A8[1]: A8[1];
wire FB_PRIORITY = A8[0];
wire BLANK = ~(H[8] | VBLANK);//J12_1
wire HBLANK = H[8];
wire VBLANK;  //~E17_8
wire nVBLANK = ~VBLANK;//E17_8
wire nVHBLANK = ~(nVBLANK & ~H[8]);//H14_3
wire SFBW = H[8] & nVBLANK;//K14_3
wire SBBW = ~H[8] & VBLANK & ~V[3];//K14_8
wire LATCH_CLK /* synthesis keep */;// K16_6;
reg  SHIFTED_HB;
reg  EXTH_nBLANK;
wire S3; //K16_8;
wire S5 = CLK5 | CLK10; //K13_8
wire RDY1; //J9_8;
reg  [8:0] H;
reg  [8:0] HH;
reg  [2:0] HHx;
wire [7:0] VV;
wire nHH0s = ~HHx[0]; //F15_12;
wire nH0 = ~H[0];     //F15_4
wire nVV0 = ~VV[0];   //K15_10

reg CLK10;

always @(posedge clk_sys) begin
	if (cen_10_p) CLK10 <= 1;
	if (cen_10_n) CLK10 <= 0;
end

////////////////////////
//    CPU/RAM/ROM     //
////////////////////////

wire [7:0] A1J2 = trackball0_sel ? IPA1J2[15:8] : 
                  trackball1_sel ? IPA1J2[7:0] : 8'd0;

wire [7:0] ram_dout = C5_Q | C6_Q | C7_Q | C9_10_Q | C8_9_Q | C10_11_Q;
wire [7:0] rom_dout;
wire [7:0] cpu_din = ram_dout | rom_dout | B11 | B12 | B14 | A1J2 | E8_Ao | BGRAMROM_DO;

always @(posedge clk_sys) begin : A8A9A10
	if (!WR_n) begin
		if (op2_sel) A10 <= cpu_dout;
		if (op3_sel) A8 <= cpu_dout;
		if (op4_sel) A9 <= cpu_dout;
	end
end

i8088 B1(
  .CORE_CLK(CPU_CORE_CLK),
  .CLK(CPU_CLK),
  .RESET(reset),
  .READY(RDY1 & ~pause & ~nvram_init & ~nvram_upl),
  .INTR(0),
  .NMI(VBLANK),
  .INTA_n(),
  .addr(addr),
  .dout(cpu_dout),
  .din(cpu_din),
  .IOM(IOM),
  .RD_n(RD_n),
  .WR_n(WR_n)
);

reg ram0_cs, ram1_cs, ram2_cs, ram3_cs, ram4_cs, ram5_cs, FRSEL, BRSEL;
always @(*) begin : B6
	ram0_cs = 0;
	ram1_cs = 0;
	ram2_cs = 0;
	ram3_cs = 0;
	ram4_cs = 0;
	ram5_cs = 0;
	FRSEL = 0;
	BRSEL = 0;
	if (~IOM & addr[15:14] == 2'b00)
		case (addr[13:11])
			3'd0: ram0_cs = 1;
			3'd1: ram1_cs = 1;
			3'd2: ram2_cs = 1;
			3'd3: ram3_cs = 1;
			3'd4: ram4_cs = 1;
			3'd5: ram5_cs = 1;
			3'd6: FRSEL = 1;
			3'd7: BRSEL = 1;
			default: ;
		endcase
end

reg rom0_ce, rom1_ce, rom2_ce, rom3_ce, rom4_ce, ram_io_ce;
always @(*) begin : B8
	rom0_ce = 0;
	rom1_ce = 0;
	rom2_ce = 0;
	rom3_ce = 0;
	rom4_ce = 0;
	ram_io_ce = 0;
	if (~IOM)
		case (addr[15:13])
			3'd2: ram_io_ce = 1; //4000-5FFF
			3'd3: rom4_ce = 1; //6000-7FFF
			3'd4: rom3_ce = 1; //8000-9FFF
			3'd5: rom2_ce = 1; //A000-BFFF
			3'd6: rom1_ce = 1; //C000-DFFF
			3'd7: rom0_ce = 1; //E000-FFFF
			default: ;
		endcase
end

reg wdcl, op1_sel, op2_sel, op3_sel, op4_sel;
always @(*) begin: B9
	// IO write selects
	wdcl = 0;
	op1_sel = 0;
	op2_sel = 0;
	op3_sel = 0;
	op4_sel = 0;
	if (~WR_n & ram_io_ce & addr[12:11] == 2'b11 & ~addr[3])
		case (addr[2:0])
			3'd0: wdcl = 1;
			3'd1: op1_sel = 1;
			3'd2: op2_sel = 1;
			3'd3: op3_sel = 1;
			3'd4: op4_sel = 1;
			default: ;
		endcase
end

reg dip_sel, IP1710_sel, IP4740_sel, trackball0_sel, trackball1_sel;
always @(*) begin : B10
	// IO read selects
	dip_sel = 0;
	IP1710_sel = 0;
	IP4740_sel = 0;
	trackball0_sel = 0;
	trackball1_sel = 0;
	if (~RD_n & ram_io_ce & addr[12:11] == 2'b11 & ~addr[3])
		case (addr[2:0])
			3'd0: dip_sel = 1;
			3'd1: IP1710_sel = 1;
			3'd2: trackball0_sel = 1;
			3'd3: trackball1_sel = 1;
			3'd4: IP4740_sel = 1;
			default: ;
		endcase
end

wire [7:0] B11 = IP1710_sel ? IP1710 : 8'd0;

wire [7:0] B12 = dip_sel ? dip_switch : 8'd0;

wire [7:0] B14 = IP4740_sel ? IP4740 : 8'd0;

// TODO: load from MRA and fill with $FF if empty
wire [10:0] nvram_addr = (nvram_init | nvram_upl) ? rom_init_address[10:0] : addr[10:0];
wire  [7:0] nvram_din = nvram_init ? rom_init_data : cpu_dout;
wire        nvram_nwr = nvram_init ? 1'b0 : WR_n;
wire        nvram_nrd = nvram_upl ? 1'b0 : RD_n;
assign      nvram_data = C5_Q | C6_Q;

wire [10:0] ramrom_addr = rom_init ? rom_init_address[10:0] : addr[10:0];
wire        ramrom_nwr = rom_init ? 1'b0 : WR_n;
wire  [7:0] ramrom_din = rom_init ? rom_init_data : cpu_dout;

// nvram 1 - 0000-07FF
ram #(.addr_width(11),.data_width(8)) C5 (
  .clk(clk_sys),
  .din(nvram_din),
  .addr(nvram_addr),
  .cs((nvram_init | nvram_upl) ? ~(rom_init_address < 18'h800) : ~ram0_cs),
  .oe(nvram_nrd),
  .wr(nvram_nwr),
  .Q(C5_Q)
);

// nvram 2 - 0800-0FFF
ram #(.addr_width(11),.data_width(8)) C6 (
  .clk(clk_sys),
  .din(nvram_din),
  .addr(nvram_addr),
  .cs((nvram_init | nvram_upl) ? ~(rom_init_address >= 18'h800 && rom_init_address < 18'h1000) : ~ram1_cs),
  .oe(nvram_nrd),
  .wr(nvram_nwr),
  .Q(C6_Q)
);

// RAM or ROM - 1000-17FF
ram #(.addr_width(11),.data_width(8)) C7 (
  .clk(clk_sys),
  .din(ramrom_din),
  .addr(ramrom_addr),
  .cs(rom_init ? ~(rom_init_address < 18'hA800) : ~ram2_cs),
  .oe(RD_n),
  .wr(ramrom_nwr),
  .Q(C7_Q)
);

// 1800-1FFF
ram #(.addr_width(11),.data_width(8)) C8_9 (
  .clk(clk_sys),
  .din(ramrom_din),
  .addr(ramrom_addr),
  .cs(rom_init ? ~(rom_init_address < 18'hB000) : ~ram3_cs),
  .oe(RD_n),
  .wr(ramrom_nwr),
  .Q(C8_9_Q)
);

// 2000-27FF
ram #(.addr_width(11),.data_width(8)) C9_10 (
  .clk(clk_sys),
  .din(ramrom_din),
  .addr(ramrom_addr),
  .cs(rom_init ? ~(rom_init_address < 18'hB800) : ~ram4_cs),
  .oe(RD_n),
  .wr(ramrom_nwr),
  .Q(C9_10_Q)
);

// 2800-2FFF
ram #(.addr_width(11),.data_width(8)) C10_11 (
  .clk(clk_sys),
  .din(ramrom_din),
  .addr(ramrom_addr),
  .cs(rom_init ? ~(rom_init_address < 18'hC000) : ~ram5_cs),
  .oe(RD_n),
  .wr(ramrom_nwr),
  .Q(C10_11_Q)
);

reg [15:0] CPU_addr;
always @(posedge clk_sys) CPU_addr <= addr[15:0];

`ifdef EXT_ROM
assign cpu_rom_addr = {~CPU_addr[15:13], CPU_addr[12:0]};
assign rom_dout = ((rom0_ce | rom1_ce | rom2_ce | rom3_ce | rom4_ce) & ~RD_n) ? cpu_rom_do : 8'h00;
`else
assign rom_dout = C11_12_Q | C12_13_Q | C13_14_Q | C14_15_Q | C16_Q;

dpram  #(.addr_width(13),.data_width(8)) C11_12 (
  .clk(clk_sys),
  .addr(CPU_addr[12:0]),
  .dout(C11_12_Q),
  .ce(~rom0_ce),
  .oe(~RD_n),
  .we(rom_init & rom_init_address < 18'h2000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram  #(.addr_width(13),.data_width(8)) C12_13 (
  .clk(clk_sys),
  .addr(CPU_addr[12:0]),
  .dout(C12_13_Q),
  .ce(~rom1_ce),
  .oe(~RD_n),
  .we(rom_init & rom_init_address < 18'h4000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram  #(.addr_width(13),.data_width(8)) C13_14 (
  .clk(clk_sys),
  .addr(CPU_addr[12:0]),
  .dout(C13_14_Q),
  .ce(~rom2_ce),
  .oe(~RD_n),
  .we(rom_init & rom_init_address < 18'h6000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram  #(.addr_width(13),.data_width(8)) C14_15 (
  .clk(clk_sys),
  .addr(CPU_addr[12:0]),
  .dout(C14_15_Q),
  .ce(~rom3_ce),
  .oe(~RD_n),
  .we(rom_init & rom_init_address < 18'h8000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram  #(.addr_width(13),.data_width(8)) C16 (
  .clk(clk_sys),
  .addr(CPU_addr[12:0]),
  .dout(C16_Q),
  .ce(~rom4_ce),
  .oe(~RD_n),
  .we(rom_init & rom_init_address < 18'ha000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);
`endif // EXT_ROM

////////////////////////
// Horizontal counter //
////////////////////////

always @(posedge clk_sys) begin : J16J17K17
	if (cen_10_p) CLK5 <= ~CLK5;
	if (cen_5) begin
		CLK5 <= 1;
		H <= H + 1'd1;
		if (H == 9'd317) H <= 0;
	end
end

wire K14_6 = ~&H[7:1] & ~H[8];

always @(posedge clk_sys) begin : J13
	if (cen_5) begin
		if (H[1:0] == 2'b01) begin // rising edge of H[1]
			EXTH_nBLANK <= ~HBLANK;
			SHIFTED_HB <= HBLANK;
		end
		if (~K14_6) EXTH_nBLANK <= 0;
	end
end

always @(posedge clk_sys) begin : G16G17
	if (cen_5) begin
		HH <= {K14_6, {8{HORIZFLIP}} ^ H[7:0]};
		HHx <= H[2:0];
	end
end

assign J13_Q1 = EXTH_nBLANK;

assign S3 = ~(H[2:0] == 3'b011 & ~CLK5);
assign LATCH_CLK = ~(H[2:0] == 3'b001 & ~CLK5);
wire LATCH_CLK_EN_N = cen_10_p & ~cen_5 & H[2:0] == 3'b001; // next cycle is LATCH_CLK = 0

////////////////////////
// Vertical counter   //
////////////////////////

reg [7:0] V, Vlatch;
always @(posedge clk_sys) begin : D17F16
	if (cen_5) begin
		if (H == 255) V <= V + 1'd1;
	end
end

always @(posedge clk_sys) begin : E16
	if (cen_5) begin
		if (~HH[8] & K14_6) Vlatch <= V; // rising edge of HH[8]
	end
end

assign VBLANK = &V[7:4];
assign D16_S = Vlatch[7:4] + VERTFLOP;

assign VV = {8{VERTFLOP}} ^ {D16_S, Vlatch[3:0]};

//////////////////////////
//  Foreground objects  //
//////////////////////////


wire [5:0] FGREG_addr = H[5:0];

wire [7:0] E1_2_dout;
assign E1_2_Q = ~(E1_2_dout - {hflip, 3'd0});
//vertical position reg
dpram #(.addr_width(10),.data_width(8)) E1_2(
  .clk(clk_sys),
  .addr(FGREG_addr),
  .dout(E1_2_dout),
  .ce(1'b0),
  .oe(1'b0),
  .we(~nFRWR & addr[0] & ~addr[1]),
  .waddr(addr[7:2]),
  .wdata(cpu_dout[7:0])
);

wire [7:0] E2_3_dout;
assign E2_3_Q = ~E2_3_dout;
//object select reg
dpram #(.addr_width(10),.data_width(8)) E2_3(
  .clk(clk_sys),
  .addr(FGREG_addr),
  .dout(E2_3_dout),
  .ce(1'b0),
  .oe(1'b0),
  .we(~nFRWR & ~addr[0] & addr[1]),
  .waddr(addr[7:2]),
  .wdata(cpu_dout[7:0])
);

wire [7:0] E4_dout;
assign E4_Q = ~(E4_dout + {vflip, 2'd0});
//horizontal position reg
dpram #(.addr_width(10),.data_width(8)) E4(
  .clk(clk_sys),
  .addr(FGREG_addr),
  .dout(E4_dout),
  .ce(1'b0),
  .oe(1'b0),
  .we(~nFRWR & ~addr[0] & ~addr[1]),
  .waddr(addr[7:2]),
  .wdata(cpu_dout[7:0])
);

wire [7:0] FRBD = VV[7:0] + E4_Q[7:0];

wire nENBUF = ~(nVBLANK & HBLANK & (&FRBD[7:4]));

// line RAM address counter
reg [4:0] linea;
always @(posedge clk_sys) begin : G6G8
	if (cen_5) begin
		if (~nENBUF) linea <= linea + 1'd1;
	end
	if (~HBLANK) linea <= 0;
end

wire S1 = VBLANK | ~HBLANK;

wire J8_3 = CLK5 | nENBUF;
wire H14_6 = ~(~H[1] & H[2]);

wire S2 = S1 ? H14_6 : J8_3; //G9b

wire [4:0] FBA = S1 ? H[7:3] : linea[4:0]; //G7-G9a
wire [7:0] HPD = S1 ? 8'hFF : E1_2_Q; //G1-G2
wire [7:0] PND = S1 ? 8'hFF : E2_3_Q; //G3-G4
wire [3:0] PLD = S1 ? 4'hF  : FRBD[3:0]; //G5

reg  [7:0] VPOSRAM[32];
reg  [7:0] VPOSRAM_DO;
always @(posedge clk_sys) begin : H1H2H3H4
	if (!S2) VPOSRAM[FBA] <= ~HPD;
	else VPOSRAM_DO <= VPOSRAM[FBA];
end

// line buffer address counter
reg  [7:0] LB;
always @(posedge clk_sys) begin : H5H6G8
	if (cen_10_n) begin
		if (~&LB) LB <= LB + 1'd1;
		if (!S3) LB <= VPOSRAM_DO;
	end
end

wire [7:0] LBAx = SHIFTED_HB ? 8'd0 : VV[0] ? HH[7:0] : LB; //H9-H7
wire [7:0] LBA  = SHIFTED_HB ? 8'd0 : VV[0] ? LB : HH[7:0]; //H10-H8

reg [11:0] HPOSRAM[32];
reg [11:0] HPOSRAM_DO;
always @(posedge clk_sys) begin : J1J2J3J4J5J6
	if (!S2) HPOSRAM[FBA] <= ~{PND, PLD};
	else HPOSRAM_DO <= HPOSRAM[FBA];
end

reg [11:0] RAx /* synthesis noprune */;
always @(posedge clk_sys) begin : K1K2K3
	if (LATCH_CLK_EN_N) RAx <= ~HPOSRAM_DO; // negedge of LATCH_CLK
end

// L11
wire nSRLD = ~(boons[2:0] == 3'b011); // L11_6
// wire L11_8 = ~(L12_Q[2] & 1'b1);

// "Boons counter"
reg  [3:0] boons;
always @(posedge clk_sys) begin : L12
	if (cen_10_n) begin
		boons <= boons + 1'd1;
		if (!LATCH_CLK) boons <= 0;
	end
end

wire [12:0] RA = { RAx, boons[3] };

//00000000 1100 0000 0000 0000
// K4,K5,K6,K7_8 addr_width(14), bit13 = BANK_SEL - fix me!
wire bit13 = BANK_SEL;
reg [13:0] FGROM_addr;
always @(posedge clk_sys) FGROM_addr <= {bit13,RA};

`ifdef EXT_ROM
assign bg_rom_addr = FGROM_addr;
assign K4_D = bg_rom_do[7:0];
assign K5_D = bg_rom_do[15:8];
assign K6_D = bg_rom_do[23:16];
assign K7_8_D = bg_rom_do[31:24];
`else
dpram #(.addr_width(14),.data_width(8)) K4(
  .clk(clk_sys),
  .addr(FGROM_addr),
  .dout(K4_D),
  .ce(1'b0),
  .oe(1'b0),
  .we(rom_init && rom_init_address < 18'h14000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram #(.addr_width(14),.data_width(8)) K5(
  .clk(clk_sys),
  .addr(FGROM_addr),
  .dout(K5_D),
  .ce(1'b0),
  .oe(1'b0),
  .we(rom_init && rom_init_address < 18'h18000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram #(.addr_width(14),.data_width(8)) K6(
  .clk(clk_sys),
  .addr(FGROM_addr),
  .dout(K6_D),
  .ce(1'b0),
  .oe(1'b0),
  .we(rom_init && rom_init_address < 18'h1C000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);

dpram #(.addr_width(14),.data_width(8)) K7_8(
  .clk(clk_sys),
  .addr(FGROM_addr),
  .dout(K7_8_D),
  .ce(1'b0),
  .oe(1'b0),
  .we(rom_init & rom_init_address < 18'h20000),
  .waddr(rom_init_address),
  .wdata(rom_init_data)
);
`endif

reg [7:0] SR1, SR2, SR3, SR4;
always @(posedge clk_sys) begin : L4_5_6_7_8
	if (cen_10_p) begin
		SR1 <= { SR1[6:0], 1'b0 };
		SR2 <= { SR2[6:0], 1'b0 };
		SR3 <= { SR3[6:0], 1'b0 };
		SR4 <= { SR4[6:0], 1'b0 };
		if (!nSRLD) begin
			SR1 <= K4_D;
			SR2 <= K5_D;
			SR3 <= K6_D;
			SR4 <= K7_8_D;
		end
	end
end

wire K13_11 = ~(SR4[7] | SR3[7] | SR2[7] | SR1[7]) | CLK10;
assign K9_Y = VV[0] ? { 1'b0, S5, 1'b0, K13_11 } : { 1'b0, K13_11, 1'b0, S5 };
assign K10_Y = nVV0  ? 4'd0 : {SR4[7], SR3[7], SR2[7], SR1[7]};
assign K11_Y = VV[0] ? 4'd0 : {SR4[7], SR3[7], SR2[7], SR1[7]};

// line buffers
ram #(.addr_width(8), .data_width(4)) J10(
  .clk(clk_sys),
  .din(K10_Y),
  .addr(LBA),
  .cs(1'b0),
  .oe(VV[0]),
  .wr(K9_Y[0]),
  .Q(J10_Q)
);

ram #(.addr_width(8), .data_width(4)) J11(
  .clk(clk_sys),
  .din(K11_Y),
  .addr(LBAx),
  .cs(1'b0),
  .oe(nVV0),
  .wr(K9_Y[2]),
  .Q(J11_Q)
);

wire [3:0] FOREVID = J10_Q | J11_Q;

//////////////////////////
//      Background      //
//////////////////////////

wire [7:0] E7_doutb;
dpram #(.addr_width(10),.data_width(8)) E7(
  .clk(clk_sys),
  .addr({ V[2:0], H[7:1] }),
  .dout(E7_Q),
  .ce(1'b0),
  // .oe(SBBW ? 1'b0 : RD_n), // ? no difference?
  .oe(1'b0),
  .we(~nBRWR),
  // .we(SBBW ? 1'b0 : ~nBRWR), // break test mode
  .waddr(addr[9:0]),
  .wdata(cpu_dout[7:0]),
  .doutb(E7_doutb)
);

assign E8_Ao = ~nBRSEL & ~RD_n ? E7_doutb : 8'd0;

dpram #(.addr_width(10),.data_width(8)) E10_11(
  .clk(clk_sys),
  .addr({ VV[7:3], HH[7:3] }),
  .ce(1'b0),
  .oe(nVHBLANK),
  .dout(E10_11_Q),
  .we(SBBW ? ~nH0: 1'b0), // fix rolling cube
  .waddr({ V[2:0], H[7:1] }),
  .wdata(E7_Q)
);

reg   [8:0] BGRAM_LATCH;
always @(posedge clk_sys) begin : D11L10
	if (cen_5) begin
		if (HHx[1:0] == 2'b01) begin // rising edge of HHx[1]
			BGRAM_LATCH <= { E10_11_Q[7:0], VV[2] };
		end
	end
end

wire BGA1 = ~HHx[2] ^ HH[1]; //F17_8

wire [12:0] E11_12_addr = {BGRAM_LATCH[8:0], VV[1:0], BGA1, ~HH[1]}; 

wire  [7:0] BGRAMROM_Q;
wire  [7:0] BGRAMROM_DO = nBOJRSEL1 ? 8'd0 : BGRAMROM_Q;

// This can be either RAM or ROM.
dpram  #(.addr_width(13),.data_width(8)) E11_12 (
  .clk(clk_sys),
  .addr(E11_12_addr),
  .dout(E11_12_Q),
  .ce(1'b0),
  //.ce(L10_Q1),
  .oe(1'b0),
  .we(rom_init ? rom_init_address < 18'h10000 : bgram & ~nBOJRWR),
  .waddr(rom_init ? rom_init_address : addr[12:0]),
  .wdata(rom_init ? rom_init_data : cpu_dout),
  .doutb(BGRAMROM_Q)
);

reg [7:0] LBV;
always @(posedge clk_sys) begin : G11
	if (cen_5) begin
		if (HH[0]) LBV <= E11_12_Q|E13_Q; // falling edge of HH[0]
	end
end

wire [3:0] BACKVID = nHH0s ? LBV[7:4] : LBV[3:0];

////////////////////////
// Final color output //
////////////////////////

wire J12_4 = ~(H11_5 | J12_10);
wire J12_10 = ~(H11_6 | FB_PRIORITY);
wire J12_13 = ~FB_PRIORITY;

wire H11_5 = ~(|BACKVID|J12_13);
wire H11_6 = ~(|FOREVID);

// fg/bg priority
always @(posedge clk_sys) begin : H12
	if (cen_10_p & CLK5) begin // falling edge of CLK5
		H12_Y <= J12_4 ? BACKVID : FOREVID;
	end
end

// G13, G14 & G15 are now dpram
wire F6_11 = nCOLSEL | WR_n;
wire J7_2 = ~F6_11;

// H14
wire H14_8 = ~(J7_2 & addr[0]);
wire H14_11 = ~(J7_2 & ~addr[0]);

dpram #(.addr_width(4),.data_width(4)) G13(
  .clk(clk_sys),
  .addr(H12_Y),
  .ce(1'b0),
  .oe(1'b0),
  .we(~H14_8),
  .waddr(addr[4:1]),
  .wdata(cpu_dout[3:0]),
  .dout(G13_Q)
);

dpram #(.addr_width(4),.data_width(4)) G14(
  .clk(clk_sys),
  .addr(H12_Y),
  .ce(1'b0),
  .oe(1'b0),
  .we(~H14_11),
  .waddr(addr[4:1]),
  .wdata(cpu_dout[3:0]),
  .dout(G14_Q)
);

dpram #(.addr_width(4),.data_width(4)) G15(
  .clk(clk_sys),
  .addr(H12_Y),
  .ce(1'b0),
  .oe(1'b0),
  .we(~H14_11),
  .waddr(addr[4:1]),
  .wdata(cpu_dout[7:4]),
  .dout(G15_Q)
);

////////////////////////////
//      Ready logic       //
////////////////////////////

// J8
wire J8_6 = J8_11 | nBRSEL;
wire J8_11 = V[3] | nVBLANK;

// K13
wire K13_6 = J13_Q1 | nFRSEL;

// J9
wire J9_8 = K13_6 & J8_6;

assign RDY1 = J9_8;

endmodule
