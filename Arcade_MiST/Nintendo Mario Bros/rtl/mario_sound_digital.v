//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Digital sound module.
//----------------------------------------------------------------------------

module mario_sound_digital
(
   input         I_CLK_48M,
   input         I_CEN_12M,
   input         I_CEN_11M,
   input         I_RST,
   input         I_DLCLK,
   input   [16:0]I_DLADDR,
   input    [7:0]I_DLDATA,
   input         I_DLWR,
   input    [7:0]I_SND_DATA,
   input    [6:0]I_SND_CTRL,

   output   signed [15:0]O_SND_DAC,
   output   signed [15:0]O_SND_OUT

);

//----------------
// Sub CPU M58715
//----------------

wire    [7:0]M58715_DBI;
wire    [7:0]M58715_DBO;
wire    [7:0]M58715_PAI;
wire    [7:0]M58715_PBI;
wire    M58715_ALE;
wire    M58715_RDn;
wire    M58715_WRn;
wire    M58715_PSENn;

wire    [7:0]M58715_PAO = {4'b0000, I_SND_CTRL[6:3]};

M58715IP SOUND_CPU
(
   .I_CLK(I_CLK_48M),
   .I_CLK_EN(I_CEN_11M),
   .I_RSTn(I_RST),
   .I_INTn(~I_SND_CTRL[0]),
   .I_EA(~M58715_PBI[5]),
   .O_PSENn(M58715_PSENn),
   .O_RDn(M58715_RDn),
   .O_WRn(M58715_WRn),
   .O_ALE(M58715_ALE),
   .O_PROGn(),
   .I_T0(I_SND_CTRL[1]),
   .O_T0(),
   .I_T1(I_SND_CTRL[2]),
   .I_DB(M58715_DBO),
   .O_DB(M58715_DBI),
   .I_P1(M58715_PAO),
   .O_P1(M58715_PAI),
   .I_P2(8'h00),
   .O_P2(M58715_PBI)
);

//--------------------------------------------
// The Mario Bros schematics show a sound ROM
// labelled as 2732 with the pinout of a 2764.
// A 2732 is used on the real board with the 
// option of using a 2764.
// M58715 has 2KB internal ROM. The External
// 4KB ROM is accessed as 2 banks of 2KB.
//--------------------------------------------

wire    [11:0]S_ROM_A;
reg     [7:0]L_ROM_A;

reg  M58715_ALE_q;
wire M58715_ALE_fall = M58715_ALE_q & ~M58715_ALE;
always@(posedge I_CLK_48M) begin
   M58715_ALE_q <= M58715_ALE;
end

always@(posedge I_CLK_48M) begin
   if (M58715_ALE_fall)
      L_ROM_A <= M58715_DBI;
end

wire    A12      = ~M58715_RDn & ~M58715_PBI[7];
wire    S_ROM_OE = ~A12 & M58715_PSENn;

assign  S_ROM_A  = {M58715_PBI[3:0],L_ROM_A[7:0]};


reg     S_7J_OC;
always@(posedge I_CLK_48M) begin
   if (I_CEN_12M)
      S_7J_OC <= ~(~M58715_RDn & M58715_PBI[7]);
end

wire    [7:0]S_PROG_D ;

//SUB_EXT_ROM srom5k(I_CLK_48M, S_ROM_A, 1'b0, S_ROM_OE, S_PROG_D,
//                   I_CLK_48M, I_DLADDR, I_DLDATA, I_DLWR);

snd_rom snd_rom(
	.clk(I_CLK_48M & S_ROM_OE),
	.addr(S_ROM_A),
	.data(S_PROG_D)
);


// M58715 Data Bus
wire    [7:0]M58715_DO = S_7J_OC == 1'b0 ? I_SND_DATA : S_PROG_D;

reg     [7:0]DO;
always@(posedge I_CLK_48M) begin
   if (I_CEN_12M)
      DO <= M58715_DO;
end

assign  M58715_DBO = DO;

// Sound out
reg [15:0]SND_DAC;

reg  M58715_WRn_q;
wire M58715_WRn_rise = ~M58715_WRn_q & M58715_WRn;
always@(posedge I_CLK_48M) begin
   M58715_WRn_q <= M58715_WRn;
end

always@(posedge I_CLK_48M) begin
   if (M58715_WRn_rise)
      SND_DAC <= {2{~M58715_DBI[7],M58715_DBI[6:0]}}; // 16-bit signed;
end

//-----------------------------------------------------
// Sound filter
// Low pass filter. f= 1178.9 Hz @ 48KHz.
//-----------------------------------------------------

// Reduce volume
wire  [15:0]W_SND_IN = {SND_DAC[15],SND_DAC[15:1]} + {{3{SND_DAC[15]}}, SND_DAC[15:3]};

wire  [15:0]W_FILT_OUT;

iir_1st_order filter
(
   .clk(I_CLK_48M),
   .reset(~I_RST),
   .div(12'd1000), // 48Mhz / 1000 = 48KHz
   .A2(-18'sd28065),
   .B1(18'sd2352),
   .B2(18'sd2352),
   .in(W_SND_IN),
   .out(W_FILT_OUT)
);

assign  O_SND_OUT = W_FILT_OUT;

endmodule
