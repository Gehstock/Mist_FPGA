module ROM 
#(
	parameter rom_file = ""
)
(
	input          CLK,
	input          RST_N,
	
	input  [20: 1] RADDR,
	output [15: 0] DO
);

// synopsys translate_off
`define SIM
// synopsys translate_on
	
`ifdef SIM

	reg [15:0] MEM [(2*1024*1024)/2];
	initial begin
		$readmemh(rom_file, MEM);
	end
	
	assign DO = MEM[RADDR[20:1]];

`else
	
	

	
	
`endif

endmodule
