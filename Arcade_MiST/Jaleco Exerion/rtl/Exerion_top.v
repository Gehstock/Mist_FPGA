//============================================================================
//  Arcade: Exerion
//
//  Manufaturer: Jaleco 
//  Type: Arcade Game
//  Genre: Shooter
//  Orientation: Vertical
//
//  Hardware Description by Anton Gale
//  https://github.com/antongale/EXERION
//
//============================================================================
`timescale 1ns/1ps

module Exerion_top(
	input clkm_20MHZ,
	input	clkaudio,
	output [2:0] RED,     	//from fpga core to sv
	output [2:0] GREEN,		//from fpga core to sv
	output [2:0] BLUE,		//from fpga core to sv
	output H_SYNC,				//from fpga core to sv
	output V_SYNC,				//from fpga core to sv
	output H_BLANK,
	output V_BLANK,
	input RESET_n,				//from sv to core, check implementation
	input pause,
	input [8:0] CONTROLS,	
	input [7:0] DIP1,
	input [7:0] DIP2,
	input [24:0] dn_addr,
	input 		 dn_wr,
	input [7:0]  dn_data,
	output reg [15:0] audio_l, //from jt49_1 .sound
	output reg [15:0] audio_r,  //from jt49_2 .sound	
	output [14:0] cpu_rom_addr,
	input [7:0] cpu_rom_do,
	output [13:0] spr_rom_addr,
	input [7:0] spr_rom_do,		
	input [15:0] hs_address,
	output [7:0] hs_data_out,
	input [7:0] hs_data_in,
	input hs_write
);

//pixel counters
reg [8:0] pixH = 9'b000000000;
reg [7:0] pixV = 8'b00000000;
reg [8:0] sppixH = 9'b000000000;
reg [7:0] sppixV = 8'b00000000;

wire [8:0] rpixelbusH;
wire [7:0] rpixelbusV;

wire [8:0] pixelbusH;
wire [7:0] pixelbusV;
wire [10:0] vramaddr;
wire RAMA_WR,RAMB_WR; 

wire VID_A,VID_B; 		//layer selection bits

wire ZA3,ZA2,ZA1,ZA0;	//layer A output (tile)
reg  ZB3,ZB2,ZB1,ZB0;	//layer B output (sprite)
wire ZC3,ZC2,ZC1,ZC0;	//layer C output (background)

wire 	U7L_Q3,U7L_Q2,U7L_Q1,U7L_Q0;
wire 	U8K_1,U8K_2;
wire 	[7:0] u6k_data;
reg 	[7:0] u7K_data;
wire 	[7:0] vramdata0in;
reg 	[7:0] vramdata0out;
wire 	[7:0] U6N_VRAM_Q;
wire 	ic2a_1q;
wire 	ic2a_2q;
wire 	ic2b_1q;
wire 	ic2b_2nq;
wire 	clk_phase2;

wire clk1_10MHZ,clk2_6MHZ,clk2_6AMHZ,clk3_3MHZ,clk4_6BMHZ;
wire spclk1_10MHZ,spclk2_6MHZ,spclk3_3MHZ,spclk4_6BMHZ;

wire PUR = 1'b1;
wire H4CA;
wire U9M_B_nq,U9M_B_q;

wire SNHI,SSEL;

wire U9S_Q7,U9S_Q6,U9S_Q5,U9S_Q4,U9S_Q3,U9S_Q2,U9S_Q1,U9S_Q0;
wire U9R_Q7,U9R_Q6,U9R_Q5,U9R_Q4,U9R_Q3,U9R_Q2,U9R_Q1,U9R_Q0;
wire bgU9R_Q7,bgU9R_Q6,bgU9R_Q5,bgU9R_Q4,bgU9R_Q3,bgU9R_Q2,bgU9R_Q1,bgU9R_Q0;

wire [15:0] Z80A_addrbus;
wire [7:0] Z80A_databus_in;
wire [7:0] Z80A_databus_out;

wire [15:0] Z80B_addrbus;
wire [7:0] Z80B_databus_in;
wire [7:0] Z80B_databus_out;

//duplicate clocks for each layer
//tile & main CPU clock
wire U2A_Aq,U2A_Anq,U2A_Aqi;
wire U2A_Bq,U2A_Bnq,U2A_Bqi;
wire U2B_Aq,U2B_Anq,U2B_Aqi;
wire U2B_Bq,U2B_Bnq,U2B_Bqi;

//background
wire U3A_Aq,U3A_Anq,U3A_Aqi;
wire U3A_Bq,U3A_Bnq,U3A_Bqi;
wire U3B_Aq,U3B_Anq,U3B_Aqi;
wire U3B_Bq,U3B_Bnq,U3B_Bqi;

//sprites
wire spU2A_Aq,spU2A_Anq,spU2A_Aqi;
wire spU2A_Bq,spU2A_Bnq,spU2A_Bqi;
wire spU2B_Aq,spU2B_Anq,spU2B_Aqi;

ls107 spU2A_B(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(spU2A_Anq|!PUR), 
   .k(spU2A_Anq|!PUR), 
   .q(spU2A_Bq), 
   .qnot(spU2A_Bnq),
	.q_immediate(spU2A_Bqi)
);

ls107 spU2A_A(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(spU2A_Bq), 
   .k(PUR), 
   .q(spU2A_Aq), 
   .qnot(spU2A_Anq),
	.q_immediate(spU2A_Aqi)
);


ls107 spU2B_A(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(PUR), 
   .k(PUR), 
   .q(spU2B_Aq), 
   .qnot(spU2B_Anq),
	.q_immediate(spU2B_Aqi)
);

buf (spclk1_10MHZ,spU2B_Aq);
not (spclk2_6MHZ,spU2A_Aq);
buf (spclk4_6BMHZ,spU2A_Bq);

ls107 U2A_B(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(U2A_Anq|!PUR), 
   .k(U2A_Anq|!PUR), 
   .q(U2A_Bq), 
   .qnot(U2A_Bnq),
	.q_immediate(U2A_Bqi)
);

ls107 U2A_A(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(U2A_Bq), 
   .k(PUR), 
   .q(U2A_Aq), 
   .qnot(U2A_Anq),
	.q_immediate(U2A_Aqi)
);

ls107 U2B_B(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(U2A_Aq), 
   .k(U2A_Aq), 
   .q(U2B_Bq), 
   .qnot(U2B_Bnq),
	.q_immediate(U2B_Bqi)
);

ls107 U2B_A(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(PUR), 
   .k(PUR), 
   .q(U2B_Aq), 
   .qnot(U2B_Anq),
	.q_immediate(U2B_Aqi)
);

buf (clk1_10MHZ,U2B_Aq);
not (clk2_6MHZ,U2A_Aq);
buf (clk3_3MHZ,U2B_Bnq);
buf (clk4_6BMHZ,U2A_Bq);


wire Z80_MREQ,Z80_WR,Z80_RD;
wire Z80B_MREQ,Z80B_WR,Z80B_RD;
reg Z80_DO_En;

wire bgclk_6, bgclk_3;
wire bgclk_6_1,bgclk_6_2;

not (bgclk_6,U3A_Aq); 
buf (bgclk_3,U3B_Bnq);

//background clocks
ls107 U3A_B(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(U3A_Anq|!PUR), 
   .k(U3A_Anq|!PUR), 
   .q(U3A_Bq), 
   .qnot(U3A_Bnq),
	.q_immediate(U3A_Bqi)
);

ls107 U3A_A(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(U3A_Bqi), 
   .k(PUR), 
   .q(U3A_Aq), 
   .qnot(U3A_Anq),
	.q_immediate(U3A_Aqi)
);

ls107 U3B_B(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(U3A_Aqi), 
   .k(U3A_Aqi), 
   .q(U3B_Bq), 
   .qnot(U3B_Bnq),
	.q_immediate(U3B_Bqi)
);

ls107 U3B_A(
   .clear(PUR), 
   .clk(clkm_20MHZ), 
   .j(PUR), 
   .k(PUR), 
   .q(U3B_Aq), 
   .qnot(U3B_Anq),
	.q_immediate(U3B_Aqi)
);

//coin input
wire nCOIN;


//coin
ttl_7474 #(.BLOCKS(1), .DELAY_RISE(0), .DELAY_FALL(0)) U1D_A (
	.n_pre(PUR),
	.n_clr(PUR),
	.d(!m_coin),
	.clk(nVDSP),
	.q(),
	.n_q(nCOIN)
);

//First Z80 CPU responsible for main game logic, sound, sprites
T80as Z80A(
	.RESET_n(RESET_n),
	.WAIT_n(wait_n),
	.INT_n(PUR),
	.BUSRQ_n(PUR),
	.NMI_n(PUR&nCOIN), //+1 coin
	.CLK_n(clk3_3MHZ),
	.MREQ_n(Z80_MREQ),
	.DI(Z80A_databus_in),
	.DO(Z80A_databus_out),
	.A(Z80A_addrbus),
	.WR_n(Z80_WR),
	.RD_n(Z80_RD)
);

//Second Z80 CPU responsible for rendering the background graphic layers
T80as Z80B(
	.RESET_n(RESET_n),
	.WAIT_n(PUR),
	.INT_n(PUR),
	.BUSRQ_n(PUR),
	.NMI_n(PUR),
	.CLK_n(bgclk_3),
	.MREQ_n(Z80B_MREQ),
	.DI(Z80B_databus_in),
	.DO(Z80B_databus_out),
	.A(Z80B_addrbus),
	.WR_n(Z80B_WR),
	.RD_n(Z80B_RD)
);

ls139 U3RA(
	.a(Z80A_addrbus[13]),
   .b(Z80A_addrbus[14]),
  	.n_g(Z80A_addrbus[15]),
  	.y(U3RA_Q)
);

ls139 U3RB(
	.a(Z80A_addrbus[14]),
   .b(Z80A_addrbus[15]),
  	.n_g(Z80_MREQ),
  	.y(U3RB_Q)
);


wire [3:0] U3RA_Q;
wire [3:0] U3RB_Q;
wire Z80_RAM_en = !U3RA_Q[3];
wire Z80_B1_en = !(U3RA_Q[2] & U3RA_Q[1] & U3RA_Q[0]);

reg [7:0] rZ80A_databus_in;
reg [7:0] rZ80B_databus_in;

//joystick inputs from MiSTer framework
wire m_right  		= CONTROLS[0];
wire m_left   		= CONTROLS[1];
wire m_down   		= CONTROLS[2];
wire m_up     		= CONTROLS[3];
wire m_shoot  		= CONTROLS[4];
wire m_shoot2  	= CONTROLS[5];
wire m_start1p  	= CONTROLS[6];
wire m_start2p  	= CONTROLS[7];
wire m_coin   		= CONTROLS[8];

//CPU read selection logic
// ******* PRIMARY CPU IC SELECTION LOGIC FOR TILE, SPRITE, SOUND & GAME EXECUTION ********
always @(posedge clk3_3MHZ) begin
if (Z80_B1_en&!Z80_MREQ) rZ80A_databus_in <= prom_prog1_out;
	else if (Z80_RAM_en & !Z80_RD) rZ80A_databus_in <= U4N_Z80A_RAM_out;					//Main System RAM

	//reads from AY sound chips
	else if (!IOA1 & IOA0) rZ80A_databus_in <= AY_12F_databus_out;
	else if (!IOA3 & IOA2) rZ80A_databus_in <= AY_12V_databus_out;

	//if !U7U_1A then the external bi-directional databus buffer is enabled
	else if ((Z80A_addrbus[15])&(!Z80_MREQ)) begin //Output of U7U_1A OR GATE

		if (!Z80_RD & !RAMA) 	rZ80A_databus_in <= U6N_VRAM_Q; 		//VRAM
		else if (!Z80_RD & !RAMB) 		rZ80A_databus_in <= rSPRITE_databus;//U11SR_SPRAM_Q; 
		else if (!Z80_RD & !IN1) 		rZ80A_databus_in <= ({m_start2p,m_start1p,m_shoot2,m_shoot,m_left,m_right,m_down,m_up});//ST2, ST1, FIRB,FIRA,LF,  RG,  DN,  UP
		else if (!Z80_RD & !IN2) 		rZ80A_databus_in <= {DIP1};//DIP SWITCH 1 //LIVES //BONUS LIFE //DIFFICULTY //CABINET
		else if (!Z80_RD & !IN3) 		rZ80A_databus_in <= {1'b0,1'b0,1'b0,1'b0,DIP2[1],DIP2[0],DIP2[2],nVDSP};//DIP SWITCH 2 & VDSP feedback

	end


end

// *************** SECOND CPU IC SELECTION LOGIC FOR BACKGROUND GRAPHICS *****************
always @(posedge bgclk_3) begin
			
	rZ80B_databus_in <= 			(!BG_PROM & !Z80B_MREQ) 				? bg_prom_prog2_out:
										(!Z80B_RD & !BG_RAM)    				? U4V_Z80B_RAM_out:
										(!Z80B_RD & !BG_IO2)   					? Z80A_IO2:
										(!Z80B_RD & !BG_VDSP)					? ({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,nVDSP,SNHI}):
																						8'b00000000;
end

wire wait_n = !pause;
wire nVDSP = V_BLANK; 
wire nHDSP = H_BLANK; //vertical & horizontal display



wire SLSE;
wire CDCK, SLD11, SLD10, SLD9, SLD8, SLD7, SLD6, SLD5, SLD4, SLD3, SLD2, SLD1, SLD0;
wire U8E_Q7,U8E_Q6,U8E_Q5;

//select background graphic timer to pre-load
ls138x U8F(
  .nE1(SLSE), //SLSE
  .nE2(U7V_q[3]),
  .E3(PUR),
  .A({U7V_q[2],U7V_q[1],U7V_q[0]}),
  .Y({SLD7,SLD6,SLD5,SLD4,SLD3,SLD2,SLD1,SLD0})
);

ls138x U8E(
  .nE1(SLSE), //SLSE
  .nE2(1'b0), 
  .E3(U7V_q[3]), 
  .A({U7V_q[2],U7V_q[1],U7V_q[0]}),
  .Y({U8E_Q7,U8E_Q6,U8E_Q5,CDCK,SLD11,SLD10,SLD9,SLD8})
);

reg [7:0] U3K_Q; //background scene selection
always @(posedge CDCK) U3K_Q<=BGRAM_out; //U3K

wire [3:0] U4KJ_Q;

//prom6301_4KJ U4KJ(
//	.addr({U3K_Q[3:0],SA3|SB3,SA2|SB2,SA1|SB1,SA0|SB0}),
//	.clk(clkm_20MHZ),
//	.n_cs(1'b0), 
//	.q(U4KJ_Q)
//);

exerion_k4 exerion_k4(
	.clk(clkm_20MHZ),
	.addr({U3K_Q[3:0],SA3|SB3,SA2|SB2,SA1|SB1,SA0|SB0}),
	.data(U4KJ_Q)
);

wire U4ML_1,U4ML_2;

top_74ls153 U4ML(
	 .A(U4KJ_Q[0]),
	 .B(U4KJ_Q[1]),
	 .EN_n({u4ML_EN,u4ML_EN}),
    .D1_0(SA0),
	 .D1_1(SA1),
	 .D1_2(SA2),
	 .D1_3(SA3),
    .D2_0(SB0), 
	 .D2_1(SB1), 
	 .D2_2(SB2), 
	 .D2_3(SB3),
    .Y1(U4ML_1), 
	 .Y2(U4ML_2)
);

//background layer output
//prom6301_3L U3L(
//	.addr({U3K_Q[7:4],U4KJ_Q[1:0],U4ML_2,U4ML_1}),
//	.clk(clkm_20MHZ),  ///clkm_20MHZ
//	.n_cs(1'b0), 
//	.q({ZC3,ZC2,ZC1,ZC0})
//);

exerion_i3 exerion_i3(
	.clk(clkm_20MHZ),  ///clkm_20MHZ
	.addr({U3K_Q[7:4],U4KJ_Q[1:0],U4ML_2,U4ML_1}),
	.data({ZC3,ZC2,ZC1,ZC0})
);

//CPUB (background layer) external I/O chip selects
ls138x U3T( //#(.WIDTH_OUT(8), .DELAY_RISE(0), .DELAY_FALL(0)) 
  .nE1(1'b0), //
  .nE2(1'b0), //
  .E3(PUR), //
  .A(Z80B_addrbus[15:13]), //
  .Y({U3T_Y7,U3T_Y6,BG_VDSP,BG_BUS,BG_IO2,BG_RAM,U3T_Y1,BG_PROM})
);

wire [7:0] BGRAM_out;
wire BG_PROM,U3T_Y1,BG_RAM,BG_IO2,BG_BUS,BG_VDSP,U3T_Y6,U3T_Y7;

//BG Z80B CPU work RAM
m6116_ram U4V_Z80B_RAM(
	.data(Z80B_databus_out),
	.addr({Z80B_addrbus[10:0]}),
	.cen(1'b1),
	.clk(clkm_20MHZ),
	.nWE(Z80B_WR | BG_RAM), //write to main CPU work RAM
	.q(U4V_Z80B_RAM_out)
);

assign Z80A_databus_in = rZ80A_databus_in;
assign Z80B_databus_in = rZ80B_databus_in;

//Z80A CPU main program program ROM
//eprom_8 prom_prog1
//(
//	.ADDR(Z80A_addrbus[14:0]),//
//	.CLK(clkC_20MHZ),//
//	.DATA(prom_prog1_out),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep8_cs_i),
//	.WR(dn_wr)
//);

assign cpu_rom_addr = Z80A_addrbus[14:0];
assign prom_prog1_out = cpu_rom_do;

wire [7:0] prom_prog1_out;
wire [7:0] bg_prom_prog2_out;
wire [7:0] U4N_Z80A_RAM_out;
wire [7:0] U4V_Z80B_RAM_out;

//background layer program ROM
//eprom_6 prom_prog2
//(
//	.ADDR(Z80B_addrbus[12:0]),//
//	.CLK(clkC_20MHZ),//
//	.DATA(bg_prom_prog2_out),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep6_cs_i),
//	.WR(dn_wr)
//);

exerion_05 exerion_05(
	.clk(clkm_20MHZ),
	.addr(Z80B_addrbus[12:0]),
	.data(bg_prom_prog2_out)
);

//main CPU (Z80A) work RAM - dual port RAM for hi-score logic
dpram_dc #(.widthad_a(11)) U4N_Z80A_RAM
(
	.clock_a(clkm_20MHZ),
	.address_a(Z80A_addrbus[10:0]),
	.data_a(Z80A_databus_out),
	.wren_a(!Z80_WR & !U3RA_Q[3]),
	.q_a(U4N_Z80A_RAM_out),
	
	.clock_b(clkm_20MHZ),
	.address_b(hs_address[10:0]),
	.data_b(hs_data_in),
	.wren_b(hs_write),
	.q_b(hs_data_out)
);

//External Bus Selection Logic #1 for Sprite & Video RAM and IN1 (control panel), IN2(dip switch 1) & IN3 (dip switch 2)
ls138x U3M(
  .nE1(1'b0),
  .nE2(U3RB_Q[2]),
  .E3(PUR),
  .A(Z80A_addrbus[13:11]),
  .Y({U3M_Q7,IN3,IN2,IN1,U3M_Q3,U3M_Q2,RAMB,RAMA})
);

//Address decoder for IO1, IO2 & sound chips
ls138x U3P(
  .nE1(1'b0),
  .nE2(U3RB_Q[3]),
  .E3(PUR),
  .A(Z80A_addrbus[13:11]),
  .Y({U3P_Q7,U3P_Q6,U3P_Q5,U3P_Q4,U3P_Q3,U3P_Q2,IO2,IO1})
);

//sound chip selection logic
assign IOA0 = !(Z80A_addrbus[0]|U3P_Q2);
assign IOA1 = !(Z80A_addrbus[1]|U3P_Q2);
assign IOA2 = !(Z80A_addrbus[0]|U3P_Q3);
assign IOA3 = !(Z80A_addrbus[1]|U3P_Q3);

assign RAMA_WR = RAMA|Z80_WR;
assign RAMB_WR = RAMB|Z80_WR;

wire RAMA,RAMB,IN1,IN2,IN3,IO1,IO2,IOA0,IOA1,IOA2,IOA3;
wire U3M_Q2,U3M_Q3,U3M_Q7;
wire U3P_Q2,U3P_Q3,U3P_Q4,U3P_Q5,U3P_Q6,U3P_Q7;

ls138x U9R( 
  .nE1(~pixH[8]), 
  .nE2(~pixH[8]), 
  .E3(pixH[7]), 
  .A(pixH[6:4]), 
  .Y({U9R_Q7,U9R_Q6,U9R_Q5,U9R_Q4,U9R_Q3,U9R_Q2,U9R_Q1,U9R_Q0})
);

wire u4ML_EN;

ttl_7474 #(.BLOCKS(1), .DELAY_RISE(0), .DELAY_FALL(0)) U8T_B(
	.n_pre(PUR),
	.n_clr(~nVDSP),
	.d(PUR),
	.clk(SNHI),
	.q(),
	.n_q(u4ML_EN)
);

//create SNHI output (Q1)
ls138x U9S( //#(.WIDTH_OUT(8), .DELAY_RISE(0), .DELAY_FALL(0)) 
  .nE1(~pixH[8]), 
  .nE2(nVDSP), 
  .E3(pixH[7]), 
  .A({1'b0,1'b0,pixH[6]}), 
  .Y({U9S_Q7,U9S_Q6,U9S_Q5,U9S_Q4,U9S_Q3,U9S_Q2,SNHI,U9S_Q0})
);

//VRAM
m6116_ram U6N_VRAM(
	.data(Z80A_databus_out),
	.addr(vramaddr),
	.clk(clkm_20MHZ),
	.cen(1'b1),
	.nWE(RAMA_WR),
	.q(U6N_VRAM_Q)
);	

wire npixH;
assign npixH=~pixH[2];


always @(posedge npixH) vramdata0out<=U6N_VRAM_Q;

//forground character ROM
//eprom_7 u6k
//(
//	.ADDR({char_ROMA12,vramdata0out[7:4],pixelbusV[2:0],vramdata0out[3:0],pixelbusH[2]}),//
//	.CLK(clkm_20MHZ),//
//	.DATA(u6k_data),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep7_cs_i),
//	.WR(dn_wr)
//);

exerion_06 exerion_06(
	.clk(clkm_20MHZ),
	.addr({char_ROMA12,vramdata0out[7:4],pixelbusV[2:0],vramdata0out[3:0],pixelbusH[2]}),
	.data(u6k_data)
);

wire npix1;
assign npix1=~pixH[1];

ls175 U7L(
	.nMR(1'b0),
	.clk(npix1),
	.D({vramdata0out[7:4]}),
	.Q({U7L_Q3,U7L_Q2,U7L_Q1,U7L_Q0}),
	.nQ()
);

always @(posedge npix1) u7K_data <= u6k_data ;

top_74ls153 U8K(
	 .A(pixelbusH[0]),
	 .B(pixelbusH[1]),
	 .EN_n({1'b0,1'b0}),
    .D1_0(u7K_data[0]),
	 .D1_1(u7K_data[1]),
	 .D1_2(u7K_data[2]),
	 .D1_3(u7K_data[3]),
    .D2_0(u7K_data[4]), 
	 .D2_1(u7K_data[5]), 
	 .D2_2(u7K_data[6]), 
	 .D2_3(u7K_data[7]),
    .Y1(U8K_1), 
	 .Y2(U8K_2)
);

//forground / text / bullet layer output
//prom6301_L8 UL8(
//	.addr({U8L_A7,U8L_A6,U8K_2,U8K_1,U7L_Q3,U7L_Q2,U7L_Q1,U7L_Q0}),
//	.clk(clkm_20MHZ),
//	.n_cs(1'b0), 
//	.q({ZA3,ZA2,ZA1,ZA0})
//);

exerion_i8 exerion_i8(
	.clk(clkm_20MHZ),
	.addr({U8L_A7,U8L_A6,U8K_2,U8K_1,U7L_Q3,U7L_Q2,U7L_Q1,U7L_Q0}),
	.data({ZA3,ZA2,ZA1,ZA0})
);

wire clrR0,clrR1,clrR2;
wire clrG0,clrG1,clrG2;
wire clrB0,clrB1;
wire [3:0] clr_addr; //U2E_Y1,U2E_Y2,U2D_Y1,U2D_Y2;

//select layer with priority
mux4_4n U2ED(
    .EN_n(nHDSP|nVDSP), //nHDSP|nVDSP
	 .A(VID_B),
	 .B(VID_A),
    .D0({ZC3,ZC2,ZC1,ZC0}), 
	 .D1({ZB3,ZB2,ZB1,ZB0}), 
	 .D2({ZA3,ZA2,ZA1,ZA0}), 
	 .D3({ZA3,ZA2,ZA1,ZA0}),
    .Y(clr_addr)
);

assign VID_A = U8K_1|U8K_2;		//tile map layer active (bullets & text)
assign VID_B = ZB3|ZB2|ZB1|ZB0;	//sprite layer active

//colour prom
//prom6331_E1 UE1(
//	.addr({VID_A|VID_B,clr_addr}),
//	.clk(clkm_20MHZ),
//	.n_cs(1'b0),
//	.q({clrB1,clrB0,clrG2,clrG1,clrG0,clrR2,clrR1,clrR0})
//);

exerion_e1 exerion_e1(
	.clk(clkm_20MHZ),
	.addr({VID_A|VID_B,clr_addr}),
	.data({clrB1,clrB0,clrG2,clrG1,clrG0,clrR2,clrR1,clrR0})
);

reg rVGA_HS;
reg rVGA_VS;
wire rSSEL;

wire r2UP; //flips the screen - removed logic to help with debugging
assign r2UP=1'b0;

wire [8:0] pixHcntz;
wire [7:0] pixVcntz;

reg char_ROMA12, U8L_A6, U8L_A7, CD4,CD5;

always @(posedge IO1) begin
//	r2UP<=1'b1;
//	//r2UP<=Z80A_databus_out[0];
	U8L_A6<=Z80A_databus_out[1];
	U8L_A7<=Z80A_databus_out[2];
	char_ROMA12<=Z80A_databus_out[3];
	CD4<=Z80A_databus_out[6];
	CD5<=Z80A_databus_out[7];
end

reg [7:0] Z80A_IO2;

always @(posedge IO2) Z80A_IO2 = Z80A_databus_out;

wire [8:0] sppixHcntz;
wire [7:0] sppixVcntz;
assign sppixHcntz=sppixH+9'd1;
assign sppixVcntz=sppixV+8'd1;
assign pixHcntz=pixH+9'd1;
assign pixVcntz=pixV+8'd1;

always @(posedge spclk2_6MHZ) begin

	//simplified pixel clock counter. The horizontal counts from 88 to 511, the vertical counts from 0 to 255
	if (sppixH==9'b111111111) 
	begin
		sppixH <= 9'b00101100z;
		sppixV <= sppixVcntz;//pixVcnt+1;
	end
	else sppixH <= sppixHcntz;

end
reg spnH4CA,spnH8CA;

always @(posedge clk2_6MHZ) begin

	
	//simplified pixel clock counter. The horizontal counts from 88 to 511, the vertical counts from 0 to 255
	if (pixH==9'b111111111) 
	begin
		pixH <= 9'b00101100z;
		pixV <= pixVcntz;//pixVcnt+1;
	end
	else pixH <= pixHcntz;

	rVGA_HS <= !U9R_Q5;							//horizontal sync
	rVGA_VS <= ((!(&pixV[7:3]))|pixV[2]); 	//vertical sync
	spnH4CA<=~&pixH[4:1];
	spnH8CA<=~&pixH[8:5];
	
end

assign	rSSEL = U9R_Q4|nVDSP;  //used to load the per line memory location for the background layer 
assign	U7V_q = (rSSEL) ? {Z80B_addrbus[3:0]} : {pixH[3:0]};	

wire [3:0] U7V_q;	

assign vramaddr = (RAMA) ? {rpixelbusV[7:3],rpixelbusH[8:3]} :
									{Z80A_addrbus[10:0]};

assign	rpixelbusH = pixH;
assign	rpixelbusV = pixV;

assign pixelbusH = rpixelbusH;
assign pixelbusV = rpixelbusV;
		
/* SPRITE VIB-B BOARD IMPLEMENTATION */
//The 10Mhz, 6Mhz and offset 6Mhz clocks are used to draw the sprites
//sprite RAM
wire [7:0] U11SR_SPRAM_Q;

m2114_ram U11SR(
	.data(Z80A_databus_out),
	.addr({spramaddr_cnt[8:2]}),
	.clk(clkm_20MHZ),
	.nWE(RAMB_WR | spRAMsel), //U10S_QB
	.q(U11SR_SPRAM_Q)
);


reg [3:0] U11H_cnt;
reg [3:0] U12H_cnt;

wire sROM_bitA, sROM_bitB, sROM_A0, sROM_A1;

assign sROM_bitA = (BIG2) ? U11H_cnt[1]^UDINV2 : U11H_cnt[0]^UDINV2; //10J
assign sROM_bitB = (BIG2) ? U11H_cnt[2]^UDINV2 : U11H_cnt[1]^UDINV2; //10J
assign sROM_A0 =   (BIG1) ? U12H_cnt[3]^UDINV1 : U12H_cnt[2]^UDINV1; //12J
assign sROM_A1 =   (BIG1) ?       UDPNT^UDINV1 : U12H_cnt[3]^UDINV1; //12J

always @(posedge P3) begin			//U12L
	CHLF<=rSPRITE_databus[7];
	sROM_A11<=rSPRITE_databus[6];
	sROM_A10<=rSPRITE_databus[5];
	sROM_A9<=CAD9;
	CHDN<=rSPRITE_databus[3];
	sROM_A4<=rSPRITE_databus[2];
	sROM_A3<=rSPRITE_databus[1];
	sROM_A2<=rSPRITE_databus[0];
end

reg CHLF,sROM_A11,sROM_A10,sROM_A9,CHDN,sROM_A4,sROM_A3,sROM_A2;
wire [7:0] sprom_data;

//eprom_5 prom_SPRITE
//(
//	.ADDR({CHDN,CHLF,sROM_A11,sROM_A10,sROM_A9,sum4,sum3,sum2,sum1,sROM_A4,sROM_A3,sROM_A2,sROM_A1,sROM_A0}),//
//	.CLK(clkm_20MHZ),//clkSP_20MHz
//	.DATA(sprom_data),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep5_cs_i),
//	.WR(dn_wr)
//);

//sprite sprite(
//	.clk(clkm_20MHZ),
//	.addr({CHDN,CHLF,sROM_A11,sROM_A10,sROM_A9,sum4,sum3,sum2,sum1,sROM_A4,sROM_A3,sROM_A2,sROM_A1,sROM_A0}),
//	.data(sprom_data)
//);

assign spr_rom_addr = {CHDN,CHLF,sROM_A11,sROM_A10,sROM_A9,sum4,sum3,sum2,sum1,sROM_A4,sROM_A3,sROM_A2,sROM_A1,sROM_A0};
assign sprom_data = spr_rom_do;

reg [7:0] U8H_Q;

always @(negedge U12H_cnt[1]) U8H_Q<=sprom_data;

wire U11J_1, U11J_2;
top_74ls153 U11J(
	 .A(sROM_bitA),
	 .B(sROM_bitB),
	 .EN_n({ERS,ERS}),
    .D1_0(U8H_Q[0]),
	 .D1_1(U8H_Q[1]),
	 .D1_2(U8H_Q[2]),
	 .D1_3(U8H_Q[3]),
    .D2_0(U8H_Q[4]), 
	 .D2_1(U8H_Q[5]), 
	 .D2_2(U8H_Q[6]), 
	 .D2_3(U8H_Q[7]),
    .Y1(U11J_1), 
	 .Y2(U11J_2)
);

wire [3:0] U10H_data;

//prom6301_H10 U10H(
//	.addr({CD5,CD4,U11J_2,U11J_1,CD3,CD2,CD1,CD0}),
//	.clk(clkm_20MHZ),
//	.n_cs(1'b0), 
//	.q({U10H_data})
//);

exerion_h10 exerion_h10(
	.clk(clkm_20MHZ),
	.addr({CD5,CD4,U11J_2,U11J_1,CD3,CD2,CD1,CD0}),
	.data({U10H_data})
);

reg [3:0] spbitdata_10;
reg [3:0] spbitdata_11;

reg U9H_A_nq,U9F_A_q;
wire U9H_d;

assign U9H_d = U11J_2|U11J_1;


always @(posedge spclk1_10MHZ) U9H_A_nq <= 	~U9H_d;

always @(posedge spclk1_10MHZ) begin
	spbitdata_11 <= (sppixV[0]) ? 4'b0000 : U10H_data;
	spbitdata_10 <= (sppixV[0]) ? U10H_data :4'b0000 ;
end


always @(posedge U10nRCO or negedge RAMB or negedge spRAMsel) U9F_A_q <= 	(!RAMB) ?	1'b1 : (!spRAMsel) ? 1'b0 : spRAMsel;

reg U9F_B_nq;
always @(posedge spnH4CA or negedge RAMB) begin
	U9F_B_nq <= 	~((!RAMB) ?	1'b1 : spnH8CA);
end

wire [3:0] U12R_sum;
wire [3:0] U12S_sum;
wire U12R_cout;

reg [7:0] rPixelBusV1;

ttl_74283 #(.WIDTH(4), .DELAY_RISE(0), .DELAY_FALL(0)) U12R(
	.a(rSPRITE_databus[3:0]),
	.b(sppixV[3:0]),
	.c_in(PUR),  
	.sum(U12R_sum),
	.c_out(U12R_cout)
);

ttl_74283 #(.WIDTH(4), .DELAY_RISE(0), .DELAY_FALL(0)) U12S(

	.a({rSPRITE_databus[7:4]}),
	.b({sppixV[7:4]}),
	.c_in(U12R_cout),
	.sum(U12S_sum),
	.c_out()
);

//sprite control signals
reg U12P_H0,U12P_CA0,U12P_CA1,U12P_Y2,U12P_BIG,U12P_UDPNT,U12P_RLINV,U12P_UDINV;
reg BIG1,UDINV1,sum1,sum2,sum3,sum4,UDPNT;
reg BIG2,UDINV2,ERS,CD3,CD2,CD1,CD0;

always @(posedge P1) {U12P_UDINV,U12P_RLINV,U12P_UDPNT,U12P_BIG,U12P_Y2,U12P_CA1,U12P_CA0,U12P_H0} <= rSPRITE_databus; //U12P
always @(posedge P3) {sum4,sum3,sum2,sum1,UDPNT,BIG1,UDINV1} <= {U12U_Q[3]^U12P_RLINV,U12U_Q[2]^U12P_RLINV,U12U_Q[1]^U12P_RLINV,U12U_Q[0]^U12P_RLINV,U12P_UDPNT,U12P_BIG,U12P_UDINV}; //U10N
always @(posedge P4) {UDINV2,BIG2,ERS,CD3,CD2,CD1,CD0} <= {U12P_UDINV,U12P_BIG,U11V_ZB,CHDN,CHLF,U12P_CA1,U12P_CA0}; //U10P

reg [3:0] U12U_Q;
reg [3:0] U12T_Q;

always @(negedge P2) begin
	U12U_Q <= (U12P_BIG) ? {U12S_sum[0],U12R_sum[3],U12R_sum[2],U12R_sum[1]} : U12R_sum; //U12U
	U12T_Q <= (U12P_BIG) ? {1'b0,U12S_sum[3],U12S_sum[2],U12S_sum[1]}        : U12S_sum; //U12T
end

reg U11V_ZB,CAD9;

always @(U12P_Y2,U12T_Q,U12P_RLINV,rSPRITE_databus) {U11V_ZB,CAD9} <= (U12P_Y2) ? {U12T_Q[1]|U12T_Q[2]|U12T_Q[3],U12T_Q[0]^U12P_RLINV} : {U12T_Q[0]|U12T_Q[1]|U12T_Q[2]|U12T_Q[3],rSPRITE_databus[4]}; //U11V

reg sp10_UD,sp10_nLD,sp10_CK,sp10_WE;
reg sp11_UD,sp11_nLD,sp11_CK,sp11_WE;

//sprite ram bit selection logic - U11E feeds the _10 bus
always @(negedge clkm_20MHZ) begin

	if (sppixV[0]) 
	begin
		sp10_WE  <= (spclk1_10MHZ|U9H_A_nq|U9F_A_q);
		sp10_CK  <= (spclk1_10MHZ|U9F_B_nq|U9F_A_q);
		sp10_nLD <= U10nRCO;
		sp11_WE  <= spclk2_6MHZ;
		sp11_CK  <= spclk2_6MHZ;
		sp11_nLD <= 1'b1;

		sp10_UD  <= 1'b1; //( rpixelbusV[0])  ? 1'b1 : nr2UP;
		sp11_UD  <= 1'b1; //(!rpixelbusV[0])  ? 1'b1 : nr2UP;		
	end
	else
	begin
		sp10_WE  <= spclk2_6MHZ;
		sp10_CK  <= spclk2_6MHZ;
		sp10_nLD <= 1'b1;
		sp11_WE  <= (spclk1_10MHZ|U9H_A_nq|U9F_A_q);
		sp11_CK  <= (spclk1_10MHZ|U9F_B_nq|U9F_A_q);
		sp11_nLD <= U10nRCO;

		sp10_UD  <= 1'b1; //( rpixelbusV[0])  ? 1'b1 : nr2UP;
		sp11_UD  <= 1'b1; //(!rpixelbusV[0])  ? 1'b1 : nr2UP;			
	end
end


reg [8:0] spramaddrb_10_cnt;
reg [8:0] spramaddrb_10_up;
//this 'should' mimic the U12A, U12D & D12E counters  
always @(posedge sp10_CK) spramaddrb_10_cnt <= spramaddrb_10_up;

reg [8:0] spramaddrb_11_cnt;
reg [8:0] spramaddrb_11_up;


always @(posedge sp11_CK) spramaddrb_11_cnt = spramaddrb_11_up;

wire [3:0] spram_out_10;
wire [3:0] spram_out_11;

always @(posedge spclk4_6BMHZ) {ZB3,ZB2,ZB1,ZB0} <= (sppixV[0]) ? {spram_out_11} : {spram_out_10}; //U9A

always @(negedge spclk1_10MHZ) begin
	U10nRCO<=!(spramaddr_cnt[0]&spramaddr_cnt[1]&spramaddr_cnt[2]&spramaddr_cnt[3]);
end

wire P4,P3,P2,P1;
wire U10U_Q4,U10U_Q5,U10U_Q6,U10U_Q7;

ls138x U10U( //#(.WIDTH_OUT(8), .DELAY_RISE(0), .DELAY_FALL(0)) 
  .nE1(spclk1_10MHZ), //
  .nE2(spramaddr_cnt[0]), //
  .E3(spramaddr_cnt[1]), //
  .A({1'b0,spramaddr_cnt[3:2]}), //
  .Y({U10U_Q7,U10U_Q6,U10U_Q5,U10U_Q4,P4,P3,P2,P1})
);

always @(posedge spclk1_10MHZ) begin

//U11H     - 161 counter that increments on the 10Mhz clock and is reset to 0 by P4, this can be a simple add counter
//U10J     - Takes the output of U11H and switches the output based on signal 'BIG2'
//U9JA & D - The outputs of U10J are XORed with control signal 'UDINV2'

	U11H_cnt <= (!P4) ? 4'b0000 : U11H_cnt2;
	
//U12H - 161 counter that increments on the 10Mhz clock and is reset to 0 by P3, this can be a simple add counter
//U12J     - Takes the output of U12H and UDPNT and switches the output based on signal 'BIG1'
//U9JC & B - The outputs of U12J are XORed with control signal 'UDINV1	'

	U12H_cnt <= (!P3) ? 4'b0000 : U12H_cnt2;

//Sprite RAM address selection logic
	spRAMbit0 <= (!spRAMsel) ? U12P_H0 : 1'b0; //U10S_QB 
	spRAMsel <= spramaddr_cnt[9];
	spramaddr_cntz3 <= spramaddr_cntz2; //spramaddr_cntz2;
end


reg spRAMbit0;
reg spRAMsel;

reg [3:0] U11H_cnt2;
reg [3:0] U12H_cnt2;
reg [9:0] spramaddr_cnt;
reg [9:0] spramaddr_cntz2;
reg [9:0] spramaddr_cntz3 ;

always @(posedge clkm_20MHZ) begin
	rSPRITE_databus <= (!spRAMsel) ? ((!RAMB_WR) ? Z80A_databus_out : U11SR_SPRAM_Q) : ({r2UP,1'b0,r2UP,r2UP,1'b0,r2UP,1'b0,1'b0}) ;
	U11H_cnt2 <= (!P4) ? 4'b0000 : U11H_cnt+4'd1;
	U12H_cnt2 <= (!P3) ? 4'b0000 : U12H_cnt+4'd1;
	spramaddr_cntz2 <= spramaddr_cnt+10'b0000000001;
	spramaddr_cnt   <= (U9F_B_nq) ?  10'b0000000000 : (!RAMB) ? ({1'b0,Z80A_addrbus[6:0],1'b0,1'b0}) : spramaddr_cntz3 ; 	

	//generate address for fast sprite ram
	spaddr_x <= {rSPRITE_databus[7:0],spRAMbit0};
	spramaddrb_10_up <= 	(!sp10_nLD) ? spaddr_x : 
							   ((sp10_UD)  ? spramaddrb_10_cnt + 9'd1 : spramaddrb_10_cnt - 9'd1);

	spramaddrb_11_up <= 	(!sp11_nLD) ? spaddr_x : 
								((sp11_UD)  ? spramaddrb_11_cnt + 9'd1 : spramaddrb_11_cnt - 9'd1);

	
end

reg [8:0] spaddr_x;

wire U10RCO;
reg U10nRCO=1'b1;
reg [7:0] rSPRITE_databus;

// *************** SOUND CHIPS *****************
wire U1D_B_nq,U1D_B_q;
wire [7:0] AY_12V_ioa_in;
wire [7:0] AY_12V_ioa_out;
wire [7:0] AY_12V_iob_in;
wire [7:0] AY_12V_iob_out;

wire [7:0] AY_12F_databus_out;
wire [7:0] AY_12V_databus_out;


ttl_7474 #(.BLOCKS(1), .DELAY_RISE(0), .DELAY_FALL(0)) U1D_B(
	.n_pre(PUR),
	.n_clr(PUR),
	.d(U1D_B_nq),
	.clk(clk3_3MHZ),
	.q(U1D_B_q),
	.n_q(U1D_B_nq)
);

wire [9:0] pre_sndl;
wire [9:0] pre_sndr;
wire [7:0] ay12F_araw, ay12F_braw, ay12F_craw;
wire [7:0] ay12V_araw, ay12V_braw, ay12V_craw;
wire signed [15:0] ay12F_adcrm, ay12F_bdcrm, ay12F_cdcrm;
wire signed [15:0] ay12V_adcrm, ay12V_bdcrm, ay12V_cdcrm;
wire AY12F_sample,AY12V_sample;
wire [9:0] sound_outF;
wire [9:0] sound_outV;

always @(posedge clkaudio) begin
	audio_l <= ({1'd0, sound_outF, 5'd0});
	audio_r <= ({1'd0, sound_outV, 5'd0});
end

jt49_bus AY_12F(
    .rst_n(RESET_n),
    .clk(clkaudio),    				// signal on positive edge //U1D_B_q
    .clk_en(1),  						/* synthesis direct_enable = 1 */
    
    .bdir(IOA1),						// bus control pins of original chip
    .bc1(IOA0),
	 .din(Z80A_databus_out),
    .sel(1'b0), 						// if sel is low, the clock is divided by 2
    .dout(AY_12F_databus_out),
    
	 .sound(sound_outF),  			// combined channel output
    .A(ay12F_araw),    				// linearised channel output
    .B(ay12F_braw),
    .C(ay12F_craw),
    .sample(AY12F_sample)
);

jt49_bus AY_12V(
    .rst_n(RESET_n),
    .clk(clkaudio),    				// signal on positive edge
    .clk_en(1),  						/* synthesis direct_enable = 1 */
    
    .bdir(IOA3),	 					// bus control pins of original chip
    .bc1(IOA2),
	 .din(Z80A_databus_out),
    .sel(1'b0), 						// if sel is low, the clock is divided by 2
    .dout(AY_12V_databus_out),
    
	 .sound(sound_outV),  			// combined channel output
    .A(ay12V_araw),      			// linearised channel output
    .B(ay12V_braw),
    .C(ay12V_craw),
    .sample(AY12V_sample),

    .IOA_in(AY_12V_ioa_in),		//IO to ICX security chip
    .IOA_out(AY_12V_ioa_out),

    .IOB_in(AY_12V_iob_in),
    .IOB_out(AY_12V_iob_out)
);

reg [7:0] tmrmask ;//= 8'b00000000;
reg [2:0] tmrcounter;
reg [2:0] tmrcnt2;
reg [7:0] zAY_12V_iob_out;
reg [7:0] outercounter;

always @(posedge U1D_B_q) begin

	tmrcounter <= tmrcounter +3'd1;
	if (tmrcounter==0)	tmrmask <= AY_12V_iob_out^8'h40;
	tmrmask<=tmrmask^8'h40;
	
end

assign AY_12V_iob_in = (tmrcounter==3'b111) ? AY_12V_iob_out : 8'd0;
assign AY_12V_ioa_in = tmrmask;//AY_12V_iob_out^8'h40;  // tmrmask;//AY_12V_ioa_out^8'h40; //8'hBE^   tmrmask;//


//************************* BACKGROUND LAYER SECTIONS ************************
wire [7:0] bg_gfx4B_out;
wire [7:0] bg_gfx4D_out;
wire [7:0] bg_gfx4E_out;
wire [7:0] bg_gfx4H_out;

//------------------------------------------------- MiSTer data write selector -------------------------------------------------//
//Instantiate MiSTer data write selector to generate write enables for loading ROMs into the FPGA's BRAM
//wire ep1_cs_i, ep2_cs_i, ep3_cs_i, ep4_cs_i, ep5_cs_i, ep6_cs_i, ep7_cs_i, ep8_cs_i;

//selector DLSEL
//(
//	.ioctl_addr(dn_addr),
//	.ep1_cs(ep1_cs_i),
//	.ep2_cs(ep2_cs_i),
//	.ep3_cs(ep3_cs_i),
//	.ep4_cs(ep4_cs_i),
//	.ep5_cs(ep5_cs_i),
//	.ep6_cs(ep6_cs_i),
//	.ep7_cs(ep7_cs_i),	
//	.ep8_cs(ep8_cs_i)
//);

//eprom_1 bg_gfx4B
//(
//	.ADDR({BG4BaddrH[7:0],BG4BaddrL[6:2]}),//
//	.CLK(clkm_20MHZ),		//
//	.CEN(BG4BaddrL[7]),
//	.DATA(bg_gfx4B_out),	//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),	//
//	.DATA_IN(dn_data),
//	.CS_DL(ep1_cs_i),
//	.WR(dn_wr)
//);

exerion_01 exerion_01(
	.clk(clkm_20MHZ),
	.addr({BG4BaddrH[7:0],BG4BaddrL[6:2]}),
	.data(bg_gfx4B_out)
);

//eprom_2 bg_gfx4D
//(
//	.ADDR({BG4DaddrH[7:0],BG4DaddrL[6:2]}),//
//	.CLK(clkm_20MHZ),//
//	.CEN(BG4DaddrL[7]),	
//	.DATA(bg_gfx4D_out),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep2_cs_i),
//	.WR(dn_wr)
//);

exerion_02 exerion_02(
	.clk(clkm_20MHZ),
	.addr({BG4DaddrH[7:0],BG4DaddrL[6:2]}),
	.data(bg_gfx4D_out)
);

//eprom_3 bg_gfx4E
//(
//	.ADDR({BG4EaddrH[7:0],BG4EaddrL[6:2]}),//
//	.CLK(clkm_20MHZ),//
//	.CEN(BG4EaddrL[7]),	//!BG4EaddrL[7]
//	.DATA(bg_gfx4E_out),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep3_cs_i),
//	.WR(dn_wr)
//);

exerion_03 exerion_03(
	.clk(clkm_20MHZ),
	.addr({BG4EaddrH[7:0],BG4EaddrL[6:2]}),
	.data(bg_gfx4E_out)
);

//eprom_4 bg_gfx4H
//(
//	.ADDR({BG4HaddrH[7:0],BG4HaddrL[6:2]}),//
//	.CLK(clkm_20MHZ),//
//	.CEN(BG4HaddrL[7]),	 //
//	.DATA(bg_gfx4H_out),//
//	.ADDR_DL(dn_addr),
//	.CLK_DL(clkm_20MHZ),//
//	.DATA_IN(dn_data),
//	.CS_DL(ep4_cs_i),
//	.WR(dn_wr)
//);

exerion_04 exerion_04(
	.clk(clkm_20MHZ),
	.addr({BG4HaddrH[7:0],BG4HaddrL[6:2]}),
	.data(bg_gfx4H_out)
);



reg [7:0] U5B_out,U5D_out,U5E_out,U5H_out;

reg U7A_Bnq,U7A_Aq;

wire L4B_clk1,L4B_clk2;
wire L4D_clk1,L4D_clk2;
wire L4E_clk1,L4E_clk2;
wire L4H_clk1,L4H_clk2;

wire nr2UP;
not (nr2UP,r2UP);

assign L4B_clk1 = (nr2UP^BG4BaddrL[4]);
assign L4B_clk2 = (nr2UP^BG4BaddrL[1]);
assign L4D_clk1 = (nr2UP^BG4DaddrL[4]);
assign L4D_clk2 = (nr2UP^BG4DaddrL[1]);
assign L4E_clk1 = (nr2UP^BG4EaddrL[4]);
assign L4E_clk2 = (nr2UP^BG4EaddrL[1]);
assign L4H_clk1 = (nr2UP^BG4HaddrL[4]);
assign L4H_clk2 = (nr2UP^BG4HaddrL[1]);

always @(posedge L4B_clk2) U5B_out<=bg_gfx4B_out; 
always @(posedge L4D_clk2) U5D_out<=bg_gfx4D_out;  
always @(posedge L4E_clk2) U5E_out<=bg_gfx4E_out; 
always @(posedge L4H_clk2) U5H_out<=bg_gfx4H_out;

wire U6A_QA,U6A_QB,U6A_QC,U6A_QD;
wire U8A_QA,U8A_QB,U8A_QC,U8A_QD;

reg [4:0] store_L8, store_L9, store_L10, store_L11;
reg [4:0] store_H8, store_H9, store_H10, store_H11;
reg SLD8os,SLD9os,SLD10os,SLD11os;
reg SLD8os_clr,SLD9os_clr,SLD10os_clr,SLD11os_clr;
reg [4:0] counterL8, counterL9, counterL10, counterL11;
reg [4:0] counterU8, counterU9, counterU10, counterU11;
reg zL4B_clk2,zL4D_clk2,zL4E_clk2,zL4H_clk2;
	
	
assign SLSE = bgclk_6|rSSEL; 

always @(negedge SLD8) begin
	store_L8 <= ({1'b0,BGRAM_out[3:0]});
	store_H8 <= ({1'b0,BGRAM_out[7:4]});
end
	
always @(negedge SLD9) begin
	store_L9 <= ({1'b0,BGRAM_out[3:0]});
	store_H9 <= ({1'b0,BGRAM_out[7:4]});
end
	
always @(negedge SLD10) begin
	store_L10 <= ({1'b0,BGRAM_out[3:0]});
	store_H10 <= ({1'b0,BGRAM_out[7:4]});
end 
	
always @(negedge SLD11) begin
	store_L11 <= ({1'b0,BGRAM_out[3:0]});
	store_H11 <= ({1'b0,BGRAM_out[7:4]});
end
	
always @(posedge clkm_20MHZ) begin

	BG4BaddrLD <= (!SLD0) ? BGRAM_out : (!rSSEL) ? BG4BaddrL : BG4BaddrLz;
	BG4DaddrLD <= (!SLD2) ? BGRAM_out : (!rSSEL) ? BG4DaddrL : BG4DaddrLz;
	BG4EaddrLD <= (!SLD4) ? BGRAM_out : (!rSSEL) ? BG4EaddrL : BG4EaddrLz;			
	BG4HaddrLD <= (!SLD6) ? BGRAM_out : (!rSSEL) ? BG4HaddrL : BG4HaddrLz;
			
	//display 'slice' of background bitmap #1
	ena_4B_1 <=  (&counterL8[3:0] )|counterL8[4];
	dis_4B_1 <=  (&counterU8[3:0] )|counterU8[4]; 
	if (L4B_clk2&!zL4B_clk2) ena_4B<=!(ena_4B_1^dis_4B_1);
	SLD8os   <= (!SLD8|SLD8os)&!SLD8os_clr;

	//display 'slice' of background bitmap #2	
	ena_4D_1 <=  (&counterL9[3:0])|counterL9[4];
	dis_4D_1 <=  (&counterU9[3:0])|counterU9[4];
	if (L4D_clk2&!zL4D_clk2) ena_4D<=!(ena_4D_1^dis_4D_1);
	SLD9os   <= (!SLD9|SLD9os)&!SLD9os_clr;

	//display 'slice' of background bitmap #3	
	ena_4E_1 <=  (&counterL10[3:0])|counterL10[4];
	dis_4E_1 <=  (&counterU10[3:0])|counterU10[4];
	if (L4E_clk2&!zL4E_clk2) ena_4E<=!(ena_4E_1^dis_4E_1);
	SLD10os   <= (!SLD10|SLD10os)&!SLD10os_clr;		

	//display 'slice' of background bitmap #4	
	ena_4H_1 <=  (&counterL11[3:0])|counterL11[4];
	dis_4H_1 <=  (&counterU11[3:0])|counterU11[4];
	if (L4H_clk2&!zL4H_clk2) ena_4H<=!(ena_4H_1^dis_4H_1);
	SLD11os   <= (!SLD11|SLD11os)&!SLD11os_clr;	

	zL4B_clk2<=L4B_clk2;
	zL4D_clk2<=L4D_clk2;
	zL4E_clk2<=L4E_clk2;
	zL4H_clk2<=L4H_clk2;

		  
end

always @(posedge L4B_clk1) begin
  counterL8 <= (SLD8os)   ? store_L8  : counterL8+5'd1;
  counterU8 <= (SLD8os)   ? store_H8  : counterU8+5'd1;
  SLD8os_clr<=SLD8os; //clear one shot 
end

always @(posedge L4D_clk1) begin
  counterL9 <= (SLD9os)   ? store_L9  : counterL9+5'd1;
  counterU9 <= (SLD9os)   ? store_H9  : counterU9+5'd1;
  SLD9os_clr<=SLD9os;
end

always @(posedge L4E_clk1) begin
  counterL10 <= (SLD10os)   ? store_L10  : counterL10+5'd1;
  counterU10 <= (SLD10os)   ? store_H10  : counterU10+5'd1;
  SLD10os_clr<=SLD10os;
end

always @(posedge L4H_clk1) begin
  counterL11 <= (SLD11os)   ? store_L11  : counterL11+5'd1;
  counterU11 <= (SLD11os)   ? store_H11  : counterU11+5'd1;
  SLD11os_clr<=SLD11os;
end

reg ena_4B,ena_4D,ena_4E,ena_4H;
reg dis_4B,dis_4D,dis_4E,dis_4H;
reg ena_4B_1,ena_4D_1,ena_4E_1,ena_4H_1;
reg dis_4B_1,dis_4D_1,dis_4E_1,dis_4H_1;
wire SA0,SA1,SA2,SA3;
wire SB0,SB1,SB2,SB3;

mux4_2n U5A(
    .EN_n(ena_4B),
    .A(BG4BaddrL[0]), 
	 .B(BG4BaddrL[1]),
    .D0({U5B_out[0],U5B_out[4]}), 
	 .D1({U5B_out[1],U5B_out[5]}), 
	 .D2({U5B_out[2],U5B_out[6]}), 
	 .D3({U5B_out[3],U5B_out[7]}),
    .Y({SA0,SB0})
);

mux4_2n U5C(
    .EN_n(ena_4D),
    .A(BG4DaddrL[0]), 
	 .B(BG4DaddrL[1]),
    .D0({U5D_out[0],U5D_out[4]}), 
	 .D1({U5D_out[1],U5D_out[5]}), 
	 .D2({U5D_out[2],U5D_out[6]}), 
	 .D3({U5D_out[3],U5D_out[7]}),
    .Y({SA1,SB1})
);

mux4_2n U5F(
    .EN_n(ena_4E),
    .A(BG4EaddrL[0]), 
	 .B(BG4EaddrL[1]),
    .D0({U5E_out[0],U5E_out[4]}), 
	 .D1({U5E_out[1],U5E_out[5]}), 
	 .D2({U5E_out[2],U5E_out[6]}), 
	 .D3({U5E_out[3],U5E_out[7]}),
    .Y({SA2,SB2})
);

mux4_2n U5J(
    .EN_n(ena_4H),
    .A(BG4HaddrL[0]), 
	 .B(BG4HaddrL[1]),
    .D0({U5H_out[0],U5H_out[4]}), 
	 .D1({U5H_out[1],U5H_out[5]}), 
	 .D2({U5H_out[2],U5H_out[6]}), 
	 .D3({U5H_out[3],U5H_out[7]}),
    .Y({SA3,SB3})
);

reg [7:0] BG4BaddrL,BG4BaddrH,BG4DaddrL,BG4DaddrH,BG4EaddrL,BG4EaddrH,BG4HaddrL,BG4HaddrH;
reg [7:0] BG4BaddrLD,BG4DaddrLD,BG4EaddrLD,BG4HaddrLD;
reg [7:0] BG4BaddrLz,BG4DaddrLz,BG4EaddrLz,BG4HaddrLz;

always @(negedge SLD1) BG4BaddrH <= BGRAM_out;
always @(negedge SLD3) BG4DaddrH <= BGRAM_out;
always @(negedge SLD5) BG4EaddrH <= BGRAM_out;
always @(negedge SLD7) BG4HaddrH <= BGRAM_out;

always @(posedge bgclk_6) begin
	BG4BaddrL<=BG4BaddrLD;
	BG4DaddrL<=BG4DaddrLD;
	BG4EaddrL<=BG4EaddrLD;
	BG4HaddrL<=BG4HaddrLD;
end

always @(negedge bgclk_6) begin
	BG4BaddrLz<=BG4BaddrL+8'd1;
	BG4DaddrLz<=BG4DaddrL+8'd1;
	BG4EaddrLz<=BG4EaddrL+8'd1;
	BG4HaddrLz<=BG4HaddrL+8'd1;
end


ls89_ram_x2 U6UT_BG_RAM(
	.data(Z80B_databus_out),
	.addr(U7V_q),
	.clk(clkm_20MHZ),
	.nWE(Z80B_WR | BG_BUS), //write background scratch ram
	.q(BGRAM_out)
);

//sprite alternating line buffers
m2511_ram_4 sprites_10(
	.data(spbitdata_10),	
	.clk(clkm_20MHZ),
	.addr({spramaddrb_10_cnt[8:0]}),
	.nWE(sp10_WE),
	.q(spram_out_10)
);

m2511_ram_4 sprites_11(
	.data(spbitdata_11),	
	.clk(clkm_20MHZ),
	.addr({spramaddrb_11_cnt[8:0]}),
	.nWE(sp11_WE),
	.q(spram_out_11)
);

//  ****** FINAL 7-BIT ANALOGUE OUTPUT *******
assign BLUE =  {clrB1,clrB0,1'b0}; //rBLUE;
assign RED =   {clrR2,clrR1,clrR0}; //rRED;
assign GREEN = {clrG2,clrG1,clrG0}; //rGREEN;
assign H_SYNC = rVGA_HS;
assign V_SYNC = rVGA_VS;
assign H_BLANK =  pixH<96 || pixH>432;
assign V_BLANK = pixV>240 || pixV<16;

endmodule
