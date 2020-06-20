//----------------------------------------
//  Sub CPU
//----------------------------------------
module gaplus_sub
(
	input SCPU_CLK,
	input	RESET,
	input VBLK,

	input   [7:0] scpu_mr,
	output [15:0] scpu_ma,
	output        scpu_we,
	output  [7:0] scpu_do,
	output [14:0] sub_cpu_addr,
	input   [7:0] sub_cpu_do
);

wire [7:0]  scpu_di;
wire        scpu_rw, scpu_vma;
wire        scpu_wr = ~scpu_rw;
wire        scpu_rd =  scpu_rw;

wire scpu_irom_cs = ( scpu_ma[15]               ) & scpu_vma;
wire scpu_mram_cs = ( scpu_ma[15:13] == 3'b000  ) & scpu_vma;
wire scpu_irqe_cs = ( scpu_ma[15:12] == 4'b0110 ) & scpu_vma;

wire	[7:0]	srom_d;
assign sub_cpu_addr = scpu_ma[14:0];
assign srom_d = sub_cpu_do;

dataselector2 scpu_disel( scpu_di, scpu_irom_cs, srom_d, scpu_mram_cs, scpu_mr, 8'hFF );

assign scpu_we =  scpu_mram_cs & scpu_wr;

reg	sirq_en  = 1'b1;
wire	scpu_irq = (~sirq_en) & VBLK;

always @ ( negedge SCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		sirq_en <= 1'b1;
	end else begin
		if ( scpu_irqe_cs ) sirq_en <= (~scpu_ma[0]);
	end
end

cpu6809 subcpu (
	.clkx2(SCPU_CLK),
	.rst(RESET),
	.rw(scpu_rw),
	.vma(scpu_vma),
	.address(scpu_ma),
	.data_in(scpu_di),
	.data_out(scpu_do),
	.halt(1'b0),
	.hold(1'b0),
	.irq(scpu_irq),
	.firq(1'b0),
	.nmi(1'b0)
);

endmodule


// CPU core wrapper
module cpu6809
(
	input				clkx2,
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

// Phase Generator
reg rE=1'b0, rQ=1'b0;
always @(posedge clkx2) rQ <= ~rQ;
always @(negedge clkx2) rE <= ~rE;

// CPU core
mc6809i core (
	.D(data_in),.DOut(data_out),.ADDR(address),.RnW(rw),.E(rE),.Q(rQ),
	.nIRQ(~irq),.nFIRQ(~firq),.nNMI(~nmi),
	.nHALT(~halt),.nRESET(~rst),
	.nDMABREQ(1'b1)
);

assign vma = rE;

endmodule 