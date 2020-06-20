/*************************************************
   Wave-base Sound Generator (8CH) with AUX-in

					Copyright (c) 2007,2019 MiSTer-X
**************************************************/
module WSG_8CH_AUX
(
	CLK24M,
	RST,
	
	ADDR,
	DATA,
	WE,

	WAVE_CL,
	WAVE_AD,
	WAVE_DT,

	AUX_CL,
	AUX_DT,

	WSG_ENABLE,

	SND
);

input			 CLK24M;
input			 RST;

input	 [5:0] ADDR;
input  [7:0] DATA;
input			 WE;

output		 WAVE_CL;
output [7:0] WAVE_AD;
input	 [7:0] WAVE_DT;

output		 AUX_CL;
input  [7:0] AUX_DT;

input			 WSG_ENABLE;

output [7:0] SND;


//-------------------------------------------
//  Clock Generator & Ctrl Registers
//-------------------------------------------
reg	[9:0] clk24k_cnt = 0;

wire  CLK_WSGx8  = clk24k_cnt[6];	// 24KHz*8
wire	CLK_WSG    = clk24k_cnt[9];	// 24KHz

reg	 [7:0] fl [0:7];
reg	 [7:0] fm [0:7];
reg	 [3:0] fh [0:7];
reg	 [2:0] fv [0:7];
reg	 [3:0]  v [0:7];

wire	 [2:0] ra = ADDR[5:3];
wire	 [2:0] rc = clk24k_cnt[2:0];

always @( posedge CLK24M ) begin
	if ( RST ) begin
		v[rc] <= 0;
	end
	else if ( WE ) begin
		case ( ADDR[2:0] )
		3'h3:  v[ra] <= DATA[3:0];
		3'h4: fl[ra] <= DATA;
		3'h5: fm[ra] <= DATA;
		3'h6: begin
				fh[ra] <= DATA[3:0];
				fv[ra] <= DATA[6:4];
				end
		default: begin end
		endcase
	end
	clk24k_cnt <= clk24k_cnt + 1;
end

//-------------------------------------------
//  WSG core (8ch)
//-------------------------------------------
reg	[2:0]	phase = 0;

reg	[7:0] o, ot;
reg  [19:0] c [0:7];
reg   [7:0] wa;
reg   [3:0] wm;
reg			en;

wire [19:0] fq = { fh[phase], fm[phase], fl[phase] };
wire  [7:0] va = WAVE_DT[3:0] * wm;

wire [19:0] cx = c[phase];

assign WAVE_CL = CLK_WSGx8;
assign WAVE_AD = wa;

always @ ( negedge CLK_WSGx8 ) begin
	if ( phase ) begin
		ot <= ot + (en ? { 4'h0, va[7:4] } : 8'h0);
	end else begin
		o  <= ot;
		ot <= en ? { 4'h0, va[7:4] } : 8'h0;
	end
	c[phase] <= cx + fq;
	en       <= (fq!=0);
	wm       <= v[phase];
	wa       <= { fv[phase], cx[19:15] };
	phase    <= phase + 1;
end

wire [7:0] _o = o[6:0] + AUX_DT;
wire [7:0] wsgmix = ( _o[6:0] | {7{_o[7]}} );

assign AUX_CL = CLK_WSG;
assign SND = wsgmix;

endmodule
