/**************************************************************
	FPGA Jungler (Main part)
***************************************************************/
module jng_top
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
	output  [10:0]	SND,			// Sound (unsigned PCM)
	input   [7:0]	DSW1,			// DipSW
	input   [7:0]	DSW2,			// DipSW
	input	  [7:0]	CTR1,			// Controler (Negative logic)
	input	  [7:0]	CTR2
);


//--------------------------------------------------
//  Clock Generators
//--------------------------------------------------
reg [2:0] _CCLK;
always @( posedge CLK24M ) _CCLK <= _CCLK+1;

wire	CLK    = CLK24M;		// 24MHz
wire	CCLKx4 = _CCLK[0];	// CPU CLOCKx4 : 12.0MHz
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


reg			out1r  = 1'b0;
reg			out2r  = 1'b0;
reg			out3r  = 1'b0;
reg 			sonr  = 1'b0;//sound On

wire			vblk  = (VP==224)&(HP<=8);

wire			lat_Wce = ( ad[15:4] == 12'hA18 ) & mw;

wire			sndw = ( lat_Wce & ( ad[3:0] == 4'h0 ) );
wire			iewr = ( lat_Wce & ( ad[3:0] == 4'h1 ) );
wire			mute = ( lat_Wce & ( ad[3:0] == 4'h1 ) );//mute
wire			flip = ( lat_Wce & ( ad[3:0] == 4'h3 ) );//flip
wire			out1w = ( lat_Wce & ( ad[3:0] == 4'h4 ) );
//wire			out2w = ( lat_Wce & ( ad[3:0] == 4'h5 ) );//NOP
wire			out3w = ( lat_Wce & ( ad[3:0] == 4'h6 ) );
//wire			starw = ( lat_Wce & ( ad[3:0] == 4'h7 ) );//not used
wire			iowr = ( (~wr) & (~ie) & m1 );


always @( posedge CCLK ) begin
	if ( iowr ) intv <= odt;
	if ( vblk ) intl <= 1'b1;
	if ( iewr ) begin
		inte <= odt[0];
		intl <= 1'b0; 
	end
	if ( sndw ) sonr <= odt[0];
	if ( out1w ) out1r <= odt[0];
//	if ( out2w ) out2r <= odt[0];
	if ( out3w ) out3r <= odt[0];
end

wire	irq_n = ~( intl & inte );


// address decoders
wire	rom_Rce = ( ( ad[15] == 1'b0        ) & mr );		   // $0000-$7FFF(R)
wire	ram_Rce = ( ( ad[15:11] == 5'b1001_1    ) & mr );		// $9800-$9FFF(R)
wire	ram_Wce = ( ( ad[15:11] == 5'b1001_1    ) & mw );		// $9800-$9FFF(W)
wire	inp_Rce = ( ( ad[15:12] == 4'b1010      ) & mr );		// $A000-$AFFF(R)
wire	snd_Wce = ( ( ad[15:8]  == 8'b1010_0001 ) & mw );		// $A100-$A1FF(W)
wire	vid_Rce;


wire [7:0]	romdata;
jng_prg_rom jng_prg_rom (
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
wire [7:0]  in2data = DSW1;
wire [7:0]  in3data = DSW2;
wire [7:0]  inpdata = (ad[8:7] == 2'b11) ? in3data : (ad[8:7] == 2'b10) ? in2data : (ad[8:7] == 2'b01) ? in1data : in0data;
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
	.INT_n(1'b1),
	.NMI_n(irq_n),
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

jng_video video( 
	.VCLKx4(CLK),  
	.HPOS(HP+3), 
	.VPOS(VP+1), 
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
	
jng_hvgen hvgen(
	.HPOS(HP),
	.VPOS(VP),
	.PCLK(PCLK),
	.HBLK(hblank),
	.VBLK(vblank),
	.HSYN(hsync),
	.VSYN(vsync)
	);

//--------------------------------------------------
//  SOUND //ToDo
//--------------------------------------------------
jng_sound jng_sound(
	.clock_12(CCLKx4),
	.reset(RESET), 
	.sound_req(sonr),
	.sound_code_in(odt),
	.sound_timing(snd_Wce),
	.audio_out(SND)
  );

endmodule
