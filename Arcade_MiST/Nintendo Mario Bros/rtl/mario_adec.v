//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Address decoding.
//----------------------------------------------------------------------------

module mario_adec
(
   input        I_CLK_48M,
   input        I_CEN_12M,
   input        I_CEN_4Mp,
   input        I_CEN_4Mn,
   input        I_RESET_n,
   input  [15:0]I_AB,
   input   [7:0]I_DB,
   input        I_MREQ_n,
   input        I_RFSH_n,
   input        I_RD_n,
   input        I_WR_n,
   input        I_VRAMBUSY_n,
   input        I_VBLK_n,
   output       O_WAIT_n,
   output       O_NMI_n,
   output  [3:0]O_MROM_CSn,
   output  [1:0]O_MRAM_CSn,
   output       O_3J_G_n,        // To LS245. Not used?
   output       O_OBJ_RQ_n,      // 7000 H - 73FF H
   output       O_OBJ_RD_n,      // 7000 H - 73FF H  (R mode)
   output       O_OBJ_WR_n,      // 7000 H - 73FF H  (W mode)
   output       O_VRAM_RD_n,     // 7400 H - 77FF H  (R mode)
   output       O_VRAM_WR_n,     // 7400 H - 77FF H  (W mode)
   output       O_SW1_OE_n,      // 7C00 H           (R mode)
   output       O_SW2_OE_n,      // 7C80 H           (R mode)
   output       O_DIPSW_OE_n,    // 7F80 H           (R mode)
   output  [7:0]O_4C_Q,          // Misc addressing
   output  [7:0]O_2L_Q,          // Misc control signals
   output  [7:0]O_7M_Q,          // Sound control signals
   output  [7:0]O_7J_Q           // Sound data
);

//----------
// CPU WAIT
//----------

reg    W_3D_Q;
reg    W_4D1_Qn;
assign O_WAIT_n = W_4D1_Qn;

