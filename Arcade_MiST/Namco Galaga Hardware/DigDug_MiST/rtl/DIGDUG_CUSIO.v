//-----------------------------------------------
// FPGA DigDug (Custom I/O chip emulation part)
//
//						Copyright (c) 2017 MiSTer-X
//-----------------------------------------------
module DIGDUG_CUSIO
(
	input				RESET,
	input				VBLK,

	input  [7:0]	INP0,
	input  [7:0]	INP1,
	input  [7:0]	DSW0,
	input  [7:0]	DSW1,

	input				CL,
	input				CS,
	input				WR,
	input  [4:0]	AD,
	input	 [7:0]	DI,
	output [7:0]	DO,
	output		   NMI0
);

reg		  MODE;
reg  [7:0] COMMAND;

reg  [3:0] r2, r3, r4, r5;
reg  [3:0] LCINPCRE, LCREPCIN, LCOINS;
reg  [3:0] RCINPCRE, RCREPCIN, RCOINS;
reg		  CREDITAT;
reg  [7:0] CREDITS;

reg [11:0] CLK50uc;
reg        CLK50u;

always @( posedge CL ) begin
	if (RESET) begin
		CLK50u  <= 0;
		CLK50uc <= 0;
	end
	else begin
		if ( CLK50uc == 2200 ) CLK50u <= 1'b1;
		if ( CLK50uc == 2400 ) begin
			CLK50u  <= 1'b0;
			CLK50uc <= 0;
		end
		else CLK50uc <= CLK50uc + 1;
	end
end

reg    NMI0EN = 1'b0;
assign NMI0 = NMI0EN & CLK50u;

