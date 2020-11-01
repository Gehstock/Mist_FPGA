/**************************************************************
	FPGA New Rally-X (Video Part)
***************************************************************/
module nrx_video
(
	input				  VCLKx4,		// 24.976MHz
	input         mod_jungler,
	input         mod_loco,
	input         mod_tact,
	input         mod_comm,

	input   [8:0] HPOS,
	input   [8:0] VPOS,
	output        PCLK_EN,
	output reg [7:0] POUT,

	input  [15:0] CPUADDR,
	input   [7:0] CPUDI,
	output  [7:0] CPUDO,
	input         CPUME,
	input         CPUWE,
	output        CPUDT,

	input         ROMCL,
	input  [15:0] ROMAD,
	input   [7:0] ROMDT,
	input         ROMEN
);

//-----------------------------------------
//  Clock generators
//-----------------------------------------
reg [1:0] VCLK_CNT;
wire      VCLKx2_EN;
always @(posedge VCLKx4) VCLK_CNT <= VCLK_CNT + 1'd1;
assign PCLK_EN = VCLK_CNT == 2'b00;
assign VCLKx2_EN = !VCLK_CNT[0];

//-----------------------------------------
//  BG scroll registers
//-----------------------------------------
reg [7:0] BGHSCR;
reg [7:0] BGVSCR;

