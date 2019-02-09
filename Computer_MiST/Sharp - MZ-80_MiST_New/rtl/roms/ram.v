module ram( addr, data, ce, we, oe );
	input [9:0] addr;
	inout [7:0] data;
	input ce, we, oe;

	reg [7:0] mem [0:1023];
	wire WRITE, READ;

	always @( WRITE or data ) begin
		if ( WRITE )
			mem[addr] <= data;
	end

	assign READ = oe & ce;
	assign WRITE = we & ce;
	assign data = READ ? mem[addr]: 8'hzz;

endmodule
