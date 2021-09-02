
module keyboard
(
	input clk_sys,
	input rst_n,

	input [10:0] ps2_key,
	
	input [3:0] joystick_0,
	input [3:0] joystick_1,

	output reg [7:0] keys [7:0]
);

reg release_btn = 0;
reg [7:0] code;
reg shift = 0;

reg  input_strobe = 0;

always @(posedge clk_sys or negedge rst_n) begin

    if (!rst_n)
        begin
            keys[0] <= 8'b11111111;
            keys[1] <= 8'b11111111;
            keys[2] <= 8'b11111111;
            keys[3] <= 8'b11111111;
            keys[4] <= 8'b11111111;
            keys[5] <= 8'b11111111;
            keys[6] <= 8'b11111111;
            keys[7] <= 8'b11111111;
        end
    else
		begin
			// unused or unmapped keys
			keys[2][0] = 1'b1;
			keys[3][2] = 1'b1;
			keys[3][4] = 1'b1;
			keys[3][6] = 1'b1;
			keys[7][4] = 1'b1;
			keys[7][5] = 1'b1;
			keys[7][6] = 1'b1;
			keys[7][7] = 1'b1;
		
        if (input_strobe)
            case(code)

                // @ 3800H

                8'h3e :						                		// 8
                    if (shift == 1)
                        begin
                            keys[0][0] <= release_btn;      // *
                            keys[0][7] <= 1'b1;             // unshift
                        end
                    else
                        begin
                            keys[2][2] <= release_btn;		// 8
                            keys[0][7] <= 1'b1;             // unshift
                        end
                8'h29 : keys[0][1] <= release_btn;          // SPACE
                8'h5a : keys[0][2] <= release_btn;          // ENTER
                8'h0d : keys[0][3] <= release_btn;          // TAB
                8'h66 : keys[0][4] <= release_btn;          // BACKSPACE
                8'h58 : keys[0][5] <= release_btn;          // CAPS
                8'h14 : keys[0][6] <= release_btn;          // CONTROL
                8'h12 :
                    begin
                        keys[0][7] <= release_btn;          // Left shift
                        shift <= ~release_btn;
                    end
                8'h59 :
                    begin
                        keys[0][7] <= release_btn;          // Right shift
                        shift <= ~release_btn;
                    end
                8'h1e : keys[1][0] <= release_btn;          // 2
                8'h52 :						                		// "
                    if (shift == 1)
                        begin
                            keys[1][0] <= release_btn;      // 2
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[3][7] <= release_btn;		// 3
                            keys[0][7] <= 1'b0;             // shift
                        end

                // @ 3801H

                8'h16 :						                		// 1
                    if (shift == 1)
                        begin                               // !
                            keys[2][4] <= release_btn;      // 6
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[1][1] <= release_btn;		// 1
                        end
                8'h45 :						                		// 0
                    if (shift == 1)
                        begin
                            keys[2][1] <= release_btn;      // 9
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[1][2] <= release_btn;		// 0
                        end
                8'h4a :						                		// /
                    if (shift == 1)
                        begin                               // ?
                            keys[3][3] <= release_btn;      // ?
                            keys[0][7] <= 1'b1;             // unshift
                        end
                    else
                        begin
                            keys[1][3] <= release_btn;		// /
                        end
                8'h49 :						                		// .
                    if (shift == 1)
                        begin                               // >
                            keys[1][1] <= release_btn;      // 1
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[1][4] <= release_btn;		// .
                        end
                8'h4e : keys[1][5] <= release_btn;          // -
                8'h41 :						                		// ,
                    if (shift == 1)
                        begin                               // <
                            keys[1][2] <= release_btn;      // 0
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[1][6] <= release_btn;		// ,
                        end
                8'h55 :						                		// =
                    if (shift == 1)
                        begin
                            keys[1][7] <= release_btn;      // +
                            keys[0][7] <= 1'b1;             // unshift
                        end
                    else
                        begin
                            keys[3][5] <= release_btn;		// =
                        end

                // @ 3802H

                8'h46 :						                		// 9
                    if (shift == 1)
                        begin
                            keys[2][2] <= release_btn;      // 8
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[2][1] <= release_btn;		// 9
                        end
                8'h3d : keys[2][3] <= release_btn;          // 7
                8'h36 :						                		// 6
                    if (shift == 1)
                        begin
                            keys[1][7] <= release_btn;      // +
                            keys[0][7] <= 1'b0;             // shift
                        end
                    else
                        begin
                            keys[2][4] <= release_btn;		// 6
                        end
                8'h2e : keys[2][5] <= release_btn;          // 5
                8'h25 : keys[2][6] <= release_btn;          // 4
                8'h26 : keys[2][7] <= release_btn;          // 3

                // @ 3803H

                8'h32 : keys[3][0] <= release_btn;          // B
                8'h1c : keys[3][1] <= release_btn;          // A
                8'h4c :						                		// ;
                    if (shift == 1)
                        begin
                            keys[2][3] <= release_btn;      // :, shift-7
                            keys[0][7] <= 1'b1;             // shift
                        end
                    else
                        begin
                            keys[3][7] <= release_btn;		// ;
                            keys[0][7] <= 1'b1;             // unshift
                        end

                // @ 3804H

                8'h3b : keys[4][0] <= release_btn;          // J
                8'h43 : keys[4][1] <= release_btn;          // I
                8'h33 : keys[4][2] <= release_btn;          // H
                8'h34 : keys[4][3] <= release_btn;          // G
                8'h2b : keys[4][4] <= release_btn;          // F
                8'h24 : keys[4][5] <= release_btn;          // E
                8'h23 : keys[4][6] <= release_btn;          // D
                8'h21 : keys[4][7] <= release_btn;          // C

                // @ 3805H

                8'h2d : keys[5][0] <= release_btn;          // R
                8'h15 : keys[5][1] <= release_btn;          // Q
                8'h4d : keys[5][2] <= release_btn;          // P
                8'h44 : keys[5][3] <= release_btn;          // O
                8'h31 : keys[5][4] <= release_btn;          // N
                8'h3a : keys[5][5] <= release_btn;          // M
                8'h4b : keys[5][6] <= release_btn;          // L
                8'h42 : keys[5][7] <= release_btn;          // K

                // @ 3806H

                8'h1a : keys[6][0] <= release_btn;          // Z
                8'h35 : keys[6][1] <= release_btn;          // Y
                8'h22 : keys[6][2] <= release_btn;          // X
                8'h1d : keys[6][3] <= release_btn;          // W
                8'h2a : keys[6][4] <= release_btn;          // V
                8'h3c : keys[6][5] <= release_btn;          // U
                8'h2c : keys[6][6] <= release_btn;          // T
                8'h1b : keys[6][7] <= release_btn;          // S

                default: ;
            endcase
				
		  // @ 3807H

		  keys[7][0] <= ~joystick_0[1];          // left
		  keys[7][1] <= ~joystick_0[0];          // right
		  keys[7][2] <= ~joystick_0[3];          // up
		  keys[7][3] <= ~joystick_0[2];          // down
		  keys[7][4] <= ~joystick_1[1];          // left
		  keys[7][5] <= ~joystick_1[0];          // right
		  keys[7][6] <= ~joystick_1[3];          // up
		  keys[7][7] <= ~joystick_1[2];          // down

		end
end

always @(posedge clk_sys) begin
	reg old_state;

	input_strobe <= 0;
	old_state <= ps2_key[10];

	if (old_state != ps2_key[10]) begin
		release_btn <= ~ps2_key[9];
		code <= ps2_key[7:0];
		input_strobe <= 1;
	end
end

endmodule
