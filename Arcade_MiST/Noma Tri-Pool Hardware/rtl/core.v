
module core(
	input reset,
	input clk_sys,
	input [7:0] dsw1,
	input [7:0] dsw2,
	input [7:0] p0,
	input [7:0] p1,
	input [7:0] p2,
	input [7:0] p3,
	output [2:0] red,
	output [2:0] green,
	output [1:0] blue,
	output       hb,
	output       vb,
	output       hs,
	output       vs,
	output       ce_pix,
	output [9:0] sound,
  
	output [13:0] mcpu_rom1_addr,
	input [7:0] mcpu_rom1_data,
	output [13:0] mcpu_rom2_addr,
	input [7:0] mcpu_rom2_data,
	 
	input        ioctl_download,
	input [26:0] ioctl_addr,
	input [15:0] ioctl_dout,
	input        ioctl_wr
  // input [7:0]  encryption
);

wire [15:0] mcpu_ab;
wire  [7:0] mcpu_din;
wire  [7:0] mcpu_dout;
wire        mcpu_rd;
wire        mcpu_wr;
wire        mcpu_io;
wire        mcpu_m1;

wire [15:0] scpu_ab;
wire  [7:0] scpu_din;
wire  [7:0] scpu_dout;
wire        scpu_rd;
wire        scpu_wr;
wire        scpu_io;
wire        scpu_m1;


// enable signals
wire        scpu_io_en = scpu_io;
wire        mcpu_rom1_en;
wire        mcpu_rom2_en;
wire        mcpu_ram_en;
wire        mcpu_spram_en;
wire        mcpu_sndlatch_en;
wire        mcpu_dsw1_en;
wire        mcpu_dsw2_en;
wire        mcpu_in0_en;
wire        mcpu_in1_en;
wire        mcpu_in2_en;
wire        mcpu_in3_en;
wire        mcpu_flip_en;
wire        mcpu_pal_en;
wire        mcpu_vram_en;
wire        mcpu_cram_en;
wire        scpu_rom_en;
wire        scpu_ram_en;
wire        scpu_ay_data_en;
wire        scpu_ay_addr_en;

//wire [7:0] mcpu_rom1_data;
//wire [7:0] mcpu_rom2_data;
wire [7:0] mcpu_ram_data;
wire [7:0] mcpu_vdata;
reg  [7:0] mcpu_sndlatch;

wire [7:0] scpu_rom_data;
wire [7:0] scpu_ram_data;
reg        scpu_int;

wire [12:0] char_rom_addr;
wire  [7:0] char_data1;
wire  [7:0] char_data2;
wire [12:0] spr_rom_addr;
wire  [7:0] spr_data1;
wire  [7:0] spr_data2;

reg [3:0] ay_addr;
wire [7:0] ay_dout;

wire mcpu_vdata_en = mcpu_vram_en | mcpu_cram_en | mcpu_spram_en;

wire [7:0] decrypt_data_out;

assign mcpu_din =
  mcpu_in0_en   ? p0               :
  mcpu_in1_en   ? p1               :
  mcpu_in2_en   ? p2               :
  mcpu_in3_en   ? p3               :
  mcpu_dsw1_en  ? dsw1             :
  mcpu_dsw2_en  ? dsw2             :
  mcpu_rom1_en  ? decrypt_data_out :
  mcpu_rom2_en  ? mcpu_rom2_data   :
  mcpu_ram_en   ? mcpu_ram_data    :
  mcpu_vdata_en ? mcpu_vdata       :
  8'd0;

assign scpu_din =
  scpu_ram_en               ? scpu_ram_data :
  scpu_rom_en               ? scpu_rom_data :
  scpu_ay_data_en & scpu_rd ? ay_dout       :
  8'd0;

always @(posedge clk_sys) begin
  if (scpu_ay_addr_en) begin
    if (scpu_wr) ay_addr <= scpu_dout[3:0];
  end
  if (mcpu_sndlatch_en) begin
    mcpu_sndlatch <= mcpu_dout;
    scpu_int <= 1'b1;
  end
  else begin
    scpu_int <= 1'b0;
  end
end

decode decode(
  .mcpu_ab          ( mcpu_ab          ),
  .scpu_ab          ( scpu_ab          ),
  .scpu_io_en       ( scpu_io_en       ),
  .mcpu_rom1_en     ( mcpu_rom1_en     ),
  .mcpu_rom2_en     ( mcpu_rom2_en     ),
  .mcpu_ram_en      ( mcpu_ram_en      ),
  .mcpu_spram_en    ( mcpu_spram_en    ),
  .mcpu_sndlatch_en ( mcpu_sndlatch_en ),
  .mcpu_dsw1_en     ( mcpu_dsw1_en     ),
  .mcpu_dsw2_en     ( mcpu_dsw2_en     ),
  .mcpu_in0_en      ( mcpu_in0_en      ),
  .mcpu_in1_en      ( mcpu_in1_en      ),
  .mcpu_in2_en      ( mcpu_in2_en      ),
  .mcpu_in3_en      ( mcpu_in3_en      ),
  .mcpu_flip_en     ( mcpu_flip_en     ),
  .mcpu_pal_en      ( mcpu_pal_en      ),
  .mcpu_vram_en     ( mcpu_vram_en     ),
  .mcpu_cram_en     ( mcpu_cram_en     ),
  .scpu_rom_en      ( scpu_rom_en      ),
  .scpu_ram_en      ( scpu_ram_en      ),
  .scpu_ay_data_en  ( scpu_ay_data_en  ),
  .scpu_ay_addr_en  ( scpu_ay_addr_en  )
);

