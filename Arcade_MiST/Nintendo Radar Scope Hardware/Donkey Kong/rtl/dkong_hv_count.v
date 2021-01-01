//===============================================================================
// FPGA DONKEY KONG  H&V COUNTER
//
// Version : 2.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
// 2005- 2- 9 	some changed.
//================================================================================
//-----------------------------------------------------------------------------------------
// H_CNT[0],H_CNT[1],H_CNT[2],H_CNT[3],H_CNT[4],H_CNT[5],H_CNT[6],H_CNT[7],H_CNT[8],H_CNT[9]  
//   1/2 H     1 H     2 H      4H       8H       16 H     32H      64 H     128 H   256 H
//-----------------------------------------------------------------------------------------
// V_CNT[0], V_CNT[1], V_CNT[2], V_CNT[3], V_CNT[4], V_CNT[5], V_CNT[6], V_CNT[7]  
//    1 V      2 V       4 V       8 V       16 V      32 V      64 V     128 V 
//-----------------------------------------------------------------------------------------
// VF_CNT[0],VF_CNT[1],VF_CNT[2],VF_CNT[3],VF_CNT[4],VF_CNT[5],VF_CNT[6],VF_CNT[7]  
//    1 VF     2 VF      4 VF      8 VF      16 VF     32 VF     64 VF    128 VF 


module dkong_hv_count(
	input  I_CLK,
	input  RST_n,
	input  V_FLIP,
	output O_CLK,
	output O_CLK_EN,
	output [9:0]H_CNT,
	output [7:0]V_CNT,
	output [7:0]VF_CNT,
	output H_BLANKn,
	output V_BLANKn,
	output C_BLANKn,
	output H_SYNCn,
	output V_SYNCn
	);



parameter H_count = 1536;
parameter H_BL_P  = 511;
parameter H_BL_W  = 767;
parameter V_CL_P  = 576;
parameter V_CL_W  = 640;
parameter V_BL_P  = 239;
parameter V_BL_W  = 15;

reg    [10:0]H_CNT_r = 0;
always@(posedge I_CLK)
begin
   H_CNT_r <= (H_CNT_r == H_count - 1'b1)?  - 1'b0 : H_CNT_r + 1'b1 ;
end

assign H_CNT[9:0] = H_CNT_r[10:1];
assign O_CLK      = H_CNT_r[0]   ; 
assign O_CLK_EN   = !H_CNT_r[0];

reg    V_CLK = 1'b0;
wire   V_CLK_EN = O_CLK & H_CNT[9:0] == V_CL_P;
reg    H_BLANK = 1'b0;

always@(posedge I_CLK)
if (O_CLK) begin
  case(H_CNT[9:0])
    H_BL_P: H_BLANK <= 1;
    V_CL_P: V_CLK   <= 1;
    H_BL_W: H_BLANK <= 0;
    V_CL_W: V_CLK   <= 0;
    default:;
  endcase
end

assign H_SYNCn  = ~V_CLK;
assign H_BLANKn = ~H_BLANK;


reg    [8:0]V_CNT_r;
always@(posedge I_CLK or negedge RST_n)
begin
   if(RST_n == 1'b0)
      V_CNT_r <= 0 ;
   else if (V_CLK_EN)
      V_CNT_r <= (V_CNT_r == 255)? 9'd504 : V_CNT_r + 1'b1 ;
end

reg    V_BLANK;
always@(posedge I_CLK or negedge RST_n)
begin
   if(RST_n == 1'b0)begin
      V_BLANK <= 0 ;
   end
   else if (V_CLK_EN) begin
      case(V_CNT_r[8:0])
         V_BL_P: V_BLANK <= 1;
         V_BL_W: V_BLANK <= 0;
        default:;
      endcase
   end
end

assign V_CNT[7:0] = V_CNT_r[7:0];
assign V_SYNCn    = ~V_CNT_r[8];
assign V_BLANKn   = ~V_BLANK;
assign C_BLANKn   = ~(H_BLANK | V_BLANK);
assign VF_CNT[7:0]= V_CNT ^ {8{V_FLIP}};
 
endmodule 