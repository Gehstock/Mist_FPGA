//adapted from MWR ram2114 module
module m6116_ram(
	input[7:0] data,
	input clk,
	input cen,
	input[10:0] addr,
	input nWE,
	output reg [7:0] q
);
	reg[7:0] ram[2047:0];
	reg[10:0] addr_reg;
	
	always @ (posedge clk)
	begin
		if (!nWE && cen) 	ram[addr] <= data;
		if (cen)				q <=ram[addr];  
	end
	
endmodule

module m6116_ramDP(
	input[7:0] data,
	input[7:0] data_b,	
	input clk,
	input cen,
	input[10:0] addr,
	input[10:0] addr_b,	
	input nWE,nWE_b,
	output reg [7:0] q,q_b
);
	reg[7:0] ram[2047:0];
	reg[10:0] addr_reg;
	
	always @ (posedge clk)
	begin
		if (!nWE && cen) 	ram[addr] <= data;
		if (cen)				q <=ram[addr];  
	end

	always @ (posedge clk)
	begin
		if (!nWE_b && cen) 	ram[addr_b] <= data_b;
		if (cen)				q_b <=ram[addr_b];  
	end
	
endmodule

module m2114_ram(
	input[7:0] data,
	input clk,
	input[6:0] addr,
	input nWE,
	output reg [7:0] q
);
	reg[7:0] ram[127:0];
	reg[6:0] addr_reg;
	
	always @ (posedge clk)
	begin
		if (!nWE) ram[addr] <= data;
		q <=ram[addr];  
	end
endmodule

module m2511_ram_4(
	input[3:0] data,
	input clk,
	input[8:0] addr,
	input nWE,
	output reg [3:0] q
);
	reg[3:0] ram[511:0];
	reg[8:0] addr_reg;
	
	always @ (posedge clk)
	begin
		if (!nWE) ram[addr] <= data;
		if (nWE) q <=ram[addr]; 
	end
endmodule

module ls89_ram_x2(
	input[7:0] data,
	input clk,
	input[3:0] addr,
	input nWE,
	output reg [7:0] q
);
	reg[7:0] ram[15:0];
	reg[3:0] addr_reg;
	
	always @ (posedge clk)
	begin
		if (!nWE) ram[addr] <= data;
		q <= ram[addr];
	end
endmodule
