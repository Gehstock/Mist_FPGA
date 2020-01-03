module aluShifter( input [31:0] data,
	input isByte, input isLong, swapWords,
	input dir, input cin,
	output logic [31:0] result);
	// output reg cout

	logic [31:0] tdata;         

	// size mux, put cin in position if dir == right
	always_comb begin
		tdata = data;
		if( isByte & dir)
			tdata[8] = cin;
		else if( !isLong & dir)
			tdata[16] = cin;
	end
    
	always_comb begin
		// Reverse alu/alue position for MUL & DIV
		// Result reversed again
		if( swapWords & dir)
			result = { tdata[0], tdata[31:17], cin, tdata[15:1]};
		else if( swapWords)
			result = { tdata[30:16], cin, tdata[14:0], tdata[31]};
			
		else if( dir)
			result = { cin, tdata[31:1]};
		else
			result = { tdata[30:0], cin};
	end

endmodule 