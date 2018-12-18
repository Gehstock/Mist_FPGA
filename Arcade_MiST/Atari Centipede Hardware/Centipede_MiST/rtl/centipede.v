//
// Atari Centipede, from the schematics
//
// Brad Parker <brad@heeltoe.com> 10/2015
//
// The 6502 cpu used here is not completely cycle accurate in relation to the original "real" 6502.
// Specifically, the game makes heavy use of the knowledge about when i/o space read/writes will
// occur in relationship to the cpu clocks, specially phi2.  The game hardware was set up to allow
// the cpu accces on the back side of the s_4h signal, which, based on phi0, phi2 and the mpuclk was
// when the original (i.e. real) 6502 would assert i/o signals.  Rather than fight this battle I made
// the playfield a ram synchronous dual port memory, which was natural in a modern FPGA.  This eliminated
// the contention and allowed me to remove the s_4h qualifiers from the address generation.
//
// The game code also relies on the pokey's random number generation working correctly and caused me to
// do some debugging of the pokey code I was using.
//

//`define async_lr
`define orig_phi0
	
module centipede(
		 input 	      clk_100mhz,
		 input 	      clk_12mhz,
 		 input 	      reset,
		 input [9:0]  playerinput_i,
		 input [7:0]  trakball_i,
		 input [7:0]  joystick_i,
		 input [7:0]  sw1_i,
		 input [7:0]  sw2_i,
		 output [4:1] led_o,
		 output [8:0] rgb_o,
		 output       sync_o,
		 output       hsync_o,
		 output       vsync_o,
		 output       hblank_o,
		 output       vblank_o,
		 output [3:0] audio_o
		 );

   //
   wire s_12mhz, s_12mhz_n;
   wire s_6mhz, s_6mhz_n;

   wire phi0, phi2;
   reg 	phi0a;

   //
   wire rom_n;
   wire ram0_n;
   wire steerclr_n, watchdog_n, out0_n, irqres_n;
   wire pokey_n, swrd_n, pf_n;
   wire coloram_n, ea_read_n, ea_ctrl_n, ea_addr_n;
   wire in0_n, in1_n;

   wire pframrd_n;
   wire pfwr3_n, pfwr2_n, pfwr1_n, pfwr0_n;
   wire pfrd3_n, pfrd2_n, pfrd1_n, pfrd0_n;

   wire [9:0] adecode;
   wire       pac_n;

   wire       mpu_clk;
   reg [7:0]  mpu_reset_cntr;
   reg 	      mpu_reset;
   wire       mpu_reset_n;
   reg 	      irq;
   wire       rw_n;

   wire [15:0] ab;
   
   wire [7:0] db_in;
   wire [7:0] db_out;

   wire [7:0] ram_out;
   wire [7:0] rom_out;
   
   //
   wire [7:0] vprom_addr;
   wire [3:0] vprom_out;
   reg [3:0]  vprom_reg;
   
   wire       vsync, vblank, hblank, vreset;
   reg 	      hsync;
   wire       vreset_n;
   wire       hsync_reset;
   
   wire       s_1h, s_2h, s_4h, s_8h, s_16h, s_32h, s_64h, s_128h, s_256h;
   wire       s_1v, s_2v, s_4v, s_8v, s_16v, s_32v, s_64v, s_128v;

   wire       s_4h_n, s_8h_n, s_256h_n;
   wire       s_256hd_n;
   wire       s_256h2d_n;
   wire	      vblankd_n;
   wire       s_6_12;
   
   reg 	      s_256h2d;
   reg 	      s_256hd;
   reg 	      vblankd;
   
   wire       pload_n;
   wire       write_n;
   wire       brw_n;
   
   wire [15:0] pdf;

   //
   wire [7:0]  match_line;
   wire [7:0]  match_sum;
   wire        match_sum_top;
   reg [5:0]   match_sum_hold;
	       
   wire [3:0]  match_mux;
   wire        match_n;
   wire        match_true;
   wire [3:0]  mga;

   //
   wire [7:0]  pf;
   wire [1:0]  pf_sel;
   wire [3:0]  pfa7654, pfa3210;
   wire [7:0]  pfa;
   wire [7:0]  pf_out;
   wire        pf_addr_stamp;

   wire [31:0] pfd;
   reg [29:16] pfd_hold;
   reg [29:16] pfd_hold2;

   reg [1:0]   gry;
   wire [1:0]  y;
`ifdef async_lr
   wire [1:0]  mr;
