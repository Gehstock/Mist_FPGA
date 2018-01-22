module MAX(
	input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,	 
   output        LED,
   output        AUDIO_L,
   output        AUDIO_R,	
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
	input         SPI_SS4,
   input         CONF_DATA0

	);
	
`include "build_id.sv" 
	 
localparam CONF_STR = {
		  "Commodore MAX;e0;",
		  "O2,SID Filter,On,Off;",
		  "O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
		  "T5,Reset;",
		  "V,v0.0.",`BUILD_DATE
		};	
	
wire clk_cpu, clk_sid, clk_ce, phi0_cpu;	
wire locked;
wire        scandoubler_disable;
wire        ypbpr;
wire        ps2_kbd_clk, ps2_kbd_data;
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;


reg [7:0] reset_cnt;
always @(posedge clk_cpu) begin
	if(!locked || buttons[1] || status[0] || status[5])// | dio_download)
		reset_cnt <= 8'h0;
	else if(reset_cnt != 8'd255)
		reset_cnt <= reset_cnt + 8'd1;
end 

wire reset = (reset_cnt != 8'd255);

wire [15:0]ADDR_BUS;	
wire [15:0]VIC_ADDR_BUS;	
tri [7:0]DATA_BUS;	
wire BA;
wire RW;
wire nRW_PLA;
wire nRAM;
wire nEXTRAM;
wire nVIC;
wire nSID;
wire nCIA_PLA;
wire nCIA;
wire nROML;
wire nROMH;
wire nCOLRAM;
wire nIRQ;
wire nNMI;
wire BUF;
wire AEC;

// Video
wire hs, vs;
wire [5:0]r, g, b;
wire [17:0]audio;	
//EXPANSIONS PORT
wire SP;
wire CNT;
//Joystick
wire [7:0]JoyA,JoyB;


wire [7:0]CPU_DI;
wire [7:0]CPU_DO;
wire [7:0]cpuIO;
//CIA 
wire [7:0]CIA_DO;
//VIC
wire [7:0]VIC_DO;
wire [3:0]VIC_ColIndex;
//Main RAM
wire [7:0]RAM_DO;
//Color RAM
wire [3:0]COL_DI;
wire [3:0]COL_DO;
wire [3:0]COL_rDO;
//SID
wire [7:0]SID_DO;
//CARD
wire [7:0]CARD_DO;
wire [7:0]cia_pai;
wire [7:0]cia_pao;
wire [7:0]cia_pbi;
wire [7:0]cia_pbo;

wire enableCPU, enableCIA, enableVIC = 1;
wire enablePixel;
wire pulseRd;

pll pll(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_cpu),//32
	.c1(clk_sid),//1
	.c2(clk_ce),//8
	.c3(phi0_cpu),//todo
	.locked(locked)
	);	
	
mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.conf_str(CONF_STR),
	.clk_sys(clk_cpu),
	.SPI_SCK(SPI_SCK),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SS2(SPI_SS2),
	.SPI_DO(SPI_DO),
	.SPI_DI(SPI_DI),
	.buttons(buttons),
	.switches(switches),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.status(status),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data),
	.joystick_0(JoyA),
	.joystick_1(JoyB)
);

video_mixer #(.LINE_LENGTH(600), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk_cpu),
	.ce_pix(clk_ce),
	.ce_pix_actual(clk_ce),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.scandoubler_disable(1),//scandoubler_disable),
	.hq2x(status[4:3]==1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.R(r),
	.G(g),
	.B(b),
	.mono(0),
	.HSync(hs),
	.VSync(vs),
	.line_start(0),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);
	
sigma_delta_dac sigma_delta_dac
(	
	.DACout(AUDIO_L),
	.DACin(audio),
	.CLK(clk_cpu),
	.RESET(0)
);

assign AUDIO_R = AUDIO_L;
	
//CPU MOS6510
cpu_6510 U5 (
	.clk(clk_cpu),
	.reset(reset),
	.enable(enableCPU),
	.nmi_n(nNMI),
	.nmi_ack(),	
	.irq_n(nIRQ),
	.CPUdi(CPU_DI),
	.CPUdo(CPU_DO),
	.addr(ADDR_BUS),
	.we(RW),
	.doIO(cpuIO),
	.diIO("00010111")
	);

//PLA	MOS6703
pla_6703 pla_6703 (
	.A(ADDR_BUS[15:10]),
	.CLK(clk_cpu),
	.BA(BA),
	.RW_IN(~RW),
	.RAM(nRAM), 						//invert
	.EXRAM(nEXTRAM), 					//invert
	.VIC(nVIC),  						//invert
	.SID(nSID),  						//invert
	.CIA(nCIA_PLA),					//invert
	.COLRAM(nCOLRAM),  				//invert
	.ROML(nROML),  					//invert
	.ROMH(nROMH), 						//invert
	.BUF(BUF),							//not invert
	.RW_OUT(nRW_PLA)  					//invert
	);	

	
