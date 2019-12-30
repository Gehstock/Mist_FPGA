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

module dataselector_4D_9B
(
	output [8:0] OUT,

	input 		 EN1,
	input  [8:0] IN1,

	input 		 EN2,
	input  [8:0] IN2,

	input 		 EN3,
	input  [8:0] IN3,

	input 		 EN4,
	input  [8:0] IN4,

	input  [8:0] IND
);

assign OUT = EN1 ? IN1: 
				 EN2 ? IN2: 
				 EN3 ? IN3: 
				 EN4 ? IN4:
 				       IND;

endmodule 