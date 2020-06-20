/********************************************
   I/O Module for "FPGA Gaplus"

			Copyright (c) 2007,2019 MiSTer-X
*********************************************/
module gaplus_io
(
	input			 reset,
	input			 clk,
	input	 		 VBLK,

	input	[15:0] cpu_ad,
	input			 cpu_vma,
	input			 cpu_wr,
	input	 [7:0] cpu_wd,
	output [7:0] cpu_rd,
	output		 cpu_cs,

	input	[31:0] INP0,
	input	[31:0] INP1,
	input	 [3:0] INP2,
	
	output		 pcm_kick
);

wire io_cs = ( cpu_ad[15:8] == 8'h68 ) & cpu_vma;

wire iochp0_cs = ( cpu_ad[7:4] == 4'h0 ) & io_cs;
wire iochp1_cs = ( cpu_ad[7:4] == 4'h1 ) & io_cs;
wire iocust_cs = ( cpu_ad[7:4] == 4'h2 ) & io_cs;

wire [3:0] iochp0_rd;
wire [3:0] iochp1_rd;
wire [3:0] iocust_rd;

wire [3:0] io_rd = iochp0_cs ? iochp0_rd :
						 iochp1_cs ? iochp1_rd :
						 iocust_cs ? iocust_rd :
						 4'hF;

assign cpu_cs = io_cs;
assign cpu_rd = { 4'hF, io_rd };

GAPLUS_IO_CUS0	iochp0( reset, clk, VBLK, iochp0_cs, cpu_ad[3:0], iochp0_rd, cpu_wd[3:0], cpu_wr, INP0 );
GAPLUS_IO_CUS1	iochp1( reset, clk, VBLK, iochp1_cs, cpu_ad[3:0], iochp1_rd, cpu_wd[3:0], cpu_wr, INP1 );
GAPLUS_IO_CUS2	iocust( reset, clk, iocust_cs, cpu_ad[3:0], iocust_rd, cpu_wd, cpu_wr,  pcm_kick, INP2 );

endmodule


//----------------------------------------------------------------
module GAPLUS_IO_CUS0
(
	input			 reset,
	input			 clk,
	input			 VB,
	input			 cs,
	input  [3:0] adrs,
	output [3:0] rd,
	input  [3:0] wd,
	input			 we,

	input	[31:0] INPORT
);

reg [3:0] regs [0:15];

reg [3:0] out;


reg		[7:0]	credits;
reg		[7:0]	credit_add, credit_sub;

reg	  [31:0]	pINPORT,fINPORT;
wire	  [31:0]	iINPORT = ( fINPORT ^ pINPORT ) & fINPORT;

wire		[3:0]	CREDIT_ONES, CREDIT_TENS;
BCDCONV	creditsBCD( credits, CREDIT_ONES, CREDIT_TENS );

reg pVB;

always @ ( posedge clk or posedge reset ) begin

	if ( reset ) begin
		out     <= 4'hF;
		credits <= 0;
		
		pVB <= 1'b0;
	end
	else begin

		if (~VB) pVB <= 1'b0;
		else if (~pVB) begin

			if (regs[4'h8]==4'h4) begin

				credit_add = 0;
				credit_sub = 0;

				if ( iINPORT[0] & ( credits < 99 ) ) begin
					credit_add = 8'h01;
					credits = credits + 1;
				end

				if ( regs[4'h9] == 0 ) begin
					if ( ( credits >= 2 ) & iINPORT[15] ) begin
						credit_sub = 8'h02;
						credits = credits - 2;
					end else if ( ( credits >= 1 ) & iINPORT[14] ) begin
						credit_sub = 8'h01;
						credits = credits - 1;
					end
				end
			end

			pINPORT <= fINPORT;
			fINPORT <= INPORT;
			pVB <= 1'b1;
		end

		if (cs) begin
			if (we) regs[adrs] <= wd;
			else out <= regs[adrs];
		end


		case ( regs[4'h8] )

			4'h1: begin				// Switches Input

				regs[4'h0] <= fINPORT[3:0];
				regs[4'h1] <= fINPORT[7:4];
				regs[4'h2] <= fINPORT[11:8];
				regs[4'h3] <= fINPORT[15:12];

			end

		//	4'h2: begin end		// Coinage Setting (not impl.)

			4'h4: begin				// Handle Coin & Switches Input

				regs[4'h0] <= CREDIT_TENS;
				regs[4'h1] <= CREDIT_ONES;
				regs[4'h2] <= credit_add;
				regs[4'h3] <= credit_sub;

				regs[4'h4] <= fINPORT[7:4];
				regs[4'h5] <= { fINPORT[14], iINPORT[14], fINPORT[12], iINPORT[12] };
				regs[4'h6] <= INPORT[11:8];
				regs[4'h7] <= { fINPORT[15], iINPORT[15], fINPORT[13], iINPORT[13] };

			end

			//4'h7: begin end

			4'h8: begin				// bootup check ( impl. for Gaplus )
				regs[4'h0] <= 4'h6;
				regs[4'h1] <= 4'h9;
			end

			4'h9: begin				// DIP Switches Input

				regs[4'h0] <= fINPORT[3:0];
				regs[4'h2] <= fINPORT[7:4];
				regs[4'h4] <= fINPORT[11:8];
				regs[4'h6] <= fINPORT[15:12];

				regs[4'h1] <= fINPORT[19:16];
				regs[4'h3] <= fINPORT[23:20];
				regs[4'h5] <= fINPORT[27:24];
				regs[4'h7] <= fINPORT[31:28];

			end

			default: ;

		endcase

	end

end

assign rd = out;

endmodule


//----------------------------------------------------------------
module GAPLUS_IO_CUS1
(
	input			 reset,
	input			 clk,
	input			 VB,
	input			 cs,
	input  [3:0] adrs,
	output [3:0] rd,
	input  [3:0] wd,
	input			 we,

	input [31:0] INPORT
);

reg [3:0] regs [0:15];
reg [3:0] out;

reg		[7:0]	credits;
reg		[7:0]	credit_add, credit_sub;

reg	  [31:0]	pINPORT,fINPORT;
wire	  [31:0]	iINPORT = ( fINPORT ^ pINPORT ) & fINPORT;

wire		[3:0]	CREDIT_ONES, CREDIT_TENS;
BCDCONV	creditsBCD( credits, CREDIT_ONES, CREDIT_TENS );

reg pVB;

always @ ( posedge clk or posedge reset ) begin

	if ( reset ) begin
		out <= 4'hF;
		credits <= 0;

		pVB <= 1'b0;
	end
	else begin

		if (~VB) pVB <= 1'b0;
		else if (~pVB) begin

			if (regs[4'h8]==4'h3) begin
				credit_add = 0;
				credit_sub = 0;

				if ( iINPORT[0] & ( credits < 99 ) ) begin
					credit_add = 8'h01;
					credits = credits + 1;
				end

				if ( regs[4'h9] == 0 ) begin
					if ( ( credits >= 2 ) & iINPORT[15] ) begin
						credit_sub = 8'h02;
						credits = credits - 2;
					end else if ( ( credits >= 1 ) & iINPORT[14] ) begin
						credit_sub = 8'h01;
						credits = credits - 1;
					end
				end
			end

			pINPORT <= fINPORT;
			fINPORT <= INPORT;

			pVB <= 1'b1;
		end

		if (cs) begin
			if (we) regs[adrs] <= wd;
			else out <= regs[adrs];
		end

		case ( regs[4'h8] )

			4'h1: begin				// Switches Input

				regs[4'h4] <= fINPORT[3:0];
				regs[4'h5] <= fINPORT[7:4];
				regs[4'h6] <= fINPORT[11:8];
				regs[4'h7] <= fINPORT[15:12];

			end

		//	4'h2: begin end		// Coinage Setting (not impl.)

			4'h3: begin				// Handle Coin & Switches Input

				regs[4'h0] <= credit_add;
				regs[4'h1] <= credit_sub;
				regs[4'h2] <= CREDIT_TENS;
				regs[4'h3] <= CREDIT_ONES;

				regs[4'h4] <= fINPORT[7:4];
				regs[4'h5] <= { fINPORT[14], iINPORT[14], fINPORT[12], iINPORT[12] };
				regs[4'h6] <= INPORT[11:8];
				regs[4'h7] <= { fINPORT[15], iINPORT[15], fINPORT[13], iINPORT[13] };

			end

			4'h4: begin				// DIP Switches Input

				regs[4'h0] <= fINPORT[3:0];
				regs[4'h2] <= fINPORT[7:4];
				regs[4'h4] <= fINPORT[11:8];
				regs[4'h6] <= fINPORT[15:12];

				regs[4'h1] <= fINPORT[19:16];
				regs[4'h3] <= fINPORT[23:20];
				regs[4'h5] <= fINPORT[27:24];
				regs[4'h7] <= fINPORT[31:28];

			end

			4'h5: begin				// bootup check ( impl. for GAPLUS )
				regs[4'h0] <= 4'hF;
				regs[4'h1] <= 4'hF;
			end

			default: ;

		endcase

	end

end

assign rd = out;

endmodule


//----------------------------------------------------------------
module GAPLUS_IO_CUS2
(
	input			 reset,
	input			 clk,
	input			 cs,
	input  [3:0] adrs,
	output [7:0] rd,
	input  [7:0] wd,
	input			 we,
	output		 kickpcm,
	
	input	 [3:0] INP
);

reg [7:0] mode;
reg [7:0] regs [0:15];
reg [7:0] out;

reg [8:0] nkick;

always @ ( posedge clk or posedge reset ) begin

	if ( reset ) begin
		nkick <= 0;
		out <= 8'hFF;
	end
	else begin
		if ( cs ) begin
			if ( we ) begin
				regs[adrs] <= wd;
				if ( adrs == 4'h8 ) mode <= wd;
				else if ( adrs == 4'h9 ) nkick <= 9'h1FF;
			end
			else begin
				case ( adrs )
				4'h0: out <= INP;	// {SRVSW,Cabinet,2'b11}
				4'h1: out <= ( mode == 4'h2 ) ? regs[adrs] : 4'hF;
				4'h2: out <= ( mode == 4'h2 ) ?       4'hF : 4'hE;
				4'h3: out <= ( mode == 4'h2 ) ? regs[adrs] : 4'h1;
				default: out <= regs[adrs];
				endcase
			end
		end
		if ( nkick != 0 ) nkick <= nkick - 1;
	end

end

assign rd = out;
assign kickpcm = ( nkick != 0 );

endmodule


//----------------------------------------------------------------
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


