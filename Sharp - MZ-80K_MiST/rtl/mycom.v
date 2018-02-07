

module mycom(CLK_50MHZ, BTN_NORTH,BTN_EAST,BTN_SOUTH, BTN_WEST,
				VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC, Pix_ce,
				PS2_CLK, PS2_DATA, Turbo,
				SW,LED,TP1);
	input		CLK_50MHZ;
	input		BTN_NORTH,BTN_EAST,BTN_SOUTH,BTN_WEST;
	input		PS2_CLK, PS2_DATA;
	input    Turbo;
	output	VGA_RED, VGA_GREEN, VGA_BLUE, VGA_HSYNC, VGA_VSYNC;
	output Pix_ce;
	input		[3:0] SW;
	output	[7:0] LED;
	output	TP1;
// �N���b�N�̐���
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
	assign CLK_CPU = Turbo ? clk_count[2] : clk_count[3];
//	assign CLK_CPU = clk_count[2];		// 6MHZ
//	assign CLK_CPU = clk_count[3];		// 3MHZ

// reset���H
	wire reset;
	reg reset1 = 1, reset2 = 1;
	always @( posedge CLK_CPU ) begin
		reset1 <= BTN_EAST;
		reset2 <= reset1;
	end
	assign reset = reset1 | reset2;
		
// Z80��WIRE���`
	wire	[15:0] cpu_addr;
	wire	[7:0] cpu_data_in, cpu_data_out;
	wire	mreq, iorq, rd, wr, busreq, busack, intack;
	wire	start, waitreq;

// I/O�̎��
wire [15:0]io_led,io_e000,io_e001,io_e002,io_8253,io_e008;
	assign	io_led = (cpu_addr[15:0] == 16'he300) & mreq;
	assign	io_e000 = (cpu_addr[15:0] == 16'he000) & mreq;
	assign	io_e001 = (cpu_addr[15:0] == 16'he001) & mreq;
	assign	io_e002 = (cpu_addr[15:0] == 16'he002) & mreq;
	assign	io_8253 = (cpu_addr[15:2] == 14'b11100000000001) & mreq;
	assign	io_e008 = (cpu_addr[15:0] == 16'he008) & mreq;
	wire	[7:0] io_switch = {BTN_NORTH,BTN_EAST,BTN_SOUTH,
						BTN_WEST,SW[3:0]};
	reg		[7:0] led_buf;
	reg		[7:0] sound_buf;
	reg		[3:0] key_no;
	reg				speaker_enable;
	always @(posedge CLK_CPU or posedge reset) begin
		if (reset) begin
			led_buf <= 0;
			sound_buf <= 0;
			key_no <= 0;
			speaker_enable <= 0;
		end else  begin
			if ( io_led  & wr ) begin
				led_buf <= cpu_data_out;
			end else if (io_e000 & wr ) begin
				key_no <= cpu_data_out[3:0];
			end else if (io_e008 & wr ) begin
				speaker_enable <= cpu_data_out[0];
			end
		end
	end
	assign LED = led_buf;

// Z80�̎��
	assign waitreq = start;
	wire	out0, out1, out2;
	fz80 z80(.data_in(cpu_data_in), .data_out(cpu_data_out),
		.reset_in(reset), .clk(CLK_CPU),
		.mreq(mreq), .iorq(iorq), .rd(rd), .wr(wr),
		.adr(cpu_addr), .waitreq(waitreq),
		.nmireq(0), .intreq(out2 & 0), .busreq(busreq), .busack_out(busack),
		.start(start));
// 8253�̎�� (CLK0=2M CLK1=31.25K CLK2=OUT1)
	wire	[7:0] i8253_data_out;
	i8253 i8253_1(.reset(reset), .clk(CLK_CPU), .addr(cpu_addr[1:0]), .data_out(i8253_data_out), .data_in(cpu_data_out),
						.cs(io_8253 & ~start), .rd(rd), .wr(wr),
						.clk0(CLK_2M), .clk1(CLK_31250), .clk2(out1),
						.out0(out0), .out1(out1), .out2(out2) );

// KEYBOARD�̎��
	wire [7:0] ps2_data;
	ps2 ps2_1(.clk(CLK_50MHZ), .reset(reset), .ps2_clk(PS2_CLK), .ps2_data(PS2_DATA), .cs(io_e001 & rd), .rd(rd), .addr(key_no), .data(ps2_data));

// MAIN RAM�̎��
	wire ram_select  = (( cpu_addr[15:15] == 1'b0 || cpu_addr[15:12] == 4'b1000) & mreq) & ~busack;
	wire ram_en, ram_we;
	wire [7:0] ram_data_out, ram_data_in;

	monrom monrom(.address(cpu_addr),.clock(CLK_50MHZ),.data(ram_data_in),
						.q(ram_data_out),.rden(ram_en),.wren(ram_we));
	assign ram_en = ram_select;
	assign ram_we = wr;
	assign ram_data_in = cpu_data_out;

// VRAM�̎��
	wire vram_select  = ((cpu_addr[15:11] == 5'b11010) & mreq) | busack;
	wire [11:0] vram_addr;
	wire vram_rd, vram_wr;
	wire [7:0] vram_data, vram_data_in;
	vram vram(.address(vram_addr),.clock(CLK_50MHZ),
					.data(vram_data_in),.q(vram_data),.rden(vram_select),.wren(vram_wr));
	assign vram_data_in = (vram_select & wr) ? cpu_data_out : 8'hzz;

// VGA�̎��
	wire [11:0] vga_addr;
	vga vga1(.CLK_50MHZ(CLK_50MHZ), .VGA_RED(VGA_RED), .VGA_GREEN(VGA_GREEN), .VGA_BLUE(VGA_BLUE),
			.VGA_HSYNC(VGA_HSYNC), .VGA_VSYNC(VGA_VSYNC), .Pix_ce(Pix_ce),
			.VGA_ADDR(vga_addr), .VGA_DATA(vram_data), .BUS_REQ(busreq), .BUS_ACK(busack));
	assign vram_addr[11:0] = busack ? vga_addr[11:0] : cpu_addr[11:0];
	assign vram_rd = busack | rd;
	assign vram_wr = busack ? 1'b0 : wr;
// Memory�A�N�Z�X
	assign cpu_data_in = ( io_led & rd ) ? io_switch :
						( io_e001 & rd ) ? ps2_data :
						( io_e002 & rd ) ? {VGA_VSYNC, clk_count[24], 6'b0000000} :
						( io_8253 & rd ) ? i8253_data_out :
						( io_e008 & rd ) ? {7'b0000000, clk_count[19]} :		// MUSIC���Ȃǂ�WAIT�ŏd�v
						(vram_select & rd) ? vram_data :
						(ram_select & rd) ? ram_data_out: 8'hzz;
	assign TP1	= speaker_enable & out0;
endmodule