`else
   reg [1:0]  mr;
`endif
   
   wire [7:0]  line_ram_addr;
   reg [1:0]   line_ram[0:255];
   reg [7:0]   line_ram_ctr;
   wire        line_ram_ctr_load;
   wire        line_ram_ctr_clr;

   //
   wire [7:0]  pf_mux1, pf_mux0;
   reg [7:0]   pf_shift1, pf_shift0;
   reg [1:0]   area;

   wire [10:0] pf_rom1_addr, pf_rom0_addr;
   wire [7:0]  pf_rom1_out, pf_rom0_out;
   wire [7:0]  pf_rom1_out_rev, pf_rom0_out_rev;

   reg [7:0]   pic;


   //
   wire        ea_addr_clk, ea_ctrl_clk;
   reg [5:0]   hs_addr;
   wire [7:0]  hs_out;
   reg [7:0]   hs_data;
   reg [3:0]   hs_ctrl;

   reg 	       hs;
   wire        hs_set;

   wire        hs_addr_clk;
   wire        hs_ctrl_clk;

   //
   wire        comp_sync;
   reg [3:0]   rgbi;
   wire [3:0]  coloram_out;
   wire [3:0]  coloram_rgbi;
   wire        coloram_w_n;
   reg 	      coloren;

   wire [1:0]  rama_sel;
   wire [1:0]  rama_hi;
   wire [1:0]  rama_lo;
   wire [3:0]  rama;

   wire [7:0]  audio;

   //
   wire        mob_n;
   wire        blank_clk;

   //
   wire [7:0]  joystick_out;
   wire [3:0]  tra, trb;
   wire        dir1, dir2;

   wire [7:0]  switch_out;
   wire        flip;

   wire        coin_ctr_r_drive, coin_ctr_c_drive, coin_ctr_l_drive;
   wire [7:0]  playerin_out;

   wire [7:0]  pokey_out;
   reg [11:0]  h_counter;
   reg [7:0]   v_counter;
   wire        v_counter_reset;

   initial h_counter = 0;
   
   always @(posedge s_12mhz or posedge reset)
     if (reset)
       h_counter <= 0;
     else
       if (h_counter == 12'hfff)
	 h_counter <= 12'b110100000000;
       else
	 h_counter <= h_counter + 12'd1;

   assign s_6mhz = h_counter[0];
   assign s_1h   = h_counter[1];
   assign s_2h   = h_counter[2];
   assign s_4h   = h_counter[3];
   assign s_8h   = h_counter[4];
   assign s_16h  = h_counter[5];
   assign s_32h  = h_counter[6];
   assign s_64h  = h_counter[7];
   assign s_128h = h_counter[8];
   assign s_256h = h_counter[9];

   assign s_4h_n = ~s_4h;
   assign s_8h_n = ~s_8h;
   assign s_256h_n = ~s_256h;

   assign pload_n = ~(s_1h & s_2h & s_4h);

   assign s_12mhz = clk_12mhz;
   assign s_12mhz_n = ~clk_12mhz;
   assign s_6mhz_n = ~s_6mhz;

   assign v_counter_reset = reset | ~vreset == 0;

   always @(posedge s_256h_n or posedge reset)
     if (reset)
       v_counter <= 0;
     else
       /* ld# is on positive clock edge */
       if (vreset == 1)
	 v_counter <= 0;
       else
	 v_counter <= v_counter + 8'd1;
   
   assign s_1v   = v_counter[0];
   assign s_2v   = v_counter[1];
   assign s_4v   = v_counter[2];
   assign s_8v   = v_counter[3];
   assign s_16v  = v_counter[4];
   assign s_32v  = v_counter[5];
   assign s_64v  = v_counter[6];
   assign s_128v = v_counter[7];

   assign vprom_addr = {vblank, s_128v, s_64v, s_32v, s_8v, s_4v, s_2v, s_1v};

sprom #(
	.init_file("./roms/136001-213.p4.hex"),
	.widthad_a(8),
	.width_a(4))
vprom(
	.address(vprom_addr),
	.clock(s_6mhz),
	.q(vprom_out)
	);					 

   always @(posedge s_256h_n or posedge reset)
     if (reset)
       vprom_reg <= 0;
     else
       vprom_reg <= vprom_out;

   assign vsync = vprom_reg[0];
   assign vreset = vprom_reg[2];



   assign hs_set = reset | ~s_256h_n;
   
   always @(posedge s_32h or posedge hs_set)
     if (hs_set)
       hs <= 1;
     else
       hs <= s_64h;

   assign hsync_reset = reset | hs;
   
   always @(posedge s_8h or posedge hsync_reset)
     if (hsync_reset)
       hsync <= 0;
     else
       hsync <= s_32h;

   //
   always @(posedge s_6mhz)
     if (reset)
       coloren <= 0;
     else
       coloren <= s_256hd;

   assign s_6_12 = ~(s_6mhz & s_12mhz);

   reg xxx1;
   
   always @(posedge s_6_12)
     if (reset)
       xxx1 <= 0;
     else
       xxx1 <= coloren;

	assign vblank = vprom_reg[3];
   assign hblank = (~xxx1 & ~coloren);
