// Atosm Chip
// Copyright (C) 2008 Tomasz Malesinski <tmal@mimuw.edu.pl>
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

module pokey_counter(clk_i, dat_i,
		     freq_ld, start, cnt_en,
		     out, borrow);
   input clk_i;
   input [7:0] dat_i;
   input       freq_ld;
   input       start;
   input       cnt_en;
   output [7:0] out;
   output 	borrow;

   reg [7:0]  freq;
   reg [7:0]  out;

   assign     borrow = (out == 0);

   always @ (posedge clk_i)
     if (start)
       out <= freq;
     else if (cnt_en)
       out <= out - 8'd1;

   always @ (posedge clk_i)
     if (freq_ld)
       freq <= dat_i;

endmodule

module pokey_basefreq(rst, clk_i, base15, out);

   input rst;
   input clk_i;
   input base15;
   output out;
   
   reg [5:0] div57;
   reg [1:0] div4;

   assign out = (div57 == 0) && (!base15 || div4 == 0);
   
   always @ (posedge clk_i)
     if (rst) begin
	div57 <= 6'b0;
	div4 <= 2'b0;
     end else if (div57 == 56) begin
	div57 <= 0;
	div4 <= div4 + 2'd1;
     end else
       div57 <= div57 + 6'd1;

endmodule