always@(posedge clk_cpu) begin
	if (~nRW_PLA) begin
		if (~nRAM) begin 
			RAM_DO =CPU_DI;
		if (~nVIC) begin 
			VIC_DO =CPU_DI;
		end
		end
	end
	if (~RW) begin
		if (~nSID) begin 
			SID_DO =CPU_DI;
		end
	//	if (~nCARD) begin 
//			CARD_DO =CPU_DI;
//		end
		if (~nCIA_PLA) begin 
			CIA_DO =CPU_DI;
		end		
	end
	COL_DO = COL_rDO ? (BUF & ~nCOLRAM) : 4'b0;
end	



//COLRAM 1024x4
COLRAM U11 (
	.address(ADDR_BUS[9:0]),
	.clock(clk_cpu),
	.data(CPU_DO),
	.rden(~nCOLRAM),
	.wren(~nRW_PLA),
	.q(COL_rDO)
	);

//MAINRAM 2048x8
MAINRAM U6 (
	.address(ADDR_BUS[10:0]),
	.clock(clk_cpu),
	.data(CPU_DO),
	.rden(~nRAM),
	.wren(~nRW_PLA),
	.q(CPU_DI)
	);	


//VIC MOS6566
vic_656x vic_656x (
	.clk(clk_cpu),
	.phi(phi0_cpu),// phi = 0 is VIC cycle-- phi = 1 is CPU cycle (only used by VIC when BA is low)
	.enaData(enablePixel),
	.enaPixel(enableVIC),
	.baSync(0),
	.ba(BA),
	.mode6569(0),// PAL 63 cycles and 312 lines
	.mode6567old(1),// old NTSC 64 cycles and 262 line
	.mode6567R8(0),// new NTSC 65 cycles and 263 line
	.mode6572(0),// PAL-N 65 cycles and 312 lines
	.reset(reset),
	.cs(~nVIC),
	.we(~nRW_PLA),
	.rd(pulseRd),
	.lp_n(),
	.aRegisters(DATA_BUS[5:0]),
	.diRegisters(CPU_DO),
	.datai(CPU_DO),
	.diColor(COL_DO),
	.datao(VIC_DO),
	.vicAddr(VIC_ADDR_BUS[13:0]),
	.irq_n(nIRQ),
	.hSync(hs),
	.vSync(vs),
	.colorIndex(VIC_ColIndex),
	.debugX(),
	.debugY(),
	.vicRefresh(),
	.addrValid()
	);

fpga64_rgbcolor fpga64_rgbcolor (
	.index(VIC_ColIndex),
	.r(r),
	.g(g),
	.b(b)
	);

//CIA MOS6526
cia_6526 cia_6526 (
	.clk(clk_cpu),
	.todClk(vs),
	.reset(reset),
	.enable(enableCIA),
	.cs(~nCIA),
	.we(~RW),
	.rd(pulseRd),
	.addr(ADDR_BUS[3:0]),
	.CIAdi(CPU_DO),
	.CIAdo(CIA_DO),
	.ppai(cia_pai),//Keyboard
	.ppao(cia_pao),//Keyboard
	.ppbi(cia_pbi),//Keyboard
	.ppbo(cia_pbo),//Keyboard
	.flag_n(1),
	.sp(SP),
	.cnt(CNT),
	.irq_n(~nIRQ)
	);
	
//SID MOS6581
sid_6581 sid_6581 (
	.clk32(clk_cpu),
	.clk_1MHz(clk_sid),
	.reset(reset),   	
	.cs(~nSID),
   .we(~RW),
	.addr({4'b0,ADDR_BUS[3:0]}),
   .data_i(CPU_DO),
   .data_o(SID_DO),
   .poti_x(~(cia_pao[7] & JoyA[5]) | (cia_pao[6] & JoyB[5])),//todo
   .poti_y(~(cia_pao[7] & JoyA[6]) | (cia_pao[6] & JoyB[6])),//todo   
   .audio_data(audio)
	);
	
cart cart(
	.clk0(clk_cpu),
	.addr(ADDR_BUS),
	.data_i(CPU_DO),
	.data_o(CART_DO),
	.nmi(nNMI),
   .reset(reset),
	.romL(nROML),
	.romH(nROMH),
	.rw_pla_n(nRW_PLA),
	.ba(BA),
	.cia_pla_n(nCIA_PLA),
	.cia_n(nCIA),
	.cnt(CNT),
	.exram_n(nEXTRAM),
	.sp(SP),
	.rw_n(RW),
	.irq_n(nIRQ)
	);
	
endmodule 