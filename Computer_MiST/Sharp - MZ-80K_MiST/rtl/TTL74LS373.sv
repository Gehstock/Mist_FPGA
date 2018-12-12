module TTL74LS373 (
input 			LE,
input 	[8:1]	D,
input 			OE_n,
output 	[8:1]	Q
);

reg	SYNTHESIZED_WIRE_0;
reg	SYNTHESIZED_WIRE_2;
reg	SYNTHESIZED_WIRE_4;
reg	SYNTHESIZED_WIRE_6;
reg	SYNTHESIZED_WIRE_8;
reg	SYNTHESIZED_WIRE_10;
reg	SYNTHESIZED_WIRE_12;
reg	SYNTHESIZED_WIRE_14;



always@(LE or D[1])
begin
if (LE)
	SYNTHESIZED_WIRE_0 <= D[1];
end


always@(LE or D[2])
begin
if (LE)
	SYNTHESIZED_WIRE_2 <= D[2];
end


always@(LE or D[3])
begin
if (LE)
	SYNTHESIZED_WIRE_4 <= D[3];
end


always@(LE or D[4])
begin
if (LE)
	SYNTHESIZED_WIRE_6 <= D[4];
end


always@(LE or D[5])
begin
if (LE)
	SYNTHESIZED_WIRE_8 <= D[5];
end


always@(LE or D[6])
begin
if (LE)
	SYNTHESIZED_WIRE_10 <= D[6];
end


always@(LE or D[7])
begin
if (LE)
	SYNTHESIZED_WIRE_12 <= D[7];
end


always@(LE or D[8])
begin
if (LE)
	SYNTHESIZED_WIRE_14 <= D[8];
end

assign	Q[1] = OE_n ? SYNTHESIZED_WIRE_0 : 1'bz;
assign	Q[2] = OE_n ? SYNTHESIZED_WIRE_2 : 1'bz;
assign	Q[3] = OE_n ? SYNTHESIZED_WIRE_4 : 1'bz;
assign	Q[4] = OE_n ? SYNTHESIZED_WIRE_6 : 1'bz;
assign	Q[5] = OE_n ? SYNTHESIZED_WIRE_8 : 1'bz;
assign	Q[6] = OE_n ? SYNTHESIZED_WIRE_10 : 1'bz;
assign	Q[7] = OE_n ? SYNTHESIZED_WIRE_12 : 1'bz;
assign	Q[8] = OE_n ? SYNTHESIZED_WIRE_14 : 1'bz;


endmodule
