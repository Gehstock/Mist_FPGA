//--------------------------------------------------------------------------------------
// CRTC6845(HD46505) CORE 
//
// Version : beta 4
//
// Copyright(c) 2004 Katsumi Degawa , All rights reserved.
// Copyright(c) 2004 Tatsuyuki Satoh , All rights reserved.
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk. 
//
// VerilogHDL model of MC6845(HD46505) compatible CRTC.
// This was made for FPGA-GAME(ROCK-OLA). 
// Therefore. There is a limitation in the function. 
// 1. This doesn't implement interlace mode.
// 2. This doesn't implement light pen detection founction.
// 3. This doesn't implement cursor control founction.
//
// 4. This doesn't implement display sque (HD46505SP)
// 5. This doesn't support case Nht==0
//
// File History
//  2005. 4. 5  by T.satoh
//                bugfix port size mismatch
//  2005. 1.13  by T.satoh
//                bugfix VSYNC pulse width (line to raster)
//                bugfix NEXT_R_RA bit size mismatch.
//  2004.12. 9  by T.satoh
//                rewrite source with minimize code. (178 -> 119 slice to Spartan3 with Area optimize)
//                bugfix , bypass wite register 10H-1FH ( R_ADR width change 5bit from 4bit).
//                fix register mismatch width W_Nr,O_Nr,Nvt,Nvd and Nvsp.
//                change R_V_CNT width 9bit to 7bit.
//
//  2004.10.23  First release  
//--------------------------------------------------------------------------------------


module crtc6845s #(
  // type 0 : 6845    - Based on MC6845 datasheet
  //                  - Super-80
  // type 1 : 6845-1  - supports vsync pulse width
  //                  - Rockola, BBC Micro
  // type 2 : 6545-1  - supports vsync pulse width
  //                  - Microbee
  parameter device_type = 1
) (
// INPUT
I_E,
I_DI,
I_RS,
I_RWn,
I_CSn,
I_CLK,
I_RSTn,
I_LPSTB,

// OUTPUT
O_DO,
O_RA,
O_MA,
O_H_SYNC,
O_V_SYNC,
O_DISPTMG,
O_CURSOR

);

input  I_E;
input  [7:0]I_DI;
input  I_RS;
input  I_RWn;
input  I_CSn;

input  I_CLK;
input  I_RSTn;

input  I_LPSTB;

output [7:0]O_DO;
output [4:0]O_RA;
output [13:0]O_MA;
output O_H_SYNC;
output O_V_SYNC;
output O_DISPTMG;

output O_CURSOR;

wire   [7:0]W_Nht;
wire   [7:0]W_Nhd;
wire   [7:0]W_Nhsp;
wire   [3:0]W_Nhsw;
wire   [6:0]W_Nvt;
wire   [4:0]W_Nadj;
wire   [6:0]W_Nvd;
wire   [6:0]W_Nvsp;
wire   [3:0]W_Nvsw;
wire   [4:0]W_Nr;
wire   [13:0]W_Msa;

wire   W_Vmode;
wire   W_IntSync;
wire   [1:0] W_DScue;
wire   [1:0] W_CScue;

wire   [7:6] W_STS;

mpu_if # (
.device_type(device_type)
) mpu_if (

.I_RSTn(I_RSTn),
.I_E(I_E),
.I_DI(I_DI),
.I_RS(I_RS),
.I_RWn(I_RWn),
.I_CSn(I_CSn),
.I_STS(W_STS),

.O_DO(O_DO),
.O_Nht(W_Nht),
.O_Nhd(W_Nhd),
.O_Nhsp(W_Nhsp),
.O_Nhsw(W_Nhsw),
.O_Nvt(W_Nvt),
.O_Nadj(W_Nadj),
.O_Nvd(W_Nvd),
.O_Nvsp(W_Nvsp),
.O_Nvsw(W_Nvsw),
.O_Nr(W_Nr),
.O_Msa(W_Msa),

.O_VMode(W_Vmode),
.O_IntSync(W_IntSync),
// HD46505-SP only
.O_DScue(W_DScue),
.O_CScue(W_CScue),
.O_LPRd(W_LPRd)
);