module pokey_poly4(rst, clk_i, out);
   input rst;
   input clk_i;
   output out;

   reg [3:0] shift;

   assign out = shift[3];

   always @ (posedge clk_i)
     if (rst)
       shift <= {shift[2:0], 1'b0};
     else
       shift <= {shift[2:0], shift[3] ~^ shift[2]};

endmodule

module pokey_poly5(rst, clk_i, out);
   input rst;
   input clk_i;
   output out;

   reg [4:0] shift;

   assign out = shift[4];

   always @ (posedge clk_i)
     if (rst)
       shift <= {shift[3:0], 1'b0};
     else
       shift <= {shift[3:0], shift[4] ~^ shift[2]};

endmodule

module pokey_poly17(rst, clk_i, short, out, random);

   input rst;
   input clk_i;
   input short;
   output out;
   output [7:0] random;

   reg [16:0] shift;
   wire       new_bit;
   reg 	      last_short;

   assign out = shift[16];
   assign random = shift[16:9];
   
   assign new_bit = shift[16] ~^ shift[11];

   // last_short is used to reset the shortened shift register when
   // switching from long to short.
   always @ (posedge clk_i)
     if (rst)
       last_short <= 0;
   else
     last_short <= short;

   always @ (posedge clk_i)
     if (rst)
       shift <= 0;
   else
     shift <= {shift[15:8],
               (short ? new_bit : shift[7]) & ~rst & (last_short | ~short),
	       shift[6:0], new_bit};
endmodule

module pokey_audout(rst, clk_i, dat_i,
		    audc_we,
		    poly4, poly5, poly17,
		    in, filter_en, filter_in,
		    out);
   input rst;
   input clk_i;
   input [7:0] dat_i;
   input audc_we;
   input poly4, poly5, poly17;
   input in, filter_en, filter_in;

   output [3:0] out;

   reg [3:0]  vol;
   reg 	      vol_only;
   reg 	      no_poly5;
   reg 	      poly4_sel;
   reg 	      no_poly17_4;
   reg 	      nf, filter_reg;

   wire       change;
   wire       ch_out;
   
   assign out = (ch_out | vol_only) ? vol : 4'b0;
   
   assign change = in & (no_poly5 | poly5);
   assign ch_out = filter_en ? filter_reg ^ nf : nf;

   always @ (posedge clk_i)
     if (audc_we) begin
	vol <= dat_i[3:0];
	vol_only <= dat_i[4];
	no_poly5 <= dat_i[7];
	poly4_sel <= dat_i[6];
	no_poly17_4 <= dat_i[5];
     end
	
   always @ (posedge clk_i)
     if (rst)
       nf <= 0;
     else if (change)
       if (no_poly17_4)
	 nf <= ~nf;
       else if (poly4_sel)
	 nf <= poly4;
       else
	 nf <= poly17;
   
   always @ (posedge clk_i)
     if (!filter_en || rst)
       filter_reg <= 0;
     else if (filter_in)
       filter_reg <= nf;

endmodule

module pokey_atosm(rst_i,
		   clk_i,
		   adr_i,
		   dat_i,
		   dat_o,
		   we_i,
		   stb_i,
		   ack_o,
		   irq,
		   audout,
		   p_i,
		   key_code, key_pressed, key_shift, key_break,
		   serout, serout_rdy_o, serout_ack_i,
		   serin, serin_rdy_i, serin_ack_o);
   input rst_i;
   input clk_i;
   input [3:0] adr_i;
   input [7:0] dat_i;
   input       we_i;
   input       stb_i;
   input [7:0] key_code;
   input       key_pressed, key_shift, key_break;
   input       serout_ack_i;
   input [7:0] serin;
   input       serin_rdy_i;
   input [7:0] p_i;

   output [7:0] dat_o;
   output 	ack_o;
   output 	irq;
   output [5:0] audout;
   output [7:0] serout;
   output 	serout_rdy_o, serin_ack_o;

   wire       rst_i, clk_i;
   wire [3:0] adr_i;
   wire [7:0] dat_i;
   wire       we_i;
   wire       stb_i;
   wire [7:0] key_code;
   wire       key_pressed, key_shift, key_break;
   reg 	      last_key_pressed, last_key_break;

   wire       ack_o;
   reg [7:0]  dat_o;

   wire [5:0] audout;
   
   wire [7:0] serin;
   wire       serin_rdy_i;
   reg 	      last_serin_rdy_i;
   reg 	      serin_ack_o;
   reg [7:0]  serout;
   reg 	      serout_rdy_o;
   wire       serout_ack_i;
   reg 	      last_serout_ack_i;

   wire       rst;
   wire       start_timer;

   reg 	      irq;

   parameter [2:0] IRQ_BREAK  = 7;
   parameter [2:0] IRQ_KEY    = 6;
   parameter [2:0] IRQ_SERIN  = 5;
   parameter [2:0] IRQ_SEROUT = 4;
   parameter [2:0] IRQ_SERFIN = 3;
   parameter [2:0] IRQ_TIMER4 = 2;
   parameter [2:0] IRQ_TIMER2 = 1;
   parameter [2:0] IRQ_TIMER1 = 1;

   reg [7:0] 	   irqen;
   reg [7:0] 	   irqst;

   // SKCTL bits.
   reg [1:0]  rst_bits;

   // AUDCTL bits.
   reg 	      poly9;
   reg 	      fast_ch0;
   reg 	      fast_ch2;
   reg 	      ch01;
   reg 	      ch23;
   reg 	      fi02;
   reg 	      fi13;
   reg 	      base15;

   reg [3:0]   audf_we;
   reg [3:0]   audc_we;
   wire [3:0]  start;
   wire [3:0]  cnt_en;
   wire [31:0] ctr_out;
   wire [3:0]  borrow;

   wire        poly4, poly5, poly17;
   reg [3:1]   poly4_shift, poly5_shift, poly17_shift;
   wire        base;

   wire [3:0]  audout0, audout1, audout2, audout3;

   integer    i, irq_i;

   wire [7:0] random;

   assign audout = {1'b0, audout0} + {1'b0, audout1} + {1'b0, audout2} + {1'b0, audout3};
   assign rst = (rst_bits == 2'b00) | rst_i;

   assign     ack_o = stb_i;

   //
   reg [7:0]  pot_done = 0;
   reg [7:0]  pot_cntr[0:7];
   reg [7:0]  pot_count;

   // POTGO
   always @ (posedge clk_i)
     if (we_i && stb_i && adr_i == 'hb)
       begin
	  pot_cntr[0] <= 8'h00;
	  pot_cntr[1] <= 8'h00;
	  pot_cntr[2] <= 8'h00;
	  pot_cntr[3] <= 8'h00;
	  pot_cntr[4] <= 8'h00;
	  pot_cntr[5] <= 8'h00;
	  pot_cntr[6] <= 8'h00;
	  pot_cntr[7] <= 8'h00;
	  pot_done <= 8'h00;
	  pot_count <= 0;
       end // if (we_i && stb_i && adr_i == 'hb)
     else
       begin
	  if (pot_count != 8'hff)
	    pot_count <= pot_count + 8'd1;
	  else
	    pot_done <= 8'hff;

	  pot_cntr[0] <= p_i[0] ? 8'hff : 8'h00;
	  pot_cntr[1] <= p_i[1] ? 8'hff : 8'h00;
	  pot_cntr[2] <= p_i[2] ? 8'hff : 8'h00;
	  pot_cntr[3] <= p_i[3] ? 8'hff : 8'h00;
	  pot_cntr[4] <= p_i[4] ? 8'hff : 8'h00;
	  pot_cntr[5] <= p_i[5] ? 8'hff : 8'h00;
	  pot_cntr[6] <= p_i[6] ? 8'hff : 8'h00;
	  pot_cntr[7] <= p_i[7] ? 8'hff : 8'h00;
       end
   
`ifdef never
   always @ (adr_i or key_code or random or serin or irqst or irqen or
	     key_shift or key_pressed)
     if (adr_i == 'h9)
       // KBCODE
       dat_o = key_code;
     else if (adr_i == 'ha)
       // RANDOM
       dat_o = random;
     else if (adr_i == 'hd)
       // SERIN
       dat_o = serin;
     else if (adr_i == 'he)
       // IRQST
       dat_o = ~(irqst & irqen);
     else if (adr_i == 'hf)
       // SKSTAT
       dat_o = {1'b1,  // no framing error
		1'b1,  // no keyboard overrun
		1'b1,  // no serial data input over-run
		1'b1,  // serial input pad
		~key_shift,
		~key_pressed,
		1'b1,  // serial input shift register busy
		1'b1}; // not used
     else
       dat_o = 'hff;
`else // !`ifdef never
   always @ (adr_i or key_code or random or serin or irqst or irqen or
	     key_shift or key_pressed or pot_done or
	     pot_cntr[0] or pot_cntr[1] or pot_cntr[2] or pot_cntr[3] or
     	     pot_cntr[4] or pot_cntr[5] or pot_cntr[6] or pot_cntr[7])
     case (adr_i)
       4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7:
	 dat_o = pot_cntr[adr_i[2:0]];
       4'h8: // ALLPOT
	 dat_o = pot_done;
       4'h9: // KBCODE
	 dat_o = key_code;
       4'ha: // RANDOM
	 dat_o = random;
       4'hd: // SERIN
	 dat_o = serin;
       4'he: // IRQST
	 dat_o = ~(irqst & irqen);
       4'hf: // SKSTAT
	 dat_o = {1'b1,  // no framing error
		  1'b1,  // no keyboard overrun
		  1'b1,  // no serial data input over-run
		  1'b1,  // serial input pad
		  ~key_shift,
		  ~key_pressed,
		  1'b1,  // serial input shift register busy
		  1'b1}; // not used
       default:
	 dat_o = 'hff;
     endcase
`endif // !`ifdef never
   
   always @ (adr_i) begin
      for (i = 0; i < 4; i = i + 1)
	audf_we[i] = {28'b0, adr_i} == (i << 1);
      for (i = 0; i < 4; i = i + 1)
	audc_we[i] = {28'b0, adr_i} == ((i << 1) + 32'd1);
   end

   assign start_timer = (we_i && stb_i && adr_i == 9);

   always @ (posedge clk_i)
     if (rst) begin
    	poly9 <= 0;
    	fast_ch0 <= 0;
    	fast_ch2 <= 0;
    	ch01 <= 0;
    	ch23 <= 0;
    	fi02 <= 0;
    	fi13 <= 0;
    	base15 <= 0;
     end
     else
     if (we_i && stb_i && adr_i == 8) begin
    	poly9 <= dat_i[7];
    	fast_ch0 <= dat_i[6];
    	fast_ch2 <= dat_i[5];
    	ch01 <= dat_i[4];
    	ch23 <= dat_i[3];
    	fi02 <= dat_i[2];
    	fi13 <= dat_i[1];
    	base15 <= dat_i[0];
     end

   // SKRES
   always @ (posedge clk_i)
     if (we_i && stb_i && adr_i == 'ha) begin
	// TODO: reset SKSTAT[7:5] if they are implemented
     end

   always @ (posedge clk_i) begin
      last_serin_rdy_i <= serin_rdy_i;
      if (rst)
	serin_ack_o <= 0;
      else if (stb_i && !we_i && adr_i == 'hd && serin_rdy_i)
	serin_ack_o <= 1;
      else if (!serin_rdy_i)
	serin_ack_o <= 0;
   end

   // SEROUT
   always @ (posedge clk_i) begin
      last_serout_ack_i <= serout_ack_i;
      if (rst)
	serout_rdy_o <= 0;
      else if (we_i && stb_i && adr_i == 'hd) begin
	 serout <= dat_i;
	 serout_rdy_o <= 1;
      end else if (serout_ack_i)
	serout_rdy_o <= 0;
   end

   // IRQEN
   always @ (posedge clk_i)
     if (we_i && stb_i && adr_i == 'he)
	irqen <= dat_i;

   always @ (posedge clk_i or posedge rst_i)
     if (rst_i)
       rst_bits <= 0;
     else
     if (we_i && stb_i && adr_i == 'hf) begin
	rst_bits <= dat_i[1:0];
	// TODO: rest of the bits.
     end

   always @ (posedge clk_i) begin
      last_key_pressed <= key_pressed;
      last_key_break <= key_break;
   end

   always @ (posedge clk_i)
     // IRQ_SERFIN has no latch.
     irqst <= irqen & ({irqst[7:4],
			!serout_ack_i && !serout_rdy_o,
			irqst[2:0]} |
		       {key_break && !last_key_break,
			key_pressed && !last_key_pressed,
			serin_rdy_i && !last_serin_rdy_i,
			serout_ack_i && !last_serout_ack_i,
			1'b0, borrow[3], borrow[1:0]});

   always @ (irqst) begin
      irq = 0;
      for (i = 0; i < 8; i = i + 1)
	irq = irq || irqst[i];
   end

   pokey_basefreq u_base(rst, clk_i, base15, base);

   pokey_poly4 u_poly4(rst, clk_i, poly4);
   pokey_poly5 u_poly5(rst, clk_i, poly5);
   pokey_poly17 u_poly17(rst, clk_i, poly9, poly17, random);

   always @ (posedge clk_i) begin
      poly4_shift <= {poly4_shift[2:1], poly4};
      poly5_shift <= {poly5_shift[2:1], poly5};
      poly17_shift <= {poly17_shift[2:1], poly17};
   end

   assign cnt_en[0] = fast_ch0 ? 1'b1 : base;
   assign cnt_en[1] = ch01 ? borrow[0] : base;
   assign cnt_en[2] = fast_ch2 ? 1'b1 : base;
   assign cnt_en[3] = ch23 ? borrow[2] : base;

   assign start[0] = start_timer | (ch01 ? borrow[1] : borrow[0]);
   assign start[1] = start_timer | borrow[1];
   assign start[2] = start_timer | (ch23 ? borrow[3] : borrow[2]);
   assign start[3] = start_timer | borrow[3];

   // TODO: clean it up after removing the array of instances
   // (remove assignments above)
   // TODO: do we need ctr_out?
   pokey_counter u_ctr0(clk_i, dat_i,
			audf_we[0], start[0], cnt_en[0],
			ctr_out[7:0], borrow[0]);
   pokey_counter u_ctr1(clk_i, dat_i,
			audf_we[1], start[1], cnt_en[1],
			ctr_out[15:8], borrow[1]);
   pokey_counter u_ctr2(clk_i, dat_i,
			audf_we[2], start[2], cnt_en[2],
			ctr_out[23:16], borrow[2]);
   pokey_counter u_ctr3(clk_i, dat_i,
			audf_we[3], start[3], cnt_en[3],
			ctr_out[31:24], borrow[3]);
   pokey_audout u_audout0(start_timer, clk_i, dat_i,
			  audc_we[0],
			  poly4, poly5, poly17,
			  borrow[0], fi02, borrow[2],
			  audout0);
   pokey_audout u_audout1(start_timer, clk_i, dat_i,
			  audc_we[1],
			  poly4_shift[1], poly5_shift[1], poly17_shift[1],
			  borrow[1], fi13, borrow[3],
			  audout1);
   pokey_audout u_audout2(start_timer, clk_i, dat_i,
			  audc_we[2],
			  poly4_shift[2], poly5_shift[2], poly17_shift[2],
			  borrow[2], 1'b0, 1'b0,
			  audout2);
   pokey_audout u_audout3(start_timer, clk_i, dat_i,
			  audc_we[3],
			  poly4_shift[3], poly5_shift[3], poly17_shift[3],
			  borrow[3], 1'b0, 1'b0,
			  audout3);
endmodule
