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
    Date: 21-7-2021 */

module jt7759_data(
    input             rst,
    input             clk,
    input             cen_ctl,
    input             cen_dec,
    input             mdn,
    // Control interface
    input             ctrl_flush,
    input             ctrl_cs,
    input             ctrl_busyn,
    input      [16:0] ctrl_addr,
    output reg [ 7:0] ctrl_din,
    output reg        ctrl_ok,
    // ROM interface
    output            rom_cs,
    output reg [16:0] rom_addr,
    input      [ 7:0] rom_data,
    input             rom_ok,
    // Passive interface
    input             cs,
    input             wrn,  // for slave mode only
    input      [ 7:0] din,
    output reg        drqn
);

reg  [7:0] fifo[4];
reg  [3:0] fifo_ok;
reg        drqn_l, ctrl_cs_l;
reg  [1:0] rd_addr, wr_addr;
reg        readin, readout, readin_l, good_l;
reg  [4:0] drqn_cnt;

wire       good    = mdn ? rom_ok & ~drqn_l & ~drqn : (cs&~wrn);
wire [7:0] din_mux = mdn ? rom_data : din;

assign rom_cs  = mdn && !drqn;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        drqn_cnt <= 0;
    end else begin
        // Minimum time between DRQn pulses
        if( readin || good )
            drqn_cnt <= ~0;
        else if( drqn_cnt!=0 && cen_ctl) drqn_cnt <= drqn_cnt-1'd1;
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rom_addr <= 0;
        drqn     <= 1;
        readin_l <= 0;
        good_l   <= 0;
    end else begin
        readin_l <= readin;
        good_l   <= good;

        if( !ctrl_busyn ) begin
            if(!readin && readin_l)
                rom_addr <= rom_addr + 1;
            if(fifo_ok==4'hf || (!readin && readin_l) ) begin
                drqn <= 1;
            end else if(fifo_ok!=4'hf && !readin && drqn_cnt==0 ) begin
                drqn <= 0;
            end
        end else begin
            drqn <= 1;
        end

        if( ctrl_flush )
            rom_addr <= ctrl_addr;
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rd_addr   <= 0;
        ctrl_cs_l <= 0;
        readin    <= 0;
        readout   <= 0;
        ctrl_ok   <= 0;
        fifo_ok   <= 0;
        wr_addr   <= 0;
        drqn_l    <= 1;
    end else begin
        ctrl_cs_l <= ctrl_cs;
        drqn_l <= drqn;

        // read out
        if( ctrl_cs && !ctrl_cs_l ) begin
            readout <= 1;
            ctrl_ok <= 0;
        end
        if( readout && fifo_ok[rd_addr] ) begin
            ctrl_din <= fifo[ rd_addr ];
            ctrl_ok  <= 1;
            rd_addr  <= rd_addr + 1'd1;
            fifo_ok[ rd_addr ] <= 0;
            readout  <= 0;
        end
        if( !ctrl_cs ) begin
            readout <= 0;
            ctrl_ok <= 0;
        end

        // read in
        if( !drqn && drqn_l ) begin
            readin <= 1;
        end
        if( good && readin ) begin
            fifo[ wr_addr ] <= din_mux;
            fifo_ok[ wr_addr ] <= 1;
            wr_addr <= wr_addr + 1;
            readin  <= 0;
            `ifdef JT7759_FIFO_DUMP
            $display("\tjt7759: read %X",din_mux);
            `endif
        end

        if( ctrl_busyn || ctrl_flush ) begin
            fifo_ok <= 0;
            rd_addr <= 0;
            wr_addr <= 0;
        end
    end
end

endmodule