
module LINEBUF1024_9
(
	input				CL0,
	input	 [9:0]	AD0,
	input				WE0,
	output [8:0]	DO0,

	input				CL1,
	input	 [9:0]	AD1,
	input				WE1,
	input	 [8:0]	DI1
);

LINEBUF lbcore (
	.clock_a(CL0),
	.address_a(AD0),
	.data_a(9'h0),
	.wren_a(WE0),
	.q_a(DO0),

	.clock_b(CL1),
	.address_b(AD1),
	.data_b(DI1),
	.wren_b(WE1)
);

endmodule


module GSPRAM #(parameter AW,parameter DW)
(
	input							CL,
	input [(AW-1):0]			AD,
	input							WE,
	input [(DW-1):0]			DI,
	output reg [(DW-1):0]	DO
);

reg [(DW-1):0] core[0:((2**AW)-1)];

always @(posedge CL) begin
	DO <= core[AD];
	if (WE) core[AD] <= DI;
end
	
endmodule


module GDPRAM #(parameter AW,parameter DW)
(
	input							CL0,
	input [(AW-1):0]			AD0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input [(AW-1):0]			AD1,
	input							WE1,
	input [(DW-1):0]			DI1,
	output reg [(DW-1):0]	DO1
);

reg [(DW-1):0] core[0:((2**AW)-1)];

always @(posedge CL0) DO0 <= core[AD0];
always @(posedge CL1) begin DO1 <= core[AD1]; if (WE1) core[AD1] <= DI1; end

endmodule


module GLINEBUF #(parameter AW,parameter DW)
(
	input							CL0,
	input	 [(AW-1):0]			AD0,
	input							WE0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input	 [(AW-1):0]			AD1,
	input							WE1,
	input	 [(DW-1):0]			DI1
);

reg [(DW-1):0] core[0:((2**AW)-1)];

always @(posedge CL0) begin DO0 <= core[AD0]; if (WE0) core[AD0] <= 0; end
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule


module DLROM #(parameter AW,parameter DW)
(
	input							CL0,
	input [(AW-1):0]			AD0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input [(AW-1):0]			AD1,
	input	[(DW-1):0]			DI1,
	input							WE1
);

reg [DW:0] core[0:((2**AW)-1)];

always @(posedge CL0) DO0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule


