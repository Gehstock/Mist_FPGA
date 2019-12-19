module regs
(
	input					MCPU_CLK,
	input					RESET,
	input					VBLANK,

	input	 [15:0]		MCPU_ADRS,
	input					MCPU_VMA,
	input					MCPU_WE,

	input	 [15:0]		SCPU_ADRS,
	input					SCPU_VMA,
	input					SCPU_WE,

	output reg [7:0]	SCROLL,
	output				MCPU_IRQ,
	output reg			MCPU_IRQEN,
	output				SCPU_IRQ,
	output reg			SCPU_IRQEN,
	output				SCPU_RESET,
	output				IO_RESET,
	output reg			PSG_ENABLE
);

// BG Scroll Register
wire	MCPU_SCRWE = ( ( MCPU_ADRS[15:11] == 5'b00111 ) & MCPU_VMA & MCPU_WE );
always @ ( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) SCROLL <= 8'h0;
	else if ( MCPU_SCRWE ) SCROLL <= MCPU_ADRS[10:3];
end

// MainCPU IRQ Generator
wire	MCPU_IRQWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000001 ) & MCPU_VMA & MCPU_WE );
//wire	MCPU_IRQWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000001 ) & SCPU_VMA & SCPU_WE );
assign MCPU_IRQ    = MCPU_IRQEN & VBLANK;

always @( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		MCPU_IRQEN <= 1'b0;
	end
	else begin
		if ( MCPU_IRQWE  ) MCPU_IRQEN <= MCPU_ADRS[0];
//		if ( MCPU_IRQWES ) MCPU_IRQEN <= SCPU_ADRS[0];
	end
end


// SubCPU IRQ Generator
wire	SCPU_IRQWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000000 ) & MCPU_VMA & MCPU_WE );
wire	SCPU_IRQWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000000 ) & SCPU_VMA & SCPU_WE );
assign SCPU_IRQ    = SCPU_IRQEN & VBLANK;

always @( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		SCPU_IRQEN <= 1'b0;
	end
	else begin
		if ( SCPU_IRQWE  ) SCPU_IRQEN <= MCPU_ADRS[0];
		if ( SCPU_IRQWES ) SCPU_IRQEN <= SCPU_ADRS[0];
	end
end


// SubCPU RESET Control
reg	SCPU_RSTf   = 1'b0;
wire	SCPU_RSTWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000101 ) & MCPU_VMA & MCPU_WE );
wire	SCPU_RSTWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000101 ) & SCPU_VMA & SCPU_WE );
assign SCPU_RESET  = ~SCPU_RSTf;

always @( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		SCPU_RSTf <= 1'b0;
	end
	else begin
		if ( SCPU_RSTWE  ) SCPU_RSTf <= MCPU_ADRS[0];
		if ( SCPU_RSTWES ) SCPU_RSTf <= SCPU_ADRS[0];
	end
end


// I/O CHIP RESET Control
reg	IOCHIP_RSTf   = 1'b0;
wire	IOCHIP_RSTWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000100 ) & MCPU_VMA & MCPU_WE );
assign IO_RESET     = ~IOCHIP_RSTf;

always @( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		IOCHIP_RSTf <= 1'b0;
	end
	else begin
		if ( IOCHIP_RSTWE ) IOCHIP_RSTf <= MCPU_ADRS[0];
	end
end


// Sound Enable Control
wire	PSG_ENAWE   = ( ( MCPU_ADRS[15:1] == 15'b010100000000011 ) & MCPU_VMA & MCPU_WE );
wire	PSG_ENAWES  = ( ( SCPU_ADRS[15:1] == 15'b001000000000011 ) & SCPU_VMA & SCPU_WE );

always @( negedge MCPU_CLK or posedge RESET ) begin
	if ( RESET ) begin
		PSG_ENABLE <= 1'b0;
	end
	else begin
		if ( PSG_ENAWE  ) PSG_ENABLE <= MCPU_ADRS[0];
		if ( PSG_ENAWES ) PSG_ENABLE <= SCPU_ADRS[0];
	end
end

endmodule 