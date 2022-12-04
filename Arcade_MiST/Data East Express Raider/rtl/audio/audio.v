
module audio(
  input         reset,
  input         clk_sys,
  input         ioctl_download,
  input  [26:0] ioctl_addr,
  input  [15:0] ioctl_dout,
  input         ioctl_wr,
  input         snd_write,
  input   [7:0] mcpu_dout,
  output signed [16:0] sound_mix,
  output        rom_cs,
  output [14:0] rom_addr,
  input   [7:0] rom_data
);

wire cen_e, cen_q, clk_e, clk_q;
clk_en #( 31    ) cpu_clk_e(clk_sys, cen_e, clk_e);
clk_en #( 31, 8 ) cpu_clk_q(clk_sys, cen_q, clk_q);


wire ym3526_irq;
wire [7:0] acpu_di;
wire [7:0] acpu_do;
wire [15:0] acpu_ab;
wire acpu_rw;
wire bs, ba;
wire n_irq = ym3526_irq;
wire n_firq = 1'b1;
wire n_nmi = ~snd_write;
wire avma;
wire busy;
wire lic;
wire [7:0] ym2203_do;
wire [7:0] ym3526_do;
wire cs1, cs2;
reg [7:0] ym2203_do2;


mc6809is u_acpu(
  .CLK      ( clk_sys  ),
  .D        ( acpu_di  ),
  .DOut     ( acpu_do  ),
  .ADDR     ( acpu_ab  ),
  .RnW      ( acpu_rw  ),
  .fallE_en ( cen_e    ),
  .fallQ_en ( cen_q    ),
  .BS       ( bs       ),
  .BA       ( ba       ),
  .nIRQ     ( n_irq    ),
  .nFIRQ    ( n_firq   ),
  .nNMI     ( n_nmi    ),
  .AVMA     ( avma     ),
  .BUSY     ( busy     ),
  .LIC      ( lic      ),
  .nHALT    ( 1'b1     ),
  .nRESET   ( ~reset   ),
  .nDMABREQ ( 1'b1     )
);

acpu_mem u_acpu_mem(
  .clk_sys        ( clk_sys        ),
  .cpu_cen        ( cen_q          ),
  .acpu_ab        ( acpu_ab        ),
  .din            ( acpu_do        ),
  .dout           ( acpu_di        ),
  .rw             ( acpu_rw        ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       ),
  .mcpu_dout      ( mcpu_dout      ),
  .snd_write      ( snd_write      ),
  .cs1            ( cs1            ),
  .cs2            ( cs2            ),
  .ym2203_data    ( ym2203_do      ),
  .ym3526_data    ( ym3526_do      ),
  .rom_cs         ( rom_cs         ),
  .rom_addr       ( rom_addr       ),
  .rom_data       ( rom_data       )
);

wire cen_6, cen_12;
wire clk_6, clk_12;

clk_en #( 31 ) m2h_en(clk_sys,  cen_6,  clk_6);
clk_en #( 15 ) m1h_en(clk_sys, cen_12, clk_12);

// all
assign sound_mix = {ym3526_snd[15], ym3526_snd[15:0]} + {ym2203_snd[15], ym2203_snd[15:0]} + ym2203_psg[9:0];

wire signed [15:0] ym2203_snd;
wire  [9:0] ym2203_psg;
wire signed [15:0] ym3526_snd;

wire wr1 = acpu_rw;

jt03 ym2203(
  .rst     ( reset       ),
  .clk     ( clk_sys     ),
  .cen     ( cen_6       ),
  .din     ( acpu_do     ),
  .addr    ( acpu_ab[0]  ),
  .cs_n    ( ~cs1        ),
  .wr_n    ( wr1         ),
  .dout    ( ym2203_do   ),
  .snd     ( ym2203_snd  ),
  .psg_snd ( ym2203_psg  )
);

reg old_cs2;
reg [7:0] ym3526_din;
reg ym3526_addr;
always @(posedge clk_sys) begin
  old_cs2 <= cs2;
  if (~old_cs2 & cs2) begin
    ym3526_din <= acpu_do;
    ym3526_addr <= acpu_ab[0];
  end
end

jtopl ym3526(
  .rst    ( reset       ),
  .clk    ( clk_sys     ),
  .cen    ( cen_12      ),
  .din    ( ym3526_din  ),
  .addr   ( ym3526_addr ),
  .cs_n   ( ~cs2        ),
  .wr_n   ( wr1         ),
  .dout   ( ym3526_do   ),
  .irq_n  ( ym3526_irq  ),
  .snd    ( ym3526_snd  )
);


endmodule
