module Tankb_fpga(
	input CLK_18M,
	input CLK_6M,
	input RESET_n,
	output vid_r,
	output vid_g,
	output vid_b,
	output vid_hs,
	output vid_vs,
	output vid_cs,
	output vid_hb,
	output vid_vb,
	input [7:0]  P1,
	input [7:0]  P2,
	input [7:0]  DSW,
	output signed [15:0] audio
);

wire nRESET = (nRESET_PO & RESET_n);

//power-on reset
reg [5:0] reset_cnt = 0;
wire nRESET_PO = &reset_cnt;
always @(posedge clk) begin
    reset_cnt <= reset_cnt + !nRESET_PO;
end
//end power-on reset
//wire & reg setup
wire clk = CLK_18M;
wire PUR = nRESET;
wire A5_1_nq,A6_1_q,A6_1_nq,A6_2_q,A6_2_nq;
wire H1,H2,H4,H8,H16,H32,H64,H128,nH256;
wire A5_2_d=(~H64 & H32);
wire H256=~nH256;
wire B6_ca,C6_ca,E6_ca,D6_ca;
wire nHSYNC;
wire M6Hz=~A6_2_q;
wire nM6PRI=A6_1_nq;
wire D5_2_nq;
wire Phi=H4;
wire nH4_nH8=(~H4 & ~H8);
wire V1,V2,V4,V8,V16,V32,V64,V128,nVSYNC;
wire H256star,nH256star;
wire nCOMPSYNC=(nHSYNC & nVSYNC);
wire nINTACK,nIRQ,VBLANK;
wire F5_1_d=~(V128 & V64 & V32);
wire [7:0] L2_q,K2_d;
wire J2_q;
wire [5:0] J3_q;
wire RBG2;
wire E5_14=!(H4 & H2 & H1);
wire [3:0] D4_2_y;
wire C4_11=(D4_2_y[2] & D4_2_y[0]);
wire [3:0] B2_y,C2_y,B3_y;
wire [11:0] VA;
wire Phi2=Phi;
wire NMION = J4_q[7];
wire explode = J4_q[5];

wire fire = J4_q[4];
wire motor_hi = J4_q[3];
wire motor_on = J4_q[2];
wire nNMI = ~(VBLANK & NMION);

//end wire & reg setup 

assign vid_hs = ~nHSYNC;
assign vid_vs = ~nVSYNC;
assign vid_hb = H256star;
assign vid_vb = VBLANK;

////wires
wire nDIPSW,F4_o9,F4_o8,F4_o6,nIN1,nIN0,nWDR,nOUT1,nOUT0;
wire [7:0] rom1a_dout,rom1b_dout,rom1c_dout,rom1d_dout;
wire [7:0] ram1e1j_dout,ram1f1k_dout,ram1h1l_dout,vram_dout,bullet_dout;

wire DIP_Y,IN1_Y,IN0_Y;

//start of address decoding

wire nPhi2,nWO,C4_6,nROM;
assign nROM=!A[13];
wire [3:0] C3_1_y;

   ls139 icC3_1(
    .a(A[11]),
    .b(A[12]),
    .n_g(nROM),
    .y(C3_1_y)
  );

wire nROM_A1_cs = C3_1_y[0];
wire nROM_B1_cs = C3_1_y[1];
wire nROM_C1_cs = C3_1_y[2];
wire nROM_D1_cs = C3_1_y[3];