always @( posedge CL or posedge RESET ) begin
	if (RESET) begin
		NMI0EN  <= 0;
		MODE    <= 0;
		COMMAND <= 0;

		LCINPCRE <= 0;
		LCREPCIN <= 0;
		RCINPCRE <= 0;
		RCREPCIN <= 0;
		CREDITAT <= 0;
	end
	else begin
		if (CS&WR) begin
			if (AD[4]) begin
				// command write
				COMMAND <= DI;
				MODE    <= (DI==8'hA1) ? 1'b1 : ((DI==8'hC1)|(DI==8'hE1)) ? 0 : MODE;
				NMI0EN  <= (DI!=8'h10);
			end
			else begin
				// data write
				if (COMMAND == 8'hC1) case (AD[3:0])
					4'h2: r2 <= DI[3:0];
					4'h3: r3 <= DI[3:0];
					4'h4: r4 <= DI[3:0];
					4'h5: r5 <= DI[3:0];
					4'h8: begin
							LCINPCRE <= r2;
							LCREPCIN <= r3;
							RCINPCRE <= r4;
							RCREPCIN <= r5;
							CREDITAT <= 1'b1;
							end
					default:;
				endcase
			end
		end
	end
end


// data read
wire [3:0] ADR     = AD[3:0];
wire [7:0] NONE    = 8'hFF;

reg  [7:0] SW_CC;
reg  [7:0] SW_P1;
reg  [7:0] SW_P2;

wire [7:0] ST_CC;
BCDCONV bcd( CREDITS, ST_CC[3:0], ST_CC[7:4] );

reg  [7:0] ST_P1   = 8'hF8;
reg  [7:0] ST_P2   = 8'hF8;

wire [7:0] SWMODE  = (ADR==0) ? (~SW_CC) :
							(ADR==1) ? (~SW_P1) :
							(ADR==2) ? (~SW_P2) : NONE;

wire [7:0] STMODE  = (ADR==0) ? ST_CC :
							(ADR==1) ? ST_P1 :
							(ADR==2) ? ST_P2 : NONE;

wire [7:0] READh71 = MODE ? SWMODE : STMODE;

wire [7:0] READhB1 = {8{~(ADR<=2)}};

wire [7:0] READhD2 = (ADR==0) ? DSW0 :
							(ADR==1) ? DSW1 : NONE;

wire [7:0] READDAT = (COMMAND == 8'h71) ? READh71 :
							(COMMAND == 8'hB1) ? READhB1 :
							(COMMAND == 8'hD2) ? READhD2 : NONE;

assign DO = AD[4] ? COMMAND : READDAT;

//------------------------------------------------------------

// INP0 = { SERVICE, 1'b0, m_coin2, m_coin1, m_start2, m_start1, m_pump2, m_pump1 };
// INP1 = { m_left2, m_down2, m_right2, m_up2, m_left1, m_down1, m_right1, m_up1  };

reg  [15:0] pINP,piINP,piINP0,piINP1,piINP2;
wire [15:0] nINP = {INP0,INP1}; 
wire [15:0] iINP = (pINP^nINP) & nINP;

function [3:0] stick;
input [3:0] stk;
	stick =  stk[0] ? 0 :
			   stk[1] ? 2 :
			   stk[2] ? 4 :
			   stk[3] ? 6 : 8;
endfunction

always @( posedge VBLK or posedge RESET ) begin
	if (RESET) begin
		LCOINS   = 0;
		RCOINS   = 0;
		CREDITS  = 0;

		SW_CC <= 0;
		SW_P1 <= 0;
		SW_P2 <= 0;
		ST_P1 <= 8'hF8;
		ST_P2 <= 8'hF8;

		pINP   <= 0;
		piINP  <= 0;
		piINP0 <= 0;
		piINP1 <= 0;
		piINP2 <= 0;
	end
	else begin

		SW_CC <= {nINP[15],1'b0,piINP[11],piINP[10],2'b00,iINP[13],iINP[12]};
		SW_P1 <= {2'b00, pINP[8], iINP[8],nINP[3:0]};
		SW_P2 <= {2'b00, pINP[9], iINP[9],nINP[7:4]};
		ST_P1 <= {2'b11,~pINP[8],~iINP[8],stick(nINP[3:0])};
		ST_P2 <= {2'b11,~pINP[9],~iINP[9],stick(nINP[7:4])};

		if (CREDITAT) begin
			if ( LCINPCRE > 0 ) begin
				if ( iINP[12] & ( CREDITS < 99 ) ) begin
					LCOINS = LCOINS+1;
					if ( LCOINS >= LCINPCRE ) begin
						CREDITS = CREDITS + LCREPCIN;
						LCOINS = 0;
					end
				end
				if ( iINP[13] & ( CREDITS < 99 ) ) begin
					RCOINS = RCOINS+1;
					if ( RCOINS >= RCINPCRE ) begin
						CREDITS = CREDITS + RCREPCIN;
						RCOINS = 0;
					end
				end
			end
			else CREDITS = 2;
			if ( CREDITS > 99 ) CREDITS = 99;

			if ( piINP[10] & (CREDITS >= 1) ) CREDITS = CREDITS-1;
			if ( piINP[11] & (CREDITS >= 2) ) CREDITS = CREDITS-2;
		end

		pINP   <= nINP;
		piINP0 <= iINP;
		piINP1 <= piINP0;
		piINP2 <= piINP1;
		piINP  <= piINP2;		// delay start buttons
		
	end
end

endmodule



//----------------------------------------
//  BCD Converter
//----------------------------------------
module add3(in,out);

input [3:0] in;
output [3:0] out;
reg [3:0] out;

always @ (in)
	case (in)
	4'b0000: out <= 4'b0000;
	4'b0001: out <= 4'b0001;
	4'b0010: out <= 4'b0010;
	4'b0011: out <= 4'b0011;
	4'b0100: out <= 4'b0100;
	4'b0101: out <= 4'b1000;
	4'b0110: out <= 4'b1001;
	4'b0111: out <= 4'b1010;
	4'b1000: out <= 4'b1011;
	4'b1001: out <= 4'b1100;
	default: out <= 4'b0000;
	endcase

endmodule


module BCDCONV(A,ONES,TENS);

input  [7:0] A;
output [3:0] ONES, TENS;
wire   [3:0] c1,c2,c3,c4,c5,c6,c7;
wire   [3:0] d1,d2,d3,d4,d5,d6,d7;

assign d1 = {1'b0,A[7:5]};
assign d2 = {c1[2:0],A[4]};
assign d3 = {c2[2:0],A[3]};
assign d4 = {c3[2:0],A[2]};
assign d5 = {c4[2:0],A[1]};
assign d6 = {1'b0,c1[3],c2[3],c3[3]};
assign d7 = {c6[2:0],c4[3]};

add3 m1(d1,c1);
add3 m2(d2,c2);
add3 m3(d3,c3);
add3 m4(d4,c4);
add3 m5(d5,c5);
add3 m6(d6,c6);
add3 m7(d7,c7);

assign ONES = {c5[2:0],A[0]};
assign TENS = {c7[2:0],c5[3]};

endmodule

