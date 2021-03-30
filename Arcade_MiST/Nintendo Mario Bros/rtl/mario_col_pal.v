//----------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Colour palette.
// Based on the Donkey Kong version by Katsumi Degawa.
//----------------------------------------------------------------------------

module mario_col_pal
(
	input        I_CLK_48M,
   input        I_CEN_24Mn,
   input        I_CEN_6M,
   input   [6:0]I_VRAM_D,
   input   [6:0]I_OBJ_D,
   input        I_CMPBLKn,
   input        I_CPAL_SEL,
   output  [2:0]O_R,
   output  [2:0]O_G,
   output  [1:0]O_B
);

// Link CL2 on the schematics
// Uncut = 0 - Inverted colour palette
// Cut   = 1 - Standard colour palette
parameter CL2 = 1'b1;

//-------------------------------------
// Parts 4U, 5T (74LS157)
// Selects sprites or backgound pixels
// Sprites take priority
//-------------------------------------

wire  [6:0]W_4U5T_Y = (~(I_OBJ_D[0]|I_OBJ_D[1]|I_OBJ_D[2])) ? I_VRAM_D: I_OBJ_D;

//--------------
// Parts 6T, 6U
//--------------

wire  [8:0]W_6TU_D   = {I_CPAL_SEL,W_4U5T_Y[6:0],I_CMPBLKn};
reg   [8:0]W_6TU_Q;
wire       W_6TU_RST = I_CMPBLKn | W_6TU_Q[0];

always@(posedge I_CLK_48M)
begin
	if (I_CEN_24Mn) begin
      if(W_6TU_RST == 1'b0)
         W_6TU_Q <= 9'b0;
      else if (I_CEN_6M)
         W_6TU_Q <= W_6TU_D;
   end
end

//--------------------------------------------------------------
// Colour PROM 4P (512 x 8bit)
// The PROM actually contains 2 versions of the colour palette:
//      0 - 255 = Inverted palette
//    256 - 512 = Standard palette
// Link CL2 on the PCB is used for selecting the palette.
//--------------------------------------------------------------

wire   [8:0]W_PAL_AB = {CL2,W_6TU_Q[8:1]}; 
wire   [7:0]W_4P_DO;

//CLUT_PROM_512_8 prom4p(I_CLK_48M, W_PAL_AB, W_4P_DO,
//                       I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

clut_4p clut_4p(
	.clk(I_CLK_48M),
	.addr(W_PAL_AB),
	.data(W_4P_DO)
);

assign {O_R, O_G, O_B} = W_4P_DO; // 3R:3G:2B

endmodule

