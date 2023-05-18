//-----------------------------------------------------------------------------
//
// Synthesizable model of TI's TMS9918A, TMS9928A, TMS9929A.
//
// $Id: vdp18_cpuio.vhd,v 1.17 2006/06/18 10:47:01 arnim Exp $
//
// CPU I/O Interface Module
//
//-----------------------------------------------------------------------------
//
// Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
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
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// SystemVerilog conversion (c) 2022 Frank Bruno (fbruno@asicsolutions.com)
//
//-----------------------------------------------------------------------------

import vdp18_pkg::*;

module vdp18_cpuio
  (
   input            clk_i,
   input            clk_en_10m7_i,
   input            clk_en_acc_i,
   input            reset_i,
   input            rd_i,
   input            wr_i,
   input            mode_i,
   input [0:7]      cd_i,
   output [0:7]     cd_o,
   output           cd_oe_o,
   input access_t   access_type_i,
   output opmode_t  opmode_o,
   output reg       vram_we_o,
   output [0:13]    vram_a_o,
   output [0:7]     vram_d_o,
   input [0:7]      vram_d_i,
   input            spr_coll_i,
   input            spr_5th_i,
   input [0:4]      spr_5th_num_i,
   output           reg_ev_o,
   output           reg_16k_o,
   output           reg_blank_o,
   output           reg_size1_o,
   output           reg_mag1_o,
   output [0:3]     reg_ntb_o,
   output [0:7]     reg_ctb_o,
   output [0:2]     reg_pgb_o,
   output [0:6]     reg_satb_o,
   output [0:2]     reg_spgb_o,
   output [0:3]     reg_col1_o,
   output [0:3]     reg_col0_o,
   input            irq_i,
   output           int_n_o
   );

  typedef enum bit [3:0]
               {
                state_t_ST_IDLE                = 4'd0,
                state_t_ST_RD_MODE0            = 4'd1,
                state_t_ST_WR_MODE0            = 4'd2,
                state_t_ST_RD_MODE1            = 4'd3,
                state_t_ST_WR_MODE1_1ST        = 4'd4,
                state_t_ST_WR_MODE1_1ST_IDLE   = 4'd5,
                state_t_ST_WR_MODE1_2ND_VREAD  = 4'd6,
                state_t_ST_WR_MODE1_2ND_VWRITE = 4'd7,
                state_t_ST_WR_MODE1_2ND_RWRITE = 4'd8
                } state_t;

  state_t        state_s;
  state_t        state_q;

  logic [0:7]    buffer_q;

  logic [0:13]   addr_q;

  logic          incr_addr_s;
  logic          load_addr_s;

  logic          wrbuf_cpu_s;
  logic          sched_rdvram_s;
  logic          rdvram_sched_q;
  logic          rdvram_q;
  logic          abort_wrvram_s;
  logic          sched_wrvram_s;
  logic          wrvram_sched_q;
  logic          wrvram_q;

  logic          write_tmp_s;
  logic [0:7]    tmp_q;
  logic          write_reg_s;

  // control register bits ----------------------------------------------------
  logic [0:7]    ctrl_reg_q[7:0];

  // status register ----------------------------------------------------------
  logic [0:7]    status_reg_s;
  logic          destr_rd_status_s;
  logic          sprite_5th_q;
  logic [0:4]    sprite_5th_num_q;
  logic          sprite_coll_q;
  logic          int_n_q;

  typedef enum bit
               {
                read_mux_t_RDMUX_STATUS    = 1'b0,
                read_mux_t_RDMUX_READAHEAD = 1'b1
                } read_mux_t;
  read_mux_t    read_mux_s;

  //---------------------------------------------------------------------------
  // Process seq
  //
  // Purpose:
  //   Implements the sequential elements.
  //

  always @(posedge clk_i, posedge reset_i )
    begin: seq
      logic incr_addr_v;
      if (reset_i)
        begin
          state_q        <= state_t_ST_IDLE;
          buffer_q       <= '0;
          addr_q         <= '0;
          rdvram_sched_q <= '0;
          rdvram_q       <= '0;
          wrvram_sched_q <= '0;
          wrvram_q       <= '0;
        end
        else
        begin
          // default assignments
          incr_addr_v  = incr_addr_s;

          if (clk_en_10m7_i)
            begin
              // update state vector ------------------------------------------------
              state_q <= state_s;

              // buffer and flag control --------------------------------------------
              if (wrbuf_cpu_s)
                begin
                  // write read-ahead buffer from CPU bus
                  buffer_q       <= cd_i;
                  // immediately stop read-ahead
                  rdvram_sched_q <= '0;
                  rdvram_q       <= '0;
                end
                else if (clk_en_acc_i && rdvram_q && (access_type_i == AC_CPU))
                begin
                  // write read-ahead buffer from VRAM during CPU access slot
                  buffer_q <= vram_d_i;
                  // stop scanning for CPU data
                  rdvram_q <= '0;
                  // increment read-ahead address
                  incr_addr_v = '1;
                end

              if (sched_rdvram_s)
                begin
                  // immediately stop write-back
                  wrvram_sched_q <= '0;
                  wrvram_q       <= '0;
                  // schedule read-ahead
                  rdvram_sched_q <= '1;
                end

              if (sched_wrvram_s)
                // schedule write-back
                wrvram_sched_q <= '1;

              if (abort_wrvram_s)
                // stop scanning for write-back
                wrvram_q <= '0;

              if (rdvram_sched_q && clk_en_acc_i)
                begin
                  // align scheduled read-ahead with access slot phase
                  rdvram_sched_q <= '0;
                  rdvram_q       <= '1;
                end
              if (wrvram_sched_q && clk_en_acc_i)
                begin
                  // align scheduled write-back with access slot phase
                  wrvram_sched_q <= '0;
                  wrvram_q       <= '1;
                end

              // manage address -----------------------------------------------------
              if (load_addr_s)
                begin
                  addr_q[6:13] <= tmp_q;
                  addr_q[0:5]  <= cd_i[2:7];
                end
              else if (incr_addr_v)
                addr_q <= addr_q + 1'b1;
            end
        end
    end

  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process wback_ctrl
  //
  // Purpose:
  //   Write-back control.
  //

  always_comb
    begin: wback_ctrl
      // default assignments
      abort_wrvram_s = '0;
      incr_addr_s    = '0;
      vram_we_o      = '0;

      if (wrvram_q)
        begin
          if (access_type_i == AC_CPU)
            begin
              // signal write access to VRAM
              vram_we_o = '1;

              if (clk_en_acc_i)
                begin
                  // clear write-back flag and increment address
                  abort_wrvram_s = '1;
                  incr_addr_s    = '1;
                end
            end
        end
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process reg_if
  //
  // Purpose:
  //   Implements the register interface.
  //

  always @(posedge clk_i, posedge reset_i )
    begin: reg_if
      if (reset_i)
        begin
          tmp_q            <= '0;
          ctrl_reg_q       <= '{default: '0};
          sprite_coll_q    <= '0;
          sprite_5th_q     <= '0;
          sprite_5th_num_q <= '0;
          int_n_q          <= '1;
        end

      else
        begin
          if (clk_en_10m7_i)
            begin
              // Temporary register -------------------------------------------------
              if (write_tmp_s)
                tmp_q <= cd_i;

              // Registers 0 to 7 ---------------------------------------------------
              if (write_reg_s)
                begin
                  ctrl_reg_q[cd_i[5:7]] <= tmp_q;
                end
            end

          // Fifth sprite handling ------------------------------------------------
          if (spr_5th_i && (~sprite_5th_q))
            begin
              sprite_5th_q     <= '1;
              sprite_5th_num_q <= spr_5th_num_i;
            end
          else if (destr_rd_status_s)
            sprite_5th_q <= '0;

          // Sprite collision flag ------------------------------------------------
          if (spr_coll_i)
            sprite_coll_q <= '1;
          else if (destr_rd_status_s)
            sprite_coll_q <= '0;

          // Interrupt ------------------------------------------------------------
          if (irq_i)
            int_n_q <= '0;
          else if (destr_rd_status_s)
            int_n_q <= '1;
        end
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process access_ctrl
  //
  // Purpose:
  //   Implements the combinational logic for the CPU I/F FSM.
  //   Decodes the CPU I/F FSM state and generates the control signals for the
  //   register and VRAM logic.
  //
  typedef enum bit [2:0]
               {
                transfer_mode_t_TM_NONE     = 3'd0,
                transfer_mode_t_TM_RD_MODE0 = 3'd1,
                transfer_mode_t_TM_WR_MODE0 = 3'd2,
                transfer_mode_t_TM_RD_MODE1 = 3'd3,
                transfer_mode_t_TM_WR_MODE1 = 3'd4
                } transfer_mode_t;
  transfer_mode_t transfer_mode_v;

  always_comb
    begin: access_ctrl
      // default assignments
      state_s           = state_q;
      sched_rdvram_s    = '0;
      sched_wrvram_s    = '0;
      wrbuf_cpu_s       = '0;
      write_tmp_s       = '0;
      write_reg_s       = '0;
      load_addr_s       = '0;
      read_mux_s        = read_mux_t_RDMUX_STATUS;
      destr_rd_status_s = '0;

      // determine transfer mode
      transfer_mode_v    = transfer_mode_t_TM_NONE;
      if (~mode_i)
        begin
          if (rd_i)
            transfer_mode_v = transfer_mode_t_TM_RD_MODE0;
          if (wr_i)
            transfer_mode_v = transfer_mode_t_TM_WR_MODE0;
        end
      else
        begin
          if (rd_i)
            transfer_mode_v = transfer_mode_t_TM_RD_MODE1;
          if (wr_i)
            transfer_mode_v = transfer_mode_t_TM_WR_MODE1;
        end

      // FSM state transitions
      case (state_q)
        // ST_IDLE: waiting for CPU access --------------------------------------
        state_t_ST_IDLE :
          case (transfer_mode_v)
            transfer_mode_t_TM_RD_MODE0 :
              state_s = state_t_ST_RD_MODE0;
            transfer_mode_t_TM_WR_MODE0 :
              state_s = state_t_ST_WR_MODE0;
            transfer_mode_t_TM_RD_MODE1 :
              state_s = state_t_ST_RD_MODE1;
            transfer_mode_t_TM_WR_MODE1 :
              state_s = state_t_ST_WR_MODE1_1ST;
            default: begin end
          endcase

        // ST_RD_MODE0: read from VRAM ------------------------------------------
        state_t_ST_RD_MODE0 :
          begin
            // set read mux
            read_mux_s = read_mux_t_RDMUX_READAHEAD;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              begin
                // CPU finished read access:
                // schedule new read-ahead and return to idle
                state_s = state_t_ST_IDLE;
                sched_rdvram_s = '1;
              end
          end

        // ST_WR_MODE0: write to VRAM -------------------------------------------
        state_t_ST_WR_MODE0 :
          begin
            // write data from CPU to write-back/read-ahead buffer
            wrbuf_cpu_s = '1;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              begin
                // CPU finished write access:
                // schedule new write-back and return to idle
                state_s = state_t_ST_IDLE;
                sched_wrvram_s = '1;
              end
          end

        // ST_RD_MODE1: read from status register -------------------------------
        state_t_ST_RD_MODE1 :
          begin
            // set read mux
            read_mux_s = read_mux_t_RDMUX_STATUS;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              begin
                // CPU finished read access:
                // destructive read of status register and return to IDLE
                destr_rd_status_s = '1;
                state_s = state_t_ST_IDLE;
              end
          end

        // ST_WR_MODE1_1ST: save first byte -------------------------------------
        state_t_ST_WR_MODE1_1ST :
          begin
            // update temp register
            write_tmp_s = '1;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              // CPU finished write access:
              // become idle but remember that the first byte of a paired write
              // has been written
              state_s = state_t_ST_WR_MODE1_1ST_IDLE;
          end

        // ST_WR_MODE1_1ST_IDLE: wait for next access ---------------------------
        state_t_ST_WR_MODE1_1ST_IDLE :
          // determine type of next access
          case (transfer_mode_v)
            transfer_mode_t_TM_RD_MODE0 :
              state_s = state_t_ST_RD_MODE0;
            transfer_mode_t_TM_WR_MODE0 :
              state_s = state_t_ST_WR_MODE0;
            transfer_mode_t_TM_RD_MODE1 :
              state_s = state_t_ST_RD_MODE1;
            transfer_mode_t_TM_WR_MODE1 :
              case (cd_i[0:1])
                2'b00 :
                  state_s = state_t_ST_WR_MODE1_2ND_VREAD;
                2'b01 :
                  state_s = state_t_ST_WR_MODE1_2ND_VWRITE;
                2'b10, 2'b11 :
                  state_s = state_t_ST_WR_MODE1_2ND_RWRITE;
                default: begin end
              endcase
            default: begin end
          endcase

        // ST_WR_MODE1_2ND_VREAD: write second byte of address, then read ahead -
        state_t_ST_WR_MODE1_2ND_VREAD :
          begin
            load_addr_s = '1;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              begin
                // CPU finished write access:
                // schedule new read-ahead and return to idle
                sched_rdvram_s = '1;
                state_s = state_t_ST_IDLE;
              end
          end

        // ST_WR_MODE1_2ND_VWRITE: write second byte of address
        state_t_ST_WR_MODE1_2ND_VWRITE :
          begin
            load_addr_s = '1;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              // CPU finished write access:
              // return to idle
              state_s = state_t_ST_IDLE;
          end

        // ST_WR_MODE1_2ND_RWRITE: write to register ----------------------------
        state_t_ST_WR_MODE1_2ND_RWRITE :
          begin
            write_reg_s = '1;

            if (transfer_mode_v == transfer_mode_t_TM_NONE)
              // CPU finished write access:
              // return to idle
              state_s = state_t_ST_IDLE;
          end
        default: begin end

      endcase
    end

  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Process mode_decode
  //
  // Purpose:
  //   Decodes the display mode from the M1, M2, M3 bits.
  //

  always_comb
    begin: mode_decode
      case ({ctrl_reg_q[1][3], ctrl_reg_q[1][4], ctrl_reg_q[0][6]})
        3'b000 :
          opmode_o = OPMODE_GRAPH1;
        3'b001 :
          opmode_o = OPMODE_GRAPH2;
        3'b010 :
          opmode_o = OPMODE_MULTIC;
        3'b100 :
          opmode_o = OPMODE_TEXTM;
        default :
          opmode_o = OPMODE_TEXTM;
      endcase
    end
  //
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  // Build status register
  //---------------------------------------------------------------------------
  assign status_reg_s = {(~int_n_q), sprite_5th_q, sprite_coll_q, sprite_5th_num_q};

  //---------------------------------------------------------------------------
  // Output mapping
  //---------------------------------------------------------------------------
  assign vram_a_o = addr_q;
  assign vram_d_o = buffer_q;

  assign cd_o = (read_mux_s == read_mux_t_RDMUX_READAHEAD) ? buffer_q : status_reg_s;
  assign cd_oe_o = (rd_i) ? 1'b1 : 1'b0;

  assign reg_ev_o = ctrl_reg_q[0][7];
  assign reg_16k_o = ctrl_reg_q[1][0];
  assign reg_blank_o = ~(ctrl_reg_q[1][1]);
  assign reg_size1_o = ctrl_reg_q[1][6];
  assign reg_mag1_o = ctrl_reg_q[1][7];
  assign reg_ntb_o = ctrl_reg_q[2][4:7];
  assign reg_ctb_o = ctrl_reg_q[3];
  assign reg_pgb_o = ctrl_reg_q[4][5:7];
  assign reg_satb_o = ctrl_reg_q[5][1:7];
  assign reg_spgb_o = ctrl_reg_q[6][5:7];
  assign reg_col1_o = ctrl_reg_q[7][0:3];
  assign reg_col0_o = ctrl_reg_q[7][4:7];
  assign int_n_o = int_n_q | (~ctrl_reg_q[1][2]);

endmodule
