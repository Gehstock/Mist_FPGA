`timescale 1ns / 1ps
module mc6809
(
	input         CLK,
	input         CLKEN,
	input         nRESET,

	input         CPU,

	output reg    E,
	output reg    riseE,
	output reg    fallE, // everything except interrupts/dma registered/latched here

	output reg    Q,
	output reg    riseQ,
	output reg    fallQ, // NMI,IRQ,FIRQ,DMA,HALT registered here

	input   [7:0] Din,
	output  [7:0] Dout,
	output [15:0] ADDR,
	output        RnW,

	input         nIRQ,
	input         nFIRQ,
	input         nNMI,
	input         nHALT
);

cpu09 cpu1
(
	.clk(CLK),
	.ce(fallE),
	.rst(~nRESET | CPU),
	.addr(ADDR1),
	.rw(RnW1),
	.data_out(Dout1),
	.data_in(Din),
	.irq(~nIRQ),
	.firq(~nFIRQ),
	.nmi(~nNMI),
	.halt(~nHALT)
);

mc6809is cpu2
(
	.CLK(CLK),
	.D(Din),
	.DOut(Dout2),
	.ADDR(ADDR2),
	.RnW(RnW2),
	.fallE_en(fallE),
	.fallQ_en(fallQ),
	.nIRQ(nIRQ),
	.nFIRQ(nFIRQ),
	.nNMI(nNMI),
	.nHALT(nHALT),
	.nRESET(nRESET & CPU),
	.nDMABREQ(1)
);

wire  [7:0] Dout1,Dout2;
wire [15:0] ADDR1,ADDR2;
wire        RnW1,RnW2;

assign Dout = CPU ? Dout2 : Dout1;
assign ADDR = CPU ? ADDR2 : ADDR1;
assign RnW  = CPU ? RnW2  : RnW1;

always @(posedge CLK)
begin
	reg [1:0] clk_phase =0;

	fallE <= 0;
	fallQ <= 0;
	riseE <= 0;
	riseQ <= 0;

	if (CLKEN) begin
		clk_phase <= clk_phase + 1'd1;
		case (clk_phase)
			2'b00: begin E <= 0; fallE <= 1; end
			2'b01: begin Q <= 1; riseQ <= 1; end
			2'b10: begin E <= 1; riseE <= 1; end
			2'b11: begin Q <= 0; fallQ <= 1; end
		endcase
	end
end

endmodule
