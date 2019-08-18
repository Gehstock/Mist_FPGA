//
// A simulation model of VIC20 hardware - VIA implementation
// Copyright (c) MikeJ - March 2003
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// You are responsible for any legal issues arising from your use of this code.
//
// The latest version of this file can be found at: www.fpgaarcade.com
//
// Email vic20@fpgaarcade.com
//
//
// Revision list
//
// version 005 Many fixes to all areas, VIA now passes all VICE tests
// version 004 fixes to PB7 T1 control and Mode 0 Shift Register operation
// version 003 fix reset of T1/T2 IFR flags if T1/T2 is reload via reg5/reg9 from wolfgang (WoS)
//             Ported to numeric_std and simulation fix for signal initializations from arnim laeuger
// version 002 fix from Mark McDougall, untested
// version 001 initial release
// not very sure about the shift register, documentation is a bit light.

module m6522
  (
      input [3:0]      I_RS ,
      input [7:0]      I_DATA ,
      output reg [7:0] O_DATA ,
      output           O_DATA_OE_L ,

      input            I_RW_L ,
      input            I_CS1 ,
      input            I_CS2_L ,

      output           O_IRQ_L , // note, not open drain

      // port a
      input            I_CA1 ,
      input            I_CA2 ,
      output reg       O_CA2 ,
      output reg       O_CA2_OE_L ,

      input [7:0]      I_PA ,
      output [7:0]     O_PA ,
      output [7:0]     O_PA_OE_L ,

      // port b
      input            I_CB1 ,
      output           O_CB1 ,
      output           O_CB1_OE_L ,

      input            I_CB2 ,
      output reg       O_CB2 ,
      output reg       O_CB2_OE_L ,

      input [7:0]      I_PB ,
      output [7:0]     O_PB ,
      output [7:0]     O_PB_OE_L ,

      input            I_P2_H , // high for phase 2 clock  ____////__
      input            RESET_L ,
      input            ENA_4 , // clk enable
      input            CLK
   );



   reg [1:0]       phase = 2'b00;
   reg             p2_h_t1;
   wire            cs;

   // registers
   reg [7:0]       r_ddra;
   reg [7:0]       r_ora;
   reg [7:0]       r_ira;

   reg [7:0]       r_ddrb;
   reg [7:0]       r_orb;
   reg [7:0]       r_irb;

   reg [7:0]       r_t1l_l;
   reg [7:0]       r_t1l_h;
   reg [7:0]       r_t2l_l;
   reg [7:0]       r_t2l_h; // not in real chip
   reg [7:0]       r_sr;
   reg [7:0]       r_acr;
   reg [7:0]       r_pcr;
   wire [7:0]      r_ifr;
   reg [6:0]       r_ier;

   reg             sr_write_ena;
   reg             sr_read_ena;
   reg             ifr_write_ena;
   reg             ier_write_ena;
   wire [7:0]      clear_irq;
   reg [7:0]       load_data;

   // timer 1
   reg [15:0]      t1c = 16'hffff; // simulators may not catch up w/o init here...
   reg             t1c_active;
   reg             t1c_done;
   reg             t1_w_reset_int;
   reg             t1_r_reset_int;
   reg             t1_load_counter;
   reg             t1_reload_counter;
   reg             t1_int_enable = 1'b0;
   reg             t1_toggle;
   reg             t1_irq = 1'b0;
   reg             t1_pb7 = 1'b1;
   reg             t1_pb7_en_c;
   reg             t1_pb7_en_d;

   // timer 2
   reg [15:0]      t2c = 16'hffff;  // simulators may not catch up w/o init here...
   reg             t2c_active;
   reg             t2c_done;
   reg             t2_pb6;
   reg             t2_pb6_t1;
   reg             t2_cnt_clk = 1'b1;
   reg             t2_w_reset_int;
   reg             t2_r_reset_int;
   reg             t2_load_counter;
   reg             t2_reload_counter;
   reg             t2_int_enable = 1'b0;
   reg             t2_irq = 1'b0;
   reg             t2_sr_ena;

   // shift reg
   reg [3:0]       sr_cnt;
   reg             sr_cb1_oe_l;
   reg             sr_cb1_out;
   reg             sr_drive_cb2;
   reg             sr_strobe;
   reg             sr_do_shift = 1'b0;
   reg             sr_strobe_t1;
   reg             sr_strobe_falling;
   reg             sr_strobe_rising;
   reg             sr_irq;
   reg             sr_out;
   reg             sr_active;

   // io
   reg             w_orb_hs;
   reg             w_ora_hs;
   reg             r_irb_hs;
   reg             r_ira_hs;

   reg             ca_hs_sr;
   reg             ca_hs_pulse;
   reg             cb_hs_sr;
   reg             cb_hs_pulse;

   wire            cb1_in_mux;
   reg             ca1_ip_reg_c;
   reg             ca1_ip_reg_d;
   reg             cb1_ip_reg_c;
   reg             cb1_ip_reg_d;
   wire            ca1_int;
   wire            cb1_int;
   reg             ca1_irq;
   reg             cb1_irq;

   reg             ca2_ip_reg_c;
   reg             ca2_ip_reg_d;
   reg             cb2_ip_reg_c;
   reg             cb2_ip_reg_d;
   wire            ca2_int;
   wire            cb2_int;
   reg             ca2_irq;
   reg             cb2_irq;

   reg             final_irq;


   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         p2_h_t1 <= I_P2_H;
         if ((p2_h_t1 == 1'b0) & (I_P2_H == 1'b1)) begin
            phase <= 2'b11;
         end
         else begin
            phase <= phase + 1'b1;
         end
      end
   end

   //  internal clock phase
   assign cs = (I_CS1 == 1'b1 & I_CS2_L == 1'b0 & I_P2_H == 1'b1) ? 1'b1 : 1'b0;

   // peripheral control reg (pcr)
   // 0      ca1 interrupt control (0 +ve edge, 1 -ve edge)
   // 3..1   ca2 operation
   //        000 input -ve edge
   //        001 independend interrupt input -ve edge
   //        010 input +ve edge
   //        011 independend interrupt input +ve edge
   //        100 handshake output
   //        101 pulse output
   //        110 low output
   //        111 high output
   // 7..4   as 3..0 for cb1,cb2

   // auxiliary control reg (acr)
   // 0      input latch PA (0 disable, 1 enable)
   // 1      input latch PB (0 disable, 1 enable)
   // 4..2   shift reg control
   //        000 disable
   //        001 shift in using t2
   //        010 shift in using o2
   //        011 shift in using ext clk
   //        100 shift out free running t2 rate
   //        101 shift out using t2
   //        101 shift out using o2
   //        101 shift out using ext clk
   // 5      t2 timer control (0 timed interrupt, 1 count down with pulses on pb6)
   // 7..6   t1 timer control
   //        00 timed interrupt each time t1 is loaded   pb7 disable
   //        01 continuous interrupts                    pb7 disable
   //        00 timed interrupt each time t1 is loaded   pb7 one shot output
   //        01 continuous interrupts                    pb7 square wave output
   //

   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         r_ora   <= 8'h00;
         r_orb   <= 8'h00;
         r_ddra  <= 8'h00;
         r_ddrb  <= 8'h00;
         r_acr   <= 8'h00;
         r_pcr   <= 8'h00;
         w_orb_hs <= 1'b0;
         w_ora_hs <= 1'b0;
      end else begin
         if (ENA_4 == 1'b1) begin
            w_orb_hs <= 1'b0;
            w_ora_hs <= 1'b0;
            if ((cs == 1'b1) & (I_RW_L == 1'b0)) begin
               case (I_RS)
                  4'h 0 : begin
                     r_orb     <= I_DATA;
                     w_orb_hs <= 1'b1;
                  end

                  4'h 1 : begin
                     r_ora     <= I_DATA;
                     w_ora_hs <= 1'b1;
                  end

                  4'h 2 : begin
                     r_ddrb    <= I_DATA;
                  end

                  4'h 3 : begin
                     r_ddra    <= I_DATA;
                  end


                  4'h B : begin
                     r_acr     <= I_DATA;
                  end

                  4'h C : begin
                     r_pcr     <= I_DATA;
                  end

                  4'h F : begin
                     r_ora     <= I_DATA;
                  end
               endcase
            end

            // Set timer PB7 state, only on rising edge of setting ACR(7)
            if ((t1_pb7_en_d == 1'b0) & (t1_pb7_en_c == 1'b1)) begin
               t1_pb7 <= 1'b1;
            end

            if (t1_load_counter) begin
               t1_pb7 <= 1'b0; // Reset internal timer 1 PB7 state on every timer load
            end else if (t1_toggle == 1'b1) begin
               t1_pb7 <= !t1_pb7;
            end
         end
      end
   end

   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         // The spec says, this is not reset.
         // Fact is that the 1541 VIA1 timer won't work,
         // as the firmware ONLY sets the r_t1l_h latch!!!!
         r_t1l_l   <= 8'hff; // All latches default to FFFF
         r_t1l_h   <= 8'hff;
         r_t2l_l   <= 8'hff;
         r_t2l_h   <= 8'hff;
      end else begin
         if (ENA_4 == 1'b1) begin
            t1_w_reset_int  <= 1'b0;
            t1_load_counter <= 1'b0;

            t2_w_reset_int  <= 1'b0;
            t2_load_counter <= 1'b0;

            load_data <= 8'h00;
            sr_write_ena <= 1'b0;
            ifr_write_ena <= 1'b0;
            ier_write_ena <= 1'b0;

            if ((cs == 1'b1) & (I_RW_L == 1'b0)) begin
               load_data <= I_DATA;
               case (I_RS)
                  4'h4: begin
                     r_t1l_l   <= I_DATA;
                  end

                  4'h5: begin
                     r_t1l_h   <= I_DATA;
                     t1_w_reset_int  <= 1'b1;
                     t1_load_counter <= 1'b1;
                  end

                  4'h6: begin
                     r_t1l_l   <= I_DATA;
                  end

                  4'h7: begin
                     r_t1l_h   <= I_DATA;
                     t1_w_reset_int  <= 1'b1;
                  end


                  4'h8: begin
                     r_t2l_l   <= I_DATA;
                  end

                  4'h9: begin
                     r_t2l_h   <= I_DATA;
                     t2_w_reset_int  <= 1'b1;
                     t2_load_counter <= 1'b1;
                  end

                  4'hA: begin
                     sr_write_ena    <= 1'b1;
                  end

                  4'hD: begin
                     ifr_write_ena   <= 1'b1;
                  end

                  4'hE: begin
                     ier_write_ena   <= 1'b1;
                  end

               endcase
            end
         end
      end
   end

   assign O_DATA_OE_L = (cs == 1'b1 & I_RW_L == 1'b 1) ? 1'b0 : 1'b1;

   reg [7:0] orb;

   always @(*) begin
      t1_r_reset_int <= 1'b0;
      t2_r_reset_int <= 1'b0;
      sr_read_ena <= 1'b0;
      r_irb_hs <= 1'b0;
      r_ira_hs <= 1'b0;
      O_DATA <= 8'h00; // default

      orb = (r_irb & !r_ddrb) | (r_orb & r_ddrb);

      // If PB7 under timer control, assign value from timer
      if (t1_pb7_en_d == 1'b1) begin
         orb[7] = t1_pb7;
      end

      if ((cs == 1'b1) & (I_RW_L == 1'b1)) begin
         case (I_RS)
            4'h0: begin
               O_DATA <= orb; r_irb_hs <= 1'b1;
            end
            4'h1: begin
               O_DATA <= (r_ira & !r_ddra) | (r_ora & r_ddra);
               r_ira_hs <= 1'b1;
            end
            4'h2: begin
               O_DATA <= r_ddrb;
            end
            4'h3: begin
               O_DATA <= r_ddra;
            end
            4'h4: begin
               O_DATA <= t1c[7:0];
               t1_r_reset_int <= 1'b1;
            end
            4'h5: begin
               O_DATA <= t1c[15:8];
            end
            4'h6: begin
               O_DATA <= r_t1l_l;
            end
            4'h7: begin
               O_DATA <= r_t1l_h;
            end
            4'h8: begin
               O_DATA <= t2c[7:0];
               t2_r_reset_int <= 1'b1;
            end
            4'h9: begin
               O_DATA <= t2c[15:8];
            end
            4'hA: begin
               O_DATA <= r_sr;
               sr_read_ena <= 1'b1;
            end
            4'hB: begin
               O_DATA <= r_acr;
            end
            4'hC: begin
               O_DATA <= r_pcr;
            end
            4'hD: begin
               O_DATA <= r_ifr;
            end
            4'hE: begin
               O_DATA <= (1'b0 & r_ier);
            end
            4'hF: begin
               O_DATA <= r_ira;
            end
         endcase
      end

   end

   //
   // IO
   //


   // if the shift register is enabled, cb1 may be an output
   // in this case we should NOT listen to the input as
   // CB1 interrupts are not generated by the shift register

   assign  cb1_in_mux = (sr_cb1_oe_l === 1'b 1) ? I_CB1 : 1'b1;

   // ca1 control
   assign ca1_int = (r_pcr[0] == 1'b0) ?
                    // negative edge
                    (ca1_ip_reg_d == 1'b1) & (ca1_ip_reg_c == 1'b0) :
                    // positive edge
                    (ca1_ip_reg_d == 1'b0) & (ca1_ip_reg_c == 1'b1);

   // cb1 control
   assign cb1_int = (r_pcr[4] == 1'b0) ?
                    // negative edge
                    (cb1_ip_reg_d == 1'b1) & (cb1_ip_reg_c == 1'b0) :
                    // positive edge
                    (cb1_ip_reg_d == 1'b0) & (cb1_ip_reg_c == 1'b1);


   assign ca2_int = (r_pcr[3] == 1'b1) ?
                    // ca2 input
                    1'b0 :
                    (r_pcr[2] == 1'b0) ?
                    // ca2 negative edge
                    (ca2_ip_reg_d == 1'b1) & (ca2_ip_reg_c == 1'b0) :
                    // ca2 positive edge
                    (ca2_ip_reg_d == 1'b0) & (ca2_ip_reg_c == 1'b1);


   assign cb2_int = (r_pcr[7] == 1'b1) ?
                    // cb2 input
                    1'b0 :
                    (r_pcr[6] == 1'b0) ?
                    // cb2 negative edge
                    (cb2_ip_reg_d == 1'b1) & (cb2_ip_reg_c == 1'b0) :
                    // cb2 positive edge
                    (cb2_ip_reg_d == 1'b0) & (cb2_ip_reg_c == 1'b1);





   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         O_CA2       <= 1'b1; // Pullup is default
         O_CA2_OE_L  <= 1'b1;
         O_CB2       <= 1'b1; // Pullup is default
         O_CB2_OE_L  <= 1'b1;

         ca_hs_sr <= 1'b0;
         ca_hs_pulse <= 1'b0;
         cb_hs_sr <= 1'b0;
         cb_hs_pulse <= 1'b0;
      end else begin
         if (ENA_4 == 1'b1) begin
               // ca
            if ((phase == 2'b00) & ((w_ora_hs == 1'b1) | (r_ira_hs == 1'b1))) begin
               ca_hs_sr <= 1'b1;
            end else if (ca1_int) begin
               ca_hs_sr <= 1'b0;
            end

            if (phase == 2'b00) begin
               ca_hs_pulse <= w_ora_hs | r_ira_hs;
            end

            O_CA2_OE_L <= !r_pcr[3]; // ca2 output
            case (r_pcr[3:1])
               3'b000: begin
                  O_CA2 <= I_CA2; // input, output follows input
               end
               3'b001: begin
                  O_CA2 <= I_CA2; // input, output follows input
               end
               3'b010: begin
                  O_CA2 <= I_CA2; // input, output follows input
               end
               3'b011: begin
                  O_CA2 <= I_CA2; // input, output follows input
               end
               3'b100: begin
                  O_CA2 <= !(ca_hs_sr); // handshake
               end
               3'b101: begin
                  O_CA2 <= !(ca_hs_pulse); // pulse
               end
               3'b110: begin
                  O_CA2 <= 1'b0; // low
               end
               3'b111: begin
                  O_CA2 <= 1'b1; // high
               end
            endcase

            if ((phase == 2'b00) & (w_orb_hs == 1'b1)) begin
               cb_hs_sr <= 1'b1;
            end else if (cb1_int) begin
               cb_hs_sr <= 1'b0;
            end

            if (phase == 2'b00) begin
               cb_hs_pulse <= w_orb_hs;
            end

            O_CB2_OE_L <= !(r_pcr[7] | sr_drive_cb2); // cb2 output or serial
            if (sr_drive_cb2 == 1'b1) begin // serial output
               O_CB2 <= sr_out;
            end
            else begin
               case (r_pcr[7:5])
                  3'b000: begin
                     O_CB2 <= I_CB2; // input, output follows input
                  end
                  3'b001: begin
                     O_CB2 <= I_CB2; // input, output follows input
                  end
                  3'b010: begin
                     O_CB2 <= I_CB2; // input, output follows input
                  end
                  3'b011: begin
                     O_CB2 <= I_CB2; // input, output follows input
                  end
                  3'b100: begin
                     O_CB2 <= !(cb_hs_sr); // handshake
                  end
                  3'b101: begin
                     O_CB2 <= !(cb_hs_pulse); // pulse
                  end
                  3'b110: begin
                     O_CB2 <= 1'b0; // low
                  end
                  3'b111: begin
                     O_CB2 <= 1'b1; // high
                  end
               endcase
            end
         end
      end
   end

   assign O_CB1      = sr_cb1_out;
   assign O_CB1_OE_L = sr_cb1_oe_l;

   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         ca1_irq <= 1'b0;
         ca2_irq <= 1'b0;
         cb1_irq <= 1'b0;
         cb2_irq <= 1'b0;
      end else begin
         if (ENA_4 == 1'b1) begin
            // not pretty
            if (ca1_int) begin
               ca1_irq <= 1'b1;
            end else if ((r_ira_hs == 1'b1) | (w_ora_hs == 1'b1) | (clear_irq[1] == 1'b1)) begin
               ca1_irq <= 1'b0;
            end

            if (ca2_int) begin
               ca2_irq <= 1'b1;
            end
            else begin
               if ((((r_ira_hs == 1'b1) | (w_ora_hs == 1'b1)) & (r_pcr[1] == 1'b0)) | (clear_irq[0] == 1'b1)) begin
                  ca2_irq <= 1'b0;
               end
            end

            if (cb1_int) begin
               cb1_irq <= 1'b1;
            end else if ((r_irb_hs == 1'b1) | (w_orb_hs == 1'b1) | (clear_irq[4] == 1'b1)) begin
               cb1_irq <= 1'b0;
            end

            if (cb2_int) begin
               cb2_irq <= 1'b1;
            end
            else begin
               if ((((r_irb_hs == 1'b1) | (w_orb_hs == 1'b1)) & (r_pcr[5] == 1'b0)) | (clear_irq[3] == 1'b1)) begin
                  cb2_irq <= 1'b0;
               end
            end
         end
      end
   end

   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         ca1_ip_reg_c <= 1'b0;
         ca1_ip_reg_d <= 1'b0;

         cb1_ip_reg_c <= 1'b0;
         cb1_ip_reg_d <= 1'b0;

         ca2_ip_reg_c <= 1'b0;
         ca2_ip_reg_d <= 1'b0;

         cb2_ip_reg_c <= 1'b0;
         cb2_ip_reg_d <= 1'b0;

         r_ira <= 8'h00;
         r_irb <= 8'h00;

      end else begin
         if (ENA_4 == 1'b1) begin
            // we have a fast clock, so we can have input registers
            ca1_ip_reg_c <= I_CA1;
            ca1_ip_reg_d <= ca1_ip_reg_c;

            cb1_ip_reg_c <= cb1_in_mux;
            cb1_ip_reg_d <= cb1_ip_reg_c;

            ca2_ip_reg_c <= I_CA2;
            ca2_ip_reg_d <= ca2_ip_reg_c;

            cb2_ip_reg_c <= I_CB2;
            cb2_ip_reg_d <= cb2_ip_reg_c;

            if (r_acr[0] == 1'b0) begin
               r_ira <= I_PA;
            end
            else begin // enable latching
               if (ca1_int) begin
                  r_ira <= I_PA;
               end
            end

            if (r_acr[1] == 1'b0) begin
               r_irb <= I_PB;
            end
            else begin // enable latching
               if (cb1_int) begin
                  r_irb <= I_PB;
               end
            end
         end
      end
   end


   // data direction reg (ddr) 0 = input, 1 = output
   assign O_PA = r_ora;
   assign O_PA_OE_L = ~r_ddra;

   // If PB7 is timer driven output set PB7 to the timer state, otherwise use value in ORB register
   assign O_PB = (t1_pb7_en_d == 1'b1) ? { t1_pb7 , r_orb[6:0]} : r_orb;

   // NOTE: r_ddrb(7) must be set to enable T1 output on PB7 - [various datasheets specify this]
   assign O_PB_OE_L = ~r_ddrb;

   //
   // Timer 1
   //

   // Detect change in r_acr(7), timer 1 mode for PB7
   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         t1_pb7_en_c <= r_acr[7];
         t1_pb7_en_d <= t1_pb7_en_c;
      end
   end

   reg p_timer1_done;
   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         p_timer1_done = (t1c == 16'h0000);
         t1c_done <= p_timer1_done & (phase == 2'b11);
         if ((phase == 2'b11) & !t1_load_counter) begin // Don't set reload if T1L-H written
            t1_reload_counter <= p_timer1_done;
         end else if (t1_load_counter) begin                     // Cancel a reload when T1L-H written
            t1_reload_counter <= 1'b0;
         end
         if (t1_load_counter) begin // done reset on load!
            t1c_done <= 1'b0;
         end
      end
   end

   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         if (t1_load_counter | (t1_reload_counter & phase == 2'b11)) begin
            t1c[ 7:0] <= r_t1l_l;
            t1c[15:8] <= r_t1l_h;
            // There is a need to write to Latch HI to enable interrupts for both continuous and one-shot modes
            if (t1_load_counter) begin
               t1_int_enable <= 1'b1;
            end
         end else if (phase == 2'b11) begin
            t1c <= t1c - 1'b1;
         end

         if (t1_load_counter | t1_reload_counter) begin
            t1c_active <= 1'b1;
         end else if (t1c_done) begin
            t1c_active <= 1'b0;
         end

         t1_toggle <= 1'b0;
         if (t1c_active & t1c_done) begin
            if (t1_int_enable) begin // Set interrupt only if T1L-H has been written
               t1_toggle <= 1'b1;
               t1_irq <= 1'b1;
               if (r_acr[6] == 1'b0) begin // Disable further interrupts if in one shot mode
                  t1_int_enable <= 1'b0;
               end
            end
         end else if (t1_w_reset_int | t1_r_reset_int | (clear_irq[6] == 1'b1)) begin
            t1_irq <= 1'b0;
         end
         if (t1_load_counter) begin // irq reset on load!
            t1_irq <= 1'b0;
         end
      end
   end

   //
   // Timer2
   //

   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         if (phase == 2'b01) begin // leading edge p2_h
            t2_pb6    <= I_PB[6];
            t2_pb6_t1 <= t2_pb6;
         end
      end
   end

   // Ensure we don't start counting until the P2 clock after r_acr is changed
   always @(posedge I_P2_H) begin
      if (r_acr[5] == 1'b0) begin
         t2_cnt_clk <= 1'b1;
      end
      else begin
         t2_cnt_clk <= 1'b0;
      end
   end

   reg p_timer2_done;
   reg p_timer2_done_sr;
   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         p_timer2_done = (t2c == 16'h0000);               // Normal timer expires at 0000
         p_timer2_done_sr = (t2c[7:0] == 8'h00);  // Shift register expires on low byte == 00
         t2c_done <= p_timer2_done & (phase == 2'b11);
         if (phase == 2'b11) begin
            t2_reload_counter <= p_timer2_done_sr;        // Timer 2 is only reloaded when used for the shift register
         end
         if (t2_load_counter) begin // done reset on load!
            t2c_done <= 1'b0;
         end
      end
   end

   reg p_timer2_ena;
   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         if (t2_cnt_clk == 1'b1) begin
            p_timer2_ena = 1'b1;
            t2c_active <= 1'b1;
            t2_int_enable <= 1'b1;
         end
         else begin
            p_timer2_ena = (t2_pb6_t1 == 1'b1) & (t2_pb6 == 1'b0); // falling edge
         end

         // Shift register reload is only active when shift register mode using T2 is enabled
         if (t2_reload_counter & (phase == 2'b11) & ((r_acr[4:2] == 3'b001) | (r_acr[4:2] == 3'b100) | (r_acr[4:2] == 3'b101))) begin
            t2c[7:0] <= r_t2l_l; // For shift register only low latch is loaded!
         end else if (t2_load_counter) begin
            t2_int_enable <= 1'b1;
            t2c[ 7:0] <= r_t2l_l;
            t2c[15:8] <= r_t2l_h;
         end
         else begin
            if ((phase == 2'b11) & p_timer2_ena) begin // or count mode
               t2c <= t2c - 1'b1;
            end
         end

         // Shift register strobe on T2 occurs one P2H clock after timer expires
         // so enable the strobe when we roll over to FF
         t2_sr_ena <= (t2c[7:0] == 8'hFF) & (phase == 2'b11);

         if (t2_load_counter) begin
            t2c_active <= 1'b1;
         end else if (t2c_done) begin
            t2c_active <= 1'b0;
         end

         if (t2c_active & t2c_done & t2_int_enable) begin
            t2_int_enable <= 1'b0;
            t2_irq <= 1'b1;
         end else if (t2_w_reset_int | t2_r_reset_int | (clear_irq[5] == 1'b1)) begin
            t2_irq <= 1'b0;
         end
         if (t2_load_counter) begin // irq reset on load!
            t2_irq <= 1'b0;
         end
      end
   end

   //
   // Shift Register
   //

   reg sr_dir_out      ;
   reg sr_ena          ;
   reg sr_cb1_op       ;
   reg sr_cb1_ip       ;
   reg sr_use_t2       ;
   reg sr_free_run     ;
   reg sr_count_ena ;


   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         r_sr <= 8'h00;
         sr_drive_cb2 <= 1'b0;
         sr_cb1_oe_l <= 1'b1;
         sr_cb1_out <= 1'b0;
         sr_do_shift <= 1'b0;
         sr_strobe <= 1'b1;
         sr_cnt <= 4'b0000;
         sr_irq <= 1'b0;
         sr_out <= 1'b0;
         sr_active <= 1'b0;
      end else begin
         if (ENA_4 == 1'b1) begin
            // decode mode
            sr_dir_out  = r_acr[4]; // output on cb2
            sr_cb1_op   = 1'b0;
            sr_cb1_ip   = 1'b0;
            sr_use_t2   = 1'b0;
            sr_free_run = 1'b0;

            // DMB: SR still runs even in disabled mode (on rising edge of CB1).
            // It just doesn't generate any interrupts.
            // Ref BBC micro advanced user guide p409

            case (r_acr[4:2])
               // DMB: in disabled mode, configure cb1 as an input
               3'b000: begin
                  sr_ena = 1'b0; sr_cb1_ip = 1'b1;                                  // 0x00 Mode 0 SR disabled
               end
               3'b001: begin
                  sr_ena = 1'b1; sr_cb1_op = 1'b1; sr_use_t2 = 1'b1;                   // 0x04 Mode 1 Shift in under T2 control
               end
               3'b010: begin
                  sr_ena = 1'b1; sr_cb1_op = 1'b1;                                  // 0x08 Mode 2 Shift in under P2 control
               end
               3'b011: begin
                  sr_ena = 1'b1; sr_cb1_ip = 1'b1;                                  // 0x0C Mode 3 Shift in under control of ext clock
               end
               3'b100: begin
                  sr_ena = 1'b1; sr_cb1_op = 1'b1; sr_use_t2 = 1'b1; sr_free_run = 1'b1;  // 0x10 Mode 4 Shift out free running under T2 control
               end
               3'b101: begin
                  sr_ena = 1'b1; sr_cb1_op = 1'b1; sr_use_t2 = 1'b1;                   // 0x14 Mode 5 Shift out under T2 control
               end
               3'b110: begin
                  sr_ena = 1'b1; sr_cb1_op = 1'b1;                                  // 0x18 Mode 6 Shift out under P2 control
               end
               3'b111: begin
                  sr_ena = 1'b1; sr_cb1_ip = 1'b1;                                  // 0x1C Mode 7 Shift out under control of ext clock
               end
            endcase

            // clock select
            // DMB: in disabled mode, strobe from cb1
            if (sr_cb1_ip == 1'b1) begin
               sr_strobe <= I_CB1;
            end
            else begin
               if ((sr_cnt[3] == 1'b0) & (sr_free_run == 1'b0)) begin
                  sr_strobe <= 1'b1;
               end
               else begin
                  if (((sr_use_t2 == 1'b1) & t2_sr_ena) |
                     ((sr_use_t2 == 1'b0) & (phase == 2'b00))) begin
                     sr_strobe <= !sr_strobe;
                  end
               end
            end

            // latch on rising edge, shift on falling edge of P2
            if (sr_write_ena) begin
               r_sr <= load_data;
               sr_out <= r_sr[7];

            end
            else begin
               // DMB: allow shifting in all modes
               if (sr_dir_out == 1'b0) begin
                  // input
                  if ((sr_cnt[3] == 1'b1) | (sr_cb1_ip == 1'b1)) begin
                     if (sr_strobe_rising) begin
                        sr_do_shift <= 1'b1;
                        r_sr[0] <= I_CB2;
                     end else if (sr_do_shift) begin
                        sr_do_shift <= 1'b0;
                        r_sr[7:1] <= r_sr[6:0];
                     end
                  end
               end
                  else begin
                  // output
                  if ((sr_cnt[3] == 1'b1) | (sr_cb1_ip == 1'b1) | (sr_free_run == 1'b1)) begin
                     if (sr_strobe_falling) begin
                        sr_out <= r_sr[7];
                        sr_do_shift <= 1'b1;
                     end else if (sr_do_shift) begin
                        sr_do_shift <= 1'b0;
                        r_sr <= r_sr[6:0] & r_sr[7];
                     end
                  end
               end
            end

            // Set shift enabled flag, note does not get set for free_run mode !
            if ((sr_ena == 1'b1) & (sr_cnt[3] == 1'b1)) begin
               sr_active <= 1'b1;
            end else if ((sr_ena == 1'b1) & (sr_cnt[3] == 1'b0) & (phase == 2'b11)) begin
               sr_active <= 1'b0;
            end

            sr_count_ena = sr_strobe_rising;

            // DMB: reseting sr_count when not enabled cause the sr to
            // start running immediately it was enabled, which is incorrect
            // and broke the latest SmartSPI ROM on the BBC Micro
            if ((sr_ena == 1'b1) & (sr_write_ena | sr_read_ena) & (!sr_active)) begin
               // some documentation says sr bit in IFR must be set as well ?
               sr_cnt <= 4'b1000;
            end else if (sr_count_ena & (sr_cnt[3] == 1'b1)) begin
               sr_cnt <= sr_cnt + 1'b1;
            end

            if (sr_count_ena & (sr_cnt == 4'b1111) & (sr_ena == 1'b1) & (sr_free_run == 1'b0)) begin
               sr_irq <= 1'b1;
            end else if (sr_write_ena | sr_read_ena | (clear_irq[2] == 1'b1)) begin
               sr_irq <= 1'b0;
            end

            // assign ops
            sr_drive_cb2 <= sr_dir_out;
            sr_cb1_oe_l  <= !sr_cb1_op;
            sr_cb1_out   <= sr_strobe;
         end
      end
   end

   always @(posedge CLK) begin
      if (ENA_4 == 1'b1) begin
         sr_strobe_t1 <= sr_strobe;
         sr_strobe_rising  <= (sr_strobe_t1 == 1'b0) & (sr_strobe == 1'b1);
         sr_strobe_falling <= (sr_strobe_t1 == 1'b1) & (sr_strobe == 1'b0);
      end
   end

   //
   // Interrupts
   //

   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         r_ier <= 7'b0000000;
      end else begin
         if (ENA_4 == 1'b1) begin
            if (ier_write_ena) begin
               if (load_data[7] == 1'b1) begin
                  // set
                  r_ier <= r_ier | load_data[6:0];
               end
               else begin
                  // clear
                  r_ier <= r_ier & !load_data[6:0];
               end
            end
         end
      end
   end

   assign O_IRQ_L = ~final_irq;

   assign r_ifr    = {final_irq, t1_irq, t2_irq, cb1_irq, cb2_irq, sr_irq, ca1_irq, ca2_irq};


   always @(posedge CLK, negedge RESET_L) begin
      if (RESET_L == 1'b0) begin
         final_irq <= 1'b0;
      end else begin
         if (ENA_4 == 1'b1) begin
            if ((r_ifr[6:0] & r_ier[6:0]) == 7'b0000000) begin
               final_irq <= 1'b0; // no interrupts
            end
            else begin
               final_irq <= 1'b1;
            end
         end
      end
   end

   assign clear_irq = ifr_write_ena ? load_data : 8'h00;

endmodule
