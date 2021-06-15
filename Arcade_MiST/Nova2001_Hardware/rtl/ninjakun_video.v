// Copyright (c) 2011,19 MiSTer-X

module NINJAKUN_VIDEO
(
	input         RESET,
	input         MCLK,
	input         PCLK_EN,
	input   [1:0] HWTYPE,

	input   [8:0] PH,
	input   [8:0] PV,

	output  [8:0] PALAD,	// Pixel Output (Palet Index)

	output  [9:0] FGVAD,	// FG
	input  [15:0] FGVDT,

	output  [9:0] BGVAD,	// BG
	input  [15:0] BGVDT,
	input   [7:0] BGSCX,
	input   [7:0] BGSCY,

	output [10:0] SPAAD,	// Sprite
	input   [7:0] SPADT,

	output        VBLK,
	input         DBGPD,	// Palet Display (for Debug)

	output [13:0] sp_rom_addr,
	input  [31:0] sp_rom_data,
	input         sp_rdy,
	output [12:0] fg_rom_addr,
	input  [31:0] fg_rom_data,
	output [13:0] bg_rom_addr,
	input  [31:0] bg_rom_data
);

`include "rtl/defs.v"

assign VBLK = (PV>=193);

// ROMs
wire			SPCFT = sp_rdy;
wire [13:0]	SPCAD;
wire [31:0]	SPCDT;

wire [12:0]	FGCAD;
wire [31:0]	FGCDT;

wire [13:0] BGCAD;
wire [31:0] BGCDT;

//NJFGROM sprom(~VCLKx4, SPCAD, SPCDT, ROMCL, ROMAD, ROMDT, ROMEN);
//NJFGROM fgrom(  ~VCLK, FGCAD, FGCDT, ROMCL, ROMAD, ROMDT, ROMEN);
//NJBGROM bgrom(  ~VCLK, BGCAD, BGCDT, ROMCL, ROMAD, ROMDT, ROMEN);

assign sp_rom_addr = SPCAD;
assign SPCDT = sp_rom_data;
assign fg_rom_addr = FGCAD;
assign FGCDT = fg_rom_data;

assign bg_rom_addr = BGCAD;
assign BGCDT = bg_rom_data;

// Fore-Ground Scanline Generator
wire		  FGPRI;
wire [8:0] FGOUT;
NINJAKUN_FG fg(
  MCLK, PCLK_EN, HWTYPE,
	PH, PV,
	FGVAD, FGVDT,
	FGCAD, FGCDT,
  {FGPRI, FGOUT}
);
wire FGOPQ = HWTYPE != `HW_PKUNWAR & (FGOUT[3:0]!=0);
wire FGPPQ = HWTYPE != `HW_PKUNWAR & FGOPQ & (~FGPRI);

// Back-Ground Scanline Generator
wire [8:0] BGOUT, BGPRI;

NINJAKUN_BG bg(
	MCLK, PCLK_EN, HWTYPE,
	PH, PV,
	BGSCX, BGSCY,
	BGVAD, BGVDT,
	BGCAD, BGCDT,
	BGOUT, BGPRI
);

wire BGFRC = BGPRI && BGOUT[3:0] != 0;

// Sprite Scanline Generator
wire [8:0] SPOUT;

NINJAKUN_SP sp(
	MCLK, PCLK_EN, RESET, (HWTYPE == `HW_PKUNWAR || HWTYPE == `HW_RAIDERS5),
	PH, PV,
	SPAAD, SPADT,
	SPCAD, SPCDT, SPCFT,
	SPOUT
);
wire SPOPQ = (SPOUT[3:0]!=0);

// Palet Display (for Debug)
wire [8:0] PDOUT = (PV[7]|PV[8]) ? 9'd0 : {PV[6:2],PH[7:4]};

// Color Mixer
assign PALAD = DBGPD ? PDOUT :
               BGFRC ? BGOUT :
               FGPPQ ? FGOUT :
               SPOPQ ? SPOUT :
               FGOPQ ? FGOUT :
               BGOUT;

endmodule

// ForeGround Scanline Generator
module NINJAKUN_FG
(
	input         MCLK,
	input         PCLK_EN,
	input   [1:0] HWTYPE,

	input   [8:0] PH,		// CRTC
	input   [8:0] PV,

	output reg [9:0] FGVAD,	// VRAM
	input  [15:0] FGVDT,

	output reg [12:0] FGCAD,
	input  [31:0] FGCDT,

	output  [9:0] FGOUT		// PIXEL OUT : {PRIO,PALNO[8:0]}
);

wire  [8:0] POSH  = PH+9'd8+9'd1;
wire  [8:0] POSV  = PV+9'd32;

wire  [9:0] CHRNO = (HWTYPE == `HW_RAIDERS5 || HWTYPE == `HW_NOVA2001) ? {2'b00, FGVDT[7:0]} : {1'b0,FGVDT[13],FGVDT[7:0]};
reg  [31:0] CDT;

reg   [4:0] PAL;
reg   [3:0] OUT;
always @( posedge MCLK ) begin
	if (PCLK_EN)
	case(POSH[2:0])
	 0: begin OUT <= CDT[7:4]  ; PAL   <= HWTYPE == `HW_RAIDERS5 ? {1'b0, FGVDT[15:12]} : FGVDT[12:8]; end
	 1: begin OUT <= CDT[3:0]  ; FGVAD <= {POSV[7:3],POSH[7:3]}; end
	 2: begin OUT <= CDT[15:12]; end
	 3: begin OUT <= CDT[11:8] ; end
	 4: begin OUT <= CDT[23:20]; FGCAD <= {CHRNO,POSV[2:0]}; end
	 5: begin OUT <= CDT[19:16]; end
	 6: begin OUT <= CDT[31:28]; end
	 7: begin OUT <= CDT[27:24]; CDT   <= FGCDT; end
	endcase
end

assign FGOUT = HWTYPE == `HW_NOVA2001 ? (OUT == 4'h1 ? PAL : { PAL[4], OUT }) : { PAL[4], 1'b0, PAL[3:0], OUT };

endmodule


// BackGround Scanline Generator
module NINJAKUN_BG
(
	input         MCLK,
	input         PCLK_EN,
	input   [1:0] HWTYPE,

	input   [8:0] PH,		// CRTC
	input   [8:0] PV,

	input   [7:0] BGSCX,	// SCRREG
	input   [7:0] BGSCY,

	output reg [9:0] BGVAD,	// VRAM
	input  [15:0] BGVDT,

	output reg [13:0] BGCAD,
	input  [31:0] BGCDT,

	output  [8:0] BGOUT,	// OUTPUT
	output reg    BGPRI
);

wire  [8:0] POSH  = PH+BGSCX+((HWTYPE == `HW_NOVA2001 || HWTYPE == `HW_PKUNWAR) ? 9'd9 : 9'd2) /* synthesis keep */;
wire  [8:0] POSV  = PV+BGSCY+9'd32;

wire  [10:0] CHRNO = HWTYPE == `HW_RAIDERS5 ? {2'b10, BGVDT[8:0]} : 
                     HWTYPE == `HW_NOVA2001 ? {3'b110, BGVDT[7:0]}:
					 HWTYPE == `HW_PKUNWAR  ? BGVDT[10:0]:
                     {1'b1,BGVDT[15:14],BGVDT[7:0]};
reg  [31:0] CDT;

reg   [3:0] PAL;
reg   [3:0] OUT;
always @( posedge MCLK ) begin
	if (PCLK_EN)
	case(POSH[2:0])
	 0: begin OUT <= CDT[7:4]  ;
		      PAL   <= (HWTYPE == `HW_RAIDERS5 || HWTYPE == `HW_PKUNWAR) ? BGVDT[15:12] : BGVDT[11:8];
		      BGPRI <= HWTYPE == `HW_PKUNWAR && BGVDT[11];
		end
	 1: begin OUT <= CDT[3:0]  ; BGVAD <= {POSV[7:3],POSH[7:3]}; end
	 2: begin OUT <= CDT[15:12]; end
	 3: begin OUT <= CDT[11:8] ; end
	 4: begin OUT <= CDT[23:20]; BGCAD <= {CHRNO,POSV[2:0]}; end
	 5: begin OUT <= CDT[19:16]; end
	 6: begin OUT <= CDT[31:28]; end
	 7: begin OUT <= CDT[27:24]; CDT   <= BGCDT; end
	endcase
end

assign BGOUT = HWTYPE[1] ? {1'b1, (OUT == 4'h1 ? PAL : OUT)} : { 1'b1, PAL, OUT };

endmodule