crtc_gen crtc_gen(

.I_CLK(I_CLK),
.I_RSTn(I_RSTn),
.I_Nht(W_Nht),
.I_Nhd(W_Nhd),
.I_Nhsp(W_Nhsp),
.I_Nhsw(W_Nhsw),
.I_Nvt(W_Nvt),
.I_Nadj(W_Nadj),
.I_Nvd(W_Nvd),
.I_Nvsp(W_Nvsp),
.I_Nvsw(W_Nvsw),
.I_Nr(W_Nr),
.I_Msa(W_Msa),
.I_LPSTB(I_LPSTB),
.I_LPRd(W_LPRd),

.O_STS(W_STS),
.O_RA(O_RA),
.O_MA(O_MA),
.O_H_SYNC(O_H_SYNC),
.O_V_SYNC(O_V_SYNC),
.O_DISPTMG(O_DISPTMG)

);

endmodule


module mpu_if #(
  parameter device_type
)(

I_RSTn,
I_E,
I_DI,
I_RS,
I_RWn,
I_CSn,
I_STS,

O_DO,
O_Nht,
O_Nhd,
O_Nhsp,
O_Nhsw,
O_Nvt,
O_Nadj,
O_Nvd,
O_Nvsp,
O_Nvsw,
O_Nr,
O_Msa,

O_DScue,
O_CScue,
O_VMode,
O_IntSync,
O_LPRd
);

input I_RSTn;
input  I_E;
input  [7:0]I_DI;
input  I_RS;
input  I_RWn;
input  I_CSn;
input  [6:5]I_STS;

output [7:0]O_DO;
output [7:0]O_Nht;
output [7:0]O_Nhd;
output [7:0]O_Nhsp;
output [3:0]O_Nhsw;
output [6:0]O_Nvt;
output [4:0]O_Nadj;
output [6:0]O_Nvd;
output [6:0]O_Nvsp;
output [3:0]O_Nvsw;
output [4:0]O_Nr;
output [13:0]O_Msa;
output [1:0] O_DScue;
output [1:0] O_CScue;
output O_VMode;
output O_IntSync;
output O_LPRd;

reg   [7:0]R_DO;
reg   [4:0]R_ADR;
reg   [7:0]R_Nht;
reg   [7:0]R_Nhd;
reg   [7:0]R_Nhsp;
reg   [7:0]R_Nsw;
reg   [6:0]R_Nvt;
reg   [4:0]R_Nadj;
reg   [6:0]R_Nvd;
reg   [6:0]R_Nvsp;
reg   [7:0]R_Intr;
reg   [4:0]R_Nr;
reg   [5:0]R_Msah;
reg   [7:0]R_Msal;
reg   [7:0]R_Curh;
reg   [7:0]R_Curl;
reg   [7:0]R_Lph;
reg   [7:0]R_Lpl;
reg   R_LPRd;

assign O_DO   = R_DO;
assign O_Nht  = R_Nht;
assign O_Nhd  = R_Nhd;
assign O_Nhsp = R_Nhsp;
assign O_Nhsw = R_Nsw[3:0];
assign O_Nvt  = R_Nvt;
assign O_Nadj = R_Nadj;
assign O_Nvd  = R_Nvd;
assign O_Nvsp = R_Nvsp;
assign O_Nvsw = R_Nsw[7:4];
assign O_Nr   = R_Nr;
assign O_Msa  = {R_Msah,R_Msal};
assign O_VMode   =  R_Intr[1];
assign O_IntSync =  R_Intr[0];
// HD46505-SP only
assign O_DScue   = R_Intr[5:4]; // disp   scue 0,1,2 or OFF
assign O_CScue   = R_Intr[7:6]; // cursor scue 0,1,2 or OFF
assign O_LPRd    = R_LPRd;

