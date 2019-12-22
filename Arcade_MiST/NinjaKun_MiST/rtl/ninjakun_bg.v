// BackGround Scanline Generator
module ninjakun_bg
(
	input					VCLK,

	input   [8:0]		PH,		// CRTC
	input	  [8:0]		PV,

	input   [7:0]		BGSCX,	// SCRREG
	input	  [7:0]		BGSCY,

	output reg [9:0]	BGVAD,	// VRAM
	input	 [15:0]		BGVDT,

	output reg [12:0]	BGCAD,
	input  [31:0]		BGCDT,
	
	output  [8:0]		BGOUT		// OUTPUT
);

wire  [8:0] POSH  = PH+BGSCX+2;
wire  [8:0] POSV  = PV+BGSCY+32;

wire  [9:0] CHRNO = {BGVDT[15:14],BGVDT[7:0]};
reg  [31:0] CDT;

reg   [3:0] PAL;
reg   [3:0] OUT;
always @( posedge VCLK ) begin
	case(POSH[2:0])
	 0: begin OUT <= CDT[7:4]  ; PAL   <= BGVDT[11:8]; end
	 1: begin OUT <= CDT[3:0]  ; BGVAD <= {POSV[7:3],POSH[7:3]}; end
	 2: begin OUT <= CDT[15:12]; end
	 3: begin OUT <= CDT[11:8] ; end
	 4: begin OUT <= CDT[23:20]; BGCAD <= {CHRNO,POSV[2:0]}; end
	 5: begin OUT <= CDT[19:16]; end
	 6: begin OUT <= CDT[31:28]; end
	 7: begin OUT <= CDT[27:24]; CDT   <= BGCDT; end
	endcase
end

assign BGOUT = { 1'b1, PAL, OUT };

endmodule 