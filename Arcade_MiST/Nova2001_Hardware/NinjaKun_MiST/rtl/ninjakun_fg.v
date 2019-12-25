// ForeGround Scanline Generator
module ninjakun_fg
(
	input					VCLK,

	input   [8:0]		PH,		// CRTC
	input	  [8:0]		PV,

	output reg [9:0]	FGVAD,	// VRAM
	input	 [15:0]		FGVDT,

	output reg [12:0]	FGCAD,
	input  [31:0]		FGCDT,

	output  [9:0]		FGOUT		// PIXEL OUT : {PRIO,PALNO[8:0]}
);

wire  [8:0] POSH  = PH+8+1;
wire  [8:0] POSV  = PV+32;

wire  [9:0] CHRNO = {1'b0,FGVDT[13],FGVDT[7:0]};
reg  [31:0] CDT;

reg   [4:0] PAL;
reg   [3:0] OUT;
always @( posedge VCLK ) begin
	case(POSH[2:0])
	 0: begin OUT <= CDT[7:4]  ; PAL   <= FGVDT[12:8]; end
	 1: begin OUT <= CDT[3:0]  ; FGVAD <= {POSV[7:3],POSH[7:3]}; end
	 2: begin OUT <= CDT[15:12]; end
	 3: begin OUT <= CDT[11:8] ; end
	 4: begin OUT <= CDT[23:20]; FGCAD <= {CHRNO,POSV[2:0]}; end
	 5: begin OUT <= CDT[19:16]; end
	 6: begin OUT <= CDT[31:28]; end
	 7: begin OUT <= CDT[27:24]; CDT   <= FGCDT; end
	endcase
end

assign FGOUT = { PAL[4], 1'b0, PAL[3:0], OUT }; 

endmodule 