always@(negedge I_RSTn or negedge I_E)
begin
  if(~I_RSTn) begin
    R_DO   <= 8'h00;
		// this is currently set for "non-interlace MODE 7"
		// - it's a fudge because this controller doesn't support interlace
    R_Nht  <= 8'h3F;				// 0
    R_Nhd  <= 8'h28;				// 1
    R_Nhsp <= 8'h33;				// 2
    // device_type=0 should default R_Nsw[7:4] to 16!
    //R_Nsw  <= 8'h24;				// 3
    R_Nsw  <= 8'h44;				// 3
    R_Nvt  <= 7'h1E;				// 4
    R_Nadj <= 5'h02;				// 5
    R_Nvd  <= 7'h19;				// 6
    R_Nvsp <= 7'h1B; //1C;				// 7
    R_Intr <= 8'h91; //93;				// 8
    R_Nr   <= 5'h09; //12;				// 9
    R_Msah <= 6'h28;				// 12
    R_Msal <= 8'h00;				// 13
	end else
  begin
    // Read-reset bit
    // - reads on R16,R17
    if (~I_CSn & I_RWn & I_RS & (R_ADR[4:1] == 4'b1000))
      R_LPRd <= 1'b1;
    else
      R_LPRd <= 1'b0;

    if(~I_CSn)begin
      if(I_RWn)begin
        // reads
        if(~I_RS)
          R_DO <= { 1'b0, I_STS, 5'b0 };
      end else begin
        // writes
        if(~I_RS)begin      
          R_ADR <= I_DI[4:0];
        end else begin
          case(R_ADR)
            5'h0 : R_Nht  <= I_DI ;
            5'h1 : R_Nhd  <= I_DI ;
            5'h2 : R_Nhsp <= I_DI ;
            5'h3 : R_Nsw  <= (device_type == 0
                                ? { R_Nsw[7:4], I_DI[3:0] }
                                : I_DI) ;
            5'h4 : R_Nvt  <= I_DI[6:0] ;
            4'h5 : R_Nadj <= I_DI[4:0] ;
            5'h6 : R_Nvd  <= I_DI[6:0] ;
            5'h7 : R_Nvsp <= I_DI[6:0] ;
            5'h8 : R_Intr <= I_DI[7:0] ;
            5'h9 : R_Nr   <= I_DI[4:0] ;
            5'hC : R_Msah <= I_DI[5:0] ;
            5'hD : R_Msal <= I_DI ;
            default:;
          endcase
        end
      end
    end
  end
end

endmodule

module crtc_gen(

I_CLK,
I_RSTn,
I_Nht,
I_Nhd,
I_Nhsp,
I_Nhsw,
I_Nvt,
I_Nadj,
I_Nvd,
I_Nvsp,
I_Nvsw,
I_Nr,
I_Msa,
I_LPSTB,
I_LPRd,

O_STS,
O_RA,
O_MA,
O_H_SYNC,
O_V_SYNC,
O_DISPTMG

);

input  I_CLK;
input  I_RSTn;
input  [7:0]I_Nht;
input  [7:0]I_Nhd;
input  [7:0]I_Nhsp;
input  [3:0]I_Nhsw;
input  [6:0]I_Nvt;
input  [4:0]I_Nr;
input  [4:0]I_Nadj;  //  (I_Nadj-1 <= I_Nr) is Support. (I_Nadj-1 > I_Nr) is Not Support.
input  [6:0]I_Nvd;
input  [6:0]I_Nvsp;
input  [3:0]I_Nvsw;
input  [13:0]I_Msa;
input  I_LPSTB;
input  I_LPRd;

output [6:5]O_STS;
output [4:0]O_RA;
output [13:0]O_MA;
output O_H_SYNC;
output O_V_SYNC;
output O_DISPTMG;

reg    [7:0]R_H_CNT;
reg    [6:0]R_V_CNT;
reg    [4:0]R_RA;
reg    [13:0]R_MA;
reg    R_H_SYNC,R_V_SYNC;
reg    R_DISPTMG ,R_V_DISPTMG;
reg    R_LAST_LINE;

// next count value (cnt+1)
wire   [7:0] NEXT_R_H_CNT = (R_H_CNT+8'h01);
wire   [6:0] NEXT_R_V_CNT = (R_V_CNT+7'h01);
wire   [4:0] NEXT_R_RA    = R_RA + 1;

// h return trigger
wire W_HD       = (R_H_CNT==I_Nht);

// v return trigger
wire W_VD       = (R_V_CNT==I_Nvt);
wire W_ADJ_C    = R_LAST_LINE & (NEXT_R_RA==I_Nadj);
wire W_VCNT_RET = ((R_RA==I_Nr) & (I_Nadj==0) & W_VD) | W_ADJ_C;

// RA return trigger
wire W_RA_C     = (R_RA==I_Nr) | W_ADJ_C;

// sync trigger
wire   W_HSYNC_P = (NEXT_R_H_CNT == I_Nhsp);
wire   W_HSYNC_W = (NEXT_R_H_CNT[3:0] == (I_Nhsp[3:0]+I_Nhsw) );
wire   W_VSYNC_P = (NEXT_R_V_CNT == I_Nvsp ) & W_RA_C;
wire   W_VSYNC_W = (NEXT_R_RA[3:0]==I_Nvsw);

// disp trigger
wire W_HDISP_N   = (NEXT_R_H_CNT==I_Nhd);
wire W_VDISP_N   = (NEXT_R_V_CNT==I_Nvd) & W_RA_C;

//output assign
assign O_H_SYNC = R_H_SYNC;
assign O_V_SYNC = R_V_SYNC;
assign O_RA     = R_RA;
assign O_MA     = R_MA;
assign O_DISPTMG = R_DISPTMG;

//  MA   MAX = 14'h3FFF  ---------------------
reg    [13:0] R_MA_C;
always@(negedge I_CLK or negedge I_RSTn)
begin
  if(! I_RSTn)begin
    R_MA   <= 14'h0000;
    R_MA_C <= 14'h0000;
    R_H_CNT <= 8'h00; 
    R_H_SYNC <= 0; 
    R_RA <= 5'h00; 

    R_V_CNT <= 7'h00; 
    R_LAST_LINE <= 1'b0;
    R_V_SYNC <= 0; 

    R_V_DISPTMG <= 1'b0;
    R_DISPTMG   <= 1'b0;
  end
  else begin
    // H CNT
    R_H_CNT <= W_HD ? 8'h00 : NEXT_R_H_CNT;

    // MA
    R_MA <= W_HD ? R_MA_C : R_MA + 1;

    // MA return address
    if(W_RA_C & (R_H_CNT==I_Nhd) )
      R_MA_C <= W_VCNT_RET ? I_Msa : R_MA;

    // HSYNC
    if(W_HSYNC_P)      R_H_SYNC <= 1'b1;
    else if(W_HSYNC_W) R_H_SYNC <= 1'b0;

    // H RETURN
    if(W_HD)
    begin
      // RA
      R_RA <= W_RA_C ? 5'h00 : NEXT_R_RA;

      // VSYNC
      if(W_VSYNC_P) R_V_SYNC <= 1'b1;
      else if(W_VSYNC_W) R_V_SYNC <= 1'b0;

      if(W_RA_C)
      begin
        // for adjust line
        R_LAST_LINE <= W_VD;

        // V CNT
        R_V_CNT <= W_VCNT_RET ? 7'h00 : NEXT_R_V_CNT;
      end
    end

    // V DISPTMG (next line)
    if(W_VCNT_RET)     R_V_DISPTMG <= 1'b1;
    else if(W_VDISP_N) R_V_DISPTMG <= 1'b0;

    // H & V DISPTMG
    if(W_HD)           R_DISPTMG <= R_V_DISPTMG;
    else if(W_HDISP_N) R_DISPTMG <= 1'b0;
  end
end

reg       R_LPSTB;
reg [6:5] R_STS;

always @(negedge I_RSTn or negedge I_CLK)
begin
  if (~I_RSTn)
  begin
    R_STS <= 2'b00;
  end else begin
    // negedge I_CLK
    if (I_LPSTB & ~R_LPSTB)
      R_STS[6] <= 1'b1;
    else if (I_LPRd)
      R_STS[6] <= 1'b0;
    R_STS[5] <= ~R_V_DISPTMG;
  end
  // edge-detect
  R_LPSTB <= I_LPSTB;
end

assign O_STS = R_STS;

endmodule
