//--------------------------------------------
// FPGA DigDug (Sprite part)
//
//					Copyright (c) 2017 MiSTer-X
//--------------------------------------------
module DIGDUG_SPRITE
(
	input				RCLK,			// Rendering Clock
	input				VCLK,			// Video Dot Clock
	input				VCLKx2,		// Video Dot Clockx2
	
	input  [8:0] 	POSH, 
	input  [8:0] 	POSV,

	output			SPATCL,
	output [6:0]	SPATAD,
	input [23:0]	SPATDT,

	output reg [4:0] SPCOL
);

wire [8:0] PH = POSH+1;
wire [8:0] PV = POSV+2;
wire [8:0] TY;


reg  [3:0] PHASE;
reg		  SIDE;

reg  [7:0] ADR;
reg [23:0] ATR0, ATR1;

reg  [8:0] WXP;
reg  [8:0] WCN;


wire 		  SZ = ATR0[7];													// Size
wire [8:0] SS = SZ ? 32 : 16;												// Size (Pixels)
wire [5:0] SC = ATR1[5:0];													// Color
wire [8:0] SX = {1'b0,ATR1[15:8]}-9'd39;								// Position X
wire [8:0] SY = (9'd256-TY);												// Position Y
wire [8:0] SU = (SS-WCN)^{9{ATR0[16]}};								// Position U
wire [8:0] SV = (PV-SY )^{9{ATR0[17]}};								// Position V
wire [7:0] SM = ATR0[7:0];													// Code (for Normal)
wire [7:0] SL = {SM[7]|SM[5],SM[6]|SM[4],SM[3:0],SV[4],SU[4]};	// Code (for Size)
wire [7:0] SN = SZ ? SL : SM;												// Code
wire		  SD = ATR1[17]|((PV<SY)&(SY<496))|(PV>=(SY+SS));		// Visiblity (False:Visible)

assign TY = ((({1'b0,ATR0[15:8]}+1)+(SZ ? 9'd16 : 9'd0)) & 9'd255) + 9'd30;

wire	ABORT	  = (PH==288);
wire 	STANDBY = (PH!=289);
wire	ATRTAIL = (ADR[7]);
wire	DRAWING = (WCN!=1);


assign SPATCL = ~RCLK;
assign SPATAD = ADR[6:0];

wire [8:0] WSX = {1'b0,SX[7:0]} + ((SX[7:0]<8'd16) ? 9'd256 : 9'd0);

always @( posedge RCLK ) begin
	if (ABORT) begin PHASE <= 0; WCN <= 0; end
	else case (PHASE)
	`define LOOP	(PHASE)
	`define NEXT	(PHASE+1)
	`define NXTA	(1)
		0: begin SIDE <= PV[0]; ADR <= 0; WCN <= 0; 	PHASE <= STANDBY ? `LOOP :	`NEXT; end
		1: begin 												PHASE <= ATRTAIL ? `NXTA : `NEXT; end
		2: begin ATR0 <= SPATDT; ADR <= ADR+1;			PHASE <= 						`NEXT; end
		3: begin ATR1 <= SPATDT; ADR <= ADR+1;			PHASE <= 			         `NEXT; end
		4: begin WXP  <= WSX;	 WCN <= SS;				PHASE <=      SD ? `NXTA :	`NEXT; end
					// CHIP Read 
		5: begin /* CLUT Read */ 							PHASE <= 						`NEXT; end
					// LBUF Write
		6: begin WXP <= WXP+1; WCN <= WCN-1;			PHASE <= DRAWING ?     5 :	`NXTA; end
		default:;
	endcase
end

wire [7:0] CHRD;
spchip_rom spchip(
	.clk(~RCLK),
	.addr({SN,SV[3],SU[3:2],SV[2:0]}),
	.data(CHRD)
);

wire [7:0] PIX = CHRD << (SU[1:0]);

wire [7:0] WDT;
spclut_rom spclut(
	.clk(RCLK),
	.addr({SC,PIX[7],PIX[3]}),
	.data(WDT)
);

wire [4:0] LBOUT;
LBUF1K lbuf (
	  ~RCLK, {SIDE,WXP}, (PHASE==6) & (PIX[7]|PIX[3]), {4'h1,WDT[3:0]},
	 VCLKx2, {~SIDE,PH}, (radr0==radr1), 8'h0, LBOUT
);

reg [9:0] radr0=0,radr1=1;
always @(posedge VCLK) radr0 <= {~SIDE,PH};
always @(negedge VCLK) begin 
	if (radr0!=radr1) SPCOL <= LBOUT;
	radr1 <= radr0;
end

endmodule

