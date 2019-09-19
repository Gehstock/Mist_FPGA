/**************************************************************
	FPGA New Rally-X (Main part)
***************************************************************/
module fpga_nrx
(
	input				RESET,		// RESET
	input				CLK24M,		// Clock 24.576MHz
	output			hsync,
	output			vsync,
	output			hblank,
	output			vblank,
	output  [2:0]	r,
	output  [2:0]	g,
	output  [1:0]	b,
	

	output  [7:0]	SND,			// Sound (unsigned PCM)

	input   [7:0]	DSW,			// DipSW
	input	  [7:0]	CTR1,			// Controler (Negative logic)
	input	  [7:0]	CTR2,

	output  [1:0]	LAMP
);


//--------------------------------------------------
//  Clock Generators
//--------------------------------------------------
reg [2:0] _CCLK;
always @( posedge CLK24M ) _CCLK <= _CCLK+1;

wire	CLK    = CLK24M;		// 24MHz
//wire	CCLKx2 = _CCLK[1];	// CPU CLOCKx2 : 6.0MHz
wire	CCLK   = _CCLK[2];	// CPU CLOCK   : 3.0MHz


//--------------------------------------------------
//  CPU
//--------------------------------------------------
// memory access signals
wire			rd, wr, me, ie, rf, m1;
wire [15:0] ad;
wire [7:0]  odt, viddata;

wire			mx      = rf & (~me);
wire			mr		  = mx & (~rd);
wire			mw      = mx & (~wr);

// interrupt signal/vector generator & other latches
reg			inte  = 1'b0;
reg			intl  = 1'b0;
reg  [7:0]	intv  = 8'h0;

reg			bang  = 1'b0;

reg			lp0r  = 1'b0;
reg			lp1r  = 1'b0;
assign		LAMP  = { lp1r, lp0r };

wire			vblk  = (VP==224)&(HP<=8);

wire			lat_Wce = ( ad[15:4] == 12'hA18 ) & mw;

wire			bngw = ( lat_Wce & ( ad[3:0] == 4'h0 ) );
wire			iewr = ( lat_Wce & ( ad[3:0] == 4'h1 ) );
//wire			flip = ( lat_Wce & ( ad[3:0] == 4'h3 ) );
wire			lp0w = ( lat_Wce & ( ad[3:0] == 4'h4 ) );
wire			lp1w = ( lat_Wce & ( ad[3:0] == 4'h5 ) );
wire			iowr = ( (~wr) & (~ie) & m1 );

always @( posedge CCLK ) begin
	if ( iowr ) intv <= odt;
	if ( vblk ) intl <= 1'b1;
	if ( iewr ) begin
		inte <= odt[0];
		intl <= 1'b0; 
	end
	if ( bngw ) bang <= odt[0];
	if ( lp0w ) lp0r <= odt[0];
	if ( lp1w ) lp1r <= odt[0];
end

wire	irq_n = ~( intl & inte );


// address decoders
wire	rom_Rce = ( ( ad[15:14] == 2'b00        ) & mr );		// $0000-$3FFF(R)
wire	ram_Rce = ( ( ad[15:11] == 5'b1001_1    ) & mr );		// $9800-$9FFF(R)
wire	ram_Wce = ( ( ad[15:11] == 5'b1001_1    ) & mw );		// $9800-$9FFF(W)
wire	inp_Rce = ( ( ad[15:12] == 4'b1010      ) & mr );		// $A000-$AFFF(R)
wire	snd_Wce = ( ( ad[15:8]  == 8'b1010_0001 ) & mw );		// $A100-$A1FF(W)
wire	vid_Rce;


wire [7:0]	romdata;
nrx_prg_rom nrx_prg_rom (
	.clk(CCLK),
	.addr(ad[13:0]),
	.data(romdata)
);

// Work RAM (2KB)
wire [7:0] ramdata;
GSPRAM #(11,8) workram( 
	.CL(CCLK), 
	.AD(ad[10:0]), 
	.WE(ram_Wce), 
	.DI(odt), 
	.DO(ramdata) 
	);


// Controler/DipSW input
wire [7:0]  in0data = CTR1;
wire [7:0]  in1data = CTR2;
wire [7:0]  in2data = DSW;
wire [7:0]  inpdata = ad[8] ? in2data : ad[7] ? in1data : in0data;


// databus selector
wire [7:0]	romd  = rom_Rce ? romdata : 8'h00;
wire [7:0]  ramd  = ram_Rce ? ramdata : 8'h00;
wire [7:0]  vidd  = vid_Rce ? viddata : 8'h00;
wire [7:0]	inpd  = inp_Rce ? inpdata : 8'h00;
wire [7:0]	irqv  = ( (~m1) & (~ie) ) ? intv : 8'h00;

wire [7:0]	idt   = romd | ramd | irqv | vidd | inpd;


T80s z80(
	.RESET_n(~RESET), 
	.CLK_n(CCLK),
	.WAIT_n(1'b1), 
	.INT_n(irq_n), 
	.NMI_n(1'b1), 
	.BUSRQ_n(1'b1), 
	.DI(idt),
	.M1_n(m1), 
	.MREQ_n(me), 
	.IORQ_n(ie), 
	.RD_n(rd), 
	.WR_n(wr), 
	.RFSH_n(rf), 
	.HALT_n(), 
	.BUSAK_n(),
	.A(ad),
	.DO(odt)
	);

//--------------------------------------------------
//  VIDEO
//--------------------------------------------------
wire	 [8:0]	HP;
wire   [8:0]	VP;
wire 				PCLK;

nrx_video video( 
	.VCLKx4(CLK),  
	.HPOS(HP+22), 
	.VPOS(VP-5), 
	.PCLK(PCLK), 
	.POUT({b,g,r}), 
	.CPUCLK(CCLK), 
	.CPUADDR(ad),
	.CPUDI(odt),   
	.CPUDO(viddata),
	.CPUME(mx),    
	.CPUWE(mw), 
	.CPUDT(vid_Rce)
	);
	
nrx_hvgen hvgen(
	.HPOS(HP),
	.VPOS(VP),
	.PCLK(PCLK),
	.HBLK(hblank),
	.VBLK(vblank),
	.HSYN(hsync),
	.VSYN(vsync)
	);

//--------------------------------------------------
//  SOUND
//--------------------------------------------------

nrx_sound sound(
	.CLK24M(CLK), 
	.CCLK(CCLK), 
	.SND(SND),
	.AD(ad[4:0]), 
	.DI(odt[3:0]),
	.WR(snd_Wce),
	.BANG(bang)
	);

endmodule
