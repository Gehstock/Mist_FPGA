
module MyVision_top
(
	input         clk_sys,
	input         clk_3m58,
	input         reset,
	
	///////////// CPU RAM Interface /////////////
	output [15:0] cpu_ram_a_o,
	output reg    cpu_ram_ce_n_o,
	output reg    cpu_ram_we_n_o,
	input   [7:0] cpu_ram_d_i,
	output  [7:0] cpu_ram_d_o,

	//////////// Controller Interface /////////////
	input [10:0]  ps2_key,
	input [31:0]  joy0,
	input [31:0]  joy1,

	////////////// AUDIO Interface //////////////
	output [9:0] audio,

	////////////// VIDEO Interface //////////////
	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,
	output reg    comp_sync_n_o,
	output reg    ce_pix,
	output  [7:0] rgb_r_o,
	output  [7:0] rgb_g_o,
	output  [7:0] rgb_b_o

);


reg nMEM;
reg nRD;
reg nWR;
reg nIRQ;
reg nINT;
reg nNMI;
reg nWAIT;

reg [15:0] cpu_addr;
reg [7:0] data_to_cpu;
reg [7:0] data_from_cpu;

cpu_z80 Z80CPU(
	.CLK_4M(clk_3m58),
	.nRESET(~reset),
	.SDA(cpu_addr),
	.SDD_IN(data_to_cpu),
	.SDD_OUT(data_from_cpu),
	.nIORQ(nIRQ),
	.nMREQ(nMEM),
	.nRD(nRD),
	.nWR(nWR),
	.nINT(nINT),
	.nNMI(nNMI),
	.nWAIT(nWAIT)
);

