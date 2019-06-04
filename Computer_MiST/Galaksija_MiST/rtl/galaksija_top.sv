module galaksija_top(
    input vidclk,
	 input cpuclk,
	 input audclk,
    input reset_in,
	 input [7:0] key_code,
	 input key_strobe,
	 input key_pressed,
    input ps2_clk,
    input ps2_data,
	 output [7:0] audio,
	 input cass_in,
    output cass_out,
    output [7:0] video_dat,
    output video_hs,
    output video_vs,
	 output video_blank 
);

reg  [6:0] 	reset_cnt = 0;
wire 			cpu_resetn = reset_cnt[6];
reg [31:0] 	int_cnt = 0;

always @(posedge vidclk) begin
	if(reset_in == 0) 
		reset_cnt <= 0;
	else if(cpu_resetn == 0) 
		reset_cnt <= reset_cnt + 1;
	if (int_cnt==(25000000 / (50 * 2)))
		begin
			int_n <= 1'b0;		
			int_cnt <= 0;
		end
		else begin
			int_n <= 1'b1;		
			int_cnt <= int_cnt + 1;
		end
end

wire m1_n;
wire iorq_n;
wire rd_n;
wire wr_n;
wire rfsh_n;
wire halt_n;
wire busak_n;
reg int_n = 1'b1;
wire nmi_n;
wire busrq_n = 1'b1;
wire mreq_n;
wire [15:0] addr;
wire [7:0] odata;
reg [7:0] idata;
	
T80s #(
	.Mode(0),
	.T2Write(0),
	.IOWait(1))
cpu(
	.RESET_n(cpu_resetn), 
	.CLK_n(~cpuclk),
	.WAIT_n(1'b1),
	.INT_n(int_n),
	.NMI_n(nmi_n),
	.BUSRQ_n(busrq_n),
	.M1_n(m1_n),
	.MREQ_n(mreq_n),
	.IORQ_n(iorq_n),
	.RD_n(rd_n),
	.WR_n(wr_n),
	.RFSH_n(rfsh_n),
	.HALT_n(halt_n),
	.BUSAK_n(busak_n),
	.A(addr),
	.DI(idata),
	.DO(odata)
	);	
	
wire [7:0] 	rom1_out;
reg 			rd_rom1;
	
sprom #(//4k
	.init_file("./roms/ROM1.hex"),
	.widthad_a(12),
	.width_a(8))
rom1(
	.address(addr[11:0]),
	.clock(cpuclk & rd_rom1),
	.q(rom1_out)
	);
	
wire [7:0] 	rom2_out;
reg 			rd_rom2;
	
sprom #(//4k
	.init_file("./roms/ROM2.hex"),
	.widthad_a(12),
	.width_a(8))
rom2(
	.address(addr[11:0]),
	.clock(cpuclk & rd_rom2),
	.q(rom2_out)
	);
	

wire [7:0] 	rom3_out;
reg 			rd_rom3;
	
sprom #(//4k
	.init_file("./roms/galplus.hex"),
	.widthad_a(12),
	.width_a(8))
rom3(
	.address(addr[11:0]),
	.clock(cpuclk & rd_rom3),
	.q(rom3_out)
	);

reg 			rd_mram0, wr_mram0;	
wire 			cs_mram0 = ~addr[15] & ~addr[14];
wire 			we_mram0 = wr_mram0 & cs_mram0;
wire [7:0] 	mram0_out;

spram #(//2k
	.widthad_a(11),
	.width_a(8))
ram00(
	.address(addr[10:0]),
	.clock(cpuclk),
	.wren(we_mram0),
	.data(odata),
	.q(mram0_out)
	);

reg 			rd_mram1, wr_mram1;
wire 			cs_mram1 = ~addr[15] &  addr[14];
wire 			we_mram1 = wr_mram1 & cs_mram1;
wire [7:0] 	mram1_out;
	
spram #(//2k
	.widthad_a(11),
	.width_a(8))
ram01(
	.address(addr[10:0]),
	.clock(cpuclk),
	.wren(we_mram1),
	.data(odata),
	.q(mram1_out)
	);

reg 			rd_mram2, wr_mram2;	
wire 			cs_mram2 =  addr[15] & ~addr[14];
wire 			we_mram2 = wr_mram2 & cs_mram2;
wire [7:0] 	mram2_out;	
	
spram #(//16k
	.widthad_a(14),
	.width_a(8))
ram02(
	.address(addr[13:0]),
	.clock(cpuclk),
	.wren(we_mram2),
	.data(odata),
	.q(mram2_out)
	);

reg 			rd_mram3, wr_mram3;	
wire 			cs_mram3 =  addr[15] &  addr[14];
wire 			we_mram3 = wr_mram3 & cs_mram3;
wire [7:0] 	mram3_out;

spram #(//16k
	.widthad_a(14),
	.width_a(8))
ram03(
	.address(addr[13:0]),
	.clock(cpuclk),
	.wren(we_mram3),
	.data(odata),
	.q(mram3_out)
	);	

reg rd_vram;
reg wr_vram;
wire [7:0] vram_out;

