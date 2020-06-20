/********************************************
   CPU Modules for "FPGA Gaplus"

			  Copyright (c) 2007,2019 MiSTer-X
*********************************************/

//----------------------------------------
//  Main CPU
//----------------------------------------
module gaplus_main
(
	input				MCPU_CLK,
	input				RESET,
	input				VBLK,

	input  [31:0]	INP0,
	input  [31:0]	INP1,
	input	  [3:0]	INP2,

	output [15:0]	mcpu_ma,
	output			mcpu_we,
	output  [7:0]	mcpu_do,
	input   [7:0]	mcpu_mr,

	output       	snd_we,
	input   [7:0]	snd_rd,

	output			mcpu_star_cs,

	output 			SUB_RESET,
	output			kick_explode,
	output  [14:0] main_cpu_addr,
	input    [7:0] main_cpu_do
);

wire [7:0]  mcpu_di;
wire        mcpu_rw, mcpu_vma;
wire        mcpu_wr = ~mcpu_rw;
wire        mcpu_rd =  mcpu_rw;

wire mcpu_irom_cs = ( mcpu_ma[15]                ) & mcpu_vma;
wire mcpu_mram_cs = ( mcpu_ma[15:13] == 3'b000   ) & mcpu_vma;
wire mcpu_srst_cs = ( mcpu_ma[15:12] == 4'b1000  ) & mcpu_vma & mcpu_wr;
wire mcpu_irqe_cs = ( mcpu_ma[15:12] == 4'b0111  ) & mcpu_vma & mcpu_wr;
wire mcpu_sndw_cs = ( mcpu_ma[15:11] == 5'b01100 ) & mcpu_vma;
wire mcpu_iocr_cs;

wire [7:0] mrom_d;
assign main_cpu_addr = mcpu_ma[14:0];
assign mrom_d = main_cpu_do;

assign mcpu_we =  mcpu_mram_cs & mcpu_wr;
assign snd_we  =  mcpu_sndw_cs & mcpu_wr;

reg	 mirq_en  = 1'b1;
wire	 mcpu_irq = (~mirq_en) & VBLK;

reg 	 _SUBRESET = 1'b1;
assign SUB_RESET = _SUBRESET;

always @ ( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		_SUBRESET <= 1;
		mirq_en   <= 1;
	end else begin
		if ( mcpu_srst_cs ) _SUBRESET <= mcpu_ma[11];
		if ( mcpu_irqe_cs ) mirq_en   <= mcpu_ma[11];
	end
end

wire [7:0] io_rd;
dataselector4 mcpudsel( 
	mcpu_di,
	mcpu_irom_cs, mrom_d,
	mcpu_mram_cs, mcpu_mr,
	mcpu_sndw_cs, snd_rd,
	mcpu_iocr_cs, io_rd,
	8'hFF
);

cpu6809 maincpu (
	.clkx2(MCPU_CLK),
	.rst(RESET),
	.rw(mcpu_rw),
	.vma(mcpu_vma),
	.address(mcpu_ma),
	.data_in(mcpu_di),
	.data_out(mcpu_do),
	.halt(1'b0),
	.hold(1'b0),
	.irq(mcpu_irq),
	.firq(1'b0),
	.nmi(1'b0)
);

gaplus_io io(
	RESET, MCPU_CLK, VBLK,
	mcpu_ma, mcpu_vma, mcpu_wr, mcpu_do, io_rd, mcpu_iocr_cs,
	INP0, INP1, INP2, kick_explode
);

assign mcpu_star_cs = ( mcpu_ma[15:11] == 5'b10100 ) & mcpu_vma & mcpu_wr;

endmodule 