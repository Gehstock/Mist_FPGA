`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:36:45 11/07/2015 
// Design Name: 
// Module Name:    keyboard
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module keyboard(
    input wire clk,
    input wire clkps2,
    input wire dataps2,
    input wire [7:0] rows,
    output wire [4:0] columns,
    output reg kbd_reset,
    output reg kbd_nmi,
    output reg kbd_mreset
    );

    initial begin
        kbd_reset = 1'b1;
        kbd_nmi = 1'b1;
        kbd_mreset = 1'b1;
    end

   // Teclas no extendidas
`define KEY_RELEASED 8'hf0
`define KEY_EXTENDED 8'he0
`define KEY_ESC 	8'h76
`define KEY_F1 		8'h05
`define KEY_F2 		8'h06
`define KEY_F3 		8'h04
`define KEY_F4 		8'h0C
`define KEY_F5 		8'h03
`define KEY_F6 		8'h0B
`define KEY_F7 		8'h83
`define KEY_F8 		8'h0A
`define KEY_F9 		8'h01
`define KEY_F10 	8'h09
`define KEY_F11 	8'h78
`define KEY_F12 	8'h07

`define KEY_BL 		8'h0E
`define KEY_1 		8'h16
`define KEY_2 		8'h1E
`define KEY_3 		8'h26
`define KEY_4 		8'h25
`define KEY_5 		8'h2E
`define KEY_6 		8'h36
`define KEY_7 		8'h3D
`define KEY_8 		8'h3E
`define KEY_9 		8'h46
`define KEY_0 		8'h45
`define KEY_APOS 	8'h4E
`define KEY_AEXC 	8'h55
`define KEY_BKSP 	8'h66

`define KEY_TAB 	8'h0D
`define KEY_Q 		8'h15
`define KEY_W 		8'h1D
`define KEY_E 		8'h24
`define KEY_R 		8'h2D
`define KEY_T 		8'h2C
`define KEY_Y 		8'h35
`define KEY_U 		8'h3C
`define KEY_I 		8'h43
`define KEY_O 		8'h44
`define KEY_P 		8'h4D
`define KEY_CORCHA 	8'h54
`define KEY_CORCHC 	8'h5B
`define KEY_ENTER 	8'h5A

`define KEY_CPSLK 	8'h58
`define KEY_A 		8'h1C
`define KEY_S 		8'h1B
`define KEY_D 		8'h23
`define KEY_F 		8'h2B
`define KEY_G 		8'h34
`define KEY_H 		8'h33
`define KEY_J 		8'h3B
`define KEY_K 		8'h42
`define KEY_L 		8'h4B
`define KEY_NT 		8'h4C
`define KEY_LLAVA 	8'h52
`define KEY_LLAVC 	8'h5D

`define KEY_LSHIFT	8'h12
`define KEY_LT 		8'h61
`define KEY_Z 		8'h1A
`define KEY_X 		8'h22
`define KEY_C 		8'h21
`define KEY_V 		8'h2A
`define KEY_B 		8'h32
`define KEY_N 		8'h31
`define KEY_M 		8'h3A
`define KEY_COMA 	8'h41
`define KEY_PUNTO 	8'h49
`define KEY_MENOS 	8'h4A
`define KEY_RSHIFT	8'h59

