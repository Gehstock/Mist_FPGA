/**************************************************************
	FPGA New Rally-X (Sound Part)
***************************************************************/

module nrx_namco
(
	input			clk,
	input [7:0] a0,
	input	[7:0] a1,
	input	[7:0] a2,
	output reg [3:0] d0,
	output reg [3:0] d1,
	output reg [3:0] d2
);

reg  [1:0] ph=0;

reg  [7:0] ad;
wire [7:0] dt;
nrx_nam_rom namrom(
	.clk(clk),
	.addr(ad), 
	.data(dt)
	);

always @(negedge clk) begin
	case (ph)
	0: begin d2 <= dt[3:0]; ad <= a0; ph <= 1; end
	1: begin d0 <= dt[3:0]; ad <= a1; ph <= 2; end
	2: begin d1 <= dt[3:0]; ad <= a2; ph <= 0; end
	default:;
	endcase
end

endmodule 