sprom #(
	.init_file("./roms/136001-prog.hex"),
	.widthad_a(13),
	.width_a(8))
rom(
	.address(ab[12:0]),
	.clock(s_6mhz & ~rom_n),
	.q(rom_out[7:0])
	);			
	
spram #(
	.addr_width_g(10),
	.data_width_g(8))
ram(
	.address(ab[9:0]),
	.clock(s_6mhz & ~ram0_n),
	.wren(~write_n),
	.data(db_out[7:0]),
	.q(ram_out[7:0])
	);					

   wire        irq_n;
   
   always @(posedge s_16v or negedge irqres_n)
     if (~irqres_n)
       irq <= 1'b1;
     else
//       irq <= s_32v;
       irq <= ~s_32v;

//   assign irq_n = ~irq;
   assign irq_n = irq;

   
`ifdef orig_phi0
   always @(posedge s_1h)
     if (reset)
       phi0a <= 1'b0;
     else
       case ({(pf_n | s_4h), s_2h})
	 2'b00: phi0a <= phi0a;
	 2'b01: phi0a <= 1'b0;
	 2'b10: phi0a <= 1'b1;
	 2'b11: phi0a <= ~phi0a;
       endcase
   
   assign phi0 = ~phi0a;
   assign pac_n = ~phi0a;
`else
   always @(posedge s_1h or posedge reset)
     if (reset)
       phi0a <= 1'b0;
     else
       phi0a <= ~phi0a;

   assign phi0 = ~phi0a;
   assign pac_n = ~phi0a;
`endif

   // watchdog?
   always @(posedge s_12mhz)
     if (reset)
       begin
	  mpu_reset <= 1;
	  mpu_reset_cntr <= 0;
       end
     else
       begin
//	  if (mpu_reset_cntr != 8'hff)
	  if (mpu_reset_cntr != 8'h10)
	    mpu_reset_cntr <= mpu_reset_cntr + 8'd1;
	  else
	    mpu_reset <= 0;
       end

   assign mpu_clk = s_6mhz;
      assign mpu_reset_n = ~mpu_reset;

   p6502 p6502(
	       .clk(mpu_clk),
	       .reset_n(mpu_reset_n),
	       .nmi(1'b1),
	       .irq(irq_n),
	       .so(1'b0),
	       .rdy(1'b1),
	       .phi0(phi0),
	       .phi2(phi2),
	       .rw_n(rw_n),
	       .a(ab),
	       .din(db_in[7:0]),
	       .dout(db_out[7:0])
	       );

   // Address Decoder
   assign write_n = ~(phi2 & ~rw_n);

   assign brw_n = ~rw_n;
   
   assign rom_n = brw_n | ~ab[13];

   assign adecode =
		   (ab[13:10] == 4'b0000) ? 10'b1111111110 :
		   (ab[13:10] == 4'b0001) ? 10'b1111111101 :
		   (ab[13:10] == 4'b0010) ? 10'b1111111011 :
		   (ab[13:10] == 4'b0011) ? 10'b1111110111 :
		   (ab[13:10] == 4'b0100) ? 10'b1111101111 :
		   (ab[13:10] == 4'b0101) ? 10'b1111011111 :
		   (ab[13:10] == 4'b0110) ? 10'b1110111111 :
		   (ab[13:10] == 4'b0111) ? 10'b1101111111 :
		   (ab[13:10] == 4'b1000) ? 10'b1011111111 :
		   (ab[13:10] == 4'b1001) ? 10'b0111111111 :
		   10'b1111111111;

//   assign write2_n = ~(s_6mhz & ~write_n);
   reg write2_n;
   always @(posedge s_6mhz)
     if (reset)
       write2_n <= 0;
     else
       write2_n <= write_n;
   
   assign steerclr_n = adecode[9] | write2_n;
   assign watchdog_n = adecode[8] | write2_n;
   assign out0_n =     adecode[7] | write2_n;
   assign irqres_n =  (adecode[6] | write2_n) & mpu_reset_n;

   assign coloram_n = (adecode[5] | ab[9])/* | pac_n*/;
   
   assign pokey_n = adecode[4];

   assign in0_n =   adecode[3] | ab[1];
   assign in1_n =   adecode[3] | ~ab[1];
   
   assign swrd_n =  adecode[2];
   assign pf_n =    adecode[1];
   assign ram0_n =  adecode[0];
   
   assign {ea_read_n, ea_ctrl_n, ea_addr_n} =
						({~ab[9]|adecode[5], ab[8:7]} == 3'b000) ? 3'b110 :
						({~ab[9]|adecode[5], ab[8:7]} == 3'b001) ? 3'b101 :
						({~ab[9]|adecode[5], ab[8:7]} == 3'b010) ? 3'b011 :
						3'b111;
   assign pframrd_n = pf_n | brw_n;
   
   assign {pfwr3_n, pfwr2_n, pfwr1_n, pfwr0_n} =
					({pf_n, write_n, ab[5:4]} == 4'b0000) ? 4'b1110 :
					({pf_n, write_n, ab[5:4]} == 4'b0001) ? 4'b1101 :
					({pf_n, write_n, ab[5:4]} == 4'b0010) ? 4'b1011 :
					({pf_n, write_n, ab[5:4]} == 4'b0011) ? 4'b0111 :
					4'b1111;

   assign {pfrd3_n, pfrd2_n, pfrd1_n, pfrd0_n} =
						(ab[5:4] == 2'b00) ? 4'b1110 :
						(ab[5:4] == 2'b01) ? 4'b1101 :
						(ab[5:4] == 2'b10) ? 4'b1011 :
						(ab[5:4] == 2'b11) ? 4'b0111 :
						4'b1111;

   //
//   assign mob_n = ~(s_256h_n & s_256hd) & ~(s_256h2d_n & s_256hd);
   assign mob_n = ~(s_256h_n | s_256h2d_n);

   assign blank_clk = ~s_12mhz & (h_counter[3:0] == 4'b1111);

   always @(posedge blank_clk or posedge reset)
     if (reset)
       begin
	  s_256h2d <= 1'b0;
	  s_256hd <= 1'b0;
	  vblankd <= 1'b0;
       end
     else
       begin
	  s_256h2d <= s_256hd;
	  s_256hd <= s_256h;
	  vblankd <= vblank;
       end

   assign s_256h2d_n = ~s_256h2d;
   assign s_256hd_n = ~s_256hd;
   assign vblankd_n = ~vblankd;
   
   // motion objects (vertical)

   // the motion object circuitry (vertical) receives pf data and vertical inputs from the
   // sync generator circuitry to generate the vertical component of the motion object video. PFD8-
   // 15 from the playfield memory and 1v-128v from the sync generator are compared at F6 and H6.
   // The output is gated by A7 when a motion object is on one of the sixteen vertical lines and is
   // latched by E6 and AND gate B7.  A low on B7 pin 8 indicates the presence of a motion object on
   // one of the vertical lines during non-active video time.  The signal (MATCH) enables the multi-
   // plexers in the picture data circuitry.
   //
   // when 256h goes high, 1v,2v,4v and pic0 are selected. When 256h goes low,
   // the latched output of E6 is selected. The output if D7 is EXCLUSIVE OR gated at E7 and is
   // sent to the picture data selector circuitry as motion graphics address (MGA0-MGA3). The other
   // input to EXCLUSIVE OR gate E7 is PIC7 from the playfield code multiplexer circuitry. PIC7
   // when high causes the output of E7 to be complimented.  For example, if MGA0..3 are low,
   // pic7 causes MGA0..3 to go high.  This causes the motion object video to be inverted top
   // to bottom.

   // mga0..3 (motion graphics address) from the motion object circuitry,
   //  256h and 256h_n from the sync generator
   // pic0..5 represents the code for the object to be displayed
   // mga0..3 set on of 8 different combinations of the 8-line by
   //  8-bit blocks of picture video or the 16 line by 8 bit blocks of
   //  motion object video
   //
   // 256h when high selects the playfield picture color codes to be addressed.
   // 256h when low selects the motion object color codes to be addressed

   assign match_line = { s_128v, s_64v, s_32v, s_16v, s_8v, s_4v, s_2v, s_1v };
   assign match_sum = match_line + pfd[15:8];
   assign match_sum_top = ~(match_sum[7] & match_sum[6] & match_sum[5] & match_sum[4]);

//   always @(posedge s_4h_n)
//     if (reset)
//       match_sum_hold <= 0;
//     else
//       match_sum_hold <= { match_sum_top, 1'b0, match_sum[3:0] };
   always @(posedge s_6mhz)
     if (reset)
       match_sum_hold <= 0;
     else
       if (s_4h)
       match_sum_hold <= { match_sum_top, 1'b0, match_sum[3:0] };

   assign match_mux = s_256h ? { pic[0], s_4v, s_2v, s_1v } : match_sum_hold[3:0];

   assign match_n = match_sum_hold[5] & s_256h_n;

   // for debug only
   assign match_true = (~match_n & s_256h_n) && pfd != 0;

   assign mga = { match_mux[3] ^ (pic[7] & s_256h_n),
		  match_mux[2] ^ pic[7],
		  match_mux[1] ^ pic[7],
		  match_mux[0] ^ pic[7] };

//---
   
   // motion objects (horizontal)

   // the motion object circuitry (horizontal) receives playfield data and horizontal inputs from
   // the sync generator circuitry. pfd16..23 from the pf memory determine the horizontal
   // position of the motion object.  pfd24..29 from the pf memory determine the indirect
   // color of the motion object.   pfd16:23 are latched and loaded into the horizontal position
   // counter.

//brad
//    always @(posedge s_4h)
//     if (reset)
//       pfd_hold <= 0;
//     else
//       pfd_hold <= pfd[29:16];
    always @(posedge s_6mhz)
     if (reset)
       pfd_hold <= 0;
     else
       /* posedge s_4h */
       if (~s_4h)
	 pfd_hold <= pfd[29:16];

//   always @(posedge s_4h_n)
//     if (reset)
//       pfd_hold2 <= 0;
//     else
//       pfd_hold2 <= pfd_hold;
   always @(posedge s_6mhz)
     if (reset)
       pfd_hold2 <= 0;
     else
       /* posedge s_4h_n */
       if (s_1h & s_2h & s_4h)
	   pfd_hold2 <= pfd_hold;
   
   assign y[1] =
		(area == 2'b00) ? (s_256hd ? 1'b0 : gry[1]) :
		(area == 2'b01) ? (s_256hd ? 1'b0 : pfd_hold2[25]) : 
		(area == 2'b10) ? (s_256hd ? 1'b0 : pfd_hold2[27]) :
		(area == 2'b11) ? (s_256hd ? 1'b0 : pfd_hold2[29]) :
		1'b0;

   assign y[0] =
		(area == 2'b00) ? (s_256hd ? 1'b0 : gry[0]) :
		(area == 2'b01) ? (s_256hd ? 1'b0 : pfd_hold2[24]) : 
		(area == 2'b10) ? (s_256hd ? 1'b0 : pfd_hold2[26]) :
		(area == 2'b11) ? (s_256hd ? 1'b0 : pfd_hold2[28]) :
		1'b0;

   assign line_ram_ctr_load = ~(pload_n | s_256h);
   assign line_ram_ctr_clr = ~(pload_n | ~(s_256h & s_256hd_n));
   
   always @(posedge s_6mhz)
     if (reset)
       line_ram_ctr <= 0;
     else
       begin
	  if (line_ram_ctr_clr)
	    line_ram_ctr <= 0;
	  else
	    if (line_ram_ctr_load) 
	      line_ram_ctr <= pfd_hold[23:16];
	    else
	      line_ram_ctr <= line_ram_ctr + 8'b1;
       end
   
   assign line_ram_addr = line_ram_ctr;

   always @(posedge s_6mhz)
     line_ram[line_ram_addr] <= y;

`ifdef async_lr
   assign mr = line_ram[line_ram_addr];
`else
   always @(posedge s_12mhz)
     if (reset)
       mr <= 0;
     else
       mr <= line_ram[line_ram_addr];
`endif
   
   always @(posedge s_6mhz_n)
     if (reset)
       gry <= 0;
     else
//       if (~mob_n)
//	 gry <= 2'b00;
//       else
	 gry <= mr;

   
   //  playfield multiplexer

   // The playfield multiplexer receives playfield data from the pf memory
   // (PFD0-PFD31) and the output (pf0..7) is a code that determines what is 1) dis-
   // played on the monitor or 2) read or updated by the MPU.
   //
   // When 256H is low and 4H is high, AB4 and AB5 from the MPU address bus is the
   // select output from P6.   The output is applied to multiplexers k6, l6, m6 and n6
   // as select inputs.  When the MPU is accessing the playfield code multiplexer, the
   // playfield data is either being read or updated by the MPU.  When 256H is high and 4H
   // is low, the inputs frmo the sync generator (128H and 8V) are the selected outputs.
   // These signals then select which bits of the data PFD0-PFD31 are send out via K6, L6
   // M6, and N6 for the playfield codes that eventually are displayed on the monitor.

//   always @(posedge s_4h)
//     if (reset)
//       pic <= 0;
//     else
//       pic <= pf[7:0];
   always @(posedge s_6mhz)
     if (reset)
       pic <= 0;
     else
       if (~s_4h)
	 pic <= pf[7:0];
			
sprom #(
	.init_file("./roms/136001-212.hj7.hex"),
	.widthad_a(10),
	.width_a(8))
 pf_rom1(
	.address(pf_rom1_addr),
	.clock(s_6mhz_n),
	.q(pf_rom1_out)
	);

