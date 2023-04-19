//============================================================================
//  Copyright (C) 2023 Martin Donlon
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module ga20_channel(
    input clk,
    input reset,

    input ce,
    
    input cs,
    input rd,
    input wr,
    input [2:0] addr,
    input [7:0] din,
    output reg [7:0] dout,

    output [19:0] sample_addr,
    output reg sample_req,
    input sample_ack,
    input [63:0] sample_din,

    output [15:0] sample_out
);

reg step;
reg [5:0] volume;
reg [7:0] rate;
reg [19:0] start_addr, end_addr, cur_addr;
reg [1:0] play;
reg [8:0] rate_cnt;

reg [7:0] sample_s8;

reg play_set;
wire [7:0] sample_data;

assign sample_addr = cur_addr;

always @(*) begin
    case(cur_addr[2:0])
        3'd0: sample_data = sample_din[ 7: 0];
        3'd1: sample_data = sample_din[15: 8];
        3'd2: sample_data = sample_din[23:16];
        3'd3: sample_data = sample_din[31:24];
        3'd4: sample_data = sample_din[39:32];
        3'd5: sample_data = sample_din[47:40];
        3'd6: sample_data = sample_din[55:48];
        default: sample_data = sample_din[63:56];
    endcase;
end
always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
        volume <= 6'd00;
        play <= 2'd0;
        step <= 0;
        play_set <= 0;
        sample_s8 <= 8'h00;
    end else begin
        if (cs & rd) begin
            if (addr == 3'd7) dout <= { 7'd0, play[1] };
        end else if (cs & wr) begin
            case (addr)
            3'd0: start_addr[11:0] <= { din, 4'b0000 };
            3'd1: start_addr[19:12] <= din;
            3'd2: end_addr[11:0] <= { din, 4'b0000 };
            3'd3: end_addr[19:12] <= din;
            3'd4: rate <= din;
            3'd5: volume <= din[5:0];
            3'd6: begin
                play <= din[1:0];
                play_set <= din[1];
            end
            endcase
        end

        if (ce && sample_req == sample_ack) begin
            step <= ~step;
            
            if (~step) begin
                // first cycle

                if (play_set) begin
                    cur_addr <= start_addr;
                    sample_req <= ~sample_req;
                    play_set <= 0;
                    rate_cnt <= rate + 9'd2;
                end else begin
                    rate_cnt <= rate_cnt + 9'd2;
                end
            end else begin
                // second cycle
                if (~play_set & play[1]) begin
                    if (sample_data == 8'd0) begin
                        play[1] <= 0;
                        sample_s8 <= 8'h00;
                    end else begin
                        sample_s8 <= { ~sample_data[7], sample_data[6:0] };

                        if (rate_cnt[8]) begin
                            cur_addr <= cur_addr + 20'd1;
                            if (cur_addr[2:0] == 3'b111) begin
                                sample_req <= ~sample_req;
                            end
                            rate_cnt <= rate_cnt + { 1'b1, rate };

                            if (cur_addr == end_addr) begin
                                if (play[0]) begin
                                    cur_addr <= start_addr;
                                    sample_req <= ~sample_req;
                                end else begin
                                    sample_s8 <= 8'h00;
                                    play[1] <= 0;
                                end
                            end
                        end
                    end
                end 
            end
        end
    end
end

// apply attenuation after filtering
always_ff @(posedge clk) begin
    bit [7:0] vol_one;

    vol_one = { 2'd0, volume } + 8'd1; 

    sample_out <= $signed(sample_s8) * $signed(vol_one);
end


endmodule


module ga20(
    input clk,
    input reset,
    input filter_en,

    input ce,

    input cs,
    input rd,
    input wr,
    input [4:0] addr,
    input [7:0] din,
    output [7:0] dout,


    output reg sample_rom_req,
    output reg [19:0] sample_rom_addr,
    input sample_rom_ack,
    input [63:0] sample_rom_din,

    output [15:0] sample_out
);

reg [2:0] step;

wire ce0 = step[2:1] == 2'd0;
wire ce1 = step[2:1] == 2'd1;
wire ce2 = step[2:1] == 2'd2;
wire ce3 = step[2:1] == 2'd3;

wire cs0 = cs && addr[4:3] == 2'd0;
wire cs1 = cs && addr[4:3] == 2'd1;
wire cs2 = cs && addr[4:3] == 2'd2;
wire cs3 = cs && addr[4:3] == 2'd3;

wire [7:0] dout0, dout1, dout2, dout3;

assign dout = cs0 ? dout0 : cs1 ? dout1 : cs2 ? dout2 : dout3;

wire [19:0] sample_addr[4];
wire [15:0] sample_out0, sample_out1, sample_out2, sample_out3;
wire  [3:0] sample_req;
reg   [3:0] sample_ack;
reg  [63:0] sample_data[4];
reg   [3:0] req_pending;

ga20_channel ch0( .clk(clk), .reset(reset), .ce(ce & ce0), .cs(cs0), .rd(rd), .wr(wr), .addr(addr[2:0]), .din(din), .dout(dout0), .sample_addr(sample_addr[0]), .sample_req(sample_req[0]), .sample_ack(sample_ack[0]), .sample_din(sample_data[0]), .sample_out(sample_out0));
ga20_channel ch1( .clk(clk), .reset(reset), .ce(ce & ce1), .cs(cs1), .rd(rd), .wr(wr), .addr(addr[2:0]), .din(din), .dout(dout1), .sample_addr(sample_addr[1]), .sample_req(sample_req[1]), .sample_ack(sample_ack[1]), .sample_din(sample_data[1]), .sample_out(sample_out1));
ga20_channel ch2( .clk(clk), .reset(reset), .ce(ce & ce2), .cs(cs2), .rd(rd), .wr(wr), .addr(addr[2:0]), .din(din), .dout(dout2), .sample_addr(sample_addr[2]), .sample_req(sample_req[2]), .sample_ack(sample_ack[2]), .sample_din(sample_data[2]), .sample_out(sample_out2));
ga20_channel ch3( .clk(clk), .reset(reset), .ce(ce & ce3), .cs(cs3), .rd(rd), .wr(wr), .addr(addr[2:0]), .din(din), .dout(dout3), .sample_addr(sample_addr[3]), .sample_req(sample_req[3]), .sample_ack(sample_ack[3]), .sample_din(sample_data[3]), .sample_out(sample_out3));

always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
        sample_data[0] <= 0;
        sample_data[1] <= 0;
        sample_data[2] <= 0;
        sample_data[3] <= 0;
        req_pending <= 0;
    end else begin
        if (req_pending[0]) begin
            if (sample_rom_req == sample_rom_ack) begin
                req_pending[0] <= 0;
                sample_ack[0] <= sample_req[0];
                sample_data[0] <= sample_rom_din;
            end
        end else if (req_pending[1]) begin
            if (sample_rom_req == sample_rom_ack) begin
                req_pending[1] <= 0;
                sample_ack[1] <= sample_req[1];
                sample_data[1] <= sample_rom_din;
            end
        end else if (req_pending[2]) begin
            if (sample_rom_req == sample_rom_ack) begin
                req_pending[2] <= 0;
                sample_ack[2] <= sample_req[2];
                sample_data[2] <= sample_rom_din;
            end
        end else if (req_pending[3]) begin
            if (sample_rom_req == sample_rom_ack) begin
                req_pending[3] <= 0;
                sample_ack[3] <= sample_req[3];
                sample_data[3] <= sample_rom_din;
            end
        end else if (sample_req[0] != sample_ack[0]) begin
            sample_rom_addr <= sample_addr[0];
            sample_rom_req <= ~sample_rom_req;
            req_pending[0] <= 1;
        end else if (sample_req[1] != sample_ack[1]) begin
            sample_rom_addr <= sample_addr[1];
            sample_rom_req <= ~sample_rom_req;
            req_pending[1] <= 1;
        end else if (sample_req[2] != sample_ack[2]) begin
            sample_rom_addr <= sample_addr[2];
            sample_rom_req <= ~sample_rom_req;
            req_pending[2] <= 1;
        end else if (sample_req[3] != sample_ack[3]) begin
            sample_rom_addr <= sample_addr[3];
            sample_rom_req <= ~sample_rom_req;
            req_pending[3] <= 1;
        end
    end
end

always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
        step <= 3'd0;
    end else begin
        reg prev_ce = 0;
        prev_ce <= ce;
        if (~ce & prev_ce) begin
            step <= step + 3'd1;
        end
    end
end

reg [15:0] sample_combined;

// 9685hz 2nd order 10749hz 1st order
localparam CX = 0.00000741947949554119;
localparam CY0 = -2.95726738834813529522;
localparam CY1 = 2.91526970775390958934;
localparam CY2 = -0.95799698165074131939;
reg [15:0] sample_filtered;

IIR_filter #(
    .use_params(1),
    .stereo(0),
    .coeff_x(CX),
    .coeff_x0(3),
    .coeff_x1(3),
    .coeff_x2(1),
    .coeff_y0(CY0),
    .coeff_y1(CY1),
    .coeff_y2(CY2)) lpf_sample (
	.clk(clk),
	.reset(reset),

	.ce(ce),
	.sample_ce(ce),

	.cx(), .cx0(), .cx1(), .cx2(), .cy0(), .cy1(), .cy2(),

	.input_l(sample_combined),
	.output_l(sample_filtered),

    .input_r(),
    .output_r()
);

always_ff @(posedge clk) begin
    sample_combined <= sample_out0 + sample_out1 + sample_out2 + sample_out3;
end

assign sample_out = filter_en ? sample_filtered : sample_combined;

endmodule
