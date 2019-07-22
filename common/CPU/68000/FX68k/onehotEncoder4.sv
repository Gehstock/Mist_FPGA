// bin to one-hot, 4 bits to 16-bit bitmap
module onehotEncoder4( input [3:0] bin, output reg [15:0] bitMap);
	always_comb begin
	case( bin)
		'b0000:   bitMap = 16'h0001;
		'b0001:   bitMap = 16'h0002;
		'b0010:   bitMap = 16'h0004;
		'b0011:   bitMap = 16'h0008;
		'b0100:   bitMap = 16'h0010;
		'b0101:   bitMap = 16'h0020;
		'b0110:   bitMap = 16'h0040;
		'b0111:   bitMap = 16'h0080;
		'b1000:   bitMap = 16'h0100;
		'b1001:   bitMap = 16'h0200;
		'b1010:   bitMap = 16'h0400;
		'b1011:   bitMap = 16'h0800;
		'b1100:   bitMap = 16'h1000;
		'b1101:   bitMap = 16'h2000;
		'b1110:   bitMap = 16'h4000;
		'b1111:   bitMap = 16'h8000;
	endcase
	end
endmodule 