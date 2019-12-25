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