sprom #(
	.init_file("./roms/136001-211.f7.hex"),
	.widthad_a(10),
	.width_a(8))
 pf_rom0(
	.address(pf_rom0_addr),
	.clock(s_6mhz_n),
	.q(pf_rom0_out)
	);			


   // a guess, based on millipede schematics
   wire pf_romx_haddr;
   assign pf_romx_haddr = s_256h_n & pic[0];
   assign pf_rom1_addr = { pf_romx_haddr, s_256h, pic[5:1], mga };
   assign pf_rom0_addr = { pf_romx_haddr, s_256h, pic[5:1], mga };
   assign pf_rom0_out_rev = { pf_rom0_out[0], pf_rom0_out[1], pf_rom0_out[2], pf_rom0_out[3],
			      pf_rom0_out[4], pf_rom0_out[5], pf_rom0_out[6], pf_rom0_out[7] };
   
   assign pf_rom1_out_rev = { pf_rom1_out[0], pf_rom1_out[1], pf_rom1_out[2], pf_rom1_out[3],
			      pf_rom1_out[4], pf_rom1_out[5], pf_rom1_out[6], pf_rom1_out[7] };
   
   assign pf_mux0 = match_n ? 8'b0 : (pic[6] ? pf_rom0_out_rev : pf_rom0_out);
   assign pf_mux1 = match_n ? 8'b0 : (pic[6] ? pf_rom1_out_rev : pf_rom1_out);
   
   always @(posedge s_6mhz)
     if (reset)
       pf_shift1 <= 0;
     else
       if (~pload_n)
	 pf_shift1 <= pf_mux1;
       else
	 pf_shift1 <= { pf_shift1[6:0], 1'b0 };
   
   always @(posedge s_6mhz)
     if (reset)
       pf_shift0 <= 0;
     else
       if (~pload_n)
	 pf_shift0 <= pf_mux0;
       else
	 pf_shift0 <= { pf_shift0[6:0], 1'b0 };
   
   always @(posedge s_6mhz_n)
     if (reset)
       area <= 0;
     else
       area <= { pf_shift1[7], pf_shift0[7] };

   //
   assign db_in =
		 ~rom_n ? rom_out :
		 ~ram0_n ? ram_out :
		 ~coloram_n ? { 4'b0, coloram_out } :
       ~pframrd_n ? pf_out[7:0] :
		 ~ea_read_n ? hs_out :
		 ~in0_n ? playerin_out :
		 ~in1_n ? joystick_out :
		 ~swrd_n ? switch_out :
		 ~pokey_n ? pokey_out :
		 8'b0;


   // we ignore the cpu, as pf ram is now dp and cpu has it's own port
//   assign pf_sel = mob_n ? { s_8v, s_128h } : 2'b00;
   assign pf_sel = pf_addr_stamp ? 2'b00 : { s_8v, s_128h };
   
   assign pf =
	      (pf_sel == 2'b00) ? pfd[7:0] :
	      (pf_sel == 2'b01) ? pfd[15:8] :
	      (pf_sel == 2'b10) ? pfd[23:16] :
	      (pf_sel == 2'b11) ? pfd[31:24] :
	      8'b0;

   // playfield address selector

   // when s_4h_n is low the pf addr selector receives 8h, 16, 32h & 64h and
   //  16v, 32v, 64v and 128v from the sync generator. these signals enable the sync
   //  generator circuits to access the playfield memory
   //
   // when s_4h_n goes high the game mpu addresses the pf memory
   // during horizontal blanking pfa4..7 are held high enabling the motion object
   // circuitry to access the playfield memory for the motion objects to be displayed

   assign pf_addr_stamp = hblank & ~s_256h;

   // force pf address to "stamp area" during hblank
   assign pfa7654 = pf_addr_stamp ? 4'b1111 : { s_128v, s_64v, s_32v, s_16v };
   assign pfa3210 = { s_64h, s_32h, s_16h, s_8h };
   assign pfa = { pfa7654, pfa3210 };

   wire pf_ce;
   reg 	pf_ce_d;
   wire [3:0] pf_ce4_n;
   assign pf_ce = ~(s_1h & s_2h & s_4h & s_6mhz);

   always @(posedge s_12mhz)
     if (reset)
       pf_ce_d <= 0;
     else
       pf_ce_d <= pf_ce;
   
//   assign pf_ce4_n = { pf_ce_d, pf_ce_d, pf_ce_d, pf_ce_d };
   assign pf_ce4_n = 4'b0;
	

		 
   pf_ram pf_ram(
		    .clk_a(s_6mhz),
		    .clk_b(s_6mhz_n),
		    .reset(reset),
		    //
		    .addr_a({ab[9:6], ab[3:0]}),
		    .din_a(db_out[7:0]),
		    .dout_a(pf_out),
		    .ce_a({pfrd3_n, pfrd2_n, pfrd1_n, pfrd0_n}),
		    .we_a({pfwr3_n, pfwr2_n, pfwr1_n, pfwr0_n}),
		    //
		    .addr_b(pfa),
		    .dout_b(pfd),
		    .ce_b(pf_ce4_n)
		    );
   
   // High Score Memory Circuitry

   assign hs_addr_clk = ~(~ea_addr_n & ~write2_n);
   assign hs_ctrl_clk = ~(~ea_ctrl_n & ~write2_n);

   always @(posedge hs_addr_clk)
     hs_addr <= ab[5:0];

   always @(posedge ea_ctrl_clk)
     hs_ctrl <= db_out[3:0];
		 
spram #(
	.addr_width_g(6),
	.data_width_g(8))
hs_ram(
	.address(hs_addr),
	.clock(hs_ctrl[0] & ~hs_ctrl[3]),
	.wren(~hs_ctrl[1] & hs_ctrl[2]),
	.data(hs_data),
	.q(hs_out)
	);			 

   always @(posedge hs_addr_clk)
     hs_data <= db_out[7:0];

   // Joystick Circuitry
   wire js1_right, js1_left, js1_down, js1_up;
   wire js2_right, js2_left, js2_down, js2_up;

   assign js1_right = joystick_i[7];
   assign js1_left = joystick_i[6];
   assign js1_down = joystick_i[5];
   assign js1_up = joystick_i[4];
   assign js2_right = joystick_i[3];
   assign js2_left = joystick_i[2];
   assign js2_down = joystick_i[1];
   assign js2_up = joystick_i[0];

   assign joystick_out = ab[0] ?
			 { js1_right, js1_left, js1_down, js1_up, js2_right, js2_left, js2_down, js2_up } :
			 { dir2, 3'b0, trb };
   
   // Option Input Circuitry

   assign switch_out = ab[0] ?
		       sw2_i :
		       sw1_i;

   // Player Input Circuitry
   wire coin_r, coin_c, coin_l, self_test;
   wire cocktail, slam, start1, start2, fire2, fire1;

   assign coin_r = coin_ctr_r_drive ? coin_ctr_r_drive : playerinput_i[9];
   assign coin_c = coin_ctr_c_drive ? coin_ctr_c_drive : playerinput_i[8];
   assign coin_l = coin_ctr_l_drive ? coin_ctr_l_drive : playerinput_i[7];
   assign self_test = playerinput_i[6];
   assign cocktail = playerinput_i[5];
   assign slam = playerinput_i[4];
   assign start1 = playerinput_i[3];
   assign start2 = playerinput_i[2];
   assign fire2 = playerinput_i[1];
   assign fire1 = playerinput_i[0];

   wire [7:0] playerin_out0;
   wire [7:0] playerin_out1;
   
   assign playerin_out1 = { coin_r, coin_c, coin_l, slam, fire2, fire1, start1, start2 };
   assign playerin_out0 = { dir1, vblank, self_test, cocktail, tra };

   assign playerin_out = ab[0] ? playerin_out1 : playerin_out0;
   
   // Coin Counter Output
   reg [7:0] cc_latch;

   always @(posedge s_6mhz or posedge reset)
     if (reset)
       cc_latch <= 0;
     else
       if (~out0_n)
	      cc_latch[ ab[2:0] ] <= db_out[7];

   assign flip     = cc_latch[7];
   assign led_o[4] = cc_latch[6];
   assign led_o[3] = cc_latch[5];
   assign led_o[2] = cc_latch[4];
   assign led_o[1] = cc_latch[3];
   assign coin_ctr_r_drive = cc_latch[2];
   assign coin_ctr_c_drive = cc_latch[1];
   assign coin_ctr_l_drive = cc_latch[1];
   
   // Mini-Trak Ball inputs
   wire [3:0] tb_mux;
   wire       s_1_horiz_dir, s_1_horiz_ck, s_1_vert_dir, s_1_vert_ck;
   wire       s_2_horiz_dir, s_2_horiz_ck, s_2_vert_dir, s_2_vert_ck;
   wire       tb_h_dir, tb_h_ck, tb_v_dir, tb_v_ck;
   reg 	      tb_h_reg, tb_v_reg;
   reg [3:0]  tb_h_ctr, tb_v_ctr;
   wire       tb_h_ctr_clr, tb_v_ctr_clr;
   
   assign s_1_horiz_dir = trakball_i[7];
   assign s_2_horiz_dir = trakball_i[6];
   assign s_1_horiz_ck  = trakball_i[5];
   assign s_2_horiz_ck  = trakball_i[4];
   assign s_1_vert_dir  = trakball_i[3];
   assign s_2_vert_dir  = trakball_i[2];
   assign s_1_vert_ck   = trakball_i[1];
   assign s_2_vert_ck   = trakball_i[0];

   assign tb_mux = flip ?
		   { s_1_horiz_dir, s_1_horiz_ck, s_1_vert_dir, s_1_vert_ck } :
		   { s_2_horiz_dir, s_2_horiz_ck, s_2_vert_dir, s_2_vert_ck };

   assign tb_h_dir = tb_mux[3];
   assign tb_h_ck = tb_mux[2];
   assign tb_v_dir = tb_mux[1];
   assign tb_v_ck = tb_mux[0];

   // H
   always @(posedge tb_h_ck or posedge reset)
     if (reset)
       tb_h_reg <= 0;
     else
       tb_h_reg <= tb_h_dir;

   assign tb_h_ctr_clr = reset | ~steerclr_n;
   
   always @(posedge tb_h_ck or posedge tb_h_ctr_clr)
     if (tb_h_ctr_clr)
       tb_h_ctr <= 0;
     else
       if (tb_h_reg)
	 tb_h_ctr <= tb_h_ctr + 4'd1;
       else
	 tb_h_ctr <= tb_h_ctr - 4'd1;

   // V
   always @(posedge tb_v_ck or posedge reset)
     if (reset)
       tb_v_reg <= 0;
     else
       tb_v_reg <= tb_v_dir;

   assign tb_v_ctr_clr = reset | ~steerclr_n;
   
   always @(posedge tb_v_ck or posedge tb_v_ctr_clr)
     if (tb_v_ctr_clr)
       tb_v_ctr <= 0;
     else
       if (tb_v_reg)
	 tb_v_ctr <= tb_v_ctr + 4'd1;
       else
	 tb_v_ctr <= tb_v_ctr - 4'd1;

   assign tra = tb_h_ctr;
   assign trb = tb_v_ctr;
   assign dir1 = tb_h_reg;
   assign dir2 = tb_v_reg;
   

   // Audio output circuitry


POKEY POKEY(
   .Din(db_out[7:0]),
   .Dout(pokey_out),
   .A(ab[3:0]),
   .P(8'b0),
   .phi2(phi2),
   .readHighWriteLow(rw_n),
   .cs0Bar(pokey_n),
	.audio(audio),
   .clk(clk_100mhz)
   );

   // Video output circuitry

   // The video output circuit receives motion object, playfield, address and data inputs 
   //  and produces a video output to be displayed on the game monitor.
   // when the alternate color bit is active, an alternate shade of blue or green is available   
   
   assign comp_sync = ~hsync & ~vsync;

   // XXX implement alternate shades of blue and green...
   always @(posedge s_6mhz_n)
     if (reset)
       rgbi <= 0;
     else
       rgbi <= coloram_rgbi;

   assign coloram_w_n = write_n | coloram_n;

   wire gry0_or_1;
   assign gry0_or_1 = gry[1] | gry[0];
     
   assign rama_sel = { coloram_n, gry0_or_1 };
   
   assign rama = 
		 (rama_sel == 2'b00) ? { ab[3:0] } :
		 (rama_sel == 2'b01) ? { ab[3:0] } :
		 (rama_sel == 2'b10) ? { {gry0_or_1, 1'b1}, area[1:0] } :
		 (rama_sel == 2'b11) ? { {gry0_or_1, 1'b1}, gry[1:0] } :
		 4'b0;

 //  assign rama =  gry0_or_1 ?
	//	  { {gry0_or_1, 1'b1}, gry[1:0] } :
	//	  { {gry0_or_1, 1'b1}, area[1:0] };

	
dpram #(
	.addr_width_g(4),
	.data_width_g(4))
color_ram(
	.clk_a_i(s_6mhz),
	.clk_b_i(s_6mhz_n),
	.we_i(~coloram_w_n),
	.addr_a_i(ab[3:0]),
	.data_a_o(coloram_out),
	.data_a_i(db_out[3:0]),
	.addr_b_i(rama),
	.data_b_o(coloram_rgbi)
	);

		assign rgb_o =	gry == 2'b00 & area[1:0] == 2'b00 ? 9'b000_000_000 :
							gry == 2'b00 & area[1:0] == 2'b01 ? 9'b000_000_111 :
							gry == 2'b00 & area[1:0] == 2'b10 ? 9'b000_111_000 :
							gry == 2'b00 & area[1:0] == 2'b11 ? 9'b111_000_000 :
							gry == 2'b01 ? 9'b000_000_111 :
							gry == 2'b10 ? 9'b000_111_000 :
							gry == 2'b11 ? 9'b111_000_000 : 0;

							


   assign sync_o = comp_sync;
   assign hsync_o = hsync;
   assign vsync_o = vsync;
	assign audio_o = audio ;
   assign hblank_o = hblank;
   assign vblank_o = vblank;

endmodule
