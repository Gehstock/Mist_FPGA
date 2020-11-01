/**************************************************************
	FPGA New Rally-X (Main part)
***************************************************************/
module fpga_nrx
(
	input         RESET,    // RESET
	input         CLK24M,   // Clock 24.576MHz
	input         CLK14M,   // For Time Pilot sound board (Konami games)
	input         mod_jungler,
	input         mod_loco,
	input         mod_tact,
	input         mod_comm,

	output        hsync,
	output        vsync,
	output        hblank,
	output        vblank,
	output  [2:0] r,
	output  [2:0] g,
	output  [1:0] b,

	output [14:0] cpu_rom_addr,
	input   [7:0] cpu_rom_data,

	output  [7:0] SND,   // Sound (unsigned PCM)

	input   [7:0] DSW1,  // DipSW
	input   [7:0] DSW2,
	input   [7:0] CTR1,  // Controler (Negative logic)
	input   [7:0] CTR2,

	output  [1:0] LAMP,

	input         ROMCL, // Downloaded ROM image
	input  [15:0] ROMAD,
	input   [7:0] ROMDT,
	input         ROMEN
);


//--------------------------------------------------
//  Clock Generators
//--------------------------------------------------
reg [2:0] _CCLK;
always @( posedge CLK24M ) _CCLK <= _CCLK+1'd1;

wire	CLK    = CLK24M;		// 24MHz
wire  CCLK_EN = _CCLK == 3'b011; // CPU CLOCK ENABLE  : 3.0MHz

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


