// =======================================================================
// 
//
// An Acorn System1 implementation for the Mister
//
// Copyright (C) 2019 Dave Wood
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// =======================================================================


module System1(
	input         	clk25,				 
	input				reset,
	output reg[8:0]ch0,ch1,ch2,ch3,ch4,ch5,ch6,ch7,
	input				sw0,sw1,sw2,sw3,sw4,sw5,sw6,sw7,sw8,sw9,swa,swb,swc,swd,swe,swf,swrst,swm,swl,swg,swr,swp,swU,sws,swD,
// Cassette / Sound
   input         	cas_in,
   output        	cas_out
);

wire 			rom_cs;
wire	[7:0]	rom_dout;
acrnsys1 MONROM(
	.clk(clk25 & rom_cs),
	.addr(address[8:0]),
	.data(rom_dout)
);

wire 			ram_cs;	
wire 			ram_wr = (!rnw & ram_cs);
wire	[7:0]	ram_dout;
gen_ram #(
	.dWidth(8),
	.aWidth(10))
MRAM (
	.clk(clk25 & ram_cs),
	.we(ram_wr),
	.addr(address[9:0]),
	.d(cpu_dout),
	.q(ram_dout)
);

   // ===============================================================
   // Wires/Reg definitions
   // TODO: reorganize so all defined here
   // ===============================================================


   reg         rnw;

   reg [15:0]  address;
   reg [7:0]   cpu_dout;

   wire [7:0]  via_dout;

   wire        via_irq_n;

   wire [1:0]  turbo = 2'b00;
   reg         lock;
	reg  [2:0]       phase = 3'b000;
	reg [2:0] scan = 3'b111;
	wire [7:0] PA_out;
	reg [7:0] PA_tmp = 8'b00000000;
	


   // ===============================================================
   // Clock Enable Generation
   // ===============================================================

   reg       cpu_clken;
   reg       via1_clken;
   reg       via4_clken;

   reg [4:0] clkdiv = 5'b00000;  // divider, from 25MHz down to 1, 2, 4 or 8MHz

   always @(posedge clk25) begin
      if (clkdiv == 24)
        clkdiv <= 0;
      else
        clkdiv <= clkdiv + 1;
      case (turbo)
        2'b00: // 1MHz
          begin
             cpu_clken  <= (clkdiv[3:0] == 0) & (clkdiv[4] == 0);
             via1_clken <= (clkdiv[3:0] == 0) & (clkdiv[4] == 0);
             via4_clken <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0);
          end
        2'b01: // 2MHz
          begin
             cpu_clken  <= (clkdiv[2:0] == 0) & (clkdiv[4] == 0);
             via1_clken <= (clkdiv[2:0] == 0) & (clkdiv[4] == 0);
             via4_clken <= (clkdiv[0]   == 0) & (clkdiv[4] == 0);
          end
        default: // 4MHz
          begin
             cpu_clken  <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0);
             via1_clken <= (clkdiv[1:0] == 0) & (clkdiv[4] == 0);
             via4_clken <=                      (clkdiv[4] == 0);
          end
      endcase

   end


   // ===============================================================
   // Cassette
   // ===============================================================

   // The Atom drives cas_tone from 4MHz / 16 / 13 / 8
   // 208 = 16 * 13, and start with 1MHz and toggle
   // so it's basically the same

   reg        cas_tone = 1'b0;
   reg [7:0]  cas_div = 0;

   always @(posedge clk25) begin
		
			
     if (cpu_clken)
       begin
          if (cas_div == 207)
            begin
               cas_div <= 0;
               cas_tone <= !cas_tone;
            end
          else
            cas_div <= cas_div + 1;
       end

	end

   // this is a direct translation of the logic in the atom
   // (two NAND gates and an inverter)
