
module mz80k_top(
	input		CLK_50MHZ,
	input		RESET,
	input		[10:0] PS2_KEY, 
	input		[1:0] color,
	output	VGA_RED, 
	output	VGA_GREEN, 
	output	VGA_BLUE, 
	output	VGA_HSYNC, 
	output	VGA_VSYNC,
	input		[7:0] SW,
	input   	TURBO,
	input   	SCREEN,
	output	TP1
	);
	

	wire			CLK_CPU;
	reg			CLK_2M = 0, CLK_31250 = 0;
	reg	[4:0]		count_2M = 0;
	reg	[10:0]	count_31250 = 0;
	reg	[32:0]	clk_count = 0;
	
	always @(posedge CLK_50MHZ) begin
		clk_count <= clk_count + 1;
	end
	
	always @(posedge CLK_50MHZ) begin
		count_2M		<= count_2M >= 13 ? 0 : count_2M + 1;
		count_31250	<= count_31250 >= 800 ? 0 : count_31250 + 1;
		CLK_2M		<= count_2M == 0 ? ~CLK_2M : CLK_2M;
		CLK_31250	<= count_31250 == 0 ? ~CLK_31250 : CLK_31250;
	end
	
	assign CLK_CPU = TURBO ?  clk_count[2] : clk_count[3];		// 3MHZ

// Z80
	wire	[15:0] cpu_addr;
	wire	[7:0] cpu_data_in, cpu_data_out;
	wire	mreq, iorq, rd, wr, busreq, busack, intack;
	wire	start, waitreq;