galaksija_video#(
	.h_visible(10'd640),
	.h_front(10'd16),
	.h_sync(10'd96),
	.h_back(10'd48),
	.v_visible(10'd480),
	.v_front(10'd10),
	.v_sync(10'd2),
	.v_back(10'd33))
galaksija_video(
	.clk(vidclk),
	.resetn(reset_in),
	.vga_dat(video_dat),
	.vga_hsync(video_hs),
	.vga_vsync(video_vs),
	.vga_blank(video_blank),
	.rd_ram1(rd_vram),
	.wr_ram1(wr_vram),
	.ram1_out(vram_out),
	.addr(addr[10:0]),
	.data(odata)
	);
	
	reg wr_latch;

	always @(*)
	begin
		rd_rom1 = 1'b0;		
		rd_rom2 = 1'b0;
		rd_rom3 = 1'b0;
		rd_vram = 1'b0;
		rd_mram0 = 1'b0;
		rd_mram1 = 1'b0;
		rd_mram2 = 1'b0;
		rd_mram3 = 1'b0;
		wr_vram = 1'b0;
		wr_mram0 = 1'b0;
		wr_mram1 = 1'b0;
		wr_mram2 = 1'b0;
		wr_mram3 = 1'b0;
		rd_key = 1'b0;
		wr_latch = 1'b0;

		casex ({~wr_n,~rd_n,mreq_n,addr[15:0]})
			//$0000...$0FFF — ROM "A" or "1" – 4 KB contains bootstrap, core control and Galaksija BASIC interpreter code
			{3'b010,16'b0000xxxxxxxxxxxx}: begin idata = rom1_out; rd_rom1 = 1'b1; end
			//$1000...$1FFF — ROM "B" or "2" – 4 KB (optional) – additional Galaksija BASIC commands, assembler, machine code monitor, etc.
			{3'b010,16'b0001xxxxxxxxxxxx}: begin idata = rom2_out; rd_rom2 = 1'b1; end		
			//$2000...$27FF — keyboard and latch
			{3'b010,16'b00100xxxxxxxxxxx}: begin idata = key_out;  rd_key = 1'b1; end
			{3'b100,16'b00100xxxxxxxxxxx}: wr_latch= 1'b1;
			//$2800...$2FFF — RAM "C": 2 KB ($2800...$2BFF – Video RAM)
			{3'b010,16'b00101xxxxxxxxxxx}: begin idata = vram_out; rd_vram = 1'b1; end
			{3'b100,16'b00101xxxxxxxxxxx}: wr_vram= 1'b1;
			//$3000...$37FF — RAM "D": 2 KB
			{3'b010,16'b00110xxxxxxxxxxx}: begin idata = mram0_out; rd_mram0 = 1'b1; end
			{3'b100,16'b00110xxxxxxxxxxx}: wr_mram0= 1'b1;
			//$3800...$3FFF — RAM "E": 2 KB
			{3'b010,16'b00111xxxxxxxxxxx}: begin idata = mram1_out; rd_mram1 = 1'b1; end
			{3'b100,16'b00111xxxxxxxxxxx}: wr_mram1= 1'b1;
			//$4000...$7FFF — RAM IC9, IC10: 16 KB
			{3'b010,16'b01xxxxxxxxxxxxxx}: begin idata = mram2_out; rd_mram2 = 1'b1; end
			{3'b100,16'b01xxxxxxxxxxxxxx}: wr_mram2= 1'b1;
			//$8000...$BFFF — RAM IC11, IC12: 16 KB
			{3'b010,16'b10xxxxxxxxxxxxxx}: begin idata = mram3_out; rd_mram3 = 1'b1; end
			{3'b100,16'b10xxxxxxxxxxxxxx}: wr_mram3= 1'b1;
			//$E000...$FFFF — ROM "3" + "4" IC13: 8 KB – Graphic primitives in BASIC language, Full Screen Source Editor and soft scrolling
			{3'b010,16'b111xxxxxxxxxxxxx}: begin idata = rom3_out; rd_rom3 = 1'b1; end
			default : begin end
			endcase
	end
	
wire [7:0]key_out;
wire rd_key;
galaksija_keyboard galaksija_keyboard(
	.clk(vidclk),
	.addr(addr[5:0]),
	.reset(~reset_in),
   .key_code(key_code),
	.key_strobe     (key_strobe     ),
	.key_pressed    (key_pressed    ),
	.key_out(key_out),
	.rd_key(rd_key)
	);

wire PIN_A = (1'b1 & 1'b1 & wr_n);
wire [7:0]chan_A, chan_B, chan_C;
wire A02 = ~(C00 | PIN_A);
wire B02 = ~(C00 | addr[0]);
wire D02 = ~(addr[6] | iorq_n);
wire C00 = ~(D02 & m1_n);
assign audio = chan_A & chan_B & chan_C;

AY8912 AY8912(
   .CLK(vidclk),
	.CE(audclk),
   .RESET(~reset_in),
   .BDIR(A02),
   .BC(B02),
   .DI(odata),
   .DO(),//not used
   .CHANNEL_A(chan_A),
   .CHANNEL_B(chan_B),
   .CHANNEL_C(chan_C),
   .SEL(1'b1),//
	.IO_in(),//not used
	.IO_out()//not used
	);

endmodule