wire [3:0] C3_2_y,D4_1_y;
assign nPhi2=~Phi2;
wire E4_3=!(nROM & H2);
assign C4_6=(E4_3 & C3_2_y[1]);

   ls139 icC3_2(
    .a(r_w),
    .b(1'b0),
    .n_g(A[13]),
    .y(C3_2_y)
  );
  
assign nWO=C3_2_y[0];

   ls139 icD4_1(
    .a(A[10]),
    .b(A[11]),
    .n_g(C4_6),
    .y(D4_1_y)
  );

wire nVRAM=D4_1_y[2];
wire nWRAM1=D4_1_y[1];
wire nWRAM0=D4_1_y[0];

   ls42 icF4(
    .in({D4_1_y[3],nWO,A[4],A[3]}),
  	 .out({F4_o9,F4_o8,nDIPSW,F4_o6,nIN1,nIN0,nWDR,nINTACK,nOUT1,nOUT0})
   );

//end address decode

//start horizontal timer
   ls107 icA6_1(
    .clear(PUR), 
    .clk(~clk),
    .j(A6_2_nq),
    .k(PUR),
    .q(A6_1_q),
    .qnot(A6_1_nq)
   );

   ls107 icA6_2(
    .clear(PUR), 
    .clk(~clk),
    .j(A6_1_q),
    .k(PUR),
    .q(A6_2_q),
    .qnot(A6_2_nq)
   );

   ls74 icA5(
    .n_pre1(PUR),
    .n_pre2(PUR),
    .n_clr1(PUR),
    .n_clr2(H256),
    .clk1(M6Hz),
    .clk2(H16),
    .d1(A5_1_nq),
    .d2(A5_2_d),
    .q1(H1),
    .n_q1(A5_1_nq),
    .q2(),
    .n_q2(nHSYNC)
   );

   ls161 icB6(
    .n_clr(PUR),
    .clk(M6Hz),
    .din(4'b0),
    .enp(H1), 
    .ent(H1),
    .n_load(PUR),
    .q({H16,H8,H4,H2}),
    .rco(B6_ca)
   );

   ls161 icC6(
    .n_clr(PUR),
    .clk(M6Hz),
    .din(4'b0100),
    .enp(B6_ca), 
    .ent(B6_ca),
    .n_load(~C6_ca),
    .q({nH256,H128,H64,H32}),
    .rco(C6_ca)
   );
//end horizontal timer

//start vertical timer

   ls74 icD5(
    .n_pre1(PUR),
    .n_pre2(PUR),
    .n_clr1(PUR),
    .n_clr2(PUR),
    .clk1(H8),
    .clk2(nHSYNC),
    .d1(H256),
    .d2(D5_2_nq),
    .q1(H256star),
    .n_q1(nH256star),
    .q2(V1),
    .n_q2(D5_2_nq)
   );  

   ls161 icD6(
    .n_clr(PUR),
    .clk(nHSYNC),
    .din(4'b1100),
    .enp(V1), 
    .ent(V1),
    .n_load(~E6_ca),
    .q({V16,V8,V4,V2}),
    .rco(D6_ca)
   );

   ls161 icE6(
    .n_clr(PUR),
    .clk(nHSYNC),
    .din(4'b0111),
    .enp(D6_ca), 
    .ent(D6_ca),
    .n_load(~E6_ca),
    .q({nVSYNC,V128,V64,V32}),
    .rco(E6_ca)
   );

//end vertical timer
//vblank

   ls74 icF5(
    .n_pre1(PUR),
    .n_pre2(nINTACK),
    .n_clr1(PUR),
    .n_clr2(PUR),
    .clk1(V16),
    .clk2(V16),
    .d1(F5_1_d),
    .d2(1'b0),
    .q1(),
    .n_q1(VBLANK),
    .q2(nIRQ),
    .n_q2()
  );  

//end vblank
//start screen render 3

wire [7:0] dsp_din;

   ls273 icL2(
	.d(dsp_din),
	.clk(H4),
	.res(PUR),
	.q(L2_q)
   );

k3 k3(
	.clk(clk),
	.addr({L2_q,V4,V2,V1}),
	.data(K2_d)
);

   ls166 icJ2(
    .clk(M6Hz),
    .load(C4_11),
    .in(K2_d),
    .out(J2_q)
   );

//end of screen render 3
//start of screen render 4

   ls174 icJ3(
	.d(L2_q[7:2]),
	.clk(C4_11),
	.mr(PUR),
	.q(J3_q)
   );

wire vid_i;
l3 l3(
	.clk(clk),
	.addr({J3_q[5:0],E3_q,J2_q}),
	.data({vid_b,vid_g,vid_r,vid_i})
);

//end of screen render 4
//screen render 1a

   ls139 icD4_2(
    .a(H256),
    .b(H256star),
    .n_g(E5_14),
    .y(D4_2_y)
  );

//end of screen render 1a
//start of address buffers
wire C4_3=(1'b1 & H256);//nPhi2 - 1'b1

   ls157 icB2(
	.i0({4{1'b0}}),
	.i1({PUR,1'b0,V128,V64}),
	.n_e(C4_3),//1'b0
	.s(1'b1),
	.z(B2_y)
  );

assign VA[11]=B2_y[3];
assign VA[10]=B2_y[2];
assign VA[9]=B2_y[1];
assign VA[8]=B2_y[0];

   ls157 icC2(
	.i0({4{1'b0}}),
	.i1({V32,V16,V8,H128}),
	.n_e(C4_3),//
	.s(1'b1),
	.z(C2_y)
  );

assign VA[7]=C2_y[3];
assign VA[6]=C2_y[2];
assign VA[5]=C2_y[1];
assign VA[4]=C2_y[0];

   ls157 icB3(
	.i0({4{1'b0}}),
	.i1({H64,H32,H16,H8}),
	.n_e(1'b0),
	.s(1'b1),
	.z(B3_y)
  );

assign VA[3]=B3_y[3];
assign VA[2]=B3_y[2];
assign VA[1]=B3_y[1];
assign VA[0]=B3_y[0];

//end of address buffers
//start of video out

assign vid_cs = nCOMPSYNC;
  
//end of video out
//start of cpuclk
wire cpu_clken;
clock cpu_clk1(
    .clk(clk),
    .rst_n(nRESET),
	 .Phi2(Phi2),
    .cpu_clken(cpu_clken)
    );
//end of cpuclk
//CPU 6502
wire [15:0] A;
wire r_w;
wire [7:0] cpudata_in,cpudata_out;

T65 T65(
    .Res_n(nRESET),
    .Enable(cpu_clken),
    .Clk(clk),
    .Rdy(1),
    .IRQ_n(nIRQ),
    .NMI_n(nNMI),
    .R_W_n(r_w),
    .A(A),
    .DI(cpudata_in),
    .DO(cpudata_out)
  );	

//end of CPU 6502  
//start of ROMs

a1 a1(
	.clk(clk),
	.addr(A[10:0]),
	.data(rom1a_dout)
);

b1 b1(
	.clk(clk),
	.addr(A[10:0]),
	.data(rom1b_dout)
);

c1 c1(
	.clk(clk),
	.addr(A[10:0]),
	.data(rom1c_dout)
);

d1 d1(
	.clk(clk),
	.addr(A[10:0]),
	.data(rom1d_dout)
);

//end of ROMs
//start RAMs

	ram2114_DP icE1_J1( //a is cpu side, b is display side - WRAM0
	.data_a(cpudata_out),
	.data_b(),
	.addr_a(A[10:0]),
	.addr_b(VA[10:0]),
	.we_a(!nWO & !nWRAM0),
	.we_b(1'b0),
	.clk(clk),
	.q_a(ram1e1j_dout),
	.q_b(bullet_dout)
	);

   ram2114 icF1_K1( 
	.data(cpudata_out),
	.addr(A[10:0]),
	.we(!nWO & !nWRAM1),
	.clk(clk),
	.q(ram1f1k_dout) 
   );

	ram2114_DP icH1_L1( //a is cpu side, b is display side
	.data_a(cpudata_out),
	.data_b(),
	.addr_a(A[10:0]),
	.addr_b(VA[10:0]),
	.we_a(!nWO & !nVRAM),
	.we_b(1'b0),
	.clk(clk),
	.q_a(ram1h1l_dout),
	.q_b(vram_dout)
);

//end RAMs
//start of Address muxing

assign cpudata_in = !nROM_A1_cs ? rom1a_dout :
		     !nROM_B1_cs ? rom1b_dout :
		     !nROM_C1_cs ? rom1c_dout :
		     !nROM_D1_cs ? rom1d_dout :
		     !nWRAM0 ? ram1e1j_dout :
		     !nWRAM1 ? ram1f1k_dout :
		     !nVRAM ? ram1h1l_dout :
			 !nDIPSW ? {DIP_Y,7'b0000000} :
			 !nIN0 ? {IN0_Y,7'b0000000} :
			 !nIN1 ? {IN1_Y,7'b0000000} :
			 8'hFF;

wire nWRAM0_VA = (VA[11:4] == 8'b00000000);
wire nVRAM_VA = (VA[11:10] == 2'b10);

assign dsp_din = nWRAM0_VA ? bullet_dout :
				 nVRAM_VA ? vram_dout :
				 8'hFF;

//end of Address muxing
//bullet render 2

wire F3_out,E4_11,H3_ca;
wire [3:0] H3_sigma,H2_sigma;
assign F3_out=!(H256 & H2_sigma[3] & H2_sigma[2] & H2_sigma[1] & H2_sigma[0] & H3_sigma[3] & H3_sigma[2] & E4_11);

   ls283 icH3(
	.a({V8,V4,V2,V1}),
	.b(L2_q[3:0]),
	.c_in(1'b0),
	.sum(H3_sigma),
	.c_out(H3_ca)
  );

   ls283 icH2(
	.a({V128,V64,V32,V16}),
	.b(L2_q[7:4]),
	.c_in(H3_ca),
	.sum(H2_sigma),
	.c_out()
  );

wire D2_d,E3_1_nq,E3_q;
assign E4_11=!(H3_sigma[1] & H3_sigma[0]);

   ls74 icE3(
    .n_pre1(PUR),
    .n_pre2(PUR),
    .n_clr1(PUR),
    .n_clr2(nH256star),
    .clk1(H8),
    .clk2(nM6PRI),
    .d1(F3_out),
    .d2(D2_d),
    .q1(),
    .n_q1(E3_1_nq),
    .q2(E3_q),
    .n_q2()
  );  

wire E4_6,E5_out;
assign E4_6=!(H2 & H1);
assign E5_out=!(E3_1_nq & nH4_nH8 & E4_6);

//end of bullet render 2
//bullet render 1

wire [3:0] F2_q,E2_q;
wire F2_ca;
wire C5_3=(H256star & E5_out);

ls163 icF2(
	.n_clr(D4_2_y[2]),
	.clk(M6Hz),
	.din(L2_q[3:0]),
	.enp(1'b1),
	.ent(1'b1),
	.n_load(D4_2_y[3]),
	.q(F2_q),
	.rco(F2_ca)
  );

   ls163 icE2(
	.n_clr(D4_2_y[2]),
	.clk(M6Hz),
	.din(L2_q[7:4]),
	.enp(F2_ca),
	.ent(F2_ca),
	.n_load(D4_2_y[3]),
	.q(E2_q),
	.rco()
  );

   ram8125 icD2(
	.di(H256star),
	.addr({E2_q,F2_q}),
	.we(!M6Hz),
	.clk(clk),
	.cs(!C5_3),
	.q(D2_d)
  );

//end of bullet render 1
//start of peripherals

	ls251 icF7(
		.CBA(A[2:0]),
		.s(nDIPSW),
		.D(DSW),
		.Y(DIP_Y),
		.W()
	);
	
	ls251 icD7(
		.CBA(A[2:0]),
		.s(nIN1),
		.D(P2),
		.Y(IN1_Y),
		.W()
	);
	
	ls251 icE7(
		.CBA(A[2:0]),
		.s(nIN0),
		.D(P1),
		.Y(IN0_Y),
		.W()
	);	

wire [7:0] J4_q;

	ls259 icJ4(
		.A(A[2:0]),
		.nE(nOUT1),
		.nC(nRESET),
		.D(cpudata_out[0]),
		.Q(J4_q)
	);

//end of peripherals
//start of sound

wire [15:0] wav1_amp;
wire [15:0] wav2_amp;
wire [15:0] wav3_amp;

	sound #(52095,"rom/explode.txt") wav1
	(
		.clk(CLK_18M),
		.trigger(explode),//needs to be the explosion latch
		.RESET_n(RESET_n),
		.sound_out(wav1_amp)
	);

	sound #(21791,"rom/fire.txt") wav2
	(
		.clk(CLK_18M),
		.trigger(fire),//needs to be the fire latch
		.RESET_n(RESET_n),
		.sound_out(wav2_amp)
	);

EngineSound EngineSound(	
		.Clk_6(CLK_6M),
		.Reset(motor_on),
		.highrpm(motor_hi),
		.Motor(wav3_amp[14:9])
	);

// Audio mixer
// -----------
// - Combine discrete audio circuit and wave output, then invert
wire signed [15:0] sound_combined = 16'hFFFF - (wav1_amp + wav2_amp + wav3_amp);
assign audio = sound_combined; //can just use sound combined if no pause
	
//end of sound

endmodule 