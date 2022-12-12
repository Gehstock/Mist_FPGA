/*******************************************
   Wave-base Sound Generator (8CH)

				Copyright (c) 2007 MiSTer-X
********************************************/
module WSG_8CH
(
	input      MCLK,

	input	 [5:0] ADDR,
	input  [7:0] DATA,
	input			 WE,

	input			 SND_ENABLE,

	output		 WAVE_CLK,
	output [7:0] WAVE_AD,
	input  [3:0] WAVE_DT,
	
	output reg [7:0] SOUT
);

//-------------------------------------------
//  Clock Generator & Ctrl Registers
//-------------------------------------------
reg	[10:0] clk24k_cnt = 0;

wire  CLK_WSGx8  = clk24k_cnt[7];	// 24KHz*8
wire	CLK_WSG    = clk24k_cnt[10];	// 24KHz
wire  CLK24M_EN  = clk24k_cnt[0];
wire  CLK_WSGx8_EN = clk24k_cnt[6:0] == 7'b1111111;
wire  CLK_WSG_EN   = clk24k_cnt[9:0] == 10'b1111111111;

reg	 [7:0] fl [0:7];
reg	 [7:0] fm [0:7];
reg	 [3:0] fh [0:7];
reg	 [2:0] fv [0:7];
reg	 [3:0]  v [0:7];
reg  [4:0] ct [0:7];

wire	 [2:0] ra = ADDR[5:3];

always @( posedge MCLK ) begin
	if ( CLK24M_EN & WE ) begin
		case ( ADDR[2:0] )
		3'h2: ct[ra] <= DATA[4:0];
		3'h3:  v[ra] <= DATA[3:0];
		3'h4: fl[ra] <= DATA;
		3'h5: fm[ra] <= DATA;
		3'h6: begin
				fh[ra] <= DATA[3:0];
				fv[ra] <= DATA[6:4];
				end

		default: ;
		endcase
	end
	clk24k_cnt <= clk24k_cnt+1'd1;
end

//-------------------------------------------
//  WSG core (8ch)
//-------------------------------------------
reg	[2:0]	phase = 0;

reg	[7:0] o, ot;
reg  [19:0] c [0:7];
reg   [7:0] wa;
reg   [3:0] wm;

wire  [7:0] va = WAVE_DT * wm;

wire [19:0] cx = c[phase];
wire [19:0] fq = { fh[phase], fm[phase], fl[phase] };
wire  [4:0] ctx = ct[phase];

assign WAVE_CLK = CLK_WSGx8;
assign WAVE_AD  = wa;

always @ ( posedge MCLK ) begin
 if (CLK_WSGx8_EN) begin
	if ( phase ) begin
		ot <= ot + { 4'h0, va[7:4] };
	end
	else begin
		o  <= ot;
		ot <= { 4'h0, va[7:4] };
	end
	c[phase] <= cx + fq;
	wm       <= v[phase];
	wa       <= { fv[phase], fq == 0 ? ctx[4:0] : cx[19:15] };
	phase    <= phase + 1'd1;
 end
end

wire [6:0] wsgmix = ( o[6:0] | {7{o[7]}} );

always @ ( posedge MCLK ) begin
	if (CLK_WSG_EN) SOUT <= SND_ENABLE ? { wsgmix, 1'b0 } : 8'd0;
end

endmodule

