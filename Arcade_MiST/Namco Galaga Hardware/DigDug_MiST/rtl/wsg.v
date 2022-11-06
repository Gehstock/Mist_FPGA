//--------------------------------------------
// Wave-base Sound Generator (3ch)
//
//					Copyright (c) 2017 MiSTer-X
//--------------------------------------------
module WSG_3CH
(
   input			 CLK48M,
   input        RESET,

   input        CPUCLK,
   input  [4:0] ADRS,
   input  [3:0] DATA,
   input        WR,

	output		 WROMCLK,
   output [7:0] WROMADR,
   input  [3:0] WROMDAT,

	output		 PCMCLK,
   output [7:0] PCMOUT
);

wire WSGCLKx4;
WSGCLKGEN cgen( CLK48M, WSGCLKx4 );

wire  [2:0] W0, W1, W2;
wire  [3:0] V0, V1, V2;
wire [19:0] F0;
wire [15:0]     F1, F2;

WSGREGS regs
(
	RESET,
	CPUCLK, ADRS, WR, DATA,

	W0, W1, W2,
	V0, V1, V2,
	F0, F1, F2
);

WSGCORE core
(
	RESET, WSGCLKx4,
	WROMCLK, WROMADR, WROMDAT,

	W0, W1, W2, 
	V0, V1, V2,
	F0, F1, F2,

	PCMCLK, PCMOUT
);

endmodule


module WSGREGS
(
	input			RESET,
	input			CPUCLK,
	input [4:0]	ADRS,
	input			WR,
	input [3:0]	DATA,
	
	output reg  [2:0] W0,
	output reg  [2:0] W1,
	output reg  [2:0] W2,

	output reg  [3:0] V0,
	output reg  [3:0] V1,
	output reg  [3:0] V2,
 
	output reg [19:0] F0,
	output reg [15:0] F1,
	output reg [15:0] F2
);

always @ ( posedge CPUCLK or posedge RESET ) begin

   if ( RESET ) begin

      W0 <= 0;
      W1 <= 0;
      W2 <= 0;

      F0 <= 0;
      F1 <= 0;
      F2 <= 0;

      V0 <= 0;
      V1 <= 0;
      V2 <= 0;

   end
   else begin

      if ( WR ) case ( ADRS )

      5'h05: W0 <= DATA[2:0];
      5'h0A: W1 <= DATA[2:0];
      5'h0F: W2 <= DATA[2:0];

      5'h15: V0 <= DATA;
      5'h1A: V1 <= DATA;
      5'h1F: V2 <= DATA;

      5'h10: F0[3:0]   <= DATA;
      5'h11: F0[7:4]   <= DATA;
      5'h12: F0[11:8]  <= DATA;
      5'h13: F0[15:12] <= DATA;
      5'h14: F0[19:16] <= DATA;

      5'h16: F1[3:0]   <= DATA;
      5'h17: F1[7:4]   <= DATA;
      5'h18: F1[11:8]  <= DATA;
      5'h19: F1[15:12] <= DATA;

      5'h1B: F2[3:0]   <= DATA;
      5'h1C: F2[7:4]   <= DATA;
      5'h1D: F2[11:8]  <= DATA;
      5'h1E: F2[15:12] <= DATA;

      default:;

      endcase

   end

end

endmodule


module WSGCORE
(
	input				RESET,
	input				WSGCLKx4,

	output			WROMCLK,
	output [7:0]	WROMADR,
	input  [3:0]	WROMDAT,

	input  [2:0]	W0,
	input  [2:0]	W1,
	input  [2:0]	W2,

	input  [3:0]	V0,
	input  [3:0]	V1,
	input  [3:0]	V2,

	input [19:0]	F0,
	input [15:0]	F1,
	input [15:0]	F2,

	output reg			outclk,
	output reg [7:0]	sndout
);

reg   [7:0] waveadr, cc1, cc2;

reg  [19:0] c0;
reg  [15:0] c1, c2;

reg   [3:0] wavevol;
wire  [7:0] waveout = wavevol * WROMDAT;

reg   [9:0] sndmix;
wire [10:0] sndmixdown = { 1'b0, sndmix };

reg   [1:0] phase;
always @ ( posedge WSGCLKx4 or posedge RESET ) begin

   if ( RESET ) begin
      phase  <= 0;
      sndout <= 0;
		outclk <= 0;
		cc1    <= 0;
		cc2    <= 0;
   end
   else begin

      case ( phase )

      0: begin
            sndout  <= ( sndmixdown[9:2] | {8{sndmixdown[10]}} );

				cc1     <= {W1,c1[15:11]};
				cc2     <= {W2,c2[15:11]};

            sndmix  <= 0;
            waveadr <= {W0,c0[19:15]};
            wavevol <= (F0!=0) ? V0 : 0;
         end

      1: begin
				outclk  <= 1'b1;
            sndmix  <= sndmix + waveout;

            waveadr <= cc1;
            wavevol <= (F1!=0) ? V1 : 0;
         end

      2: begin
            sndmix  <= sndmix + waveout;

            waveadr <= cc2;
            wavevol <= (F2!=0) ? V2 : 0;
         end

      3: begin
				outclk  <= 0;
            sndmix  <= sndmix + waveout;
         end

			default:;

      endcase

      phase <= phase+1;

      c0 <= c0 + F0;
      c1 <= c1 + F1;
      c2 <= c2 + F2;

   end

end

assign WROMCLK = ~WSGCLKx4;
assign WROMADR = waveadr;

endmodule


/*
   Clock Generator
     in: 48000000Hz -> out: 96000Hz
*/
module WSGCLKGEN( input in, output reg out );
reg [7:0] count;
always @( posedge in ) begin
	if (count > 8'd249) begin
		count <= count - 8'd249;
      out <= ~out;
	end
   else count <= count + 8'd1;
end
endmodule