mcpu mcpu(
  .clk_sys     ( clk_sys     ),
  .reset       ( reset       ),
  .mcpu_din    ( mcpu_din    ),
  .mcpu_dout   ( mcpu_dout   ),
  .mcpu_ab     ( mcpu_ab     ),
  .mcpu_wr     ( mcpu_wr     ),
  .mcpu_rd     ( mcpu_rd     ),
  .mcpu_io     ( mcpu_io     ),
  .mcpu_m1     ( mcpu_m1     ),
  .vb          ( vb          )
);

scpu scpu(
  .clk_sys     ( clk_sys     ),
  .reset       ( reset       ),
  .scpu_din    ( scpu_din    ),
  .scpu_dout   ( scpu_dout   ),
  .scpu_ab     ( scpu_ab     ),
  .scpu_wr     ( scpu_wr     ),
  .scpu_rd     ( scpu_rd     ),
  .scpu_io     ( scpu_io     ),
  .scpu_m1     ( scpu_m1     ),
  .scpu_int    ( scpu_int    )
);

wire cen, cen_t;
clk_en #(16-1) jt49_clk_en(clk_sys, cen);
clk_en #(512) timer_clk_en(clk_sys, cen_t); // 512 seems not fast enough

reg [7:0] timer;
always @(posedge clk_sys)
  if (cen_t) timer <= timer + 1;

jt49 u_jt49(
  .rst_n  ( ~reset                       ),
  .clk    ( clk_sys                      ),
  .clk_en ( cen                          ),
  .addr   ( ay_addr                      ),
  .cs_n   ( ~scpu_ay_data_en             ),
  .wr_n   ( ~(scpu_ay_data_en & scpu_wr) ),
  .din    ( scpu_dout                    ),
  .sel    ( 1'b0                         ),
  .dout   ( ay_dout                      ),
  .sound  ( sound                        ),
  .IOA_in ( mcpu_sndlatch                ),
  .IOB_in ( timer[7:0]                   )
);

decrypt_mcpu decrypt_mcpu(
  .encryption ( 1'b0             ),
  .data_in    ( mcpu_rom1_data   ),
  .addr       ( mcpu_ab          ),
  .data_out   ( decrypt_data_out )
);

assign mcpu_rom1_addr = mcpu_ab[13:0];


//mcpu_rom1 mcpu_rom1(
//  .clk_sys        ( clk_sys        ),
//  .rom_data       ( mcpu_rom1_data ),
//  .cpu_ab         ( mcpu_ab        ),
//  .ioctl_download ( ioctl_download ),
//  .ioctl_addr     ( ioctl_addr     ),
//  .ioctl_dout     ( ioctl_dout     ),
//  .ioctl_wr       ( ioctl_wr       )
//);

assign mcpu_rom2_addr = mcpu_ab[13:0];

//mcpu_rom2 mcpu_rom2(
//  .clk_sys        ( clk_sys        ),
//  .rom_data       ( mcpu_rom2_data ),
//  .cpu_ab         ( mcpu_ab        ),
//  .ioctl_download ( ioctl_download ),
//  .ioctl_addr     ( ioctl_addr     ),
//  .ioctl_dout     ( ioctl_dout     ),
//  .ioctl_wr       ( ioctl_wr       )
//);

scpu_rom scpu_rom(
  .clk_sys        ( clk_sys        ),
  .rom_data       ( scpu_rom_data  ),
  .cpu_ab         ( scpu_ab        ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

ram #(13,8) mcpu_ram(
  .clk  ( clk_sys       ),
  .addr ( mcpu_ab[12:0] ),
  .din  ( mcpu_dout     ),
  .q    ( mcpu_ram_data ),
  .rd_n ( ~mcpu_rd      ),
  .wr_n ( ~mcpu_wr      ),
  .ce_n ( ~mcpu_ram_en  )
);

ram #(10,8) scpu_ram(
  .clk  ( clk_sys       ),
  .addr ( scpu_ab[9:0] ),
  .din  ( scpu_dout     ),
  .q    ( scpu_ram_data ),
  .rd_n ( ~scpu_rd      ),
  .wr_n ( ~scpu_wr      ),
  .ce_n ( ~scpu_ram_en  )
);

vdata u_vdata(
  .clk_sys        ( clk_sys        ),
  .char_rom_addr  ( char_rom_addr  ),
  .char_data1     ( char_data1     ),
  .char_data2     ( char_data2     ),
  .spr_rom_addr   ( spr_rom_addr   ),
  .spr_data1      ( spr_data1      ),
  .spr_data2      ( spr_data2      ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

video video(
  .reset       ( reset       ),
  .clk_sys     ( clk_sys     ),
  .hb          ( hb          ),
  .vb          ( vb          ),
  .hs          ( hs          ),
  .vs          ( vs          ),
  .ce_pix      ( ce_pix      ),

  .mcpu_ab     ( mcpu_ab     ),
  .mcpu_data   ( mcpu_dout   ),
  .mcpu_wr     ( mcpu_wr     ),
  .mcpu_rd     ( mcpu_rd     ),
  .mcpu_vdata  ( mcpu_vdata  ),

  .mcpu_pal_en   ( mcpu_pal_en   ),
  .mcpu_spram_en ( mcpu_spram_en ),
  .mcpu_vram_en  ( mcpu_vram_en  ),
  .mcpu_cram_en  ( mcpu_cram_en  ),
  .mcpu_flip_en  ( mcpu_flip_en  ),

  .char_rom_addr  ( char_rom_addr  ),
  .char_data1     ( char_data1     ),
  .char_data2     ( char_data2     ),
  .spr_rom_addr   ( spr_rom_addr   ),
  .spr_data1      ( spr_data1      ),
  .spr_data2      ( spr_data2      ),

  .red         ( red         ),
  .green       ( green       ),
  .blue        ( blue        )
);


endmodule
