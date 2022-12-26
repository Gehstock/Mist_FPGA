
module audio(
  input         reset,
  input         clk_sys,
  input         sn1_wr,
  input         sn2_wr,
  input   [7:0] cpu_dout,
  output [15:0] sound_mix,
  output        sn1_rdy,
  output        sn2_rdy
);

wire clk_en;
wire [13:0] sn1_out;
wire [13:0] sn2_out;
reg   [7:0] sn_data;
reg sn1_wr_n;
reg sn2_wr_n;
reg sn1_ce_n;
reg sn2_ce_n;

assign sound_mix = sn1_out + sn2_out;

clk_en #(18) snd_clk_en(clk_sys, clk_en);


always @(posedge clk_sys) begin
  if (sn1_wr) sn1_ce_n <= 1'b0;
  if (sn2_wr) sn2_ce_n <= 1'b0;
  if (sn1_wr | sn2_wr) sn_data <= cpu_dout;
  if (clk_en) begin
    if (~sn1_ce_n) sn1_wr_n <= 1'b0;
    if (~sn2_ce_n) sn2_wr_n <= 1'b0;
    if (~sn1_wr_n) begin sn1_wr_n <= 1'b1; sn1_ce_n <= 1'b1; end
    if (~sn2_wr_n) begin sn2_wr_n <= 1'b1; sn2_ce_n <= 1'b1; end
  end
end

sn76489_audio sn1(
  .clk_i       ( clk_sys    ),
  .en_clk_psg_i( clk_en     ),
  .ce_n_i      ( sn1_ce_n   ),
  .wr_n_i      ( sn1_wr_n   ),
  .ready_o     ( sn1_rdy    ),
  .data_i      ( sn_data    ),
  .mix_audio_o ( sn1_out    )
);

//sn76489_top sn1(
//  .clock_i		( clk_sys    ),
//  .clock_en_i	( clk_en     ),
//  .res_n_i		( !reset		 ),
//  .ce_n_i		( sn1_ce_n   ),
//  .we_n_i		( sn1_wr_n   ),
//  .ready_o		( sn1_rdy    ),
//  .d_i			( sn_data    ),
//  .aout_o		( sn1_out    )
//  );

sn76489_audio sn2(
  .clk_i       ( clk_sys    ),
  .en_clk_psg_i( clk_en     ),
  .ce_n_i      ( sn2_ce_n   ),
  .wr_n_i      ( sn2_wr_n   ),
  .ready_o     ( sn2_rdy    ),
  .data_i      ( sn_data    ),
  .mix_audio_o ( sn2_out    )
);

//sn76489_top sn2(
//  .clock_i		( clk_sys    ),
//  .clock_en_i	( clk_en     ),
//  .res_n_i		( !reset		 ),
//  .ce_n_i		( sn2_ce_n   ),
//  .we_n_i		( sn2_wr_n   ),
//  .ready_o		( sn2_rdy    ),
//  .d_i			( sn_data    ),
//  .aout_o		( sn2_out    )
//  );

endmodule