wire			bngw = ( lat_Wce & ( ad[3:0] == 4'h0 ) );
wire			iewr = ( lat_Wce & ( ad[3:0] == 4'h1 ) );
//wire			flip = ( lat_Wce & ( ad[3:0] == 4'h3 ) );
wire			lp0w = ( lat_Wce & ( ad[3:0] == 4'h4 ) );
wire			lp1w = ( lat_Wce & ( ad[3:0] == 4'h5 ) );
wire			iowr = ( (~wr) & (~ie) & m1 );

always @( posedge CLK ) begin
	if (CCLK_EN) begin
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
end

wire	irq_n = ~( intl & inte );


// address decoders
wire rom_Rce = ( ( ad[15:14] == 2'b00        ) & mr );		// $0000-$3FFF(R)
wire rom_Rce2= ( ( ad[15:14] == 2'b01        ) & mr );		// $4000-$7FFF(R)
wire ram_Rce = ( ( ad[15:11] == 5'b1001_1    ) & mr );		// $9800-$9FFF(R)
wire ram_Wce = ( ( ad[15:11] == 5'b1001_1    ) & mw );		// $9800-$9FFF(W)
wire inp_Rce = ( ( ad[15:12] == 4'b1010      ) & mr );		// $A000-$AFFF(R)
wire lat_Wce = ( ad[15:3] == {12'hA18, 1'b0} ) & mw;      // $A180-$A187(W)
wire snd_Wce = ( ad[15:5] == {8'hA1, 3'b000} ) & mw;      // $A100-$A11F(W)
wire vid_Rce;

wire [7:0]	romdata;
assign cpu_rom_addr = ad[14:0];
assign romdata = cpu_rom_data;
/*
dpram #(8,14) nrx_prg_rom(
	.clk_a(CLK),
	.addr_a(ad[13:0]),
	.we_a(1'b0),
	.d_a(),
	.q_a(romdata),
	.clk_b(ROMCL),
	.addr_b(ROMAD),
	.we_b(ROMEN & (ROMAD[15:14]==2'b00)),
	.d_b(ROMDT),
	.q_b()
	);

wire [7:0]	romdata2;
dpram #(8,13) nrx_prg_rom2(
	.clk_a(CLK),
	.addr_a(ad[12:0]),
	.we_a(1'b0),
	.d_a(),
	.q_a(romdata2),
	.clk_b(ROMCL),
	.addr_b(ROMAD),
	.we_b(ROMEN & (ROMAD[15:13]==3'b010)),
	.d_b(ROMDT),
	.q_b()
	);
*/
// Work RAM (2KB)
wire [7:0] ramdata;
spram #(8,11) workram(
	.clk(CLK),
	.addr(ad[10:0]),
	.we(ram_Wce),
	.d(odt),
	.q(ramdata)
	);

// Controler/DipSW input
wire [7:0]  in0data = CTR1;
wire [7:0]  in1data = CTR2;
wire [7:0]  in2data = DSW1;
wire [7:0]  in3data = DSW2;
wire [7:0]  inpdata = ad[8] ? ((mod_jungler & ad[7]) ? in3data : in2data) : ad[7] ? in1data : in0data;


// databus selector
wire [7:0]  romd  = rom_Rce ? romdata : 8'h00;
wire [7:0]  romd2 = rom_Rce2? romdata : 8'h00;
wire [7:0]  ramd  = ram_Rce ? ramdata : 8'h00;
wire [7:0]  vidd  = vid_Rce ? viddata : 8'h00;
wire [7:0]  inpd  = inp_Rce ? inpdata : 8'h00;
wire [7:0]  irqv  = ( (~m1) & (~ie) ) ? intv : 8'h00;

wire [7:0]  idt   = romd | romd2 | ramd | irqv | vidd | inpd;


T80s z80(
	.RESET_n(~RESET), 
	.CLK(CLK),
	.CEN(CCLK_EN),
	.WAIT_n(1'b1), 
	.INT_n(irq_n |  mod_jungler), 
	.NMI_n(irq_n | ~mod_jungler), 
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
wire 				PCLK_EN;

nrx_video video( 
	.VCLKx4(CLK),
	.mod_jungler(mod_jungler),
	.mod_loco(mod_loco),
	.mod_tact(mod_tact),
	.mod_comm(mod_comm),
	.HPOS(HP+3), 
	.VPOS(VP+1), 
	.PCLK_EN(PCLK_EN),
	.POUT({b,g,r}), 
	.CPUADDR(ad),
	.CPUDI(odt),   
	.CPUDO(viddata),
	.CPUME(mx),    
	.CPUWE(mw), 
	.CPUDT(vid_Rce),
	.ROMCL(ROMCL),
	.ROMAD(ROMAD),
	.ROMDT(ROMDT),
	.ROMEN(ROMEN)
	);
	
nrx_hvgen hvgen(
	.CLK(CLK),
	.HPOS(HP),
	.VPOS(VP),
	.PCLK_EN(PCLK_EN),
	.HBLK(hblank),
	.VBLK(vblank),
	.HSYN(hsync),
	.VSYN(vsync)
	);

//--------------------------------------------------
//  SOUND
//--------------------------------------------------
wire  [7:0] nrx_snd;
wire [10:0] timepilot_snd;
reg   [7:0] timepilot_snd_dat;
reg   [2:0] timepilot_snd_trig;

always @(posedge CLK)	begin
	if (RESET)
		timepilot_snd_dat <= 0;
	else if (snd_Wce) 
		timepilot_snd_dat <= odt;
end

always @(posedge CLK14M) timepilot_snd_trig = {bang, timepilot_snd_trig[2:1]};

assign SND = mod_jungler ? timepilot_snd[10:3] : nrx_snd;

nrx_sound sound(
	.CLK24M(CLK),
	.SND(nrx_snd),
	.AD(ad),
	.DI(odt[3:0]),
	.WR(snd_Wce & ~mod_jungler),
	.BANG(bang & ~mod_jungler),
	.ROMCL(ROMCL),
	.ROMAD(ROMAD),
	.ROMDT(ROMDT),
	.ROMEN(ROMEN)
	);

time_pilot_sound_board sound2(
	.clock_14(CLK14M),
	.reset(RESET),
	.audio_out(timepilot_snd),
	.sound_cmd(timepilot_snd_dat),
	.sound_trig(timepilot_snd_trig[0]),
	.ROMCL(ROMCL),
	.ROMAD(ROMAD[12:0]),
	.ROMDT(ROMDT),
	.ROMEN(ROMEN & (ROMAD[15:13]==3'b011)) // 6000-7FFF
	);

endmodule
