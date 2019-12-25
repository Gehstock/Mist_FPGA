module dataselector_3D_8B
(
	output [7:0] out,
	input  [7:0] df,

	input			 en0,
	input	 [7:0] dt0,
	input			 en1,
	input	 [7:0] dt1,
	input			 en2,
	input	 [7:0] dt2
);

assign out = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 df;

endmodule 