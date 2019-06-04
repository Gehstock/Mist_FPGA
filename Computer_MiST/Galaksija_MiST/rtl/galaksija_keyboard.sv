module galaksija_keyboard(
	input 		clk,
	input 		reset,
	input  [5:0]addr,
	 input [7:0] key_code,
	 input key_strobe,
	 input key_pressed,
	output [7:0]key_out,
	input 		rd_key
);

integer num;
reg [63:0]keys;

initial 
	begin
		for(num=0;num<64;num=num+1)
		begin
			keys[num] <= 0;
		end
	end
	
always @(posedge clk) begin			
			for(num=0;num<64;num=num+1)
			begin
				keys[num] = 1'b0;
			end
				case (key_code[7:0])					
					//nix 00
					8'h1C : keys[8'd01] = 1'b1; // A
					8'h32 : keys[8'd02] = 1'b1; // B
					8'h21 : keys[8'd03] = 1'b1; // C
					8'h23 : keys[8'd04] = 1'b1; // D
					8'h24 : keys[8'd05] = 1'b1; // E
					8'h2B : keys[8'd06] = 1'b1; // F
					8'h34 : keys[8'd07] = 1'b1; // G
					8'h33 : keys[8'd08] = 1'b1; // H
					8'h43 : keys[8'd09] = 1'b1; // I
					8'h3B : keys[8'd10] = 1'b1; // J
					8'h42 : keys[8'd11] = 1'b1; // K
					8'h4B : keys[8'd12] = 1'b1; // L
					8'h3A : keys[8'd13] = 1'b1; // M
					8'h31 : keys[8'd14] = 1'b1; // N
					8'h44 : keys[8'd15] = 1'b1; // O
					8'h4D : keys[8'd16] = 1'b1; // P
					8'h15 : keys[8'd17] = 1'b1; // Q
					8'h2D : keys[8'd18] = 1'b1; // R
					8'h1B : keys[8'd19] = 1'b1; // S
					8'h2C : keys[8'd20] = 1'b1; // T
					8'h3C : keys[8'd21] = 1'b1; // U
					8'h2A : keys[8'd22] = 1'b1; // V
					8'h1D : keys[8'd23] = 1'b1; // W
					8'h22 : keys[8'd24] = 1'b1; // X
					8'h35 : keys[8'd25] = 1'b1; // Y
					8'h1A : keys[8'd26] = 1'b1; // Z
					//nix 27,28
					8'h66 : keys[8'd29] = 1'b1; // BACKSPACE
					//nix 30
					8'h29 : keys[8'd31] = 1'b1; // SPACE				
					8'h45 : keys[8'd32] = 1'b1; // 0
					8'h16 : keys[8'd33] = 1'b1; // 1
					8'h1E : keys[8'd34] = 1'b1; // 2
					8'h26 : keys[8'd35] = 1'b1; // 3
					8'h25 : keys[8'd36] = 1'b1; // 4
					8'h2E : keys[8'd37] = 1'b1; // 5
					8'h36 : keys[8'd38] = 1'b1; // 6
					8'h3D : keys[8'd39] = 1'b1; // 7
					8'h3E : keys[8'd40] = 1'b1; // 8
					8'h46 : keys[8'd41] = 1'b1; // 9
					// NUM Block
					8'h70 : keys[8'd32] = 1'b1; // 0
					8'h69 : keys[8'd33] = 1'b1; // 1
					8'h72 : keys[8'd34] = 1'b1; // 2
					8'h7A : keys[8'd35] = 1'b1; // 3
					8'h6B : keys[8'd36] = 1'b1; // 4
					8'h73 : keys[8'd37] = 1'b1; // 5
					8'h74 : keys[8'd38] = 1'b1; // 6
					8'h6C : keys[8'd39] = 1'b1; // 7
					8'h75 : keys[8'd40] = 1'b1; // 8
					8'h7D : keys[8'd41] = 1'b1; // 9				
					
					8'h4C : keys[8'd42] = 1'b1; // ; //todo "Ö" on german keyboard
					8'h7C : keys[8'd43] = 1'b1; // : //todo NUM block for now
					8'h41 : keys[8'd44] = 1'b1; // ,
					8'h55 : keys[8'd45] = 1'b1; // = ////todo "´" on german keyboard
					8'h49 : keys[8'd46] = 1'b1; // .
					8'h4A : keys[8'd47] = 1'b1; // /				
					8'h5A : keys[8'd48] = 1'b1; // ENTER
					8'h76 : keys[8'd49] = 1'b1; // ESC
					
					8'h52 : begin keys[8'd33] = 1'b1; keys[8'd53] = 1'b1; end // ! ////todo "Ä" on german keyboard
					//8'h52 : begin keys[8'd34] = 1'b1; keys[8'd53] = 1'b1; end // "	////todo shift GALAKSIJA
					8'h12 : keys[8'd53] = 1'b1; // SHIFT L
					8'h59 : keys[8'd53] = 1'b1; // SHIFT R
					
				endcase
				if (keys[8'd53] == 1'b1) begin//shift
					case (key_code[7:0])	 
						8'h1C : keys[8'd01] = 1'b1; // a
						8'h32 : keys[8'd02] = 1'b1; // b
						8'h21 : keys[8'd03] = 1'b1; // c
						8'h23 : keys[8'd04] = 1'b1; // d
						8'h24 : keys[8'd05] = 1'b1; // e
						8'h2B : keys[8'd06] = 1'b1; // f
						8'h34 : keys[8'd07] = 1'b1; // g
						8'h33 : keys[8'd08] = 1'b1; // h
						8'h43 : keys[8'd09] = 1'b1; // i
						8'h3B : keys[8'd10] = 1'b1; // j
						8'h42 : keys[8'd11] = 1'b1; // k
						8'h4B : keys[8'd12] = 1'b1; // l
						8'h3A : keys[8'd13] = 1'b1; // m
						8'h31 : keys[8'd14] = 1'b1; // n
						8'h44 : keys[8'd15] = 1'b1; // O
						8'h4D : keys[8'd16] = 1'b1; // p
						8'h15 : keys[8'd17] = 1'b1; // q
						8'h2D : keys[8'd18] = 1'b1; // r
						8'h1B : keys[8'd19] = 1'b1; // s
						8'h2C : keys[8'd20] = 1'b1; // t
						8'h3C : keys[8'd21] = 1'b1; // u
						8'h2A : keys[8'd22] = 1'b1; // v
						8'h1D : keys[8'd23] = 1'b1; // w
						8'h22 : keys[8'd24] = 1'b1; // x
						8'h35 : keys[8'd25] = 1'b1; // y
						8'h1A : keys[8'd26] = 1'b1; // z
					endcase
				end;
		if (rd_key) key_out <= (keys[addr]==1) ? 8'hfe : 8'hff;	
end		
endmodule  