always@(posedge I_CLK_48M or negedge I_VBLK_n)
begin
   if(I_VBLK_n == 1'b0)
      W_4D1_Qn <= 1'b1;
   else  if (I_CEN_4Mp)
      W_4D1_Qn <= I_VRAMBUSY_n | W_4A2_Q[1] | ~I_RFSH_n;
end

// Enable signal for writing to VRAM and OBJRAM.
always@(posedge I_CLK_48M)
begin
   W_3D_Q <= W_4D1_Qn;
end

//-----------------------------------------------
// CPU NMI
// NMI is activated at the start of each VBLANK.
// CPU can clear the NMI via register @ 2L.
//-----------------------------------------------

wire  W_VBLK = ~I_VBLK_n;
reg   W_VBLK_q;
reg   W_4D2_Q;

always@(posedge I_CLK_48M) begin
   W_VBLK_q <= W_VBLK;
end
wire W_VBLK_rise = ~W_VBLK_q & W_VBLK;

always@(posedge I_CLK_48M or negedge W_2L_Q[4])
begin
   if(~W_2L_Q[4])
      W_4D2_Q <= 1'b1;
   else if (W_VBLK_rise)
      W_4D2_Q <= 1'b0;
end

assign O_NMI_n = W_4D2_Q;

//---------------------------
// Address Decoder PROM @ 5B
//---------------------------

wire  [7:0]W_PROM5B_Q;

//ADEC_PROM prom5b(I_CLK_48M, I_AB[15:11], W_PROM5B_Q, 
//                 I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

adec_5p adec_5p(
	.clk(I_CLK_48M),
	.addr(I_AB[15:11]),
	.data(W_PROM5B_Q)
);

assign O_MROM_CSn = {W_PROM5B_Q[7],W_PROM5B_Q[2:0]};

//--------------
// 74LS139 @ 4A
//--------------

wire   [3:0]W_4A1_Q, W_4A2_Q;

logic_74xx139 U_4A_1
(
   .I_G(W_PROM5B_Q[4]),
   .I_Sel({1'b0,I_AB[11]}),
   .O_Q(W_4A1_Q)
);

// This output goes to a LS245 @ 7H enable which is not used in the FPGA implementation.
assign O_3J_G_n = W_4A1_Q[0] & W_4C_Q[2] & W_4C_Q[3]; 

logic_74xx139 U_4A_2
(
   .I_G(W_PROM5B_Q[4] | I_MREQ_n),
   .I_Sel(I_AB[11:10]),
   .O_Q(W_4A2_Q)
);

assign O_OBJ_RQ_n = W_4A2_Q[0];

//------------------------------------
// 74LS138 @ 3A
// Address decoding 7000H - 7FFFH (R)
//------------------------------------

wire  [7:0]W_3A_Q;

logic_74xx138 U_3A
(
   .I_G1(1'b1),
   .I_G2a(I_RD_n),
   .I_G2b(I_MREQ_n),
   .I_Sel({W_PROM5B_Q[4],I_AB[11:10]}),
   .O_Q(W_3A_Q)
);

assign O_OBJ_RD_n  = W_3A_Q[0]; // 7000H - 73FFH - Sprite RAM (R)
assign O_VRAM_RD_n = W_3A_Q[1]; // 7400H - 77FFH - VRAM (R)

//------------------------------------
// 74LS138 @ 3B
// Address decoding 7000H - 7FFFH (W)
//------------------------------------

wire  [7:0]W_3B_Q;

logic_74xx138 U_3B
(
   .I_G1(W_3D_Q),
   //.I_G1(1'b1), // No Wait
   .I_G2a(I_WR_n),
   .I_G2b(I_MREQ_n),
   .I_Sel({W_PROM5B_Q[4],I_AB[11:10]}),
   .O_Q(W_3B_Q)
);

assign O_OBJ_WR_n  = W_3B_Q[0]; // 7000H - 73FFH - Sprite RAM (W)
assign O_VRAM_WR_n = W_3B_Q[1]; // 7400H - 77FFH - VRAM (W)

//--------------------------------------
// 74LS138 @ 3C
// Address decoding 6000H - 6FFFH (R/W)
// RAM0 @ 7B - 6000H - 67FFH
// RAM1 @ 7A - 6800H - 6FFFH
//--------------------------------------

wire  [7:0]W_3C_Q;

logic_74xx138 U_3C
(
   .I_G1(1'b1),
   .I_G2a(I_MREQ_n),
   .I_G2b(I_RD_n & I_WR_n),
   .I_Sel({W_PROM5B_Q[3],1'b0, I_AB[11]}),
   .O_Q(W_3C_Q)
);

assign O_MRAM_CSn = W_3C_Q[1:0];

//------------------------------------
// 74LS138 @ 4B
// Address decoding 7C00H - 7FFFH (R)
// Enable signals for reading inputs
// and and DIP switches
//------------------------------------

wire [7:0]W_4B_Q;

logic_74xx138 U_4B
(
   .I_G1(1'b1),
   .I_G2a(I_RD_n),
   .I_G2b(W_4A2_Q[3]),
   .I_Sel(I_AB[9:7]),
   .O_Q(W_4B_Q)
);

assign O_SW1_OE_n   = W_4B_Q[0]; // 7C00H - Service,2P Start,1P Start,Jump,D,U,L,R
assign O_SW2_OE_n   = W_4B_Q[1]; // 7C80H - x,Coin 2,Coin 1,Jump2,2D,2U,2L,2R
assign O_DIPSW_OE_n = W_4B_Q[7]; // 7F80H - Dip switches

//------------------------------------
// 74LS138 @ 4C
// Address decoding 7C00H - 7FFFH (W)
// Miscellaneous addressing.
//------------------------------------

wire [7:0]W_4C_Q;

logic_74xx138 U_4C
(
   .I_G1(1'b1),
   .I_G2a(I_WR_n),
   .I_G2b(W_4A2_Q[3]),
   .I_Sel(I_AB[9:7]),
   .O_Q(W_4C_Q)
);

// W_4C_Q[0] - 7C00H - Mario Walk analogue sound trigger
// W_4C_Q[1] - 7C80H - Luigi Walk analogue sound trigger
// W_4C_Q[2] - 7D00H - V MOV, Vertical scroll register select
// W_4C_Q[3] - 7D80H - ??? Write to video.
// W_4C_Q[4] - 7E00H - Write to sound register (sound select) (7J).
// W_4C_Q[5] - 7E80H - Enable for misc. control signals (2L).
// W_4C_Q[6] - 7F00H - Enable for sound port (7M).
assign O_4C_Q = W_4C_Q;

//--------------------------------------
// 74LS259 @ 2L
// Misc control signals (7E80H - 7E87H)
//--------------------------------------

reg   [7:0]W_2L_Q;

always@(posedge I_CLK_48M or negedge I_RESET_n)
begin
   if(I_RESET_n == 1'b0) begin
      W_2L_Q <= 0;
   end 
   else if (I_CEN_12M) begin
      if(W_4C_Q[5] == 1'b0) begin
         case(I_AB[2:0])
            3'h0 : W_2L_Q[0] <= I_DB[0]; // 7E80H - T ROM - GFX bank select
            3'h1 : W_2L_Q[1] <= I_DB[0]; // 7E81H - 2PSL - sprite bank select
            3'h2 : W_2L_Q[2] <= I_DB[0]; // 7E82H - Flip (must be inverted)
            3'h3 : W_2L_Q[3] <= I_DB[0]; // 7E83H - CREF 0 - colour palette bank select.
            3'h4 : W_2L_Q[4] <= I_DB[0]; // 7E84H - Reset NMI (Sets flip flop)
            3'h5 : W_2L_Q[5] <= I_DB[0]; // 7E85H - Z80 DMA RDY write
            3'h6 : W_2L_Q[6] <= I_DB[0]; // 7E86H - Coin counter 1 (misnumbered on schematic)
            3'h7 : W_2L_Q[7] <= I_DB[0]; // 7E87H - Coin counter 2 (misnumbered on schematic)
         endcase
      end
   end
end

assign O_2L_Q = W_2L_Q;

//----------------------------
// 74LS259 @ 7M
// Sound Port (7F00H - 7F07H)
// Tiggers sound effects.
//----------------------------

reg   [7:0]W_7M_Q;

always@(posedge I_CLK_48M or negedge I_RESET_n)
begin
   if(I_RESET_n == 1'b0) begin
      W_7M_Q <= 0;
   end 
   else if (I_CEN_12M) begin
      if(W_4C_Q[6] == 1'b0) begin
         case(I_AB[2:0])
            3'h0 : W_7M_Q[0] <= I_DB[0]; // 7F00H - /INT
            3'h1 : W_7M_Q[1] <= I_DB[0]; // 7F01H - T0
            3'h2 : W_7M_Q[2] <= I_DB[0]; // 7F02H - T1
            3'h3 : W_7M_Q[3] <= I_DB[0]; // 7F03H - PA0
            3'h4 : W_7M_Q[4] <= I_DB[0]; // 7F04H - PA1
            3'h5 : W_7M_Q[5] <= I_DB[0]; // 7F05H - PA2
            3'h6 : W_7M_Q[6] <= I_DB[0]; // 7F06H - PA3
            3'h7 : W_7M_Q[7] <= I_DB[0]; // 7F07H - Skid analogue sound trigger.
         endcase
      end
   end
end

assign O_7M_Q = W_7M_Q;


//--------------------------
// 74LS374 @ 7J
// Sound data (7E00H)
// Data latch for sound CPU
//--------------------------

reg [7:0]W_7J_Q;

reg W_4C_Q4q;
always@(posedge I_CLK_48M) begin
   W_4C_Q4q <= W_4C_Q[4];
end
wire W_4C_Q4_rise = ~W_4C_Q4q & W_4C_Q[4];

always@(posedge I_CLK_48M) begin
   if (W_4C_Q4_rise)
      W_7J_Q <= I_DB;
end

assign O_7J_Q = W_7J_Q;


endmodule 