//   assign cas_out = !(!(!cas_tone & pia_pc[1]) & pia_pc[0]);
//	assign PB_in[7] = cas_in;



   // ===============================================================
   // 6502 CPU
   // ===============================================================

   wire  [7:0] cpu_din;
   wire [7:0]  cpu_dout_c;
   wire [15:0] address_c;
   wire        rnw_c;

   // Arlet's 6502 core is one of the smallest available
   cpu CPU
     (
      .clk(clk25),
      .reset(swrst | reset),
      .AB(address_c),
      .DI(cpu_din),
      .DO(cpu_dout_c),
      .WE(rnw_c),
      .IRQ(1'b0), //(!via_irq_n),
      .NMI(1'b0),
      .RDY(cpu_clken)
      );

   // The outputs of Arlets's 6502 core need registing
   always @(posedge clk25)
     begin
        if (cpu_clken)
          begin
             address  <= address_c;
             cpu_dout <= cpu_dout_c;
             rnw      <= !rnw_c;
          end
     end
		
   // ===============================================================
   // Address decoding logic and data in multiplexor
   // ===============================================================

   // 0000-3FFF RAM

   // 0Exx-0Fxx 6522 VIA

   // FExx-FFxx Monitor Prom
	
	assign  rom_cs = (address[15:9]   == 7'b1111111); //FE00 - FFFF
   wire    via_cs = (address[15:9]   == 7'b0000111);  //0Exx
   assign  ram_cs = (address[15:10]  == 6'b000000);  //0000 - 003F 

   assign  cpu_din = via_cs   ? 	via_dout  : 
							ram_cs 	?	ram_dout		:
							rom_cs 	?	rom_dout		:
							8'b11111111;

   // ===============================================================
   // 6522 VIA at 0x0Exx
   // ===============================================================
  
	wire [7:0] PB_out;
	wire [7:0] PB_oe,PA_oe;
	reg  [7:0] PB_in;
	wire pressed = (~sw0 & ~sw1 & ~sw2 & ~sw3 & ~sw4 & ~sw5 & ~sw6 & ~sw7 & ~sw8 & ~sw9 & ~swa & ~swb & ~swc & ~swd & ~swe & ~swf & ~swm & ~swl & ~swg & ~swr & ~swp & ~swU & ~sws & ~swD);

	always @(posedge via1_clken) begin
		if (pressed) PB_in <= 8'b00111111;
		if (phase == 3'b000 && PB_out[2:0] == 3'b111) begin
			ch0 <= PA_out;
			phase = 3'b001;
			if (sw7) PB_in <= 8'b00011111;
			if (swD) PB_in <= 8'b00101111;
			if (swf) PB_in <= 8'b00110111;
		end
		if (phase == 3'b001 && PB_out[2:0] == 3'b110) begin
			ch1 <= PA_out;
			phase = 3'b010;
			if (sw6) PB_in <= 8'b00011111;
			if (swU) PB_in <= 8'b00101111;
			if (swe) PB_in <= 8'b00110111;
		end
		if (phase == 3'b010 && PB_out[2:0] == 3'b101) begin
			ch2 <= PA_out;
			phase = 3'b011;	
			if (sw5) PB_in <= 8'b00011111;
			if (swr) PB_in <= 8'b00101111;
			if (swd) PB_in <= 8'b00110111;
		end
		if (phase == 3'b011 && PB_out[2:0] == 3'b100) begin
			ch3 <= PA_out;
			phase = 3'b100;
			if (sw4) PB_in <= 8'b00011111;
			if (swl) PB_in <= 8'b00101111;
			if (swc) PB_in <= 8'b00110111;
		end
		if (phase == 3'b100 && PB_out[2:0] == 3'b011) begin
			ch4 <= PA_out;
			phase = 3'b101;	
			if (sw3) PB_in <= 8'b00011111;
			if (sws) PB_in <= 8'b00101111;
			if (swb) PB_in <= 8'b00110111;
		end
		if (phase == 3'b101 && PB_out[2:0] == 3'b010) begin
			ch5 <= PA_out;
			phase = 3'b110;
			if (sw2) PB_in <= 8'b00011111;
			if (swp) PB_in <= 8'b00101111;
			if (swa) PB_in <= 8'b00110111;
		end
		if (phase == 3'b110 && PB_out[2:0] == 3'b001) begin
			ch6 <= PA_out;
			phase = 3'b111;	
			if (sw1) PB_in <= 8'b00011111;
			if (swg) PB_in <= 8'b00101111;
			if (sw9) PB_in <= 8'b00110111;
		end
		if (phase == 3'b111 && PB_out[2:0] == 3'b000) begin
			ch7 <= PA_out;
			phase = 3'b000;
			if (sw0) PB_in <= 8'b00011111;
			if (swm) PB_in <= 8'b00101111;
			if (sw8) PB_in <= 8'b00110111;			
		end
	end
	

   m6522 VIA
     (
      .I_RS(address[3:0]),
      .I_DATA(cpu_dout),
      .O_DATA(via_dout),
      .O_DATA_OE_L(),
      .I_RW_L(rnw),
      .I_CS1(via_cs),
      .I_CS2_L(1'b0),
      .O_IRQ_L(via_irq_n),
      .I_CA1(1'b0),
      .I_CA2(1'b0),
      .O_CA2(),
      .O_CA2_OE_L(),
      .I_PA(8'b0),
      .O_PA(PA_out),
      .O_PA_OE_L(PA_oe),
      .I_CB1(1'b0),
      .O_CB1(),
      .O_CB1_OE_L(),
      .I_CB2(1'b0),
      .O_CB2(),
      .O_CB2_OE_L(),
      .I_PB(PB_in),
      .O_PB(PB_out),
      .O_PB_OE_L(PB_oe),
      .I_P2_H(via1_clken),
      .RESET_L(!reset),
      .ENA_4(via4_clken),
      .CLK(clk25)
      );

/*
		wire [7:0] digit_0 = 8'h3F;
		wire [7:0] digit_1 = 8'h06;
		wire [7:0] digit_2 = 8'h5B;
		wire [7:0] digit_3 = 8'h4F;
		wire [7:0] digit_4 = 8'h66;
		wire [7:0] digit_5 = 8'h6D;
		wire [7:0] digit_6 = 8'h7D;
		wire [7:0] digit_7 = 8'h07;
		wire [7:0] digit_8 = 8'h7F;
		wire [7:0] digit_9 = 8'h6F;
		wire [7:0] digit_A = 8'h77;
		wire [7:0] digit_B = 8'h7C;
		wire [7:0] digit_C = 8'h58;
		wire [7:0] digit_D = 8'h5E;
		wire [7:0] digit_E = 8'h79;
		wire [7:0] digit_F = 8'h71;
*/		


endmodule
