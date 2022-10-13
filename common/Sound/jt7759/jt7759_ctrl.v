/*  This file is part of JT7759.
    JT7759 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public Licen_ctlse as published by
    the Free Software Foundation, either version 3 of the Licen_ctlse, or
    (at your option) any later version.

    JT7759 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public Licen_ctlse for more details.

    You should have received a copy of the GNU General Public Licen_ctlse
    along with JT7759.  If not, see <http://www.gnu.org/licen_ctlses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 5-7-2020 */

module jt7759_ctrl(
    input             rst,
    input             clk,
    input             cen_ctl,
    input             cen_dec,
    output reg [ 5:0] divby,
    input             stn,  // STart (active low)
    input             cs,
    input             mdn,  // MODE: 1 for stand alone mode, 0 for slave mode
    input             drqn,
    output            busyn,
    // CPU interface
    input             wrn,  // for slave mode only
    input      [ 7:0] din,
    // ADPCM engine
    output reg        dec_rst,
    output reg [ 3:0] dec_din,
    // ROM interface
    output            rom_cs,      // equivalent to DRQn in original chip
    output reg [16:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok,
    output reg        flush
);

localparam STW = 11;
localparam [STW-1:0] RST    =1<<0;  // 1
localparam [STW-1:0] IDLE   =1<<1;  // 2
localparam [STW-1:0] SND_CNT=1<<2;  // 4
localparam [STW-1:0] PLAY   =1<<3;  // 8
localparam [STW-1:0] WAIT   =1<<4;  // 10
localparam [STW-1:0] GETN   =1<<5;  // 20
localparam [STW-1:0] MUTED  =1<<6;  // 40
localparam [STW-1:0] LOAD   =1<<7;  // 80
localparam [STW-1:0] READCMD=1<<8;  // 100
localparam [STW-1:0] READADR=1<<9;  // 200
localparam [STW-1:0] SIGN   =1<<10; // 400

localparam MTW = 13; // Mute counter 7+6 bits

reg  [    7:0] max_snd; // sound count: total number of sound samples
reg  [STW-1:0] st;
reg  [    3:0] next;
reg  [MTW-1:0] mute_cnt;
reg  [    8:0] data_cnt;
reg  [    3:0] rep_cnt;
reg  [   15:0] addr_latch;
reg  [   16:0] rep_latch;
reg  [    7:0] sign[0:3];
reg            last_wr, getdiv, headerok;
reg            signok; // ROM signature ok
wire           write, wr_posedge;
wire [   16:0] next_rom;
wire [    1:0] sign_addr = rom_addr[1:0]-2'd1;
reg            pre_cs, pulse_cs;

assign      write      = cs && (!mdn || !stn );
assign      wr_posedge = !last_wr && write;
assign      busyn      = st == IDLE || st == RST;
assign      next_rom   = rom_addr+1'b1;
assign      rom_cs     = pre_cs & ~pulse_cs;

initial begin
    sign[0] = 8'h5a;
    sign[1] = 8'ha5;
    sign[2] = 8'h69;
    sign[3] = 8'h55;
end

// Simulation log
`ifdef SIMULATION
`define JT7759_SILENCE   $display("\tjt7759: silence");
`define JT7759_PLAY      $display("\tjt7759: play");
`define JT7759_PLAY_LONG $display("\tjt7759: play n");
`define JT7759_REPEAT    $display("\tjt7759: repeat");
`define JT7759_DONE      $display("\tjt7759: sample done");
`else
`define JT7759_SILENCE
`define JT7759_PLAY
`define JT7759_PLAY_LONG
`define JT7759_REPEAT
`define JT7759_DONE
`endif


always @(posedge clk, posedge rst) begin
    if( rst ) begin
        max_snd   <= 8'd0;
        st        <= RST;
        pre_cs    <= 0;
        rom_addr  <= 17'd0;
        divby     <= 6'h10; // ~8kHz
        last_wr   <= 0;
        dec_rst   <= 1;
        dec_din   <= 4'd0;
        mute_cnt  <= 0;
        data_cnt  <= 9'd0;
        signok    <= 0;
        rep_cnt   <= ~4'd0;
        rep_latch <= 17'd0;
        headerok  <= 0;
        addr_latch<= 0;
        pulse_cs  <= 0;
        flush     <= 0;
    end else begin
        last_wr <= write;
        flush   <= 0;
        if( pulse_cs ) begin
            /*if(cen_ctl)*/ pulse_cs <= 0;
        end else begin
            case( st )
                default: if(cen_ctl) begin // start up process
                    if( mdn ) begin
                        rom_addr <= 17'd0;
                        pre_cs   <= 0;
                        dec_rst  <= 1;
                        //pre_cs   <= 1;
                        //st       <= SND_CNT; // Reads the ROM header
                        st       <= IDLE;
                    end
                    else st <= IDLE;
                end
                // Check the chip signature
                SIGN: if (cen_ctl) begin
                    if( !mdn ) begin
                        st <= READADR;
                        rom_addr[0] <= ~rom_addr[0];
                    end else begin
                        if( rom_ok ) begin
                            if( rom_data != sign[sign_addr] ) begin
                                signok <= 0;
                                st <= IDLE;
                                `ifdef SIMULATION
                                $display("Wrong ROM assigned to jt7759");
                                $finish;
                                `endif
                            end
                            else begin
                                if( &sign_addr ) begin
                                    signok <= 1;
                                    st<=IDLE;
                                end
                                rom_addr<= next_rom;
                            end
                        end
                    end
                end
                IDLE: begin
                    flush <= 1;
                    if( wr_posedge && drqn ) begin
                        //if( din <= max_snd || !mdn ) begin
                            pre_cs   <= 1;
                            pulse_cs <= 1;
                            rom_addr <= { 7'd0, {1'd0, din} + 9'd2, 1'b1 };
                            st       <= READADR;
                        //end
                    end else begin
                        pre_cs  <= 0;
                        dec_rst <= 1;
                    end
                end
                SND_CNT: begin
                    if( rom_ok ) begin
                        max_snd <= rom_data;
                        rom_addr<= next_rom;
                        st      <= SIGN;
                    end
                end
                READADR: if(cen_ctl) begin
                    if( rom_ok ) begin
                        if( rom_addr[0] ) begin
                            rom_addr <= next_rom;
                            pulse_cs <= 1;
                            addr_latch[ 7:0] <= rom_data;
                        end else begin
                            addr_latch[15:8] <= addr_latch[7:0];
                            addr_latch[ 7:0] <= rom_data;
                            st               <= LOAD;
                            pre_cs           <= 0;
                        end
                    end
                end
                LOAD: if(cen_ctl) begin
                    rom_addr <= { addr_latch, 1'b1 };
                    headerok <= 0;
                    st       <= READCMD;
                    pre_cs   <= 1;
                    pulse_cs <= 1;
                    rep_cnt  <= ~4'd0;
                    if ( mdn ) flush <= 1;
                end
                READCMD: if(cen_ctl) begin
                    if( rom_ok ) begin
                        rom_addr <= next_rom;
                        pre_cs   <= 1;
                        pulse_cs <= 1;
                        if( ~&rep_cnt ) begin
                            rep_cnt  <= rep_cnt-1'd1;
                        end

                        if(rom_data!=0)
                            headerok <= 1;
                        case( rom_data[7:6] )
                            2'd0: begin // Silence
                                `JT7759_SILENCE
                                mute_cnt <= {rom_data[5:0],7'd0};
                                if( rom_data==0 && headerok) begin
                                    st <= IDLE;
                                    dec_rst <= 1;
                                    `JT7759_DONE
                                end else begin
                                    st <= MUTED;
                                end
                                pre_cs  <= 0;
                            end
                            2'd1: begin // 256 nibbles
                                data_cnt  <= 9'hff;
                                divby     <= rom_data[5:0];
                                st        <= PLAY;
                                `JT7759_PLAY
                            end
                            2'd2: begin // n nibbles
                                data_cnt[8] <= 0;
                                divby       <= rom_data[5:0];
                                st          <= GETN;
                                `JT7759_PLAY_LONG
                            end
                            2'd3: begin // repeat loop
                                rep_cnt   <= {1'b0, rom_data[2:0]};
                                rep_latch <= next_rom;
                                `JT7759_REPEAT
                            end
                        endcase
                    end
                end
                GETN: begin
                    if( rom_ok ) begin
                        rom_addr <= next_rom;
                        pre_cs   <= 1;
                        pulse_cs <= 1;
                        data_cnt <= {1'b0, rom_data};
                        st       <= PLAY;
                    end
                end
                MUTED: if( cen_ctl ) begin
                    if(cen_dec) dec_rst<= 1;
                    if( mute_cnt != 0 ) begin
                        mute_cnt <= mute_cnt-1'd1;
                    end else begin
                        st     <= READCMD;
                        pre_cs <= 1;
                        pulse_cs <= 1;
                    end
                end
                PLAY: begin
                    if(cen_dec) begin
                        if( pre_cs ) begin
                            if( rom_ok ) begin
                                { dec_din, next } <= rom_data;
                                dec_rst           <= 0;
                                pre_cs            <= 0;
                                data_cnt          <= data_cnt-1'd1;
                                if( data_cnt==0 ) begin
                                    pre_cs   <= 1;
                                    pulse_cs <= 1;
                                    st       <= READCMD;
                                end
                            end
                        end else begin
                            dec_din  <= next;
                            rom_addr <= next_rom;
                            pre_cs   <= 1;
                            pulse_cs <= 1;
                            data_cnt <= data_cnt-1'd1;
                            if( data_cnt==0 ) begin
                                st <= READCMD;
                            end
                        end
                    end
                end
            endcase
        end // pulse_cen
    end
end


endmodule