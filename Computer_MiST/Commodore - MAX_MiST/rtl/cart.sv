module cart(
   input         	clk0,
	input [15:0]	addr,
	input [7:0]		data_i,
	output [7:0]	data_o,
	output reg    	nmi,
   input         	reset,	
	input         	romL,						// romL signal in
	input         	romH,
	input				rw_pla_n,
	input				ba,
	input				cia_pla_n,
	input				cia_n,
	input				cnt,
	input				exram_n,
	input				sp,
	input				rw_n,
	input				irq_n
);

endmodule 