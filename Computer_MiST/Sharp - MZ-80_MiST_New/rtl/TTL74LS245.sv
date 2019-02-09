module TTL74LS245 (
	input 		OE,
	input 		DIR,
	input [7:0] Ain,
	output [7:0]Aout,
	input [7:0] Bin,
	output [7:0]Bout
	);

always @ (OE, DIR, Ain,Bin) begin
	if (OE== 1'b0 & DIR == 1'b1)
		Bout = Ain;
	else if (OE== 1'b0 & DIR == 1'b0)
		Aout = Bin;
end
endmodule 