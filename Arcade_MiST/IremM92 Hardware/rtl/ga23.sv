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

module GA23(
    input clk,

    input ce,

    input paused,

    input reset,

    input io_wr,
    input [15:0] addr,
    input [15:0] cpu_din,

    output reg [14:0] vram_addr,
    output reg vram_req,
    input [31:0] vram_din,

    input NL,

    input large_tileset,

    input  [31:0] sdr_data_a,
    output [24:0] sdr_addr_a,
    output        sdr_req_a,
    input         sdr_ack_a,

    input  [31:0] sdr_data_b,
    output [24:0] sdr_addr_b,
    output        sdr_req_b,
    input         sdr_ack_b,

    input  [31:0] sdr_data_c,
    output [24:0] sdr_addr_c,
    output        sdr_req_c,
    input         sdr_ack_c,

    output vblank,
    output vsync,
    output hblank,
    output hsync,

    output hpulse,
    output vpulse,

    output hint,

    output reg [10:0] color_out,
    output reg prio_out,

    input [2:0] dbg_en_layers
);


//// VIDEO TIMING
reg [9:0] hcnt, vcnt;
reg [9:0] hint_line;

assign hsync = hcnt < 10'd65 || hcnt > 10'd448;
assign hblank = hcnt < 10'd104 || hcnt > 10'd422;
assign vblank = vcnt > 10'd113 && vcnt < 10'd136;
assign vsync = vcnt > 10'd119 && vcnt < 10'd125;
assign hpulse = hcnt == 10'd48;
assign vpulse = (vcnt == 10'd124 && hcnt > 10'd260) || (vcnt == 10'd125 && hcnt < 10'd260);

