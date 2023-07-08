module TMS320C1X_tb;

	bit         CLK;
	bit         RST_N;
	
	bit [31: 3] C_A;
	bit [31: 0] C_DI;
	
	bit [11: 0] A;
	bit [15: 0] DI;
	bit [15: 0] DO;
	bit         WE_N;
	bit         DEN_N;
	bit         MEN_N;
	
	bit [15: 0] PROM_DO;
	bit [15: 0] PORT_DO;
	bit [15: 0] IN0;
	bit [15: 0] IN1;
	bit [15: 0] IN2;
	bit [15: 0] OUT0;
	bit [15: 0] OUT1;
	bit [15: 0] OUT2;
	bit [15: 0] OUT3;
	bit [15: 0] OUT7;
	 
	//clock generation
	always #5 CLK = ~CLK;
	 
	//reset Generation
	initial begin
	  RST_N = 0;
	  #6 RST_N = 1;
	end
	
	bit CE_F,CE_R;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			CE_F <= 0;
			CE_R <= 0;
		end
		else begin
			CE_F <= ~CE_F;
			CE_R <= CE_F;
		end
	end
	
	
	TMS320C1X #("bsmt2000.txt") core
	(
		.CLK(CLK),
		.RST_N(RST_N),
		.EN(1),
		
		.CE_F(CE_F),
		.CE_R(CE_R),
		
		.RS_N(1),
		.INT_N(1),
		.BIO_N(1),
		
		.A(A),
		.DI(DI),
		.DO(DO),
		.WE_N(WE_N),
		.DEN_N(DEN_N),
		.MEN_N(MEN_N),
		.RDY(1)
	);
		
	
	wire [15:0] ROM_DO;
	always @(posedge CLK or negedge RST_N) begin
		if (!RST_N) begin
			OUT0 <= 0;
			OUT1 <= 0;
			OUT2 <= 0;
			OUT3 <= 0;
			OUT7 <= 0;
			IN0 <= 16'h0002;
			IN1 <= 0;
		end
		else begin
			if (!WE_N && CE_R)
				case (A[2:0])
					3'd0: OUT0 <= DO;
					3'd1: OUT1 <= DO;
					3'd2: OUT2 <= DO;
					3'd3: OUT3 <= DO;
					3'd7: OUT7 <= DO;
					default: ;
				endcase
		end
	end
	
	always_comb begin
		case (A[2:0])
			3'd0: PORT_DO <= IN0;
			3'd1: PORT_DO <= IN1;
			3'd2: PORT_DO <= ROM_DO;
			default: PORT_DO <= '0;
		endcase
	end
	
	wire [20:1] ROM_A = {OUT1[3:0],OUT0};
	ROM #(.rom_file("btc0-s.txt")) rom(CLK, RST_N, ROM_A, ROM_DO);
	
	assign DI = PORT_DO;

	
endmodule