always @ ( posedge VCLKx4 ) begin
	if ( ( CPUADDR == 16'hA130 ) & CPUME & CPUWE ) begin
		BGHSCR <= CPUDI-3'd3;
	end
	if ( ( CPUADDR == 16'hA140 ) & CPUME & CPUWE ) begin
		BGVSCR <= CPUDI;
	end
end


//-----------------------------------------
//  HV
//-----------------------------------------
wire [8:0] BGHPOS = HPOS + { 1'b0, BGHSCR };
wire [8:0] BGVPOS = VPOS + { 1'b0, BGVSCR };

wire oHB = HPOS > 291;
wire oVB = VPOS > 224;


//----------------------------------------
//  VideoRAM Scanner
//----------------------------------------
wire        BF = ( HPOS >= 227 );
wire  [8:0] HP = ( BF ? HPOS : BGHPOS ) - 2'd3;
wire  [8:0] VP = ( BF ? VPOS : BGVPOS ) + 9'h0F;

wire [10:0] SPRAADRS;
wire  [3:0] ARAMADRS;

reg  [10:0] VRAMADRS;
always @ ( * ) begin
	VRAMADRS = oHB ? 
		SPRAADRS :
		BF ? { 1'b0, VP[7:3], 2'b00, HP[5:3] } : { 1'b1, VP[7:3], HP[7:3] };
end

wire	[7:0]		CHRC;
wire	[7:0]		ATTR;
wire	[7:0]		ARDT;

wire	[7:0]		V0DO, V1DO;

wire				CEV0	= ( ( CPUADDR[15:12] == 4'b1000 ) & (~CPUADDR[11]) ) & CPUME;
wire				CEV1	= ( ( CPUADDR[15:12] == 4'b1000 ) &   CPUADDR[11]  ) & CPUME;
wire				CEAT  = (   CPUADDR[15:4]  == 12'b1010_0000_0000         ) & CPUME;

wire	[7:0]		DTV0	= CEV0 ? V0DO : 8'h00;
wire	[7:0]		DTV1	= CEV1 ? V1DO : 8'h00;

assign			CPUDO = DTV0 | DTV1;
assign			CPUDT = ( ~CPUWE ) & ( CEV0 | CEV1 );

dpram #(8,11)
vram0(
	.clk_a(VCLKx4),
	.addr_a(VRAMADRS),
	.we_a(1'b0),
	.d_a(),
	.q_a(CHRC),

	.clk_b(VCLKx4),
	.addr_b(CPUADDR[10:0]),
	.we_b(( CPUWE & CEV0 )),
	.d_b(CPUDI),
	.q_b(V0DO)
	);

dpram #(8,11)
vram1(
	.clk_a(VCLKx4),
	.addr_a(VRAMADRS),
	.we_a(1'b0),
	.d_a(),
	.q_a(ATTR),

	.clk_b(VCLKx4),
	.addr_b(CPUADDR[10:0]),
	.we_b(CPUWE & CEV1),
	.d_b(CPUDI),
	.q_b(V1DO)
	);

dpram #(8,4)
aram0(
	.clk_a(VCLKx4),
	.addr_a(ARAMADRS),
	.we_a(1'b0),
	.d_a(),
	.q_a(ARDT),

	.clk_b(VCLKx4),
	.addr_b(CPUADDR[3:0]),
	.we_b(CPUWE & CEAT),
	.d_b(CPUDI),
	.q_b()
	);

wire				BGF = ATTR[5];

//----------------------------------------
//  BG/Sprite chip data reader
//----------------------------------------
wire         BGFX = mod_loco ? ~ATTR[7] : ATTR[6];
wire   [2:0] BGFY = { ATTR[7], ATTR[7], ATTR[7] };

wire  [12:0] SPCHRADR;
wire  [12:0] CHRA = oHB ? SPCHRADR : { mod_loco? {CHRC[7], ATTR[6], CHRC[6:0]} : {1'b0, CHRC}, ( HP[2] ^ BGFX ), ( VP[2:0] ^ BGFY ) };

wire	[7:0]		CHRO;
dpram #(8,13) chrrom (
	.clk_a(VCLKx4),
	.addr_a(CHRA),
	.we_a(1'b0),
	.d_a(),
	.q_a(CHRO),

	.clk_b(ROMCL),
	.addr_b(ROMAD[12:0]),
	.we_b(ROMEN & (ROMAD[15:13]==3'b100)), //8000-9FFF
	.d_b(ROMDT),
	.q_b()
	);

//----------------------------------------
//  Rader-dot chip ROM
//----------------------------------------
wire  [7:0] 	DROMAD;
wire  [7:0] 	DROMDT;
dpram #(8,8) dotrom (
	.clk_a(VCLKx4),
	.addr_a(DROMAD),
	.we_a(1'b0),
	.d_a(),
	.q_a(DROMDT),

	.clk_b(ROMCL),
	.addr_b(ROMAD[7:0]),
	.we_b(ROMEN & (ROMAD[15:8]==8'hA0)),
	.d_b(ROMDT),
	.q_b()
	);

//----------------------------------------
//  BG/FG scanline generator
//----------------------------------------
wire [5:0] BGPL = ATTR[5:0];
reg  [7:0] BGCOL;

always @ ( posedge VCLKx4 ) begin
	if (PCLK_EN) begin
		case ( { mod_jungler, HP[1:0]^{2{BGFX}} } )
			3'b000: BGCOL <= { BGPL, CHRO[4], CHRO[0] };
			3'b001: BGCOL <= { BGPL, CHRO[5], CHRO[1] };
			3'b010: BGCOL <= { BGPL, CHRO[6], CHRO[2] };
			3'b011: BGCOL <= { BGPL, CHRO[7], CHRO[3] };

			3'b100: BGCOL <= { BGPL, CHRO[0], CHRO[4] };
			3'b101: BGCOL <= { BGPL, CHRO[1], CHRO[5] };
			3'b110: BGCOL <= { BGPL, CHRO[2], CHRO[6] };
			3'b111: BGCOL <= { BGPL, CHRO[3], CHRO[7] };
		endcase
	end
end	


//----------------------------------------
//  Sprite Engine
//----------------------------------------
wire [8:0] SPCOL;
NRX_SPRITE speng( 
	.VCLKx4(VCLKx4),
	.VCLKx2_EN(VCLKx2_EN),
	.VCLK_EN(PCLK_EN),
	.mod_jungler(mod_jungler),
	.mod_loco(mod_loco),
	.mod_tact(mod_tact),
	.mod_comm(mod_comm),
	.HBLK(oHB),
	.HPOS(HPOS), 
	.VPOS(VPOS),
	.SPRAADRS(SPRAADRS), 
	.SPRADATA({ ATTR, CHRC }), 
	.ARAMADRS(ARAMADRS), 
	.ARAMDATA(ARDT), 
	.SPCHRADR(SPCHRADR), 
	.SPCHRDAT(CHRO), 
	.DROMAD(DROMAD), 
	.DROMDT(DROMDT), 
	.SPCOL(SPCOL) 
	);


//----------------------------------------
//  Color mixer
//----------------------------------------
wire bBGOPAQUE = ~mod_jungler & ( BF | BGF ) & ~SPCOL[8];
wire bSPTRANSP = ( SPCOL[1:0] == 2'b00 );

wire	[7:0]		OUTCOL = ( bBGOPAQUE | bSPTRANSP ) ? BGCOL : SPCOL[7:0];
wire	[3:0]		CLUT;

dpram #(4,8) colrom (
	.clk_a(~VCLKx4),
	.addr_a(OUTCOL),
	.we_a(1'b0),
	.d_a(),
	.q_a(CLUT),

	.clk_b(ROMCL),
	.addr_b(ROMAD[7:0]),
	.we_b(ROMEN & (ROMAD[15:8]==8'hA2)),
	.d_b(ROMDT[3:0]),
	.q_b()
	);

wire	[4:0]		PALA = SPCOL[8] ? SPCOL[4:0] : { 1'b0, CLUT };
wire	[7:0]		PALO;

dpram #(8,5) palrom (
	.clk_a(VCLKx4),
	.addr_a(PALA),
	.we_a(1'b0),
	.d_a(),
	.q_a(PALO),

	.clk_b(ROMCL),
	.addr_b(ROMAD[4:0]),
	.we_b(ROMEN & (ROMAD[15:5]=={8'hA3,3'b000})),
	.d_b(ROMDT),
	.q_b()
	);

//----------------------------------------
//  Color output
//----------------------------------------
always @ ( posedge VCLKx4 ) if (PCLK_EN) POUT <= (oHB|oVB) ? 8'h0 : PALO;

endmodule