wire [9:0] VE = vcnt ^ {1'b0, {9{NL}}};

assign hint = VE == hint_line && hcnt > 10'd422 && ~paused;


always_ff @(posedge clk) begin
    if (ce) begin
        hcnt <= hcnt + 10'd1;
        if (hcnt == 10'd471) begin
            hcnt <= 10'd48;
            vcnt <= vcnt + 10'd1;
            if (vcnt == 10'd375) begin
                vcnt <= 10'd114;
            end
        end
    end
end

wire [21:0] rom_addr[3];
wire [31:0] rom_data[3];
wire        rom_req[3];
wire        rom_ack[3];

//// MEMORY ACCESS
reg [2:0] mem_cyc;
reg [3:0] rs_cyc;

reg [9:0] x_ofs[3], y_ofs[3];
reg [7:0] control[3];
reg [9:0] rowscroll[3];

wire [14:0] layer_vram_addr[3];
reg layer_load[3];
wire layer_prio[3];
wire [10:0] layer_color[3];
reg [15:0] vram_latch;

reg [37:0] control_save_0[512];
reg [37:0] control_save_1[512];
reg [37:0] control_save_2[512];

reg [37:0] control_restore[3];

reg rowscroll_active, rowscroll_pending;

always_ff @(posedge clk, posedge reset) begin
    bit [9:0] rs_y;
    if (reset) begin
        mem_cyc <= 0;

        // layer regs
        x_ofs[0] <= 10'd0; x_ofs[1] <= 10'd0; x_ofs[2] <= 10'd0;
        y_ofs[0] <= 10'd0; y_ofs[1] <= 10'd0; y_ofs[2] <= 10'd0;
        control[0] <= 8'd0; control[1] <= 8'd0; control[2] <= 8'd0;
        hint_line <= 10'd0;

        rowscroll_pending <= 0;
        rowscroll_active <= 0;

    end else begin

        if (ce) begin
            layer_load[0] <= 0; layer_load[1] <= 0; layer_load[2] <= 0;
            mem_cyc <= mem_cyc + 3'd1;

            if (hpulse) begin
                mem_cyc <= 3'd7;
                rowscroll_pending <= 1;
            end

            if (rowscroll_active) begin
                rs_cyc <= rs_cyc + 4'd1;
                case(rs_cyc)
                0: vram_addr <= 'h7800;
                4: begin
                    rs_y = y_ofs[0] + VE;
                    vram_addr <= 'h7a00 + rs_y[8:0];
                    vram_req <= ~vram_req;
                end
                7: rowscroll[0] <= vram_din[9:0];
                8: begin
                    rs_y = y_ofs[1] + VE;
                    vram_addr <= 'h7c00 + rs_y[8:0];
                    vram_req <= ~vram_req;
                end
                10: rowscroll[1] <= vram_din[9:0];
                12: begin
                    rs_y = y_ofs[2] + VE;
                    vram_addr <= 'h7e00 + rs_y[8:0];
                    vram_req <= ~vram_req;
                end
                14: rowscroll[2] <= vram_din[9:0];
                15: rowscroll_active <= 0;
                endcase

            end else begin

                case(mem_cyc)
                3'd0: begin
                    vram_addr <= layer_vram_addr[0];
                    vram_req <= ~vram_req;
                end
                3'd1: begin
                    layer_load[0] <= 1; // would be better a bit later
                end
                3'd2: begin
                    vram_addr <= layer_vram_addr[1];
                    vram_req <= ~vram_req;
                end
                3'd4: begin
                    layer_load[1] <= 1;
                end
                3'd5: begin
                    vram_addr <= layer_vram_addr[2];
                    vram_req <= ~vram_req;
                end
                3'd7: begin
                    layer_load[2] <= 1;

                    if (rowscroll_pending) begin
                        rowscroll_pending <= 0;
                        rowscroll_active <= 1;
                        rs_cyc <= 4'd0;
                    end
                end
                endcase
            end

            prio_out <= layer_prio[0] | layer_prio[1] | layer_prio[2];
            if (|layer_color[0][3:0]) begin
                color_out <= layer_color[0];
            end else if (|layer_color[1][3:0]) begin
                color_out <= layer_color[1];
            end else begin
                color_out <= layer_color[2];
            end
        end

        if (io_wr) begin
            case(addr[7:0])
            'h80: y_ofs[0][7:0] <= cpu_din[7:0];
            'h81: y_ofs[0][9:8] <= cpu_din[1:0];
            'h84: x_ofs[0][7:0] <= cpu_din[7:0];
            'h85: x_ofs[0][9:8] <= cpu_din[1:0];

            'h88: y_ofs[1][7:0] <= cpu_din[7:0];
            'h89: y_ofs[1][9:8] <= cpu_din[1:0];
            'h8c: x_ofs[1][7:0] <= cpu_din[7:0];
            'h8d: x_ofs[1][9:8] <= cpu_din[1:0];

            'h90: y_ofs[2][7:0] <= cpu_din[7:0];
            'h91: y_ofs[2][9:8] <= cpu_din[1:0];
            'h94: x_ofs[2][7:0] <= cpu_din[7:0];
            'h95: x_ofs[2][9:8] <= cpu_din[1:0];

            'h98: control[0] <= cpu_din[7:0];
            'h9a: control[1] <= cpu_din[7:0];
            'h9c: control[2] <= cpu_din[7:0];

            'h9e: hint_line[7:0] <= cpu_din[7:0];
            'h9f: hint_line[9:8] <= cpu_din[1:0];
            endcase
        end
`ifdef CTRL_SAVE
        if (hcnt == 10'd104 && ~paused) begin // end of hblank
            control_save_0[vcnt] <= { y_ofs[0], x_ofs[0], control[0], rowscroll[0] };
            control_save_1[vcnt] <= { y_ofs[1], x_ofs[1], control[1], rowscroll[1] };
            control_save_2[vcnt] <= { y_ofs[2], x_ofs[2], control[2], rowscroll[2] };
        end else if (paused) begin
            control_restore[0] <= control_save_0[vcnt];
            control_restore[1] <= control_save_1[vcnt];
            control_restore[2] <= control_save_2[vcnt];
        end
`endif
    end
end


assign rom_data[0] = sdr_data_a;
assign sdr_addr_a = REGION_TILE.base_addr[24:0] | rom_addr[0];
assign sdr_req_a = rom_req[0];
assign rom_ack[0] = sdr_ack_a;

assign rom_data[1] = sdr_data_b;
assign sdr_addr_b = REGION_TILE.base_addr[24:0] | rom_addr[1];
assign sdr_req_b = rom_req[1];
assign rom_ack[1] = sdr_ack_b;

assign rom_data[2] = sdr_data_c;
assign sdr_addr_c = REGION_TILE.base_addr[24:0] | rom_addr[2];
assign sdr_req_c = rom_req[2];
assign rom_ack[2] = sdr_ack_c;

//// LAYERS
generate
    genvar i;
    for(i = 0; i < 3; i = i + 1 ) begin : generate_layer
        wire [9:0] _y_ofs = paused ? control_restore[i][37:28] : y_ofs[i];
        wire [9:0] _x_ofs = paused ? control_restore[i][27:18] : x_ofs[i];
        wire [7:0] _control = paused ? control_restore[i][17:10] : control[i];
        wire [9:0] _rowscroll = paused ? control_restore[i][9:0] : rowscroll[i];

        ga23_layer layer(
            .clk(clk),
            .ce_pix(ce),

            .NL(NL),
            .large_tileset(large_tileset),

            .x_ofs(_x_ofs),
            .y_ofs(_y_ofs),
            .control(_control),

            .x_base({hcnt[9:3] ^ {7{NL}}, 3'd0}),
            .y(_y_ofs + VE),
            .rowscroll(_rowscroll),

            .vram_addr(layer_vram_addr[i]),

            .load(layer_load[i]),
            .attrib(vram_din[31:16]),
            .index(vram_din[15:0]),

            .color_out(layer_color[i]),
            .prio_out(layer_prio[i]),

            .sdr_addr(rom_addr[i]),
            .sdr_data(rom_data[i]),
            .sdr_req(rom_req[i]),
            .sdr_ack(rom_ack[i]),

            .dbg_enabled(dbg_en_layers[i])
        );
    end
endgenerate
endmodule
