module ninjakun_irqgen
( 
	input			CLK,
	input			VBLK,

	input			IRQ0_ACK,
	input			IRQ1_ACK,

	output reg	IRQ0,
	output reg	IRQ1
);

`define CYCLES 12500		// 1/240sec.

reg  pVBLK;
wire VBTG = VBLK & (pVBLK^VBLK);

reg [13:0] cnt;
wire IRQ1_ACT = (cnt == 1);
wire CNTR_RST = (cnt == `CYCLES)|VBTG;

always @( posedge CLK ) begin
	if (VBTG)	  IRQ0 <= 1'b1;
	if (IRQ1_ACT) IRQ1 <= 1'b1;

	if (IRQ0_ACK) IRQ0 <= 1'b0;
	if (IRQ1_ACK) IRQ1 <= 1'b0;

	cnt   <= CNTR_RST ? 0 : (cnt + 1'b1);
	pVBLK <= VBLK;
end

endmodule 
