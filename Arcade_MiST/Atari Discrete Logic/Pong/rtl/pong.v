/*
  MIT License

  Copyright (c) 2019 Richard Eng

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

/*
  Arcade: Atari Pong (1972)
  A Verilog implementation based on the original schematics.

  Written by: Richard Eng
*/
`default_nettype none

module pong(
    input wire mclk,
    input wire clk7_159, coin_sw,
    input wire [7:0] dip_sw, // dip_sw[0] - 0: 11 points, 1: 15 points
    input wire [7:0] paddle1_vpos,
    input wire [7:0] paddle2_vpos,
    /* verilator lint_off UNOPTFLAT */    
    output wire net, _hsync, _vsync, sync_2_2k, pads_net_1k, score_1_2k, sound_out, hsync, vsync, hblank, vblank,
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
    /* verilator lint_on UNOPTFLAT */
);

// hcounter
/* verilator lint_off UNUSED */  
wire h1, h2, h4, h8, h16, h32, h64, h128, h256, _h256, hreset, _hreset;
  /* verilator lint_on UNUSED */  
//wire [8:0] hcnt;
//assign hcnt = { h256, h128, h64, h32, h16, h8, h4, h2, h1 };
hcounter hc(clk7_159, h1, h2, h4, h8, h16, h32, h64, h128, h256, _h256, hreset, _hreset);

// hsync
wire _hblank;
hsync hs(mclk, clk7_159, _hreset, h16, h32, h64, hblank, _hblank, _hsync);
assign hsync = ~_hsync;

// vcounter
/* verilator lint_off UNUSED */  
wire v1, v2, v4, v8, v16, v32, v64, v128, v256, _v256, vreset, _vreset;
/* verilator lint_on UNUSED */  
//wire [8:0] vcnt;
//assign vcnt = { v256, v128, v64, v32, v16, v8, v4, v2, v1 };
vcounter vc(hreset, v1, v2, v4, v8, v16, v32, v64, v128, v256, _v256, vreset, _vreset);

// vsync
/* verilator lint_off UNOPTFLAT */
wire _vblank;
/* verilator lint_on UNOPTFLAT */
vsync vs(mclk, vreset, v4, v8, v16, vblank, _vblank, _vsync);
assign vsync = ~_vsync;

// net
net n(clk7_159, vblank, v4, h256, _h256, net);

// sound
wire sc, hit_sound;
sound snd(clk7_159, _miss, v32, vball16, _hit, vball240, _serve, _vvid, vblank, vvid, vball32, _attract, sc, hit_sound, sound_out);

// video
wire hit, _hit, _hit1, _hit2;
video v(score, _hsync, _vsync, pad1, pad2, net, _hvid, _vvid, score_1_2k, sync_2_2k, pads_net_1k, _hit, _hit2, hit, _hit1);
assign r = hblank ? 4'h0 : vblank ? 4'h0 : pads_net_1k ? 4'hf : score_1_2k ? 4'hb : 4'h0;
assign g = r;
assign b = r; 

// score board
wire _miss, stop_g, score;
score s(dip_sw, _hvid, hblank, _attract, left, right, srst, _srst, h4, h8, h16, h32, h64, h128, h256, v4, v8, v16, v32, v64, v128, _miss, stop_g, score);

// ball horizontal
wire left, right, _hvid;
ball_horizontal bal_hor(_h256, vreset, rst_speed, hit_sound, _hit2, sc, attract, _hit1, _hblank, clk7_159, _attract, serve, left, right, _hvid);

// ball vertical
wire vball16, vball32, vball240, _vvid, vvid;
ball_vertical bal_ver(_hsync, _vblank, vblank, _hit, d1, _h256, d2, h256, c1, c2, b2, b1, attract, hit, vball16, vball32, vball240, _vvid, vvid);

// game control
wire _srst, srst, rst_speed, attract, _attract, serve, _serve;
game_control game_control(clk7_159, _miss, stop_g, pad1, coin_sw, _srst, srst, rst_speed, attract, _attract, serve, _serve);

// paddles
wire pad1, b1, c1, d1;
wire pad2, b2, c2, d2;
paddles paddles(paddle1_vpos, paddle2_vpos, _hsync, _v256, _attract, h4, h128, h256, _h256, b1, c1, d1, pad1, b2, c2, d2, pad2);

endmodule
