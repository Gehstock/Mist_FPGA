////============================================================================
////
////  This program is free software; you can redistribute it and/or modify it
////  under the terms of the GNU General Public License as published by the Free
////  Software Foundation; either version 2 of the License, or (at your option)
////  any later version.
////
////  This program is distributed in the hope that it will be useful, but WITHOUT
////  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
////  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
////  more details.
////
////  You should have received a copy of the GNU General Public License along
////  with this program; if not, write to the Free Software Foundation, Inc.,
////  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
////
////============================================================================
//
//`default_nettype none
//
//module emu
//(
//    //Master input clock
//    input         CLK_50M,
//
//    //Async reset from top-level module.
//    //Can be used as initial reset.
//    input         RESET,
//
//    //Must be passed to hps_io module
//    inout  [48:0] HPS_BUS,
//
//    //Base video clock. Usually equals to CLK_SYS.
//    output        CLK_VIDEO,
//
//    //Multiple resolutions are supported using different CE_PIXEL rates.
//    //Must be based on CLK_VIDEO
//    output        CE_PIXEL,
//
//    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
//    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
//    output [12:0] VIDEO_ARX,
//    output [12:0] VIDEO_ARY,
//
//    output  [7:0] VGA_R,
//    output  [7:0] VGA_G,
//    output  [7:0] VGA_B,
//    output        VGA_HS,
//    output        VGA_VS,
//    output        VGA_DE,     // = ~(VBlank | HBlank)
//    output        VGA_F1,
//    output [2:0]  VGA_SL,
//    output        VGA_SCALER, // Force VGA scaler
//
//    input  [11:0] HDMI_WIDTH,
//    input  [11:0] HDMI_HEIGHT,
//    output        HDMI_FREEZE,
//
//`ifdef MISTER_FB
//    // Use framebuffer in DDRAM (USE_FB=1 in qsf)
//    // FB_FORMAT:
//    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
//    //    [3]   : 0=16bits 565 1=16bits 1555
//    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
//    //
//    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
//    output        FB_EN,
//    output  [4:0] FB_FORMAT,
//    output [11:0] FB_WIDTH,
//    output [11:0] FB_HEIGHT,
//    output [31:0] FB_BASE,
//    output [13:0] FB_STRIDE,
//    input         FB_VBL,
//    input         FB_LL,
//    output        FB_FORCE_BLANK,
//
//`ifdef MISTER_FB_PALETTE
//    // Palette control for 8bit modes.
//    // Ignored for other video modes.
//    output        FB_PAL_CLK,
//    output  [7:0] FB_PAL_ADDR,
//    output [23:0] FB_PAL_DOUT,
//    input  [23:0] FB_PAL_DIN,
//    output        FB_PAL_WR,
//`endif
//`endif
//
//    output        LED_USER,  // 1 - ON, 0 - OFF.
//
//    // b[1]: 0 - LED status is system status OR'd with b[0]
//    //       1 - LED status is controled solely by b[0]
//    // hint: supply 2'b00 to let the system control the LED.
//    output  [1:0] LED_POWER,
//    output  [1:0] LED_DISK,
//
//    // I/O board button press simulation (active high)
//    // b[1]: user button
//    // b[0]: osd button
//    output  [1:0] BUTTONS,
//
//    //Audio
//    input         CLK_AUDIO, // 24.576 MHz
//    output [15:0] AUDIO_L,
//    output [15:0] AUDIO_R,
//    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
//    output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
//
//    //ADC
//    inout   [3:0] ADC_BUS,
//
//    //SD-SPI
//    output        SD_SCK,
//    output        SD_MOSI,
//    input         SD_MISO,
//    output        SD_CS,
//    input         SD_CD,
//
//    //High latency DDR3 RAM interface
//    //Use for non-critical time purposes
//    output        DDRAM_CLK,
//    input         DDRAM_BUSY,
//    output  [7:0] DDRAM_BURSTCNT,
//    output [28:0] DDRAM_ADDR,
//    input  [63:0] DDRAM_DOUT,
//    input         DDRAM_DOUT_READY,
//    output        DDRAM_RD,
//    output [63:0] DDRAM_DIN,
//    output  [7:0] DDRAM_BE,
//    output        DDRAM_WE,
//
//    //SDRAM interface with lower latency
//    output        SDRAM_CLK,
//    output        SDRAM_CKE,
//    output [12:0] SDRAM_A,
//    output  [1:0] SDRAM_BA,
//    inout  [15:0] SDRAM_DQ,
//    output        SDRAM_DQML,
//    output        SDRAM_DQMH,
//    output        SDRAM_nCS,
//    output        SDRAM_nCAS,
//    output        SDRAM_nRAS,
//    output        SDRAM_nWE,
//
//`ifdef MISTER_DUAL_SDRAM
//    //Secondary SDRAM
//    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
//    input         SDRAM2_EN,
//    output        SDRAM2_CLK,
//    output [12:0] SDRAM2_A,
//    output  [1:0] SDRAM2_BA,
//    inout  [15:0] SDRAM2_DQ,
//    output        SDRAM2_nCS,
//    output        SDRAM2_nCAS,
//    output        SDRAM2_nRAS,
//    output        SDRAM2_nWE,
//`endif
//
//    input         UART_CTS,
//    output        UART_RTS,
//    input         UART_RXD,
//    output        UART_TXD,
//    output        UART_DTR,
//    input         UART_DSR,
//
//`ifdef MISTER_ENABLE_YC
//    output [39:0] CHROMA_PHASE_INC,
//    output        YC_EN,
//    output        PALFLAG,
//`endif
//
//    // Open-drain User port.
//    // 0 - D+/RX
//    // 1 - D-/TX
//    // 2..6 - USR2..USR6
//    // Set USER_OUT to 1 to read from USER_IN.
//    input   [6:0] USER_IN,
//    output  [6:0] USER_OUT,
//
//    input         OSD_STATUS
//);
//
/////////// Default values for ports not used in this core /////////
//
//assign ADC_BUS  = 'Z;
//assign USER_OUT = 0;
//assign {UART_RTS, UART_TXD, UART_DTR} = 0;
//assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
////assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
////assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;
//assign VGA_F1 = 0;
//assign VGA_SCALER = 0;
//assign HDMI_FREEZE = 0;
//
//assign AUDIO_MIX = 0;
//assign LED_USER = ioctl_download & cpu_a[0] & & tms_addr & & tms_dout & & tms_rom_addr & & tms_rom_dout ;
//assign LED_DISK = 0;
//assign LED_POWER = 0;
//assign BUTTONS = 0;
//
//// Status Bit Map:
////              Upper Case                     Lower Case           
//// 0         1         2         3          4         5         6   
//// 01234567890123456789012345678901 23456789012345678901234567890123
//// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
//// X  XXXXXXXX    X   XXXX XXXXXXXX X     X    XX           XXXXXXXX
//
//wire [1:0] aspect_ratio = status[9:8];
//wire       orientation  = ~status[3];
//wire [2:0] scan_lines   = status[6:4];
//reg        refresh_mod;
//reg        new_vmode;
//
//always @(posedge clk_sys) begin
//    if (refresh_mod != status[19]) begin
//        refresh_mod <= status[19];
//        new_vmode <= ~new_vmode;
//    end
//end
//
//wire [3:0] hs_offset = status[27:24];
//wire [3:0] vs_offset = status[31:28];
//wire [3:0] hs_width  = status[59:56];
//wire [3:0] vs_width  = status[63:60];
//
//assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd4 : 8'd3) : (aspect_ratio - 1'd1);
//assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd3 : 8'd4) : 12'd0;
//
//`include "build_id.v" 
//localparam CONF_STR = {
//    "Toaplan V1;;",
//    "-;",
//    "P1,Video Settings;",
//    "P1-;",
//    "P1O89,Aspect Ratio,Original,Full Screen,[ARC1],[ARC2];",
//    "P1O3,Orientation,Horz,Vert;",
//    "P1-;",
//    "P1O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%,CRT 100%;",
//    "P1OA,Force Scandoubler,Off,On;",
//    "P1-;",
//    "P1O7,Video Mode,NTSC,PAL;",
//    "P1OM,Video Signal,RGBS/YPbPr,Y/C;",
//    "P1OJ,Refresh Rate,Native,NTSC;",
//    "P1-;",
//    "P1OOR,H-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
//    "P1OSV,V-sync Pos Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
//    "P1-;",
//    "P1oOR,H-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
//    "P1oSV,V-sync Width Adj,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
//    "P1-;",
//    "P2,Audio Settings;",
//    "P2-;",
//    "P2oBC,OPL2 Volume,Default,50%,25%,0%;",
//    "P2-;",
//    "-;",
//    "P3,Core Options;",
//    "P3-;",
//    "P3o6,Swap P1/P2 Joystick,Off,On;",
//    "P3-;",
//    "P3OF,68k Freq.,10Mhz,17.5MHz;",
//    "P3-;",
//    "P3o0,Scroll Debug,Off,On;",
//    "P3-;",
//    "DIP;",
//    "-;",
//    "OK,Pause OSD,Off,When Open;",
//    "OL,Dim Video,Off,10s;",
//    "-;",
//    "R0,Reset;",
//    "V,v",`BUILD_DATE
//};
//
//wire hps_forced_scandoubler;
//wire forced_scandoubler = hps_forced_scandoubler | status[10];
//
//wire  [1:0] buttons;
//wire [63:0] status;
//wire [10:0] ps2_key;
//wire [15:0] joy0, joy1;
//
//hps_io #(.CONF_STR(CONF_STR)) hps_io
//(
//    .clk_sys(clk_sys),
//    .HPS_BUS(HPS_BUS),
//
//    .buttons(buttons),
//    .ps2_key(ps2_key),
//    .status(status),
//    .status_menumask(direct_video),
//    .forced_scandoubler(hps_forced_scandoubler),
//    .gamma_bus(gamma_bus),
//    .new_vmode(new_vmode),
//    .direct_video(direct_video),
//    .video_rotated(video_rotated),
//
//    .ioctl_download(ioctl_download),
//    .ioctl_upload(ioctl_upload),
//    .ioctl_wr(ioctl_wr),
//    .ioctl_addr(ioctl_addr),
//    .ioctl_dout(ioctl_dout),
//    .ioctl_din(ioctl_din),
//    .ioctl_index(ioctl_index),
//    .ioctl_wait(ioctl_wait),
//
//    .joystick_0(joy0),
//    .joystick_1(joy1)
//);
//
//// INPUT
//
//// 8 dip switches of 8 bits
//reg [7:0] sw[8];
//always @(posedge clk_sys) begin
//    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
//        sw[ioctl_addr[2:0]] <= ioctl_dout;
//    end
//end
//
//wire        direct_video;
//
//wire        ioctl_download;
//wire        ioctl_upload;
//wire        ioctl_upload_req;
//wire        ioctl_wait;
//wire        ioctl_wr;
//wire [15:0] ioctl_index;
//wire [26:0] ioctl_addr;
//wire [15:0] ioctl_dout;
//wire [15:0] ioctl_din;
//
//wire        tile_priority_type;
//wire [15:0] scroll_y_offset;
//
//wire [21:0] gamma_bus;
//
////<buttons names="Fire,Jump,Start,Coin,Pause" default="A,B,R,L,Start" />
//// Inputs tied to z80_din
//reg [7:0] p1;
//reg [7:0] p2;
//reg [7:0] z80_dswa;
//reg [7:0] z80_dswb;
//reg [7:0] z80_tjump;
//reg [7:0] system;
//
//always @ (posedge clk_sys ) begin
//    p1        <= { 1'b0, p1_buttons[2:0], p1_right, p1_left, p1_down, p1_up };
//    p2        <= { 1'b0, p2_buttons[2:0], p2_right, p2_left, p2_down, p2_up };
//    z80_dswa  <= sw[0];
//    z80_dswb  <= sw[1];
//    z80_tjump <= sw[2];
//
//    if ( status[32] == 1 ) begin
//        system    <= { vbl, start2 | p1_buttons[3], start1 | p1_buttons[3], coin_b, coin_a, service | status[32], key_tilt, key_service };
//    end else begin
//        system    <= { vbl, start2,                 start1,                 coin_b, coin_a, service,              key_tilt, key_service };
//    end
//end
//
//reg        p1_swap;
//
//reg        p1_right;
//reg        p1_left;
//reg        p1_down;
//reg        p1_up;
//reg [3:0]  p1_buttons;
//
//reg        p2_right;
//reg        p2_left;
//reg        p2_down;
//reg        p2_up;
//reg [3:0]  p2_buttons;
//
//reg start1;
//reg start2;
//reg coin_a;
//reg coin_b;
//reg b_pause;
//reg service;
//
//always @ * begin
//    p1_swap <= status[38];
//
//        if ( status[38] == 0 ) begin
//        p1_right   <= joy0[0]   | key_p1_right;
//        p1_left    <= joy0[1]   | key_p1_left;
//        p1_down    <= joy0[2]   | key_p1_down;
//        p1_up      <= joy0[3]   | key_p1_up;
//        p1_buttons <= joy0[7:4] | {key_p1_c, key_p1_b, key_p1_a};
//
//        p2_right   <= joy1[0]   | key_p2_right;
//        p2_left    <= joy1[1]   | key_p2_left;
//        p2_down    <= joy1[2]   | key_p2_down;
//        p2_up      <= joy1[3]   | key_p2_up;
//        p2_buttons <= joy1[7:4] | {key_p2_c, key_p2_b, key_p2_a};
//    end else begin
//        p2_right   <= joy0[0]   | key_p1_right;
//        p2_left    <= joy0[1]   | key_p1_left;
//        p2_down    <= joy0[2]   | key_p1_down;
//        p2_up      <= joy0[3]   | key_p1_up;
//        p2_buttons <= joy0[7:4] | {key_p1_c, key_p1_b, key_p1_a};
//
//        p1_right   <= joy1[0]   | key_p2_right;
//        p1_left    <= joy1[1]   | key_p2_left;
//        p1_down    <= joy1[2]   | key_p2_down;
//        p1_up      <= joy1[3]   | key_p2_up;
//        p1_buttons <= joy1[7:4] | {key_p2_c, key_p2_b, key_p2_a};
//    end
//end
//
//always @ * begin
//        start1    <= joy0[8]  | joy1[8]  | key_start_1p;
//        start2    <= joy0[9]  | joy1[9]  | key_start_2p;
//
//        coin_a    <= joy0[10] | joy1[10] | key_coin_a;
//        coin_b    <= joy0[11] | joy1[11] | key_coin_b;
//
//        b_pause   <= joy0[12] | key_pause;
//        service   <= key_test;
//end
//
//// Keyboard handler
//
//reg key_start_1p, key_start_2p, key_coin_a, key_coin_b;
//reg key_tilt, key_test, key_reset, key_service, key_pause;
//
//reg key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_a, key_p1_b, key_p1_c;
//reg key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_a, key_p2_b, key_p2_c;
//
//wire pressed = ps2_key[9];
//
//always @(posedge clk_sys) begin
//    reg old_state;
//    old_state <= ps2_key[10];
//    if ( old_state ^ ps2_key[10] ) begin
//        casex ( ps2_key[8:0] )
//            'h016 :  key_start_1p   <= pressed;            // 1
//            'h01E :  key_start_2p   <= pressed;            // 2
//            'h02E :  key_coin_a     <= pressed;            // 5
//            'h036 :  key_coin_b     <= pressed;            // 6
//            'h006 :  key_test       <= key_test ^ pressed; // f2
//            'h004 :  key_reset      <= pressed;            // f3
//            'h046 :  key_service    <= pressed;            // 9
//            'h02C :  key_tilt       <= pressed;            // t
//            'h04D :  key_pause      <= pressed;            // p
//
//            'h175 :  key_p1_up      <= pressed;            // up
//            'h172 :  key_p1_down    <= pressed;            // down
//            'h16B :  key_p1_left    <= pressed;            // left
//            'h174 :  key_p1_right   <= pressed;            // right
//            'h014 :  key_p1_a       <= pressed;            // lctrl
//            'h011 :  key_p1_b       <= pressed;            // lalt
//            'h029 :  key_p1_c       <= pressed;            // spacebar
//
//            'h02D :  key_p2_up      <= pressed;            // r
//            'h02B :  key_p2_down    <= pressed;            // f
//            'h023 :  key_p2_left    <= pressed;            // d
//            'h034 :  key_p2_right   <= pressed;            // g
//            'h01C :  key_p2_a       <= pressed;            // a
//            'h01B :  key_p2_b       <= pressed;            // s
//            'h015 :  key_p2_c       <= pressed;            // q
//        endcase
//    end
//end
//
//
//
//
//
//
//
//endmodule





