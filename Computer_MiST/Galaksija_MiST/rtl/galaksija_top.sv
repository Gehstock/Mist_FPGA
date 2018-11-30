module galaksija_top(
    input sysclk,
	 input audclk,
    input reset_in,
	 input [10:0] ps2_key,
	 output [7:0] audio,
	 input cass_in,
    output cass_out,
    output [7:0] video_dat,
    output video_hs,
    output video_vs,
	 output video_blankn 
);

reg  [6:0] 	reset_cnt = 0;
wire 			cpu_resetn = reset_cnt[6];
reg [31:0] 	int_cnt = 0;

always @(posedge sysclk) begin
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
	.CLK_n(~sysclk),
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
	
sprom #(
	.init_file("./roms/ROM1.hex"),
	.widthad_a(12),
	.width_a(8))
rom1(
	.address(addr[11:0]),
	.clock(sysclk & rd_rom1),
	.q(rom1_out)
	);
	
wire [7:0] 	rom2_out;
reg 			rd_rom2;
	
sprom #(
	.init_file("./roms/ROM2.hex"),
	.widthad_a(12),
	.width_a(8))
rom2(
	.address(addr[11:0]),
	.clock(sysclk & rd_rom2),
	.q(rom2_out)
	);
	
/*//todo CS Signal
wire [7:0] 	rom3_out;
reg 			rd_rom3;
	
sprom #(
	.init_file("./roms/galplus.hex"),
	.widthad_a(12),
	.width_a(8))
rom3(
	.address(addr[11:0]),
	.clock(sysclk & rd_rom3),
	.q(rom3_out)
	);*/

reg 			rd_mram, wr_mram;	
wire 			cs_mram0 = ~addr[15] & ~addr[14];
wire 			we_mram0 = wr_mram & cs_mram0;
wire [7:0] 	mram0_out;

spram #(
	.widthad_a(14),
	.width_a(8))
ram00(
	.address(addr[13:0]),
	.clock(sysclk),
	.wren(we_mram0),
	.data(odata),
	.q(mram0_out)
	);

wire 			cs_mram1 = ~addr[15] &  addr[14];
wire 			we_mram1 = wr_mram & cs_mram1;
wire [7:0] 	mram1_out;
	
spram #(
	.widthad_a(14),
	.width_a(8))
ram01(
	.address(addr[13:0]),
	.clock(sysclk),
	.wren(we_mram1),
	.data(odata),
	.q(mram1_out)
	);

wire 			cs_mram2 =  addr[15] & ~addr[14];
wire 			we_mram2 = wr_mram & cs_mram2;
wire [7:0] 	mram2_out;	
	
spram #(
	.widthad_a(14),
	.width_a(8))
ram02(
	.address(addr[13:0]),
	.clock(sysclk),
	.wren(we_mram2),
	.data(odata),
	.q(mram2_out)
	);
	/*
wire 			cs_mram3 =  addr[15] &  addr[14];
wire 			we_mram3 = wr_mram & cs_mram3;
wire [7:0] 	mram3_out;

spram #(
	.widthad_a(14),
	.width_a(8))
ram03(
	.address(addr[13:0]),
	.clock(sysclk),
	.wren(we_mram3),
	.data(odata),
	.q(mram3_out)
	);*/	

reg rd_vram;
reg wr_vram;
wire [7:0] vram_out;

