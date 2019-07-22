//
// microrom and nanorom instantiation
//
// There is bit of wasting of resources here. An extra registering pipeline happens that is not needed.
// This is just for the purpose of helping inferring block RAM using pure generic code. Inferring RAM is important for performance.
// Might be more efficient to use vendor specific features such as clock enable.
//

module uRom( input clk, input [UADDR_WIDTH-1:0] microAddr, output logic [UROM_WIDTH-1:0] microOutput);
	reg [UROM_WIDTH-1:0] uRam[ UROM_DEPTH];		
	initial begin
		$readmemb("microrom.mem", uRam);
	end
	
	always_ff @( posedge clk) 
		microOutput <= uRam[ microAddr];
endmodule


module nanoRom( input clk, input [NADDR_WIDTH-1:0] nanoAddr, output logic [NANO_WIDTH-1:0] nanoOutput);
	reg [NANO_WIDTH-1:0] nRam[ NANO_DEPTH];		
	initial begin
		$readmemb("nanorom.mem", nRam);
	end
	
	always_ff @( posedge clk) 
		nanoOutput <= nRam[ nanoAddr];
endmodule