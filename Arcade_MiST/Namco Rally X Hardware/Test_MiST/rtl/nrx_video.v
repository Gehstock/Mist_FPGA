/**************************************************************
	FPGA New Rally-X (Video Part)
***************************************************************/
module nrx_video
(
	input				 VCLKx4,		// 24.976MHz

	input  [8:0]		HPOS,
	input  [8:0]		VPOS,
	output				PCLK,
	output reg [7:0]	POUT,

	input					CPUCLK,
	input	 [15:0]		CPUADDR,
	input	 [7:0]		CPUDI,
	output [7:0]		CPUDO,
	input					CPUME,
	input					CPUWE,
	output				CPUDT
);

//-----------------------------------------
//  Clock generators
//-----------------------------------------
reg VCLKx2;
always @( posedge VCLKx4 ) begin
	VCLKx2 <= ~VCLKx2;
end

reg VCLK;
always @( posedge VCLKx2 ) begin
	VCLK   <= ~VCLK;
end

//-----------------------------------------
//  BG scroll registers
//-----------------------------------------
reg [7:0] BGHSCR;
reg [7:0] BGVSCR;

always @ ( posedge CPUCLK ) begin
	if ( ( CPUADDR == 16'hA130 ) & CPUME & CPUWE ) begin
		BGHSCR <= CPUDI-3;
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

wire oHB = ( HPOS > 288 ) ? 1 : 0;
wire oVB = ( VPOS > 224 ) ? 1 : 0;


//----------------------------------------
//  VideoRAM Scanner
//----------------------------------------
wire				BF	= ( HPOS >= 224 );
wire	[8:0]		HP  = BF ? HPOS : BGHPOS;
wire	[8:0]		VP  = ( BF ? VPOS : BGVPOS ) + 9'h0F;

wire	[10:0]	SPRAADRS;
wire	[3:0]		ARAMADRS;

reg	[10:0]	VRAMADRS;
always @ ( HPOS ) begin
	VRAMADRS <= oHB ? 
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

GDPRAM #(11,8) vram0( VCLKx4, VRAMADRS, CHRC, CPUCLK, CPUADDR[10:0], ( CPUWE & CEV0 ), CPUDI, V0DO );  
/*dpram #(
	.widthad_a(11),
	.width_a(8))
vram0(
	.address_a(VRAMADRS),
	.address_b(CPUADDR[10:0]),
	.clock_a(VCLKx4),
	.clock_b(CPUCLK),
	.data_a(),
	.data_b(CPUDI),
	.wren_a(),
	.wren_b(( CPUWE & CEV0 )),
	.q_a(CHRC),
	.q_b(V0DO)
	);*/
	
GDPRAM #(11,8)	vram1( VCLKx4, VRAMADRS, ATTR, CPUCLK, CPUADDR[10:0], ( CPUWE & CEV1 ), CPUDI, V1DO ); 
/*dpram #(
	.widthad_a(11),
	.width_a(8))
vram1(
	.address_a(VRAMADRS),
	.address_b(CPUADDR[10:0]),
	.clock_a(VCLKx4),
	.clock_b(CPUCLK),
	.data_a(),
	.data_b(CPUDI),
	.wren_a(),
	.wren_b(( CPUWE & CEV1 )),
	.q_a(ATTR),
	.q_b(V1DO)
	); */
GDPRAM #(4,8)	aram0( VCLKx4, ARAMADRS, ARDT, CPUCLK, CPUADDR[3:0],  ( CPUWE & CEAT ), CPUDI );
/*dpram #(
	.widthad_a(8),
	.width_a(4))
aram0(
	.address_a(ARAMADRS),
	.address_b(CPUADDR[3:0]),
	.clock_a(VCLKx4),
	.clock_b(CPUCLK),
	.data_a(),
	.data_b(CPUDI),
	.wren_a(),
	.wren_b(( CPUWE & CEAT )),
	.q_a(ARDT),
	.q_b()
	); */
	
wire				BGF = ATTR[5];


//----------------------------------------
//  BG/Sprite chip data reader
//----------------------------------------
wire				BGFX = ATTR[6];
wire	[2:0]		BGFY = { ATTR[7], ATTR[7], ATTR[7] };

wire	[11:0]	SPCHRADR;
wire	[11:0]	CHRA = oHB ? SPCHRADR : { CHRC, ( HP[2] ^ BGFX ), ( VP[2:0] ^ BGFY ) };

wire	[7:0]		CHRO;
jng_chr_rom chrrom(
	.clk(VCLKx4),
	.addr(CHRA), 
	.data(CHRO)
);

//----------------------------------------
//  Rader-dot chip ROM
//----------------------------------------
wire  [7:0] 	DROMAD;
wire  [7:0] 	DROMDT;
jng_dot_rom dotrom(
	.clk(VCLKx4),
	.addr(DROMAD), 
	.data(DROMDT)
	);

//----------------------------------------
//  BG/FG scanline generator
//----------------------------------------
wire [5:0] BGPL = ATTR[5:0];
reg  [7:0] BGCOL;

always @ ( posedge VCLK ) begin
	case ( HP[1:0]^{2{BGFX}} )
		2'b00: BGCOL <= { BGPL, CHRO[4], CHRO[0] };
		2'b01: BGCOL <= { BGPL, CHRO[5], CHRO[1] };
		2'b10: BGCOL <= { BGPL, CHRO[6], CHRO[2] };
		2'b11: BGCOL <= { BGPL, CHRO[7], CHRO[3] };
	endcase
end	


//----------------------------------------
//  Sprite Engine
//----------------------------------------
wire [8:0] SPCOL;
NRX_SPRITE speng( 
	.VCLKx4(VCLKx4), 
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
wire bBGOPAQUE = ( ( BF | BGF ) & (~SPCOL[8]) );
wire bSPTRANSP = ( SPCOL[1:0] == 2'b00 );

wire	[7:0]		OUTCOL = ( bBGOPAQUE | bSPTRANSP ) ? BGCOL : SPCOL[7:0];
wire	[3:0]		CLUT;
jng_col_rom colrom(
	.clk(~VCLKx4),
	.addr(OUTCOL), 
	.data(CLUT)
	);

wire	[4:0]		PALA = SPCOL[8] ? SPCOL[4:0] : { 1'b0, CLUT };
wire	[7:0]		PALO;

jng_pal_rom palrom(
	.clk(VCLKx4),
	.addr(PALA), 
	.data(PALO)
	);

//----------------------------------------
//  Color output
//----------------------------------------
always @ ( posedge PCLK ) POUT <= (oHB|oVB) ? 8'h0 : PALO;
assign PCLK = VCLK;


endmodule