assign cpu_ram_we_n_o = (cpu_ram_a_o > 16'h7FFF && (~nMEM && ~nWR)) ? 1'b0 : 1'b1;
assign cpu_ram_ce_n_o = (~nMEM && !nRD) ? 1'b0 : 1'b1;
assign nWAIT = 1'b1;
assign nNMI = 1'b1;
assign cpu_ram_a_o = cpu_addr;
assign cpu_ram_d_o = data_from_cpu;
assign data_to_cpu = (cpu_addr[15:2] == 14'h3800 && ~nRD && ~nMEM) ? vdp_data_out :
                     (cpu_ram_a_o[7:0] == 8'h02 && ~nRD && ~nIRQ) ? ym_data_out :
                     cpu_ram_d_i;

///////////////////////////SOUND///////////////////////////


reg       clk_snd;
reg [7:0] ym_data_out;

always @(posedge clk_3m58) begin
	if(reset) clk_snd <= 1'b1;
	else clk_snd <= ~clk_snd;
end

ym2149 sound
(
	//Data BUS
	.I_DA(data_from_cpu),
	.O_DA(ym_data_out),
	.O_DA_OE_L(),
	//control
	.I_A9_L((cpu_ram_a_o[7:2] == 6'h00 && (~nWR || ~nRD) && ~nIRQ) ? 1'b0 : 1'b1),
	.I_A8(1'b1),
	.I_BDIR((cpu_ram_a_o[7:2] == 6'h00 && ~nWR && ~nIRQ) ? 1'b1 : 1'b0),
	.I_BC2((((cpu_ram_a_o[7:0] == 8'h01 && ~nWR) || (cpu_ram_a_o[7:0] == 8'h02 && ~nRD)) && ~nIRQ) ? 1'b1 : 1'b0),
	.I_BC1((cpu_ram_a_o[7:0] == 8'h02 && ~nRD && ~nIRQ) ? 1'b1 : 1'b0),
	.I_SEL_L(1'b1),
	.O_AUDIO(audio),
	//port a
	.I_IOA(keydata),
	.O_IOA(),
	.O_IOA_OE_L(),
	//port b
	.I_IOB(8'hFF),
	.O_IOB(key_column),
	.O_IOB_OE_L(),	
	.ENA(1'b1),
	.RESET_L(~reset),
	.CLK(clk_snd)
);

/////////////////////////// IO ///////////////////////////

reg [7:0] io_data;
reg [7:0] io_regs[8];
reg [7:0] FD_data;
reg       FD_buffer_flag;
reg [1:0] rd_sampler,wr_sampler;
reg [7:0] port_status;

always @(posedge clk_sys) begin
	rd_sampler = {rd_sampler[0],~(~nRD && ~nMEM)};
	wr_sampler = {wr_sampler[0],~(~nWR && ~nMEM)};
end

//Keyboard
wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];

always @(posedge clk_3m58) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code[7:0])
//Left Controller
			'hX16: btn_1     <= ~pressed; // 1
			'hX1E: btn_2     <= ~pressed; // 2
			'hX26: btn_3     <= ~pressed; // 3
			'hX25: btn_4     <= ~pressed; // 4
			'hX2E: btn_5     <= ~pressed; // 5
			'hX36: btn_6     <= ~pressed; // 6
			'hX3D: btn_7     <= ~pressed; // 7
			'hX3E: btn_8     <= ~pressed; // 8
			'hX46: btn_9     <= ~pressed; // 9
			'hX45: btn_10    <= ~pressed; // 0
			'hX4E: btn_11    <= ~pressed; // - => 11
			'hX55: btn_12    <= ~pressed; // = => 12
			'hX66: btn_13    <= ~pressed; // BackSpace => 13
			'hX5D: btn_14    <= ~pressed; // \ => 14

			'hX75: btn_up    <= ~pressed; //B
			'hX72: btn_down  <= ~pressed; //C
			'hX6B: btn_left  <= ~pressed; //A
			'hX74: btn_right <= ~pressed; //D
			'hX29: btn_fire  <= ~pressed; //Space <= E

			'hX1C: btn_1     <= ~pressed; // a
			'hX32: btn_2     <= ~pressed; // b
			'hX21: btn_3     <= ~pressed; // c
			'hX23: btn_4     <= ~pressed; // d
			'hX24: btn_5     <= ~pressed; // e
			'hX2B: btn_6     <= ~pressed; // f
			'hX34: btn_7     <= ~pressed; // g
			'hX33: btn_8     <= ~pressed; // h
			'hX43: btn_9     <= ~pressed; // i
			'hX3B: btn_10    <= ~pressed; // j
			'hX42: btn_11    <= ~pressed; // k
			'hX4B: btn_12    <= ~pressed; // l
			'hX3A: btn_13    <= ~pressed; // m
			'hX31: btn_14    <= ~pressed; // n

		endcase
	end
end

wire [7:0] key_row[4];
assign key_row[0] = { btn_1 , btn_5 , btn_9 , btn_down & ~joy0[2] , btn_13 , 3'b111 };
assign key_row[1] = { btn_4 , btn_8 , btn_12 , 1'b1 , btn_up & ~joy0[3] , 3'b111 };
assign key_row[2] = { btn_2 , btn_6 , btn_10 , btn_right & ~joy0[0] , btn_14 , 3'b111 };
assign key_row[3] = { btn_3 , btn_7 , btn_11 , btn_fire & ~joy0[4] , btn_left & ~joy0[1] , 3'b111 };

reg btn_1     = 1;
reg btn_2     = 1;
reg btn_3     = 1;
reg btn_4     = 1;
reg btn_5     = 1;
reg btn_6     = 1;
reg btn_7     = 1;
reg btn_8     = 1;
reg btn_9     = 1;
reg btn_10    = 1;
reg btn_11    = 1;
reg btn_12    = 1;
reg btn_13    = 1;
reg btn_14    = 1;

reg btn_up    = 1;
reg btn_down  = 1;
reg btn_left  = 1;
reg btn_right = 1;
reg btn_fire  = 1;


////////////////////////////PIA////////////////////////////

reg [7:0] ppi_dout, key_column;
reg [7:0] keydata;
reg [7:0] joydata;

assign keydata = 8'hFF & (key_column[7] ? 8'hFF : key_row[0]) & (key_column[6] ? 8'hFF : key_row[1]) & (key_column[5] ? 8'hFF : key_row[2]) & (key_column[4] ? 8'hFF : key_row[3]);

///////////////////////////VIDEO///////////////////////////
reg [7:0] R,G,B;

//  -----------------------------------------------------------------------------
//  -- TMS9928A Video Display Processor
//  -----------------------------------------------------------------------------
// VDP read and write signals
wire        vdp_wr;
wire        vdp_rd;
wire  [7:0] vdp_data_out;
reg         hsync_n,vsync_n;
reg   [3:0] col_o;

always @(posedge clk_sys) begin
	if(ce_10m7) begin
		vdp_wr <= 1'b0;
	end
	if(cpu_addr[15:2] == 14'h3800 && wr_sampler == 2'b10 && ~nMEM) vdp_wr <= 1'b1;
end
assign vdp_rd = (cpu_addr[15:2] == 14'h3800 && ~nRD && ~nMEM) ? 1'b1: 1'b0;  // Should we also check if IAQS is low?


reg ce_10m7 = 0;
reg ce_5m3 = 0;
always @(posedge clk_sys) begin
	reg [2:0] div;
	
	div <= div+1'd1;
	ce_10m7 <= !div[1:0];
	ce_5m3  <= !div[2:0];
end
assign ce_pix = ce_5m3;

vdp18_core vdp
(
	.clk_i(clk_sys),
	.clk_en_10m7_i(ce_10m7),
	.reset_n_i(~reset),
	.csr_n_i(~vdp_rd),
	.csw_n_i(~vdp_wr),
	.mode_i(cpu_addr[1]),
	.int_n_o(nINT),
	.cd_i(data_from_cpu),
	.cd_o(vdp_data_out),
	.vram_we_o(vram_we_o),
	.vram_a_o(vram_a_o),
	.vram_d_o(vram_d_o),
	.vram_d_i(vram_d_i),
	.col_o(col_o),
	.rgb_r_o(rgb_r_o),
	.rgb_g_o(rgb_g_o),
	.rgb_b_o(rgb_b_o),
	.hsync_n_o(hsync_n),
	.vsync_n_o(vsync_n),
	.blank_n_o(),
	.hblank_o(HBlank),
	.vblank_o(VBlank),
	.comp_sync_n_o(comp_sync_n_o)
	
);

assign HSync = ~hsync_n;
assign VSync = ~vsync_n;

reg [13:0] vram_a_o;
reg        vram_we_o;
reg  [7:0] vram_d_o;
reg  [7:0] vram_d_i;

spram #(14, 8) vram
(
	.clock(clk_sys),
	.address(vram_a_o),
	.wren(vram_we_o),
	.data(vram_d_o),
	.q(vram_d_i)
);


endmodule
