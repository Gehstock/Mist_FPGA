module dataselector_5D_8B
(
	output [7:0] out,
	input			 en0,
	input  [7:0] dt0,
	input			 en1,
	input  [7:0] dt1,
	input			 en2,
	input  [7:0] dt2,
	input			 en3,
	input  [7:0] dt3,
	input			 en4,
	input  [7:0] dt4
);

assign out = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 en3 ? dt3 :
				 en4 ? dt4 :
				 8'hFF;

endmodule 