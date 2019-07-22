// Translate uaddr to nanoaddr
module microToNanoAddr(
	input [UADDR_WIDTH-1:0] uAddr,
	output [NADDR_WIDTH-1:0] orgAddr);

	wire [UADDR_WIDTH-1:2] baseAddr = uAddr[UADDR_WIDTH-1:2];
	logic [NADDR_WIDTH-1:2] orgBase;
	assign orgAddr = { orgBase, uAddr[1:0]};

	always @( baseAddr)
	begin
		// nano ROM (136 addresses)
		case( baseAddr)

'h00: orgBase = 7'h0 ;
'h01: orgBase = 7'h1 ;
'h02: orgBase = 7'h2 ;
'h03: orgBase = 7'h2 ;
'h08: orgBase = 7'h3 ;
'h09: orgBase = 7'h4 ;
'h0A: orgBase = 7'h5 ;
'h0B: orgBase = 7'h5 ;
'h10: orgBase = 7'h6 ;
'h11: orgBase = 7'h7 ;
'h12: orgBase = 7'h8 ;
'h13: orgBase = 7'h8 ;
'h18: orgBase = 7'h9 ;
'h19: orgBase = 7'hA ;
'h1A: orgBase = 7'hB ;
'h1B: orgBase = 7'hB ;
'h20: orgBase = 7'hC ;
'h21: orgBase = 7'hD ;
'h22: orgBase = 7'hE ;
'h23: orgBase = 7'hD ;
'h28: orgBase = 7'hF ;
'h29: orgBase = 7'h10 ;
'h2A: orgBase = 7'h11 ;
'h2B: orgBase = 7'h10 ;
'h30: orgBase = 7'h12 ;
'h31: orgBase = 7'h13 ;
'h32: orgBase = 7'h14 ;
'h33: orgBase = 7'h14 ;
'h38: orgBase = 7'h15 ;
'h39: orgBase = 7'h16 ;
'h3A: orgBase = 7'h17 ;
'h3B: orgBase = 7'h17 ;
'h40: orgBase = 7'h18 ;
'h41: orgBase = 7'h18 ;
'h42: orgBase = 7'h18 ;
'h43: orgBase = 7'h18 ;
'h44: orgBase = 7'h19 ;
'h45: orgBase = 7'h19 ;
'h46: orgBase = 7'h19 ;
'h47: orgBase = 7'h19 ;
'h48: orgBase = 7'h1A ;
'h49: orgBase = 7'h1A ;
'h4A: orgBase = 7'h1A ;
'h4B: orgBase = 7'h1A ;
'h4C: orgBase = 7'h1B ;
'h4D: orgBase = 7'h1B ;
'h4E: orgBase = 7'h1B ;
'h4F: orgBase = 7'h1B ;
'h54: orgBase = 7'h1C ;
'h55: orgBase = 7'h1D ;
'h56: orgBase = 7'h1E ;
'h57: orgBase = 7'h1F ;
'h5C: orgBase = 7'h20 ;
'h5D: orgBase = 7'h21 ;
'h5E: orgBase = 7'h22 ;
'h5F: orgBase = 7'h23 ;
'h70: orgBase = 7'h24 ;
'h71: orgBase = 7'h24 ;
'h72: orgBase = 7'h24 ;
'h73: orgBase = 7'h24 ;
'h74: orgBase = 7'h24 ;
'h75: orgBase = 7'h24 ;
'h76: orgBase = 7'h24 ;
'h77: orgBase = 7'h24 ;
'h78: orgBase = 7'h25 ;
'h79: orgBase = 7'h25 ;
'h7A: orgBase = 7'h25 ;
'h7B: orgBase = 7'h25 ;
'h7C: orgBase = 7'h25 ;
'h7D: orgBase = 7'h25 ;
'h7E: orgBase = 7'h25 ;
'h7F: orgBase = 7'h25 ;
'h84: orgBase = 7'h26 ;
'h85: orgBase = 7'h27 ;
'h86: orgBase = 7'h28 ;
'h87: orgBase = 7'h29 ;
'h8C: orgBase = 7'h2A ;
'h8D: orgBase = 7'h2B ;
'h8E: orgBase = 7'h2C ;
'h8F: orgBase = 7'h2D ;
'h94: orgBase = 7'h2E ;
'h95: orgBase = 7'h2F ;
'h96: orgBase = 7'h30 ;
'h97: orgBase = 7'h31 ;
'h9C: orgBase = 7'h32 ;
'h9D: orgBase = 7'h33 ;
'h9E: orgBase = 7'h34 ;
'h9F: orgBase = 7'h35 ;
'hA4: orgBase = 7'h36 ;
'hA5: orgBase = 7'h36 ;
'hA6: orgBase = 7'h37 ;
'hA7: orgBase = 7'h37 ;
'hAC: orgBase = 7'h38 ;
'hAD: orgBase = 7'h38 ;
'hAE: orgBase = 7'h39 ;
'hAF: orgBase = 7'h39 ;
'hB4: orgBase = 7'h3A ;
'hB5: orgBase = 7'h3A ;
'hB6: orgBase = 7'h3B ;
'hB7: orgBase = 7'h3B ;
'hBC: orgBase = 7'h3C ;
'hBD: orgBase = 7'h3C ;
'hBE: orgBase = 7'h3D ;
'hBF: orgBase = 7'h3D ;
'hC0: orgBase = 7'h3E ;
'hC1: orgBase = 7'h3F ;
'hC2: orgBase = 7'h40 ;
'hC3: orgBase = 7'h41 ;
'hC8: orgBase = 7'h42 ;
'hC9: orgBase = 7'h43 ;
'hCA: orgBase = 7'h44 ;
'hCB: orgBase = 7'h45 ;
'hD0: orgBase = 7'h46 ;
'hD1: orgBase = 7'h47 ;
'hD2: orgBase = 7'h48 ;
'hD3: orgBase = 7'h49 ;
'hD8: orgBase = 7'h4A ;
'hD9: orgBase = 7'h4B ;
'hDA: orgBase = 7'h4C ;
'hDB: orgBase = 7'h4D ;
'hE0: orgBase = 7'h4E ;
'hE1: orgBase = 7'h4E ;
'hE2: orgBase = 7'h4F ;
'hE3: orgBase = 7'h4F ;
'hE8: orgBase = 7'h50 ;
'hE9: orgBase = 7'h50 ;
'hEA: orgBase = 7'h51 ;
'hEB: orgBase = 7'h51 ;
'hF0: orgBase = 7'h52 ;
'hF1: orgBase = 7'h52 ;
'hF2: orgBase = 7'h52 ;
'hF3: orgBase = 7'h52 ;
'hF8: orgBase = 7'h53 ;
'hF9: orgBase = 7'h53 ;
'hFA: orgBase = 7'h53 ;
'hFB: orgBase = 7'h53 ;

			default:
				orgBase = 'X;
		endcase
	end

endmodule 