galaksija_video
 #(
  .h_visible(10'd640),
  .h_front(10'd16),
  .h_sync(10'd96),
  .h_back(10'd48),
  .v_visible(10'd480),
  .v_front(10'd10),
  .v_sync(10'd2),
  .v_back(10'd33)
 )
galaksija_video
 (
  .clk(sysclk),
  .resetn(reset_in),
  .vga_dat(video_dat),
  .vga_hsync(video_hs),
  .vga_vsync(video_vs),
  .vga_blankn(video_blankn),
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
		rd_vram = 1'b0;
		rd_mram = 1'b0;
		wr_vram = 1'b0;
		wr_mram = 1'b0;
		rd_key = 1'b0;
		wr_latch = 1'b0;

		casex ({~wr_n,~rd_n,mreq_n,addr[15:0]})
			// CS & RD Signals
			{3'b010,16'b0000xxxxxxxxxxxx}: begin idata = rom1_out; rd_rom1 = 1'b1; end         // 0x0000-0x0fff
			{3'b010,16'b0001xxxxxxxxxxxx}: begin idata = rom2_out; rd_rom2 = 1'b1; end         // 0x1000-0x1fff			
//			{3'b010,16'b0001xxxxxxxxxxxx}: begin idata = rom3_out; rd_rom3 = 1'b1; end         // todo ROM3 CS

			{3'b010,16'b00100xxxxxxxxxxx}: begin idata = key_out;  rd_key = 1'b1; end         // 0x2000-0x27ff

			{3'b010,16'b00101xxxxxxxxxxx}: begin idata = vram_out; rd_vram = 1'b1; end         // 0x2800-0x2fff
			{3'b010,16'b00110xxxxxxxxxxx}: begin idata = mram0_out; rd_mram = 1'b1; end         // 0x3000-0x37ff
			{3'b010,16'b00111xxxxxxxxxxx}: begin idata = mram0_out; rd_mram = 1'b1; end         // 0x3800-0x3fff
			{3'b010,16'b01xxxxxxxxxxxxxx}: begin idata = mram1_out; rd_mram = 1'b1; end         // 0x4000-0xffff
			{3'b010,16'b10xxxxxxxxxxxxxx}: begin idata = mram2_out; rd_mram = 1'b1; end         // 0x4000-0xffff
//			{3'b010,16'b11xxxxxxxxxxxxxx}: begin idata = mram3_out; rd_mram = 1'b1; end         // 0x4000-0xffff //not enough BRAM for this

			// WE Signals
			{3'b100,16'b00100xxxxxxxxxxx}: wr_latch= 1'b1; // 0x2000-0x27ff
			{3'b100,16'b00101xxxxxxxxxxx}: wr_vram= 1'b1; // 0x2800-0x2fff
			{3'b100,16'b00110xxxxxxxxxxx}: wr_mram= 1'b1; // 0x3000-0x37ff
			{3'b100,16'b00111xxxxxxxxxxx}: wr_mram= 1'b1; // 0x3000-0x37ff
			{3'b100,16'b01xxxxxxxxxxxxxx}: wr_mram= 1'b1;
			{3'b100,16'b10xxxxxxxxxxxxxx}: wr_mram= 1'b1;
			{3'b100,16'b11xxxxxxxxxxxxxx}: wr_mram= 1'b1;
		endcase
	end
	

wire [7:0]key_out;
reg keys[63:0];
reg rd_key;
integer num;

initial 
	begin
		for(num=0;num<63;num=num+1)
		begin
			keys[num] <= 0;
		end
	end

always @(posedge sysclk) begin	
	if (rd_key)
		begin
			key_out <= (keys[addr[5:0]]==1) ? 8'hfe : 8'hff;
			for (num=0;num<63;num=num+1) keys[num] = 1'b0;
		end			
		if(sysclk)
		begin
			for(num=0;num<63;num=num+1)
			begin
				keys[num] = 1'b0;
			end
				case (ps2_key[7:0])					
					//nix 00
					8'h1C : keys[8'd01] = 1'b1; // A
					8'h32 : keys[8'd02] = 1'b1; // B
					8'h21 : keys[8'd03] = 1'b1; // C
					8'h23 : keys[8'd04] = 1'b1; // D
					8'h24 : keys[8'd05] = 1'b1; // E
					8'h2B : keys[8'd06] = 1'b1; // F
					8'h34 : keys[8'd07] = 1'b1; // G
					8'h33 : keys[8'd08] = 1'b1; // H
					8'h43 : keys[8'd09] = 1'b1; // I
					8'h3B : keys[8'd10] = 1'b1; // J
					8'h42 : keys[8'd11] = 1'b1; // K
					8'h4B : keys[8'd12] = 1'b1; // L
					8'h3A : keys[8'd13] = 1'b1; // M
					8'h31 : keys[8'd14] = 1'b1; // N
					8'h44 : keys[8'd15] = 1'b1; // O
					8'h4D : keys[8'd16] = 1'b1; // P
					8'h15 : keys[8'd17] = 1'b1; // Q
					8'h2D : keys[8'd18] = 1'b1; // R
					8'h1B : keys[8'd19] = 1'b1; // S
					8'h2C : keys[8'd20] = 1'b1; // T
					8'h3C : keys[8'd21] = 1'b1; // U
					8'h2A : keys[8'd22] = 1'b1; // V
					8'h1D : keys[8'd23] = 1'b1; // W
					8'h22 : keys[8'd24] = 1'b1; // X
					8'h35 : keys[8'd25] = 1'b1; // Y
					8'h1A : keys[8'd26] = 1'b1; // Z
					//nix 27,28,30,31
					8'h66 : keys[8'd29] = 1'b1; // BACKSPACE
					8'h29 : keys[8'd31] = 1'b1; // SPACE				
					8'h45 : keys[8'd32] = 1'b1; // 0
					8'h16 : keys[8'd33] = 1'b1; // 1
					8'h1E : keys[8'd34] = 1'b1; // 2
					8'h26 : keys[8'd35] = 1'b1; // 3
					8'h25 : keys[8'd36] = 1'b1; // 4
					8'h2E : keys[8'd37] = 1'b1; // 5
					8'h36 : keys[8'd38] = 1'b1; // 6
					8'h3D : keys[8'd39] = 1'b1; // 7
					8'h3E : keys[8'd40] = 1'b1; // 8
					8'h46 : keys[8'd41] = 1'b1; // 9			
					//NUM Block
					8'h70 : keys[8'd32] = 1'b1; // 0
					8'h69 : keys[8'd33] = 1'b1; // 1
					8'h72 : keys[8'd34] = 1'b1; // 2
					8'h7A : keys[8'd35] = 1'b1; // 3
					8'h6B : keys[8'd36] = 1'b1; // 4
					8'h73 : keys[8'd37] = 1'b1; // 5
					8'h74 : keys[8'd38] = 1'b1; // 6
					8'h6C : keys[8'd39] = 1'b1; // 7
					8'h75 : keys[8'd40] = 1'b1; // 8
					8'h7D : keys[8'd41] = 1'b1; // 9	
					
				
					8'h4C : keys[8'd42] = 1'b1; // ; //todo "Ö" on german keyboard
					8'h7C : keys[8'd43] = 1'b1; // : //todo NUM block for now
					8'h41 : keys[8'd44] = 1'b1; // ,
					8'h55 : keys[8'd45] = 1'b1; // = ////todo "´" on german keyboard
					8'h49 : keys[8'd46] = 1'b1; // .
					8'h4A : keys[8'd47] = 1'b1; // /				
					8'h5A : keys[8'd48] = 1'b1; // ENTER
					8'h76 : keys[8'd49] = 1'b1; // ESC
					
					8'h52 : begin keys[8'd33] = 1'b1; keys[8'd53] = 1'b1; end // ! ////todo "Ä" on german keyboard
					8'h52 : begin keys[8'd34] = 1'b1; keys[8'd53] = 1'b1; end // "	////todo shift GALAKSIJA
					8'h12 : keys[8'd53] = 1'b1; // SHIFT L
					8'h59 : keys[8'd53] = 1'b1; // SHIFT R

					
					
					/*				
					8'h1C : keys[8'd01] = 1'b1; // a
					8'h32 : keys[8'd02] = 1'b1; // b
					8'h21 : keys[8'd03] = 1'b1; // c
					8'h23 : keys[8'd04] = 1'b1; // d
					8'h24 : keys[8'd05] = 1'b1; // e
					8'h2B : keys[8'd06] = 1'b1; // f
					8'h34 : keys[8'd07] = 1'b1; // g
					8'h33 : keys[8'd08] = 1'b1; // h
					8'h43 : keys[8'd09] = 1'b1; // i
					8'h3B : keys[8'd10] = 1'b1; // j
					8'h42 : keys[8'd11] = 1'b1; // k
					8'h4B : keys[8'd12] = 1'b1; // ,
					8'h3A : keys[8'd13] = 1'b1; // m
					8'h31 : keys[8'd14] = 1'b1; // n
					8'h44 : keys[8'd15] = 1'b1; // O
					8'h4D : keys[8'd16] = 1'b1; // p
					8'h15 : keys[8'd17] = 1'b1; // q
					8'h2D : keys[8'd18] = 1'b1; // r
					8'h1B : keys[8'd19] = 1'b1; // s
					8'h2C : keys[8'd20] = 1'b1; // t
					8'h3C : keys[8'd21] = 1'b1; // u
					8'h2A : keys[8'd22] = 1'b1; // v
					8'h1D : keys[8'd23] = 1'b1; // w
					8'h22 : keys[8'd24] = 1'b1; // x
					8'h35 : keys[8'd25] = 1'b1; // y
					8'h1A : keys[8'd26] = 1'b1; // z
*/	
				endcase
		end
	end	


endmodule
