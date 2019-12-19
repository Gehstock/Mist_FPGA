module cpucore
(
	input				clk,
	input				rst,
	output 			rw,
	output			vma,
	output [15:0]	address,
	input   [7:0]	data_in,
	output  [7:0]	data_out,
	input				halt,
	input				hold,
	input				irq,
	input				firq,
	input				nmi
);


mc6809 cpu
(
   .D(data_in),
	.DOut(data_out),
   .ADDR(address),
   .RnW(rw),
	.E(vma),
   .nIRQ(~irq),
   .nFIRQ(~firq),
   .nNMI(~nmi),
   .EXTAL(clk),
   .nHALT(~halt),
   .nRESET(~rst),
	.XTAL(1'b0),
	.MRDY(1'b1),
	.nDMABREQ(1'b1)
);

endmodule 