`define KEY_LCTRL 	8'h14
`define KEY_LALT 	8'h11
`define KEY_SPACE 	8'h29

`define KEY_KP0 	8'h70
`define KEY_KP1 	8'h69
`define KEY_KP2 	8'h72
`define KEY_KP3 	8'h7A
`define KEY_KP4 	8'h6B
`define KEY_KP5 	8'h73
`define KEY_KP6 	8'h74
`define KEY_KP7 	8'h6C
`define KEY_KP8 	8'h75
`define KEY_KP9 	8'h7D
`define KEY_KPPUNTO 8'h71
`define KEY_KPMAS 	8'h79
`define KEY_KPMENOS 8'h7B
`define KEY_KPASTER 8'h7C

`define KEY_BLKNUM	8'h77
`define KEY_BLKSCR 	8'h7E

// Teclas extendidas (E0 + scancode)
`define KEY_WAKEUP 	8'h5E
`define KEY_SLEEP 	8'h3F
`define KEY_POWER 	8'h37
`define KEY_INS 	8'h70
`define KEY_SUP 	8'h71
`define KEY_HOME 	8'h6C
`define KEY_END 	8'h69
`define KEY_PGU 	8'h7D
`define KEY_PGD 	8'h7A
`define KEY_UP 		8'h75
`define KEY_DOWN 	8'h72
`define KEY_LEFT 	8'h6B
`define KEY_RIGHT 	8'h74
`define KEY_RCTRL 	8'h14
`define KEY_ALTGR 	8'h11
`define KEY_KPENTER 8'h5A
`define KEY_KPSLASH 8'h4A
`define KEY_PRTSCR 	8'h7C


    wire new_key_aval;
    wire [7:0] scancode;
    wire is_released;
    wire is_extended;

    reg shift_pressed = 1'b0;
    reg ctrl_pressed = 1'b0;
    reg alt_pressed = 1'b0;

    ps2_port ps2_kbd (
        .clk(clk),  // se recomienda 1 MHz <= clk <= 600 MHz
        .enable_rcv(1'b1),  // habilitar la maquina de estados de recepcion
        .ps2clk_ext(clkps2),
        .ps2data_ext(dataps2),
        .kb_interrupt(new_key_aval),  // a 1 durante 1 clk para indicar nueva tecla recibida
        .scancode(scancode), // make o breakcode de la tecla
        .released(is_released),  // soltada=1, pulsada=0
        .extended(is_extended)  // extendida=1, no extendida=0
    );

    reg [4:0] matrix[0:7];  // 40-key matrix keyboard
    initial begin
        matrix[0] = 5'b11111;  // C X Z SS CS
        matrix[1] = 5'b11111;  // G F D S A
        matrix[2] = 5'b11111;  // T R E W Q
        matrix[3] = 5'b11111;  // 5 4 3 2 1
        matrix[4] = 5'b11111;  // 6 7 8 9 0
        matrix[5] = 5'b11111;  // Y U I O P
        matrix[6] = 5'b11111;  // H J K L ENT
        matrix[7] = 5'b11111;  // V B N M SP
    end

    assign columns = (matrix[0] | { {8{rows[0]}} }) &
                     (matrix[1] | { {8{rows[1]}} }) &
                     (matrix[2] | { {8{rows[2]}} }) &
                     (matrix[3] | { {8{rows[3]}} }) &
                     (matrix[4] | { {8{rows[4]}} }) &
                     (matrix[5] | { {8{rows[5]}} }) &
                     (matrix[6] | { {8{rows[6]}} }) &
                     (matrix[7] | { {8{rows[7]}} });

    always @(posedge clk) begin
        if (new_key_aval == 1'b1) begin
            case (scancode)
                // Special and control keys
                `KEY_LSHIFT,
                `KEY_RSHIFT:
                    shift_pressed <= ~is_released;
                `KEY_LCTRL,
                `KEY_RCTRL:
                    begin
                        ctrl_pressed <= ~is_released;
                        if (is_extended)
                            matrix[0][1] <= is_released;  // Right control = Symbol shift
                        else
                            matrix[0][0] <= is_released;  // Left control = Caps shift
                    end
                `KEY_LALT:
                    alt_pressed <= ~is_released;
                `KEY_KPPUNTO:
                    if (ctrl_pressed && alt_pressed) begin
                        kbd_reset <= is_released;
                        if (is_released == 1'b0) begin
                            matrix[0] <= 5'b11111;  // C X Z SS CS
                            matrix[1] <= 5'b11111;  // G F D S A
                            matrix[2] <= 5'b11111;  // T R E W Q
                            matrix[3] <= 5'b11111;  // 5 4 3 2 1
                            matrix[4] <= 5'b11111;  // 6 7 8 9 0
                            matrix[5] <= 5'b11111;  // Y U I O P
                            matrix[6] <= 5'b11111;  // H J K L ENT
                            matrix[7] <= 5'b11111;  // V B N M SP
                        end
                    end                            
                `KEY_F5:
                    if (ctrl_pressed && alt_pressed)
                        kbd_nmi <= is_released;
                `KEY_ENTER:
                    matrix[6][0] <= is_released;
                `KEY_ESC:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[7][0] <= is_released;
                    end
                `KEY_BKSP:
                    if (ctrl_pressed && alt_pressed) begin
                        kbd_mreset <= is_released;                        
                    end
                    else begin
                        matrix[0][0] <= is_released;
                        matrix[4][0] <= is_released;
                    end
                `KEY_CPSLK:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[3][1] <= is_released;  // CAPS LOCK
                    end
                `KEY_F2:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[3][0] <= is_released;  // EDIT
                    end
                        
                // Digits and puntuaction marks inside digits
                `KEY_1:
                    begin
                        if (alt_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[1][1] <= is_released;  // |
                        end
                        else if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[3][0] <= is_released;  // !
                        end
                        else
                            matrix[3][0] <= is_released;
                        
                    end
                `KEY_2:
                    begin
                        if (alt_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[3][1] <= is_released;  // @
                        end
                        else if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[5][0] <= is_released;  // "
                        end
                        else
                            matrix[3][1] <= is_released;
                    end
                `KEY_3:
                    begin
                        if (!shift_pressed)
                            matrix[3][2] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[3][2] <= is_released;  // #
                        end
                    end
                `KEY_4:
                    begin
                        if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[3][3] <= is_released;  // $
                        end
                        else if (ctrl_pressed) begin
                            matrix[0][0] <= is_released;
                            matrix[3][3] <= is_released; // INV VIDEO
                        end
                        else
                            matrix[3][3] <= is_released;                        
                    end
                `KEY_5:
                    begin
                        if (!shift_pressed)
                            matrix[3][4] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[3][4] <= is_released;  // %
                        end
                    end
                `KEY_6:
                    begin
                        if (!shift_pressed)
                            matrix[4][4] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[4][4] <= is_released;  // &
                        end
                    end
                `KEY_7:
                    begin
                        if (!shift_pressed)
                            matrix[4][3] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[7][4] <= is_released;  // /
                        end
                    end
                `KEY_8:
                    begin
                        if (!shift_pressed)
                            matrix[4][2] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[4][2] <= is_released;  // (
                        end
                    end
                `KEY_9:
                    begin
                        if (shift_pressed) begin
                            matrix[0][1] <= is_released;
                            matrix[4][1] <= is_released;  // )
                        end
                        else if (ctrl_pressed) begin
                            matrix[0][0] <= is_released;
                            matrix[4][1] <= is_released;
                        end
                        else
                            matrix[4][1] <= is_released;
                    end
                `KEY_0:
                    begin
                        if (!shift_pressed)
                            matrix[4][0] <= is_released;
                        else begin
                            matrix[0][1] <= is_released;
                            matrix[6][1] <= is_released;  // =
                        end
                    end
                    
                // Alphabetic characters
                `KEY_Z:
                    begin
                        matrix[0][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_X:
                    begin
                        matrix[0][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_C:
                    begin
                        matrix[0][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_A:
                    begin
                        matrix[1][0] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_S:
                    begin
                        matrix[1][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_D:
                    begin
                        matrix[1][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_F:
                    begin
                        matrix[1][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_G:
                    begin
                        matrix[1][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_Q:
                    begin
                        matrix[2][0] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_W:
                    begin
                        matrix[2][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_E:
                    begin
                        matrix[2][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_R:
                    begin
                        matrix[2][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_T:
                    begin
                        matrix[2][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_P:
                    begin
                        matrix[5][0] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_O:
                    begin
                        matrix[5][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_I:
                    begin
                        matrix[5][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_U:
                    begin
                        matrix[5][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_Y:
                    begin
                        matrix[5][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_L:
                    begin
                        matrix[6][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_K:
                    begin
                        matrix[6][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_J:
                    begin
                        matrix[6][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_H:
                    begin
                        matrix[6][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_M:
                    begin
                        matrix[7][1] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_N:
                    begin
                        matrix[7][2] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_B:
                    begin
                        matrix[7][3] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                `KEY_V:
                    begin
                        matrix[7][4] <= is_released;
                        if (shift_pressed)
                            matrix[0][0] <= is_released;
                    end
                    
                // Symbols
                `KEY_APOS:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[4][3] <= is_released;
                        else
                            matrix[0][4] <= is_released;  // ?
                    end
                `KEY_CORCHA:
                    begin
                        matrix[0][1] <= is_released;
                        if (alt_pressed || shift_pressed)
                            matrix[5][4] <= is_released;  // [
                        else
                            matrix[6][4] <= is_released;  // ^
                    end
                `KEY_CORCHC:
                    begin
                        matrix[0][1] <= is_released;
                        if (shift_pressed)
                            matrix[7][3] <= is_released;  // *
                        else if (alt_pressed)
                            matrix[5][3] <= is_released;  // ]
                        else
                            matrix[6][2] <= is_released;  // +
                    end
                `KEY_LLAVA:
                    begin
                        matrix[0][1] <= is_released;
                        if (alt_pressed || shift_pressed)
                            matrix[1][3] <= is_released;  // {
                        else
                            matrix[0][3] <= is_released; // pound
                    end
                `KEY_LLAVC:
                    begin
                        matrix[0][1] <= is_released;
                        if (alt_pressed || shift_pressed)
                            matrix[1][4] <= is_released;  // }
                        else
                            matrix[5][2] <= is_released;  // copyright
                    end
                `KEY_COMA:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[7][2] <= is_released;
                        else
                            matrix[5][1] <= is_released;  // ;
                    end
                `KEY_PUNTO:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[7][1] <= is_released;
                        else
                            matrix[0][2] <= is_released;  // :
                    end
                `KEY_MENOS:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[6][3] <= is_released;  //
                        else
                            matrix[4][0] <= is_released;  // _
                    end
                `KEY_LT:
                    begin
                        matrix[0][1] <= is_released;
                        if (!shift_pressed)
                            matrix[2][3] <= is_released;  // <
                        else
                            matrix[2][4] <= is_released;  // >
                    end
                `KEY_BL:
                    begin
                        matrix[0][1] <= is_released;
                        matrix[1][2] <= is_released;  // \
                    end       
                `KEY_SPACE:
                    matrix[7][0] <= is_released;
                    
                // Cursor keys
                `KEY_UP:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[4][4] <= is_released;
                    end
                `KEY_DOWN:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[4][3] <= is_released;
                    end
                `KEY_LEFT:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[3][4] <= is_released;
                    end
                `KEY_RIGHT:
                    begin
                        matrix[0][0] <= is_released;
                        matrix[4][2] <= is_released;
                    end
            endcase    
        end
    end
endmodule
