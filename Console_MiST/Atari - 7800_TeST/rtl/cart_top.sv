`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/02/2015 11:36:06 AM
// Design Name: 
// Module Name: cart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "atari7800.vh"

`define    INPUT_CYCLES 256
`define    INPUT_CYCLES_NBITS 9

module cart_top(
	input         CLOCK_27,
   output  [5:0] VGA_R,
   output  [5:0] VGA_G,
   output  [5:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,	 
   output        LED,
   output        AUDIO_L,
   output        AUDIO_R,
//   output        UART_TX,//uses for Tape Record
//   input         UART_RX,//uses for Tape Play	
   input         SPI_SCK,
   output        SPI_DO,
   input         SPI_DI,
   input         SPI_SS2,
   input         SPI_SS3,
	input         SPI_SS4,
   input         CONF_DATA0,
    
    output logic [7:0] ld,
    
    input logic [7:0] sw,
    input logic PB_UP,PB_DOWN,PB_LEFT,PB_RIGHT,PB_CENTER,

    
    inout logic [6:0] ctrl_0_fmc, ctrl_1_fmc
    );
	 
`include "rtl\build_id.v" 
assign 		LED = 1;	 
localparam CONF_STR = {
		  "ATARI7800;;",
		  "O34,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
		  "T6,Reset;",
		  "V,v0.0.",`BUILD_DATE
		};
	 

	 
	 wire clk25, clk7p143, clk6p25;
	 wire locked;
	 
	pll pll (
		.inclk0(CLOCK_27),
		.c0(clk25),
		.c1(clk7p143),
		.c2(clk6p25),
		.locked(locked)
		);
	wire        scandoubler_disable;
	wire        ypbpr;
	wire        ps2_kbd_clk, ps2_kbd_data;
	wire [31:0] status;
	wire  [1:0] buttons;
	wire  [1:0] switches;
	wire 	[3:0] r, g, b;
	wire 			hs, vs, hb, vb;
	wire			blankn = ~(hb | vb);	
		
    
    logic [7:0]  cart_data_out;
    logic [15:0] AB;
    logic        RW;
    logic        pclk_0;
    reg [`INPUT_CYCLES_NBITS-1:0]    paddleA0_ctr = {`INPUT_CYCLES_NBITS{1'b0}};
    reg [`INPUT_CYCLES_NBITS-1:0]    paddleB0_ctr = {`INPUT_CYCLES_NBITS{1'b0}};
    reg [`INPUT_CYCLES_NBITS-1:0]    paddleA1_ctr = {`INPUT_CYCLES_NBITS{1'b0}};
    reg [`INPUT_CYCLES_NBITS-1:0]    paddleB1_ctr = {`INPUT_CYCLES_NBITS{1'b0}}; 
    
    always_ff @(posedge pclk_0) begin
        if (~ctrl_0_fmc[6])
           paddleA0_ctr <= 0;
        else if (paddleA0_ctr < `INPUT_CYCLES)
           paddleA0_ctr <= paddleA0_ctr + 1;
           
        if (~ctrl_0_fmc[4])
           paddleB0_ctr <= 0;
        else if (paddleB0_ctr < `INPUT_CYCLES)
           paddleB0_ctr <= paddleB0_ctr + 1;

        if (~ctrl_1_fmc[6])
           paddleA1_ctr <= 0;
        else if (paddleA1_ctr < `INPUT_CYCLES)
           paddleA1_ctr <= paddleA1_ctr + 1;
             
        if (~ctrl_1_fmc[4])
           paddleB1_ctr <= 0;
        else if (paddleB1_ctr < `INPUT_CYCLES)
           paddleB1_ctr <= paddleB1_ctr + 1;
    end
    

    logic [3:0] idump;
    logic [1:0] ilatch;
    logic [7:0] PAin, PBin, PAout, PBout;
	 logic [15:0] audio;
	 
    
    logic right_0_b, left_0_b, down_0_b, up_0_b, fire_0_b, paddle_A_0, paddle_B_0;
    logic right_1_b, left_1_b, down_1_b, up_1_b, fire_1_b, paddle_A_1, paddle_B_1;
    logic player1_2bmode, player2_2bmode;
    
    assign player1_2bmode = ~PBout[2] & ~tia_en;
    assign player2_2bmode = ~PBout[4] & ~tia_en;
    
    assign {right_0_b, left_0_b, down_0_b, up_0_b} = ctrl_0_fmc[3:0];
    assign {right_1_b, left_1_b, down_1_b, up_1_b} = ctrl_1_fmc[3:0];
    
    assign paddle_B_0 = paddleB0_ctr == `INPUT_CYCLES;
    assign paddle_B_1 = paddleB1_ctr == `INPUT_CYCLES;
    assign paddle_A_0 = paddleA0_ctr == `INPUT_CYCLES;
    assign paddle_A_1 = paddleA1_ctr == `INPUT_CYCLES;
    
    assign fire_0_b = (~paddle_A_0 & ~paddle_B_0);
    assign fire_1_b = (~paddle_A_1 & ~paddle_B_1); 
    logic tia_en;
    
    assign PAin[7:4] = {right_0_b, left_0_b, down_0_b, up_0_b};
    assign PAin[3:0] = {right_1_b, left_1_b, down_1_b, up_1_b};
    
    assign PBin[7] = sw[1]; // RDiff
    assign PBin[6] = sw[0]; // LDiff
    assign PBin[5] = 1'b0;  // Unused
    assign PBin[4] = 1'b0;
    assign PBin[3] = ~PB_DOWN; // Pause
    assign PBin[2] = 1'b0; // 2 Button mode
    assign PBin[1] = ~PB_LEFT; // Select
    assign PBin[0] = ~PB_UP; // Reset 

    
    assign ilatch[0] = fire_0_b;
    assign ilatch[1] = fire_1_b;
    
    assign idump = {paddle_A_0, paddle_B_0, paddle_A_1, paddle_B_1};

   logic [7:0] def_dout;
   assign cart_data_out = def_dout;
   
   defender_rom defender_rom (
     .clock(pclk_0),
     .address(AB[11:0]),
     .q(def_dout)
   );
     
    Atari7800 console(
       .clock_25(clk25),
       .sysclk_7_143(clk7p143),
       .clock_divider_locked(locked),
       .reset((buttons[1] || status[0] || status[6])),
       .RED(r), 
		 .GREEN(g), 
		 .BLUE(b),
       .HSync(hs), 
		 .VSync(vs),
       .aud_signal_out(audio),
       
       .cart_DB_out(cart_data_out),
       .AB(AB),
       .RW(RW),
       .pclk_0(pclk_0),
       .ld(ld),
       .tia_en(tia_en),
       
       .idump(idump), 
		 .ilatch(ilatch),
       .PAin(PAin), 
		 .PBin(PBin),
       .PAout(PAout), 
		 .PBout(PBout)
    );
    
sigma_delta_dac #(.MSBI(15)) sigma_delta_dac (
   .DACout(AUDIO_L),
   .DACin(audio),
   .CLK(clk25),
   .RESET()
);

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mist_io
(
	.conf_str(CONF_STR),
	.clk_sys(clk25),
	.SPI_SCK(SPI_SCK),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SS2(SPI_SS2),
	.SPI_DO(SPI_DO),
	.SPI_DI(SPI_DI),
	.buttons(buttons),
	.switches(switches),
	.scandoubler_disable(scandoubler_disable),
	.ypbpr(ypbpr),
	.status(status),
	.ps2_kbd_clk(ps2_kbd_clk),
	.ps2_kbd_data(ps2_kbd_data)
);

video_mixer #(.LINE_LENGTH(480), .HALF_DEPTH(0)) video_mixer
(
	.clk_sys(clk25),
	.ce_pix(clk6p25),
	.ce_pix_actual(clk6p25),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI(SPI_DI),
	.scanlines(scandoubler_disable ? 2'b00 : {status[4:3] == 3, status[4:3] == 2}),
	.scandoubler_disable(1),//scandoubler_disable),
	.hq2x(status[4:3]==1),
	.ypbpr(ypbpr),
	.ypbpr_full(1),
	.R({r,r[1:0]}),
	.G({g,g[1:0]}),
	.B({b,b[1:0]}),
//	.R(blankn ? {r,r[1:0]} : "000000"),
//	.G(blankn ? {g,g[1:0]} : "000000"),
//	.B(blankn ? {b,b[1:0]} : "000000"),
	.mono(0),
	.HSync(hs),
	.VSync(vs),
	.line_start(0),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS)
);

    
assign AUDIO_R = AUDIO_L;
   
endmodule