// I/O
 /*   CS_E0_n             <= '0'  when CS_E_n='0' and T80_A16(11 downto 2)="0000000000"                                                     -- 8255
                                else '1';
    CS_E1_n             <= '0'  when CS_E_n='0' and T80_A16(11 downto 2)="0000000001"                                                     -- 8253
                                else '1';
    CS_E2_n             <= '0'  when CS_E_n='0' and T80_A16(11 downto 2)="0000000010"                                                     -- LS367
                                else '1';
    CS_ESWP_n           <= '0'  when CONFIG(MZ_A)='1' and CS_E_n='0' and T80_RD_n='0' and T80_A16(11 downto 5)="0000000"                  -- ROM/RAM Swap
                                else '1';*/
	//wire	io_e000 = (cpu_addr[15:0] == 16'he000) & mreq;
	//wire	io_e001 = (cpu_addr[15:0] == 16'he001) & mreq;
	wire	io_e002 = (cpu_addr[15:0] == 16'he002) & mreq;
	wire	io_8253 = (cpu_addr[15:2] == 14'b11100000000001) & mreq;
	wire	io_8255 = (cpu_addr[15:2] == 14'b11100000000000) & mreq;
	wire	io_e008 = (cpu_addr[15:0] == 16'he008) & mreq;

	reg				speaker_enable;
	always @(posedge CLK_CPU or posedge RESET) begin
		if (RESET) begin
			speaker_enable <= 0;
		end else  begin
			if (io_e008 & wr ) begin
				speaker_enable <= cpu_data_out[0];
			end
		end
	end

// Z80
	assign waitreq = start;
	wire	out0, out1, out2;
	fz80 z80(
		.data_in(cpu_data_in), 
		.data_out(cpu_data_out),
		.reset_in(RESET), 
		.clk(CLK_CPU),
		.mreq(mreq), 
		.iorq(iorq), 
		.rd(rd), 
		.wr(wr),
		.adr(cpu_addr), 
		.waitreq(waitreq),
		.nmireq(0), 
		.intreq(out2 & 0), 
		.busreq(busreq), 
		.busack_out(busack),
		.start(start)
		);
		
// 8253(CLK0=2M CLK1=31.25K CLK2=OUT1)
	wire	[7:0] i8253_data_out;
	i8253 i8253_1(
		.reset(RESET), 
		.clk(CLK_CPU), 
		.addr(cpu_addr[1:0]), 
		.data_out(i8253_data_out), 
		.data_in(cpu_data_out),
		.cs(io_8253 & ~start), 
		.rd(rd), 
		.wr(wr),
		.clk0(CLK_2M), 
		.clk1(CLK_31250), 
		.clk2(out1),
		.out0(out0), 
		.out1(out1), 
		.out2(out2) 
		);

	wire	[7:0] i8255_data_out;	
	wire	[7:0] i8255_PA_I;
	wire	[7:0] i8255_PA_O;
	wire	[7:0] i8255_PB_I;
	wire	[7:0] i8255_PB_O;
	wire	[7:0] i8255_PC_I;
	wire	[7:0] i8255_PC_O;
		
i8255 i8255_1(
      .RESET(RESET),
      .CLK(CLK_CPU),
      .ENA(1'b1),
      .ADDR(cpu_addr[1:0]), 
      .DI(cpu_data_out),
      .DO(i8255_data_out),
      .CS_n(~io_8255),
      .RD_n(~rd),
      .WR_n(~wr),
      .PA_I(i8255_PA_I),
      .PA_O(i8255_PA_O),
      .PA_O_OE_n(),
      .PB_I(i8255_PB_I),
      .PB_O(i8255_PB_O),
      .PB_O_OE_n(),
      .PC_I(i8255_PC_I),
      .PC_O(i8255_PC_O),
      .PC_O_OE_n()
    );
		
keymatrix keymatrix(
		.RST_n(~RESET), 
		.PA(i8255_PA_O[3:0]),
		.PB(i8255_PB_I),
		.STALL(i8255_PA_O[4]),
		.PS2_KEY(PS2_KEY),
		.KEY_BANK(3'b000),
		.CKCPU(CLK_CPU)
    );		
		
// VGA
	wire [11:0] vga_addr;
	vga vga1(
		.CLK_50MHZ(CLK_50MHZ),
		.color(color),
		.RD_n(~rd),
      .WR_n(~wr),
		.VGA_RED(VGA_RED), 
		.VGA_GREEN(VGA_GREEN), 
		.VGA_BLUE(VGA_BLUE),
		.VGA_HSYNC(VGA_HSYNC), 
		.VGA_VSYNC(VGA_VSYNC),
		.VGA_ADDR(vga_addr), 
		.VGA_DATA(vram_data), 
		.BUS_REQ(busreq), 
		.BUS_ACK(busack)
		);

// MAIN RAM
	wire ram_select  = (( cpu_addr[15:15] == 1'b0 || cpu_addr[15:12] == 4'b1000) & mreq) & ~busack;
	wire ram_en, ram_we;
	wire [7:0] ram_data_out, ram_data_in;
	
	monrom mon_rom(
		.address(cpu_addr),
		.clock(CLK_50MHZ),
		.data(ram_data_in),
		.q(ram_data_out),
		.clken(ram_en),
		.wren(ram_we)
		);

	assign ram_en = ram_select;
	assign ram_we = wr;
	assign ram_data_in = cpu_data_out;

// VRAM
	wire vram_select  = ((cpu_addr[15:11] == 5'b11010) & mreq) | busack;
	wire [11:0] vram_addr;
	wire vram_rd, vram_wr;
	wire [7:0] vram_data, vram_data_in;
	
	ram2 ram2_2(
		.address(vram_addr),
		.clock(CLK_50MHZ),
		.data(vram_data_in),
		.q(vram_data),
		.clken(vram_select),
		.rden(vram_rd),
		.wren(vram_wr)
		);
	assign vram_data_in = (vram_select & wr) ? cpu_data_out : 8'hzz;

		
	assign vram_addr[11:0] = busack ? vga_addr[11:0] : cpu_addr[11:0];
	assign vram_rd = busack | rd;
	assign vram_wr = busack ? 1'b0 : wr;
// Memory
	assign cpu_data_in = 
								( io_e002 & rd ) ? {VGA_VSYNC, clk_count[24], 6'b0000000} :
								( io_8253 & rd ) ? i8253_data_out :
								( io_8255 & rd ) ? i8255_data_out :
								( io_e008 & rd ) ? {7'b0000000, clk_count[19]} :		// MUSIC���Ȃǂ�WAIT�ŏd�v
								(vram_select & rd) ? vram_data :
								(ram_select & rd) ? ram_data_out: 8'hzz;
	assign TP1	= speaker_enable & out0;
endmodule
