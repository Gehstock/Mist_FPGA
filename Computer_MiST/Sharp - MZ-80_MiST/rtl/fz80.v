// Z80 CPU binary compatible soft core
// Copyright (C) 2004,2005 by Yasuo Kuwahara
// version 1.04

// This software is provided "AS IS", with NO WARRANTY.
// NON-COMMERCIAL USE ONLY

//`define DEBUG
//`define ICE
//`define M1

module fz80(data_in, reset_in, clk, adr, intreq, nmireq, busreq, start,
mreq, iorq, rd, wr, data_out, busack_out, intack_out, mr, 
`ifdef M1
	m1, radr, nmiack_out,
`endif
`ifdef ICE
	ice_enable, sclk, sdata,
`endif
	waitreq
);
`ifdef M1
	output m1, nmiack_out;
	output [15:0] radr;
`endif
`ifdef ICE
	input sclk, ice_enable;
	output sdata;
`endif
	input [7:0] data_in;
	input reset_in, clk, intreq, nmireq, busreq, waitreq;
	output start, mreq, iorq, rd, wr, busack_out, intack_out, mr;
	output [7:0] data_out;
	output [15:0] adr;
	wire [7:0] q_f;
	wire [7:0] q_a, q_b, q_c, q_d, q_e, q_h, q_l, q_sph, q_spl, q_pch, q_pcl, q_adrh, q_adrl, q_r, q_i, q_data;
	reg sel_af, sel_exx;
	wire g_if, g_imm2, g_mr1, g_mr2, g_disp, g_mw1, g_mw2, g_in, g_out;
	wire sgate;
	wire s_if, s_if2, s_imm1, s_imm2, s_mr1, s_mr2, s_disp, s_iack, s_mw1, s_mw2, s_in, s_out;
	wire [1:0] intmode;
	wire eschalt;
	wire icb, idd, ied, ifd;
	wire [7:0] inst_reg;
	wire [7:0] q_f_out;
	wire [7:0] d_f;
	wire cond, cond2;
`ifdef M1
	wire [15:0] radr = { q_i, q_r };
`endif
//
	function [3:0] decode2;
		input [1:0] a;
		begin
			case (a) 
				2'h0: decode2 = 4'b0001;
				2'h1: decode2 = 4'b0010;
				2'h2: decode2 = 4'b0100;
				2'h3: decode2 = 4'b1000;
			endcase
		end
	endfunction
	function [7:0] decode3;
		input [2:0] a;
		begin
			case (a) 
				3'h0: decode3 = 8'b00000001;
				3'h1: decode3 = 8'b00000010;
				3'h2: decode3 = 8'b00000100;
				3'h3: decode3 = 8'b00001000;
				3'h4: decode3 = 8'b00010000;
				3'h5: decode3 = 8'b00100000;
				3'h6: decode3 = 8'b01000000;
				3'h7: decode3 = 8'b10000000;
			endcase
		end
	endfunction
	function [7:0] select0;
		input [1:0] sel;
		input [15:0] a;
		begin
			case (sel)
				3'h1: select0 = a[15:8];
				3'h2: select0 = a[7:0];
				default: select0 = 8'b00000000;
			endcase
		end
	endfunction
	function [3:0] select1h;
		input [3:0] sel;
		input [59:0] a;
		begin
			case (sel) 
				default: select1h = a[59:56];
				4'h1: select1h = a[55:52];
				4'h2: select1h = a[51:48];
				4'h3: select1h = a[47:44];
				4'h4: select1h = a[43:40];
				4'h5: select1h = a[39:36];
				4'h6: select1h = a[35:32];
				4'h7: select1h = a[31:28];
				4'h8: select1h = a[27:24];
				4'h9: select1h = a[23:20];
				4'ha: select1h = a[19:16];
				4'hb: select1h = a[15:12];
				4'hc: select1h = a[11:8];
				4'hd: select1h = a[7:4];
				4'hf: select1h = a[3:0];
			endcase
		end
	endfunction
	function [3:0] select1l;
		input [3:0] sel;
		input [63:0] a;
		begin
			case (sel) 
				4'h0: select1l = a[63:60];
				4'h1: select1l = a[59:56];
				4'h2: select1l = a[55:52];
				4'h3: select1l = a[51:48];
				4'h4: select1l = a[47:44];
				4'h5: select1l = a[43:40];
				4'h6: select1l = a[39:36];
				4'h7: select1l = a[35:32];
				4'h8: select1l = a[31:28];
				4'h9: select1l = a[27:24];
				4'ha: select1l = a[23:20];
				4'hb: select1l = a[19:16];
				4'hc: select1l = a[15:12];
				4'hd: select1l = a[11:8];
				4'he: select1l = a[7:4];
				4'hf: select1l = a[3:0];
			endcase
		end
	endfunction
	function [15:0] select2;
		input [2:0] sel;
		input [95:0] a;
		begin
			case (sel)
				3'h0: select2 = a[95:80];
				3'h1: select2 = a[79:64];
				3'h2: select2 = a[63:48];
				3'h4: select2 = a[47:32];
				3'h5: select2 = a[31:16];
				default: select2 = a[15:0];
			endcase
		end
	endfunction
	function [7:0] select3;
		input [1:0] sel;
		input [15:0] a;
		begin
			case (sel)
				2'h1: select3 = a[15:8];
				2'h2: select3 = a[7:0];
				default: select3 = 8'b00000000;
			endcase
		end
	endfunction
	function [7:0] selectah;
		input [2:0] sel;
		input [63:0] a;
		begin
			case (sel)
				3'h1: selectah = a[63:56];
				3'h2: selectah = a[55:48];
				3'h3: selectah = a[47:40];
				3'h4: selectah = a[39:32];
				3'h5: selectah = a[31:24];
				3'h6: selectah = a[23:16];
				3'h7: selectah = a[15:8];
				default: selectah = a[7:0];
			endcase
		end
	endfunction
	function [7:0] selectal;
		input [2:0] sel;
		input [47:0] a;
		begin
			case (sel)
				3'h1: selectal = a[47:40];
				3'h4: selectal = a[39:32];
				3'h5: selectal = a[31:24];
				3'h6: selectal = a[23:16];
				3'h7: selectal = a[15:8];
				default: selectal = a[7:0];
			endcase
		end
	endfunction
	function [7:0] selectf;
		input [1:0] sel;
		input [31:0] a;
		begin
			case (sel) 
				2'h0: selectf = a[31:24];
				2'h1: selectf = a[23:16];
				2'h2: selectf = a[15:8];
				2'h3: selectf = a[7:0];
			endcase
		end
	endfunction
`ifdef ICE
	parameter INST_COUNT_TARGET = 0;
	reg [6:0] rs_count = 0;
	reg [5:0] rs_timing = 0;
	reg ice_wait = 0, sclk1 = 0, sclk2 = 0;
	reg [7:0] inst_count = 0;
	wire [7:0] ice_data_tmp;
	assign ice_data_tmp = rd ? data_in : data_out;
	wire [111:0] sdata_sel = { 2'b00, g_if, mr, mreq, iorq, rd, wr, ice_data_tmp, adr, q_f_out, q_a, q_h, q_l, q_d, q_e, q_b, q_c, q_pch, q_pcl };
	wire sdata = sdata_sel[rs_count];
	wire waitreq1 = waitreq | start | ice_wait & inst_count == INST_COUNT_TARGET;
	always @(posedge clk) begin
		sclk1 <= sclk;
		sclk2 <= sclk1;
		if (sclk1 ^ sclk2) begin
			if (rs_count == 111) ice_wait <= 0;
			rs_count <= rs_count + 1;
		end
		else if (sclk2) begin
			rs_timing <= rs_timing + 1;
			if (rs_timing == 31) rs_count <= 0;
		end
		else rs_timing <= 0;
		if (start & ice_enable) ice_wait <= 1;
		if (s_if & ~s_if2 & inst_count != INST_COUNT_TARGET) 
			inst_count <= inst_count + 1;
	end
`else
	wire waitreq1 = waitreq;
`endif
// instruction decoder
	wire intack;
	wire int1 = intmode == 2'b10 & intack;
	wire [7:0] data = data_in | { 8 { int1 } };
	wire [7:0] i = g_if ? data : inst_reg;
	wire i0 = ~icb & ~ied;
	wire [3:0] ih = decode2(i[7:6]);
	wire [7:0] im = decode3(i[5:3]);
	wire [7:0] il = decode3(i[2:0]);
	// 8-bit load group
	wire i_ldrr = i0 & ih[1] & ~im[6] & ~il[6];
	wire i_ldrn = i0 & ih[0] & ~im[6] & il[6];
	wire i_ldrhl = i0 & ih[1] & ~im[6] & il[6];
	wire i_ldhlr = i0 & ih[1] & im[6] & ~il[6];
	wire i_ldhln = i0 & ih[0] & im[6] & il[6];
	wire i_ldabc = i0 & ih[0] & im[1] & il[2];
	wire i_ldade = i0 & ih[0] & im[3] & il[2];
	wire i_ldann = i0 & ih[0] & im[7] & il[2];
	wire i_ldbca = i0 & ih[0] & im[0] & il[2];
	wire i_lddea = i0 & ih[0] & im[2] & il[2];
	wire i_ldnna = i0 & ih[0] & im[6] & il[2];
	wire i_ldai = ied & ih[1] & im[2] & il[7];
	wire i_ldar = ied & ih[1] & im[3] & il[7];
	wire i_ldia = ied & ih[1] & im[0] & il[7];
	wire i_ldra = ied & ih[1] & im[1] & il[7];
	wire ldair = i_ldai | i_ldar;
	// 16-bit load group
	wire i_ldddnn = i0 & ih[0] & ~i[3] & il[1];
	wire i_ldhl_nn = i0 & ih[0] & im[5] & il[2];
	wire i_lddd_nn = ied & ih[1] & i[3] & il[3];
	wire i_ldnnhl = i0 & ih[0] & im[4] & il[2];
	wire i_ldnndd = ied & ih[1] & ~i[3] & il[3];
	wire i_ldsphl = i0 & ih[3] & im[7] & il[1];
	wire i_push = i0 & ih[3] & ~i[3] & il[5];
	wire i_pop = i0 & ih[3] & ~i[3] & il[1];
	// exchange, block
	wire i_exdehl = i0 & ih[3] & im[5] & il[3];
	wire i_exafaf = i0 & ih[0] & im[1] & il[0];
	wire i_exx = i0 & ih[3] & im[3] & il[1];
	wire i_exsphl = i0 & ih[3] & im[4] & il[3];
	wire i_ldblock = ied & ih[2] & i[5] & il[0];
	wire i_cpblock = ied & ih[2] & i[5] & il[1];
	// 8-bit arithmetic & logical
	wire al = i0 & (ih[2] | ih[3] & il[6]);
	wire al_r = i0 & ih[2] & ~il[6];
	wire al_n = i0 & ih[3] & il[6];
	wire al_hl = i0 & ih[2] & il[6];
	wire al_r_notcp = al_r & ~im[7];
	wire al_n_notcp = al_n & ~im[7];
	wire al_hl_notcp = al_hl & ~im[7];
	wire arith8_notcp = al & ~i[5];
	wire i_cp = al & im[7];
	wire arith8 = arith8_notcp | i_cp;
	wire logica = al & i[5] & (~i[4] | ~i[3]);
	wire i_and = logica & im[4];
	wire i_xor = logica & im[5];
	wire i_or = logica & im[6];
	wire incdec8 = i0 & ih[0] & i[2] & ~i[1];
	wire dec8 = incdec8 & i[0];
	wire incdec_hl = incdec8 & im[6];
	// gen. arithmetic & CPU control
	wire i_daa = i0 & ih[0] & im[4] & il[7];
	wire i_cpl = i0 & ih[0] & im[5] & il[7];
	wire i_neg = ied & ih[1] & im[0] & il[4];
	wire i_ccf = i0 & ih[0] & im[7] & il[7];
	wire i_scf = i0 & ih[0] & im[6] & il[7];
	wire i_halt = i0 & ih[1] & im[6] & il[6];
	wire i_eidi = i0 & ih[3] & i[5] & i[4] & il[3];
	wire i_im = ied & ih[1] & ~i[5] & il[6];
	// 16-bit arithmetic
	wire add16 = i0 & ih[0] & i[3] & il[1];
	wire arith16 = ied & ih[1] & il[2];
	wire i_c16 = add16 | arith16;
	wire i_incdec16 = i0 & ih[0] & il[3];
	// rotate & shift
	wire i_rotate1 = i0 & ih[0] & ~i[5] & il[7];
	wire i_rs_r = icb & ih[0] & ~il[6];
	wire i_rs_hl = icb & ih[0] & il[6];
	wire i_rotate2 = icb & ih[0] & ~i[5];
	wire rotate = i_rotate1 | i_rotate2;
	wire shift = icb & ih[0] & i[5];
	wire rs = rotate | shift;
	wire i_rd = ied & ih[1] & i[5] & ~i[4] & il[7];
	wire i_rld = i_rd & i[3];
	wire i_rrd = i_rd & ~i[3];
	wire l = rs & ~i[3];
	wire r = rs & i[3];
	// bit/set/res
	wire i_bit_r = icb & ih[1] & ~il[6];
	wire i_bit_hl = icb & ih[1] & il[6];
	wire i_setres_r = icb & i[7] & ~il[6];
	wire i_setres_hl = icb & i[7] & il[6];
	wire ibit = icb & ih[1];
	wire set = icb & ih[3];
	wire res = icb & ih[2];
	// jump
	wire i_jpnn = i0 & ih[3] & im[0] & il[3];
	wire i_jpccnn = i0 & ih[3] & il[2];
	wire i_jr = i0 & ih[0] & im[3] & il[0];
	wire i_jrcc = i0 & ih[0] & i[5] & il[0];
	wire i_jphl = i0 & ih[3] & im[5] & il[1];
	wire i_djnz = i0 & ih[0] & im[2] & il[0];
	// call/return
	wire i_call = i0 & ih[3] & im[1] & il[5];
	wire i_callcc = i0 & ih[3] & il[4];
	wire i_ret = i0 & ih[3] & im[1] & il[1];
	wire i_retcc = i0 & ih[3] & il[0];
	wire retin = ied & ih[1] & (im[1] | im[0]) & il[5];
	wire i_rst = i0 & ih[3] & il[7];
	// I/O
	wire i_inan = i0 & ih[3] & im[3] & il[3];
	wire i_inrc = ied & ih[1] & il[0];
	wire i_outna = ih[3] & im[2] & il[3];
	wire i_outcr = ied & ih[1] & il[1];
	wire i_ioblock = ied & ih[2] & i[5] & ~i[2] & i[1];
	wire i_inblock = i_ioblock & ~i[0];
	wire i_outblock = i_ioblock & i[0];
	// bus cycle decoder
	wire nmiack, g_iack;
	wire imm1 = i_ldrn | i_ldhln | al_n | i_inan | i_outna | i_jr | i_jrcc | i_djnz;
	wire imm2 = i_ldddnn | i_ldann | i_ldnna | i_ldhl_nn | i_ldnnhl | i_ldnndd | i_lddd_nn
		| i_jpnn | i_jpccnn | i_call | i_callcc;
	wire mr1 = i_ldrhl | i_ldabc | i_ldade | i_ldann | i_ldblock | i_cpblock | al_hl | incdec_hl
		| i_rs_hl | i_rd | i_bit_hl | i_setres_hl | i_outblock;
	wire mr2 = i_ldhl_nn | i_lddd_nn | i_pop | i_exsphl
		| i_ret | i_retcc & cond | retin
		| intmode == 2'b11 & intack;
	wire mw1 = i_ldhlr | i_ldbca | i_lddea | i_ldnna | i_ldhln | i_ldblock | incdec_hl
		| i_rs_hl | i_rd | i_setres_hl | i_inblock;
	wire mw2 = i_ldnnhl | i_ldnndd | i_exsphl | i_push | i_call | i_callcc & cond | i_rst 
		| intmode == 2'b11 & intack | nmiack;
	wire disp = (idd | ifd) & (mr1 | mw1);
	wire i_in = i_inan | i_inrc | i_inblock;
	wire i_out = i_outna | i_outcr | i_outblock;
	//
	wire mr = g_mr1 | g_mr2; // for debug
	wire intack_out = (g_if | g_iack) & intack;
	`ifdef M1
	wire nmiack_out = g_iack & nmiack;
	`endif
	// load
	wire tmp0 = s_if & (i_rs_r | i_setres_r);
	wire tmp1 = s_if & (i_ldrr | incdec8) | s_imm1 & i_ldrn | s_mr1 & i_ldrhl | s_in & i_inrc;
	wire load_a = tmp1 & im[7]
		| tmp0 & il[7]
		| s_mr1 & (i_ldabc | i_ldade | i_ldann | al_hl_notcp)
		| s_mr2 & i_pop & im[6]
		| s_if & (ldair | al_r_notcp | i_daa | i_cpl | i_neg | i_rotate1)
		| s_imm1 & al_n_notcp
		| s_mw1 & i_rd
		| s_in & i_inan;
	wire load_f = s_mr1 & i_pop & im[6];
	wire load_b = tmp1 & im[0]
		| tmp0 & il[0]
		| s_imm2 & i_ldddnn & im[0]
		| s_mr2 & i_lddd_nn & im[1]
		| s_mr2 & i_pop & im[0]
		| s_imm1 & i_djnz;
	wire load_c = tmp1 & im[1]
		| tmp0 & il[1]
		| s_imm1 & i_ldddnn & im[0]
		| s_mr1 & i_lddd_nn & im[1]
		| s_mr1 & i_pop & im[0];
	wire load_d = tmp1 & im[2]
		| tmp0 & il[2]
		| s_imm2 & i_ldddnn & im[2]
		| s_mr2 & i_lddd_nn & im[3]
		| s_mr2 & i_pop & im[2];
	wire load_e = tmp1 & im[3]
		| tmp0 & il[3]
		| s_imm1 & i_ldddnn & im[2]
		| s_mr1 & i_lddd_nn & im[3]
		| s_mr1 & i_pop & im[2];
	wire load_h = tmp1 & im[4]
		| tmp0 & il[4]
		| s_imm2 & i_ldddnn & im[4]
		| s_mr2 & i_ldhl_nn
		| s_mr2 & i_lddd_nn & im[5]
		| s_mr2 & i_pop & im[4]
		| s_if & i_c16;
	wire load_l = tmp1 & im[5]
		| tmp0 & il[5]
		| s_imm1 & i_ldddnn & im[4]
		| s_mr1 & i_ldhl_nn
		| s_mr1 & i_lddd_nn & im[5]
		| s_mr1 & i_pop & im[4];
	wire tmp_adr = i_ldann | i_ldnna | i_ldhl_nn | i_lddd_nn | i_ldnnhl | i_ldnndd | i_call | i_callcc | i_inan | i_outna;
	wire load_adrh = s_mr2 & i_exsphl | s_imm2 & tmp_adr;
	wire load_adrl = s_mr1 & i_exsphl | s_imm1 & tmp_adr | s_iack;
	wire load_r = s_if & i_ldra;
	wire load_i = s_if & i_ldia;
	wire loadex = s_if & i_exdehl;
	wire tmp2 = s_imm2 & (i_jpnn | i_jpccnn & cond);
	wire load_pch = tmp2
		| s_mr2 & (i_ret | i_retcc | retin | intack);
	wire load_pcl = tmp2
		| s_mr1 & (i_ret | i_retcc | retin | intack);
	wire load_sph = s_imm2 & i_ldddnn & im[6]
		| s_mr2 & i_lddd_nn & im[7];
	wire load_spl = s_imm1 & i_ldddnn & im[6]
		| s_mr1 & i_lddd_nn & im[7];
	wire load_data = s_if & (i_rst | i_outcr)
		| s_mr1 & (i_ldblock | incdec_hl | i_rd | i_rs_hl | i_setres_hl | i_outblock)
		| s_imm1 & (i_ldhln | i_jpnn | i_jpccnn)
		| s_in & i_inblock;
	wire loada_bc = s_if & (i_ldblock | i_cpblock | i_incdec16 & ~i[5] & ~i[4]) 
		| s_in & i_inblock | s_mr1 & i_outblock;
	wire loada_de = s_if & (i_exdehl | (i_incdec16 & ~i[5] & i[4]))
		| s_mw1 & i_ldblock;
	wire loada_l = s_if & i_c16;
	wire loada_hl = s_if & i_incdec16 & i[5] & ~i[4]
		| s_mr1 & (i_ldblock | i_cpblock)
        | s_out & i_outblock
		| s_mw1 & i_inblock
		| s_mw2 & i_exsphl;
	wire loada_sp = s_if & (i_push | i_ldsphl | i_incdec16 & i[5] & i[4] | i_call | i_callcc & cond | i_rst | intack | nmiack)
		| s_mw1 & (i_push | i_exsphl | i_call | i_callcc | i_rst | intack | nmiack)
		| s_mr1 & (i_pop | i_exsphl | i_ret | i_retcc | retin)
		| s_mr2 & (i_pop | i_ret | i_retcc | retin)
		| s_iack;
	wire alu_zero;
	wire loada_pc = s_if & i_jphl
		| s_imm1 & (i_jr | i_jrcc & cond2 | i_djnz & ~alu_zero)
		| s_mw2 & (i_call | i_callcc);
	wire loada_adr = s_disp 
		| s_mr1 & (i_ldhl_nn | i_lddd_nn | intack)
		| s_mw1 & (i_ldnnhl | i_ldnndd);
	wire load3_pc = s_mw2 & i_rst;
	wire load66_pc = s_mw2 & nmiack;
	wire clr_pch = s_mw2 & (i_rst | nmiack);
	wire count_pc = (s_if | s_imm1 | s_imm2) & ~(i_halt | intack | nmiack) & ~(s_if2 & (i_ldblock | i_cpblock | i_ioblock)) 
		| s_disp
		| s_mr1 & (i_ldblock | i_cpblock)
		| s_in & i_inblock
		| s_out & i_outblock
		| eschalt;
	wire asu_zero;
	reg q_asu_zero;
	wire dec_pc = (i_ldblock | i_cpblock) & i[4] & ~q_asu_zero & ~(i_cpblock & alu_zero)
		| i_inblock  & i[4] & ~asu_zero
		| i_outblock & i[4] & ~q_f[6];
	wire count_r = s_if;
	//
	// ALU block
	//
	// selector 0 (for alu-input a)
	wire sel0_a = i_cpblock | al | i_daa;
	wire sel0_h = i_c16;
	wire [1:0] sel0 = { sel0_h, sel0_a };
	// selector 1 (for alu-input b)
	wire sel1_tmp = i_ldrr | i_ldrhl | i_ldhlr | al_r | i_rs_r | i_bit_r | i_setres_r;
	wire sel1_b = sel1_tmp & il[0]
		| incdec8 & im[0]
		| g_mw2 & i_ldnndd & im[0]
		| g_mw1 & i_push & im[0]
		| i_c16 & (im[0] | im[1])
		| i_djnz
		| i_outcr & im[0];
	wire sel1_c = sel1_tmp & il[1]
		| incdec8 & im[1]
		| g_mw1 & i_ldnndd & im[0]
		| g_mw2 & i_push & im[0]
		| i_outcr & im[1];
	wire sel1_d = sel1_tmp & il[2]
		| incdec8 & im[2]
		| g_mw2 & i_ldnndd & im[2]
		| g_mw1 & i_push & im[2]
		| i_c16 & (im[2] | im[3])
		| i_outcr & im[2];
	wire sel1_e = sel1_tmp & il[3]
		| incdec8 & im[3]
		| g_mw1 & i_ldnndd & im[2]
		| g_mw2 & i_push & im[2]
		| i_outcr & im[3];
	wire sel1_h = sel1_tmp & il[4]
		| incdec8 & im[4]
		| g_mw2 & (i_ldnnhl | i_ldnndd & im[4])
		| g_mw1 & (i_push & im[4] | i_exsphl)
		| i_c16 & (im[4] | im[5])
		| i_outcr & im[4];
	wire sel1_l = sel1_tmp & il[5]
		| incdec8 & im[5]
		| g_mw1 & (i_ldnnhl | i_ldnndd & im[4])
		| g_mw2 & (i_push & im[4] | i_exsphl)
		| i_outcr & im[5];
	wire sel1_a = sel1_tmp & il[7] | i_ldbca | i_lddea 
		| incdec8 & im[7]
		| i_cpl | i_neg 
		| g_mw1 & (i_ldnna | i_push & im[6])
		| i_rotate1
		| i_outna
		| i_outcr & im[7];
	wire sel1_data = g_mw1 & (i_ldhln | i_ldblock | incdec_hl | i_rs_hl | i_setres_hl | i_inblock)
		| g_imm2 & (i_jpnn | i_jpccnn)
		| g_out & (i_outcr & im[6] | i_outblock);
	wire sel1_sph = g_mw2 & i_ldnndd & im[6]
		| i_c16 & (im[6] | im[7]);
	wire sel1_spl = g_mw1 & i_ldnndd & im[6];
	wire sel1_pch = g_mw1 & (i_call | i_callcc | i_rst | intack | nmiack);
	wire sel1_pcl = g_mw2 & (i_call | i_callcc | i_rst | intack | nmiack);
	wire sel1_i = i_ldai;
	wire sel1_r = i_ldar;
	wire [3:0] sel1 = {
		sel1_b | sel1_c | sel1_d | sel1_e | sel1_h | sel1_l | sel1_a,
		sel1_h | sel1_l | sel1_a | sel1_pch | sel1_pcl | sel1_i | sel1_r,
		sel1_sph | sel1_spl | sel1_d | sel1_e | sel1_a | sel1_pch | sel1_pcl,
		sel1_data | sel1_spl | sel1_c | sel1_e | sel1_l | sel1_a | sel1_pcl | sel1_r
	};
	wire sel_rld = g_mw1 & i_rld;
	wire sel_rrd = g_mw1 & i_rrd;
	wire [3:0] sel1h = {
		sel1[3] | sel_rld | sel_rrd,
		sel1[2] | sel_rld | sel_rrd,
		sel1[1] | sel_rld | sel_rrd,
		sel1[0] | sel_rld | sel_rrd
	};
	wire [3:0] sel1l = {
		sel1[3] | sel_rld,
		sel1[2] | sel_rld,
		sel1[1] | sel_rld,
		sel1[0] | sel_rrd
	};
	//initial $monitor($stime,, sel1_b, sel1_c, sel1_d, sel1_e, sel1_h, sel1_l, sel1_a, sel1_data, sel1_sph, sel1_spl, sel1_pch, sel1_pcl);
	//
	wire [7:0] alu_z, alu_c;
	assign alu_zero = ~| alu_z;
	wire inva = dec8 | i_djnz;
	wire sub = i_cpblock | arith8 & i[4] | i_daa & q_f[1] | i_cpl | i_neg | arith16 & ~i[3];
	wire asu_co;
	wire ci = q_f[0] & arith8 & ~i[5] & i[3] | (add16 | arith16) & asu_co | incdec8 & ~i[0];
	wire s_and = i_and;
	wire s_xor = i_cpblock | i_cpl | arith8 | i_xor | incdec8 | i_c16 | i_daa | i_neg | i_djnz;
	wire s_or = ~s_and & ~s_xor & ~rs & ~i_outcr;
	wire ec = i_cpblock | arith8 & (~i[5] | i[3]) | incdec8 | i_c16 | i_daa | i_neg | i_djnz;
	wire [7:0] alu_a = select0(sel0, { q_a, q_h });
	wire [3:0] alu_bh = select1h(sel1h, { data[7:4], q_data[7:4], q_sph[7:4], q_spl[7:4], q_i[7:4], q_r[7:4], q_pch[7:4], q_pcl[7:4], q_b[7:4], q_c[7:4], q_d[7:4], q_e[7:4], q_h[7:4], q_l[7:4], q_a[7:4] });
	wire [3:0] alu_bl = select1l(sel1l, { data[3:0], q_data[3:0], q_sph[3:0], q_spl[3:0], q_i[3:0], q_r[3:0], q_pch[3:0], q_pcl[3:0], q_b[3:0], q_c[3:0], q_d[3:0], q_e[3:0], q_h[3:0], q_l[3:0], q_data[7:4], q_a[3:0] });
	wire [7:0] alu_b = { alu_bh, alu_bl };
	alu alu(.c_in(ci), .im(im), .a(alu_a), .b(alu_b), .inva(inva), .invb(sub), 
		.reg_q_c(q_f[0]), .reg_q_h(q_f[4]),
		.s_and(s_and), .s_or(s_or), .s_xor(s_xor), .ec(ec),
		.i_daa(i_daa), .set(set), .res(res), .l(l), .r(r),
		.z(alu_z), .co(alu_c));
	//
	// ASU block
	//
	// selector 2 (for asu-input a)
	wire sel2_bc = g_if & (i_ldblock | i_cpblock | (i_c16 | i_incdec16) & ~i[5] & ~i[4])
		| g_in & i_inblock
		| g_mr1 & i_outblock;
	wire sel2_de = g_mw1 & i_ldblock
		| (i_c16 | i_incdec16) & ~i[5] & i[4];
	wire sel2_hl = g_disp 
		| i_ldsphl | i_exdehl | (i_c16 | i_incdec16) & i[5] & ~i[4] | i_jphl
		| g_mr1 & (i_ldblock | i_cpblock)
		| g_out & i_outblock
		| g_mw1 & i_inblock;
	wire sel2_pc = i_jr | i_jrcc | i_djnz;
	wire sel2_adr = i_ldhl_nn | i_lddd_nn | i_ldnnhl | i_ldnndd 
		| g_mr1 & intack
		| g_mw2 & (i_exsphl | i_call | i_callcc);
	wire [2:0] sel2 = {
		sel2_bc | sel2_de | sel2_hl,
		sel2_adr | sel2_hl,
		sel2_pc | sel2_de
	};
	// selector 3 (for asu-input b)
	wire sel3_l = i_c16;
	wire sel3_data_in = g_disp | i_jr | i_jrcc | i_djnz;
	wire [1:0] sel3 = {
		sel3_data_in,
		sel3_l
	};
	//
	wire [15:0] asu_z;
	assign asu_zero = ~| asu_z[15:8] & (i_ioblock | ~| asu_z[7:0]);
	wire asu_ci = i_ldhl_nn | i_lddd_nn | i_ldnnhl | i_ldnndd | i_pop 
		| s_mr1 & (i_exsphl | intack)
		| (s_mr1 | s_mw1) & (i_ldblock | i_cpblock) & ~i[3]
		| (s_out | s_mw1) & i_ioblock & ~i[3]
		| q_f[0] & arith16 | i_incdec16 & ~i[3] | i_jr | i_jrcc | i_djnz | i_ret | i_retcc | retin;
	wire [2:0] asu_i = {
		s_in & i_inblock | s_mr1 & i_outblock,
		s_in & i_inblock | s_mr1 & i_outblock
		| s_if & (i_push | i_ldblock | i_cpblock | i_incdec16 & i[3] | i_call | i_callcc | i_rst | intack | nmiack)
		| s_mw1 & (i_push | i_exsphl | (i_ldblock | i_inblock) & i[3] | i_call | i_callcc | i_rst | intack | nmiack)
		| s_mr1 & (i_ldblock | i_cpblock) & i[3]
		| s_out & i_outblock & i[3]
		| s_iack,
		s_if & i_c16 & ~i[3]
	};
	wire [15:0] asu_a = select2(sel2, { q_sph, q_spl, q_pch, q_pcl, q_adrh, q_adrl, q_b, q_c, q_d, q_e, q_h, q_l });
	wire [7:0] asu_b = select3(sel3, { q_l, data_in });
	asu asu(.a(asu_a), .b(asu_b), .ci(asu_ci), .i(asu_i), .z(asu_z), .co(asu_co));
	always @(posedge clk)
		if (s_if | s_in) q_asu_zero <= asu_zero;
	//
	// address selector
	//
	wire sela_tmp = g_mr1 | g_mr2 | g_mw1 | g_mw2 | g_in | g_out;
	wire sela_tmp2 = i_ldann | i_ldnna | i_ldhl_nn | i_lddd_nn | i_ldnnhl | i_ldnndd;
	wire sela_tmp3 = (idd | ifd) & (g_mr1 | g_mw1);
	wire selah_a = sela_tmp & (i_inan | i_outna);
	wire sela_bc = sela_tmp & (i_ldabc | i_ldbca | i_inrc | i_outcr)
		| g_in & i_inblock | g_out & i_outblock;
	wire sela_de = g_mr1 & i_ldade | g_mw1 & (i_lddea | i_ldblock);
	wire sela_hl = ~sela_tmp3 & (sela_tmp & (i_ldrhl | i_ldhlr | i_ldhln | i_cpblock | al_hl | incdec_hl | i_rs_hl | i_rd | i_bit_hl | i_setres_hl)
		| g_mw1 & i_inblock
		| g_mr1 & (i_ldblock | i_outblock));
	wire selah_adr = sela_tmp3 | sela_tmp & sela_tmp2;
	wire selal_adr = sela_tmp3
		| sela_tmp & (sela_tmp2 | i_inan | i_outna)
		| (g_mr1 | g_mr2) & intack;
	wire sela_sp = sela_tmp & (i_push | i_pop | i_exsphl | i_call | i_callcc | i_ret | i_retcc | retin | i_rst)
		| (g_mw1 | g_mw2) & (intack | nmiack);
	wire selah_i = (g_mr1 | g_mr2) & intack;
	wire [2:0] selah = {
		sela_bc | sela_de | sela_hl | sela_sp,
		selah_a | selah_i | sela_hl | sela_sp,
		selah_adr | selah_i | sela_de | sela_sp
	};
	wire [2:0] selal = {
		sela_bc | sela_de | sela_hl | sela_sp,
		sela_hl | sela_sp,
		selal_adr | sela_de | sela_sp
	};
	//initial $monitor($stime,, selal,, selah);
	// final selector
	wire sel_fr = g_mw2 & i_push & im[6];
	wire [1:0] self = {
		sel_rld | sel_rrd,
		sel_fr | sel_rrd
	};
	wire iff2;
	wire co_pc;
	//initial $monitor($stime,, self);
	// sequencer
	seq seq(.data_in(data), .busreq(busreq), .waitreq(waitreq1), .intreq(intreq), .nmireq(nmireq), .reset_in(reset_in), .clk(clk), 
		.intack(intack), .nmiack(nmiack), .busack(busack_out), .iff2(iff2), .start(start), 
		.icb(icb), .idd(idd), .ied(ied), .ifd(ifd), .inst_reg(inst_reg),
		.mreq(mreq), .iorq(iorq), .rd(rd), .wr(wr),
	.imm1(imm1), .imm2(imm2), .mr1(mr1), .mr2(mr2), .mw1(mw1), .mw2(mw2), .disp(disp), .i_in(i_in), .i_out(i_out), .i_eidi(i_eidi), .i_im(i_im), .retin(retin), .i43(i[4:3]), 
	.g_if(g_if), .g_imm2(g_imm2), .g_mr1(g_mr1), .g_mr2(g_mr2), .g_mw1(g_mw1), .g_mw2(g_mw2), .g_disp(g_disp), .g_in(g_in), .g_out(g_out),  .g_iack(g_iack),
	.sgate(sgate),
	.s_if(s_if), .s_if2(s_if2), .s_imm1(s_imm1), .s_imm2(s_imm2),
	.s_mr1(s_mr1), .s_mr2(s_mr2), .s_mw1(s_mw1), .s_mw2(s_mw2),
	.s_disp(s_disp), .s_in(s_in), .s_out(s_out), .s_iack(s_iack),
`ifdef M1
	.m1(m1),
`endif
	.intmode(intmode), .i_halt(i_halt), .eschalt(eschalt));
// exchange register
	always @(posedge clk) begin
		if (reset_in) begin
			sel_af <= 1'b0;
			sel_exx <= 1'b0;
		end
		else begin
			if (s_if & i_exafaf) sel_af <= ~sel_af;
			if (s_if & i_exx) sel_exx <= ~sel_exx;
		end
	end
//// F register
	wire sel = alu_z[i[5:3]];
	wire subf = incdec8 ? i[0] : sub;
	wire cv0 = arith8 | arith16 | i_daa | i_neg | add16;
	wire cv1 = i_ccf;
	wire cv2 = i_scf;
	wire cv3 = l;
	wire cv4 = r;
	wire cv5 = logica;
	assign d_f[0] = data_in[0] & load_f
		| (alu_c[7] ^ sub) & cv0
		| ~q_f[0] & cv1
		| cv2
		| alu_b[7] & cv3
		| alu_b[0] & cv4
		| q_f[0] & ~(load_f | cv0 | cv1 | cv2 | cv3 | cv4 | cv5);
	wire nv0 = i_ioblock;
	wire nv1 = (arith8 | incdec8 | arith16) & subf | i_cpblock | i_cpl | i_neg;
	wire nv2 = (arith8 | incdec8 | add16 | arith16) & ~subf | ldair | i_inrc | i_rd | i_ccf | i_scf | i_ldblock | logica | rs | ibit;
	assign d_f[1] = data_in[1] & load_f
		| alu_b[7] & nv0
		| nv1
		| q_f[1] & ~(load_f | nv0 | nv1 | nv2);
	wire pv0 = ldair;
	wire pv1 = i_ldblock | i_cpblock;
	wire pv2 = arith8 | arith16 | i_neg | incdec8;
	wire pv3 = logica | i_daa | i_rotate2 | shift | i_rd | i_inrc;
	wire pv4 = ibit;
	assign d_f[2] = data_in[2] & load_f
		| iff2 & pv0
		| ~q_asu_zero & pv1
		| (alu_c[7] ^ alu_c[6]) & pv2
		| ~^alu_z[7:0] & pv3
		|~sel & pv4
		| q_f[2] & ~(load_f | pv0 | pv1 | pv2 | pv3 | pv4);
	wire xy0 = arith8_notcp | incdec8 | i_daa | i_cpl | i_neg | i_ccf | i_scf | add16 | arith16 | rs | i_rd | i_inrc;
	wire xy1 = i_cp;
	wire xy2 = ibit;
	wire xy3 = i_ioblock;
	assign d_f[3] = data_in[3] & load_f
		| alu_z[3] & (xy0 | i_ldblock)
		| alu_b[3] & xy1
		| ~i[5] & i[4] & i[3] & sel & xy2
		| q_b[3] & xy3
		| q_f[3] & ~(load_f | xy0 | xy1 | xy2 | xy3);
	wire hv0 = arith8 | arith16 | i_neg | i_cpblock | incdec8 | add16;
	wire hv1 = i_and | i_cpl | ibit;
	wire hv2 = i_ccf;
	wire hv3 = ldair | i_inrc | i_rd | i_ldblock | i_or | i_xor | i_scf | rs;
	assign d_f[4] = data_in[4] & load_f
		| (alu_c[3] ^ subf) & hv0
		| hv1
		| q_f[0] & hv2
		| (q_f[1] ? ~alu_b[3] & (~alu_b[2] | ~alu_b[1]) : alu_b[3] & (alu_b[2] | alu_b[1])) & i_daa
		| q_f[4] & ~(load_f | hv0 | hv1 | hv2 | hv3 | i_daa);
	assign d_f[5] = data_in[5] & load_f
		| alu_z[5] & xy0
		| alu_b[5] & xy1
		| i[5] & ~i[4] & i[3] & sel & xy2
		| q_b[5] & xy3
		| alu_z[1] & i_ldblock
		| q_f[5] & ~(load_f | xy0 | xy1 | xy2 | xy3 | i_ldblock);
	wire zs0 = arith8 | arith16 | i_daa | i_neg | i_cpblock | incdec8 | ldair | i_inrc | i_rd | i_rotate2 | shift | logica;
	wire zs1 = ibit;
	wire zl = ~| alu_z[7:0];
	wire zu = ~| asu_z[7:0];
	assign d_f[6] = data_in[6] & load_f
		| zl & zs0 & (~arith16 | zu)
		| ~sel & zs1
		| q_asu_zero & i_inblock
		| asu_zero & i_outblock
		| q_f[6] & ~(load_f | zs0 | zs1 | i_ioblock);
	assign d_f[7] = data_in[7] & load_f
		| alu_z[7] & zs0
		| i[5] & i[4] & i[3] & sel & zs1
		| q_b[7] & i_ioblock
		| q_f[7] & ~(load_f | zs0 | zs1 | i_ioblock);
//	assign q_f_out = q_f;
	assign q_f_out = { q_f[7:6], 1'b0, q_f[4], 1'b0, q_f[2:0] };
	wire [7:0] cond3_sel = { q_f[7], ~q_f[7], q_f[2], ~q_f[2], q_f[0], ~q_f[0], q_f[6], ~q_f[6] };
	assign cond = cond3_sel[i[5:3]];
	wire [3:0] cond2_sel = { q_f[0], ~q_f[0], q_f[6], ~q_f[6] };
	assign cond2 = cond2_sel[i[4:3]];
//
	wire [15:0] adr = {
		selectah(selah, { q_adrh, q_a, q_i, q_b, q_d, q_h, q_sph, q_pch }),
		selectal(selal, { q_adrl, q_c, q_e, q_l, q_spl, q_pcl })
	};
	wire [7:0] data_out = selectf(self, { alu_b, q_f_out, q_data[3:0], q_a[3:0], q_a[3:0], q_data[7:4] });
	wire loadal = loada_hl | loada_l;
	wire clr_pch1 = reset_in | clr_pch;
	wire reg_load_f = sgate & ~((g_if | g_mw1) & (al_n | al_hl | incdec_hl | i_rs_hl)) & ~g_out & ~g_disp;
	reg_a reg_a(.a(alu_z), 
		.load(load_a), 
		.set(reset_in), .regsel(sel_af), .clk(clk), .q(q_a));
	reg_f reg_f(.a(d_f), 
		.load(reg_load_f),
		.set(reset_in), .regsel(sel_af), .clk(clk), .q(q_f));
	reg_dual2 reg_b(.a(alu_z), .a2(asu_z[15:8]), 
		.load(load_b), .load2(loada_bc), 
		.regsel(sel_exx), .clk(clk), .q(q_b));
	reg_dual2 reg_c(.a(alu_z), .a2(asu_z[7:0]), 
		.load(load_c), .load2(loada_bc), 
		.regsel(sel_exx),
		.clk(clk), .q(q_c));
	reg_dual2 reg_d(.a(alu_z), .a2(asu_z[15:8]), 
		.load(load_d), .load2(loada_de), 
		.regsel(sel_exx),
		.clk(clk), .q(q_d));
	reg_dual2 reg_e(.a(alu_z), .a2(asu_z[7:0]), 
		.load(load_e), .load2(loada_de), 
		.regsel(sel_exx),
		.clk(clk), .q(q_e));
	wire indexvalid = ~(g_mr1 & i_ldrhl | g_mw1 & i_ldhlr);
	reg_quad3 reg_h(.a(alu_z), .a2(asu_z[15:8]), .a3(q_d),
		.load(load_h), .load2(loada_hl), .load3(loadex),
		.regsel(sel_exx),
		.i_dd(idd & indexvalid), .i_fd(ifd & indexvalid),
		.clk(clk), .q(q_h));
	reg_quad3 reg_l(.a(alu_z), .a2(asu_z[7:0]), .a3(q_e),
		.load(load_l), .load2(loadal), .load3(loadex),
		.regsel(sel_exx),
		.i_dd(idd & indexvalid), .i_fd(ifd & indexvalid),
		.clk(clk), .q(q_l));
	reg_2s reg_sph(.a(data_in), .a2(asu_z[15:8]), 
		.load(load_sph), .load2(loada_sp), 
		.set(reset_in),
		.clk(clk), .q(q_sph));
	reg_2s reg_spl(.a(data_in), .a2(asu_z[7:0]), 
		.load(load_spl), .load2(loada_sp), 
		.set(reset_in),
		.clk(clk),
		.q(q_spl));
	reg_pch reg_pch(.a(data_in), .a2(asu_z[15:8]), 
		.load(load_pch), .load2(loada_pc), .count(co_pc), .dec(dec_pc),
		.clr(clr_pch1),
		.clk(clk),
		.q(q_pch));
	reg_pcl reg_pcl(.a(alu_z), .a2(asu_z[7:0]), .a3(q_data[5:3]),
		.load(load_pcl), .load2(loada_pc), .load3(load3_pc), .load66(load66_pc), .count(count_pc), .dec(dec_pc),
		.clr(reset_in),
		.clk(clk),
		.q(q_pcl), .co(co_pc));
	reg_2 reg_adrh(.a(data_in), .a2(asu_z[15:8]),
		.load(load_adrh), .load2(loada_adr),
		.clk(clk),
		.q(q_adrh));
	reg_2 reg_adrl(.a(data_in), .a2(asu_z[7:0]),
		.load(load_adrl), .load2(loada_adr),
		.clk(clk),
		.q(q_adrl));
	reg_r reg_r(.a(q_a),
		.load(load_r),
		.count(count_r),
		.clr(reset_in),
		.clk(clk),
		.q(q_r));
	reg_simplec reg_i(.a(q_a),
		.load(load_i),
		.clr(reset_in),
		.clk(clk),
		.q(q_i));
	reg_simple reg_data(.a(alu_z),
		.load(load_data),
		.clk(clk),
		.q(q_data));
`ifdef DEBUG
	wire [15:0] debug_pc, debug_sp, debug_bc, debug_de, debug_hl;
	assign debug_pc = { q_pch, q_pcl };
	assign debug_sp = { q_sph, q_spl };
	assign debug_bc = { q_b, q_c };
	assign debug_de = { q_d, q_e };
	assign debug_hl = { q_h, q_l };
	initial $monitor($stime, " %x %x %x %x %x %x %x %x", seq.state, debug_pc, debug_sp, debug_bc, debug_de, debug_hl, q_a, q_f_out);
`endif
endmodule

module seq(data_in, busreq, waitreq, intreq, nmireq, reset_in, clk, 
	intack, nmiack, busack, iff2, icb, idd, ied, ifd, inst_reg, start, 
	mreq, iorq, rd, wr,
	imm1, imm2, mr1, mr2, mw1, mw2, disp, i_in, i_out, i_eidi, i_im, retin, i43, 
	g_if, g_imm2, g_mr1, g_mr2, g_mw1, g_mw2, g_disp, g_in, g_out, g_iack,
	sgate,
	s_if, s_if2, s_imm1, s_imm2, s_mr1, s_mr2, s_mw1, s_mw2, s_disp, s_in, s_out, s_iack,
`ifdef M1
	m1,
`endif
	intmode, i_halt, eschalt);
	input [7:0] data_in;
	input [1:0] i43;
	input busreq, waitreq, intreq, nmireq, reset_in, clk;
	input imm1, imm2, mr1, mr2, mw1, mw2, disp, i_in, i_out, i_eidi, i_im, retin;
	input i_halt;
	output mreq, iorq, rd, wr;
	output intack, nmiack, busack, iff2, icb, idd, ied, ifd, start;
	output [7:0] inst_reg;
	output g_if, g_imm2, g_mr1, g_mr2, g_mw1, g_mw2, g_disp, g_in, g_out, g_iack;
	output sgate;
	output s_if, s_if2, s_imm1, s_imm2, s_mr1, s_mr2, s_mw1, s_mw2, s_disp, s_in, s_out, s_iack;
	output [1:0] intmode;
	output eschalt;
`ifdef M1
	output m1;
`endif
	parameter S_IF1  = 4'b0000;
	parameter S_IF2  = 4'b0001;
	parameter S_IMM1 = 4'b0010;
	parameter S_IMM2 = 4'b0011;
	parameter S_MR1  = 4'b0100;
	parameter S_MR2  = 4'b0101;
	parameter S_DISP = 4'b0110;
	parameter S_IN   = 4'b0111;
	parameter S_IACK = 4'b1000;
	parameter S_MW1  = 4'b1100;
	parameter S_MW2  = 4'b1101;
	parameter S_OUT  = 4'b1111;
	reg [3:0] state;
	reg [7:0] inst_reg;
	reg icb, ied, idd, ifd, iff1, iff2, intack, nmiack, busack, eschalt;
	reg [1:0] intmode;
	reg start;
	wire g_if = state[3:1] == 3'b000;
	wire g_if1 = state == S_IF1;
	wire g_if2 = state == S_IF2;
	wire g_imm1 = state == S_IMM1;
	wire g_imm2 = state == S_IMM2;
	wire g_mr1 = state == S_MR1;
	wire g_mr2 = state == S_MR2;
	wire g_disp = state == S_DISP;
	wire g_in = state == S_IN;
	wire g_iack = state == S_IACK; // IM2 | NMI only
	wire g_mw1 = state == S_MW1;
	wire g_mw2 = state == S_MW2;
	wire g_out = state == S_OUT;
	wire sgate = ~reset_in & ~busack & ~waitreq;
	wire s_if = sgate & g_if;
	wire s_if2 = sgate & g_if2;
	wire s_imm1 = sgate & g_imm1;
	wire s_imm2 = sgate & g_imm2;
	wire s_mr1 = sgate & g_mr1;
	wire s_mr2 = sgate & g_mr2;
	wire s_disp = sgate & g_disp;
	wire s_in = sgate & g_in;
	wire s_iack = sgate & g_iack;
	wire s_mw1 = sgate & g_mw1;
	wire s_mw2 = sgate & g_mw2;
	wire s_out = sgate & g_out;
	wire nextcycle = g_if1 & data_in != 8'hcb & data_in != 8'hdd & data_in != 8'hed & data_in != 8'hfd & ~intack & ~disp & ~imm1 & ~imm2 & ~mr1 & ~mr2 & ~mw1 & ~mw2 & ~i_in
		| g_if2 & ~imm1 & ~imm2 & ~mr1 & ~mr2 & ~i_in & ~i_out
		| g_imm1 & ~imm2 & ~mw1 & ~i_in & ~i_out
		| g_imm2 & ~mr1 & ~mr2 & ~mw1 & ~mw2
		| g_mr1 & ~mr2 & ~mw1 & ~mw2 & ~i_out
		| g_mr2 & ~intack & ~mw1 & ~mw2
		| g_mw1 & ~mw2
		| g_mw2 & ~intack
		| g_in & ~mw1
		| g_out;
	wire next_if2 = (g_if1 & (data_in == 8'hcb & ~idd & ~ifd | data_in == 8'hed)
		| g_disp & icb);
	wire next_imm1 = (g_if1 & ~disp & (imm1 | imm2)
		| g_disp & ~icb & imm1
		| g_if2 & (imm1 | imm2));
	wire next_imm2 = g_imm1 & imm2;
	wire next_mr1 = (g_if1 & ~disp & ~imm1 & ~imm2 & (mr1 | mr2)
		| g_disp & ~icb & ~imm1 & mr1
		| g_if2 & ~imm1 & ~imm2 & (mr1 | mr2)
		| g_imm2 & (mr1 | mr2)
		| g_mw2 & intack & intmode == 2'b11);
	wire next_mr2 = g_mr1 & mr2;
	wire next_disp = g_if1 & (data_in == 8'hcb & (idd | ifd) | disp);
	wire next_in = i_in & (g_if1 & ~imm1 & ~mw1
		| g_if2
		| g_imm1);
	wire next_iack = (nextcycle & (nmireq | intreq & iff1 & intmode == 2'b11));
	wire next_mw1 = (g_if1 & ~disp & ~imm1 & ~imm2 & ~mr1 & ~mr2 & (mw1 | mw2)
		| g_disp & ~icb & ~imm1 & ~mr1
		| g_imm1 & ~imm2 & mw1
		| g_imm2 & ~mr1 & ~mr2 & (mw1 | mw2)
		| g_mr1 & ~mr2 & (mw1 | mw2)
		| g_mr2 & ~intack & (mw1 | mw2)
		| g_in & mw1
		| g_iack);
	wire next_mw2 = g_mw1 & mw2;
	wire next_out = i_out & (g_if2 & ~imm1 & ~mr1
		| g_imm1
		| g_mr1);
	always @(posedge clk) begin
		if (reset_in) begin
			state <= S_IF1;
			start <= 1'b1;
			icb <= 1'b0;
			ied <= 1'b0;
			idd <= 1'b0;
			ifd <= 1'b0;
			iff1 <= 1'b0;
			iff2 <= 1'b0;
			intmode <= 2'b00;
			intack <= 1'b0;
			nmiack <= 1'b0;
			busack <= 1'b0;
			eschalt <= 1'b0;
		end
		else if (busack) begin
			if (~busreq) busack <= 1'b0;
		end
		else if (waitreq) start <= 1'b0;
		else begin
			state <= {
				next_iack | next_mw1 | next_mw2 | next_out,
				next_mr1 | next_mr2 | next_disp | next_in | next_mw1 | next_mw2 | next_out,
				next_imm1 | next_imm2 | next_disp | next_in | next_out,
				next_if2 | next_imm2 | next_mr2 | next_in | next_mw2 | next_out
			};
			start <= 1'b1;
			if (g_if1) begin
				inst_reg <= data_in;
				intack <= 1'b0; // when IM0 | IM1
				eschalt <= 1'b0;
				if (data_in == 8'hcb) icb <= 1'b1;
				if (data_in == 8'hed) ied <= 1'b1;
				if (data_in == 8'hdd) begin
					idd <= 1'b1;
					ifd <= 1'b0;
				end
				if (data_in == 8'hfd) begin
					ifd <= 1'b1;
					idd <= 1'b0;
				end
			end
			else if (g_if2) inst_reg <= data_in;
			else if (g_mr2) intack <= 1'b0; // IM2
			else if (g_mw2) begin
				if (intack & intmode != 2'b11) intack <= 1'b0;
				nmiack <= 1'b0;
			end
			else if (g_iack) eschalt <= 1'b0;
			if (i_eidi) begin
				iff1 <= i43[0];
				iff2 <= i43[0];
			end
			if (retin) iff1 <= iff2;
			if (i_im) intmode <= i43[1:0];
			if (nextcycle) begin
				icb <= 1'b0;
				ied <= 1'b0;
				idd <= 1'b0;
				ifd <= 1'b0;
				if (nmireq) begin
					nmiack <= 1'b1;
					iff1 <= 1'b0;
					eschalt <= i_halt;
					inst_reg <= 8'b00000000;
				end
				else if (intreq & iff1) begin
					intack <= 1'b1;
					iff1 <= 1'b0;
					iff2 <= 1'b0;
					eschalt <= i_halt;
					inst_reg <= 8'b00000000;
				end
			end
			if (busreq) busack <= 1'b1;
		end
	end
	wire intack_r = (g_if | g_iack) & intack;
	wire iorq_t = state[2:0] == 3'b111 | intack_r;
	wire iorq = ~busack & iorq_t;
	wire mreq = ~busack & ~iorq_t & ~intack_r;
	wire rd = ~busack & (~state[3] | g_iack) & ~intack_r;
	wire wr = ~busack & state[3] & ~g_iack;
`ifdef M1
	wire m1 = g_if | g_iack;
`endif
endmodule

// ASU
// z,co = a + b + ci	8bit/16bit  i = 3'b000 for lower 8bit of 16bit arithmetic / 16bit increment
// z,co = b - a - ci	8bit		i = 3'b001 for lower 8bit of 16bit arithmetic
// z = a - ~ci			16bit		i = 3'b010 16bit decrement
// z = a - 0x100		16bit		i = 3'b110 upper 8bit decrement

module asu(a, b, ci, i, z, co);
	input [15:0] a;
	input [7:0] b;
	input ci;
	input [2:0] i;
	output [15:0] z;
	output co;
	wire [14:0] c;
	wire [14:0] tand, tor;
	wire [7:0] a1 = a ^ { 8 { i[0] } };
	wire [7:0] b1 = b | { 8 { i[1] } };
	wire c1 = ci ^ (i[2] | i[0]);
	assign tand[7:0] = a1[7:0] & b1[7:0];
	assign tor[7:0] = a1[7:0] | b1[7:0];
	assign c[0] = tand[0] | tor[0] & c1;
	assign c[1] = tand[1] | tor[1] & tand[0]
				 | &tor[1:0] & c1;
	assign c[2] = tand[2] | tor[2] & tand[1]
				 | &tor[2:1] & tand[0]
				 | &tor[2:0] & c1;
	assign c[3] = tand[3] | tor[3] & tand[2]
				 | &tor[3:2] & tand[1]
				 | &tor[3:1] & tand[0]
				 | &tor[3:0] & c1;
	assign c[4] = tand[4] | tor[4] & tand[3]
				 | &tor[4:3] & tand[2]
				 | &tor[4:2] & tand[1]
				 | &tor[4:1] & tand[0]
				 | &tor[4:0] & c1;
	assign c[5] = tand[5] | tor[5] & tand[4]
				 | &tor[5:4] & tand[3]
				 | &tor[5:3] & tand[2]
				 | &tor[5:2] & tand[1]
				 | &tor[5:1] & tand[0]
				 | &tor[5:0] & c1;
	assign c[6] = tand[6] | tor[6] & tand[5]
				 | &tor[6:5] & tand[4]
				 | &tor[6:4] & tand[3]
				 | &tor[6:3] & tand[2]
				 | &tor[6:2] & tand[1]
				 | &tor[6:1] & tand[0]
				 | &tor[6:0] & c1;
	assign c[7] = tand[7] | tor[7] & tand[6]
				 | &tor[7:6] & tand[5]
				 | &tor[7:5] & tand[4]
				 | &tor[7:4] & tand[3]
				 | &tor[7:3] & tand[2]
				 | &tor[7:2] & tand[1]
				 | &tor[7:1] & tand[0]
				 | &tor[7:0] & c1;
	assign z[7:0] = a1[7:0] ^ b1[7:0] ^ { c[6:0], c1 };
	wire co = c[7] ^ (i[2] | i[0]);
	assign tand[14:8] = a[14:8] & { 8 { b1[7] } };
	assign tor[14:8] = a[14:8] | { 8 { b1[7] } };
	assign c[8] = tand[8] | tor[8] & co;
	assign c[9] = tand[9] | tor[9] & tand[8]
				 | &tor[9:8] & co;
	assign c[10] = tand[10] | tor[10] & tand[9]
				 | &tor[10:9] & tand[8]
				 | &tor[10:8] & co;
	assign c[11] = tand[11] | tor[11] & tand[10]
				 | &tor[11:10] & tand[9]
				 | &tor[11:9] & tand[8]
				 | &tor[11:8] & co;
	assign c[12] = tand[12] | tor[12] & tand[11]
				 | &tor[12:11] & tand[10]
				 | &tor[12:10] & tand[9]
				 | &tor[12:9] & tand[8]
				 | &tor[12:8] & co;
	assign c[13] = tand[13] | tor[13] & tand[12]
				 | &tor[13:12] & tand[11]
				 | &tor[13:11] & tand[10]
				 | &tor[13:10] & tand[9]
				 | &tor[13:9] & tand[8]
				 | &tor[13:8] & co;
	assign c[14] = tand[14] | tor[14] & tand[13]
				 | &tor[14:13] & tand[12]
				 | &tor[14:12] & tand[11]
				 | &tor[14:11] & tand[10]
				 | &tor[14:10] & tand[9]
				 | &tor[14:9] & tand[8]
				 | &tor[14:8] & co;
	assign z[15:8] = a[15:8] ^ { 8 { b1[7] } } ^ { c[14:8], co };
	//initial $monitor($stime,, a,, b,, ci,, i,, c,, z,, co);
endmodule

// ALU for general 8-bit arithmetic/logical

module alu(c_in, im, a, b, inva, invb, reg_q_c, reg_q_h, s_and, s_or, s_xor, ec, i_daa, set, res, l, r, z, co);
	input [7:0] im, a, b;
	input inva, invb, c_in, reg_q_c, reg_q_h, s_and, s_or, s_xor, ec;
	input i_daa, set, res, l, r;
	output [7:0] z, co;
	wire [7:0] b1, c;
	wire [7:0] a1 = a ^ { 8 { inva } };
	wire daah = a1[3] & (a1[2] | a1[1]);
	wire daac = a1[7] & (a1[6] | a1[5]) | a1[7] & a1[4] & daah;
	wire daa0 = i_daa & (reg_q_h | daah);
	wire daa1 = i_daa & (reg_q_c | daac);
	wire [7:0] b0 = b & { 8 { ~i_daa } };
	assign b1[0] = (b0[0] ^ invb | set & im[0]) & ~(res & im[0]);
	assign b1[1] = ((b0[1] | daa0) ^ invb | set & im[1]) & ~(res & im[1]);
	assign b1[2] = ((b0[2] | daa0) ^ invb | set & im[2]) & ~(res & im[2]);
	assign b1[3] = (b0[3] ^ invb | set & im[3]) & ~(res & im[3]);
	assign b1[4] = (b0[4] ^ invb | set & im[4]) & ~(res & im[4]);
	assign b1[5] = ((b0[5] | daa1) ^ invb | set & im[5]) & ~(res & im[5]);
	assign b1[6] = ((b0[6] | daa1) ^ invb | set & im[6]) & ~(res & im[6]);
	assign b1[7] = (b0[7] ^ invb | set & im[7]) & ~(res & im[7]);
	wire [7:0] tand = a1 & b1;
	wire [7:0] tor = a1 | b1;
	wire rlc = l & im[0];
	wire rrc = r & im[1];
	wire rl = l & im[2];
	wire rr = r & im[3];
	wire sra = r & im[5];
	wire ci = c_in ^ invb;
	assign z[0] = s_and & tand[0] | s_or & tor[0] | s_xor & (a1[0] ^ b1[0] ^ ci & ec)
		| rlc & b1[7] | rl & reg_q_c | r & b1[1];
	assign c[0] = tand[0] | tor[0] & ci;
	assign z[1] = s_and & tand[1] | s_or & tor[1] | s_xor & (a1[1] ^ b1[1] ^ c[0] & ec)
		| l & b1[0] | r & b1[2];
	assign c[1] = tand[1] | tor[1] & tand[0]
				 | &tor[1:0] & ci;
	assign z[2] = s_and & tand[2] | s_or & tor[2] | s_xor & (a1[2] ^ b1[2] ^ c[1] & ec)
		| l & b1[1] | r & b1[3];
	assign c[2] = tand[2] | tor[2] & tand[1]
				 | &tor[2:1] & tand[0]
				 | &tor[2:0] & ci;
	assign z[3] = s_and & tand[3] | s_or & tor[3] | s_xor & (a1[3] ^ b1[3] ^ c[2] & ec)
		| l & b1[2] | r & b1[4];
	assign c[3] = tand[3] | tor[3] & tand[2]
				 | &tor[3:2] & tand[1]
				 | &tor[3:1] & tand[0]
				 | &tor[3:0] & ci;
	assign z[4] = s_and & tand[4] | s_or & tor[4] | s_xor & (a1[4] ^ b1[4] ^ c[3] & ec)
		| l & b1[3] | r & b1[5];
	assign c[4] = tand[4] | tor[4] & tand[3]
				 | &tor[4:3] & tand[2]
				 | &tor[4:2] & tand[1]
				 | &tor[4:1] & tand[0]
				 | &tor[4:0] & ci;
	assign z[5] = s_and & tand[5] | s_or & tor[5] | s_xor & (a1[5] ^ b1[5] ^ c[4] & ec)
		| l & b1[4] | r & b1[6];
	assign c[5] = tand[5] | tor[5] & tand[4]
				 | &tor[5:4] & tand[3]
				 | &tor[5:3] & tand[2]
				 | &tor[5:2] & tand[1]
				 | &tor[5:1] & tand[0]
				 | &tor[5:0] & ci;
	assign z[6] = s_and & tand[6] | s_or & tor[6] | s_xor & (a1[6] ^ b1[6] ^ c[5] & ec)
		| l & b1[5] | r & b1[7];
	assign c[6] = tand[6] | tor[6] & tand[5]
				 | &tor[6:5] & tand[4]
				 | &tor[6:4] & tand[3]
				 | &tor[6:3] & tand[2]
				 | &tor[6:2] & tand[1]
				 | &tor[6:1] & tand[0]
				 | &tor[6:0] & ci;
	assign z[7] = s_and & tand[7] | s_or & tor[7] | s_xor & (a1[7] ^ b1[7] ^ c[6] & ec)
		| l & b1[6] | rrc & b1[0] | rr & reg_q_c | sra & b1[7];
	assign c[7] = tand[7] | tor[7] & tand[6]
				 | &tor[7:6] & tand[5]
				 | &tor[7:5] & tand[4]
				 | &tor[7:4] & tand[3]
				 | &tor[7:3] & tand[2]
				 | &tor[7:2] & tand[1]
				 | &tor[7:1] & tand[0]
				 | &tor[7:0] & ci;
	assign co = { i_daa ? daa1 ^ invb : c[7], c[6:0] };
	//initial $monitor($stime,, c_in, a1,, b1,, inva, invb, reg_q_c, reg_q_h, s_and, s_or, s_xor, ec, i_daa, set, res, l, r, z, co);
endmodule

// A register: dual register

module reg_a(a, load, set, regsel, clk, q);
	input [7:0] a;
	input load, set, regsel, clk;
	output [7:0] q;
	reg [7:0] q0, q1;
	always @(posedge clk) begin
		if (set) begin
			q0 <= 8'b11111111;
			q1 <= 8'b11111111;
		end
		else if (load) 
			if (regsel) q1 <= a;
			else q0 <= a;
	end
	assign q = regsel ? q1 : q0;
endmodule

// F register: dual register

module reg_f(a, load, set, regsel, clk, q);
	input [7:0] a;
	input load, set, regsel, clk;
	output [7:0] q;
	reg [7:0] q0, q1;
	always @(posedge clk) begin
		if (set) begin
			q0 <= 8'b11111111;
			q1 <= 8'b11111111;
		end
		else if (load) 
			if (regsel) q1 <= a;
			else q0 <= a;
	end
	assign q = regsel ? q1 : q0;
endmodule

// simple register

module reg_simple(a, load, clk, q);
	input [7:0] a;
	input load, clk;
	output [7:0] q;
	reg [7:0] q;
	always @(posedge clk) begin
		if (load) q <= a;
	end
endmodule

// simple register w/clear

module reg_simplec(a, load, clr, clk, q);
	input [7:0] a;
	input load, clr, clk;
	output [7:0] q;
	reg [7:0] q;
	always @(posedge clk) begin
		if (clr) q <= 8'b00000000;
		else if (load) q <= a;
	end
endmodule

// 2 input dual register

module reg_dual2(a, a2, load, load2, regsel, clk, q);
	input [7:0] a, a2;
	input load, load2, regsel, clk;
	output [7:0] q;
	reg [7:0] q0 = 8'b00000000, q1 = 8'b00000000;
	always @(posedge clk) begin
		if (load) 
			if (regsel) q1 <= a;
			else q0 <= a;
		else if (load2) 
			if (regsel) q1 <= a2;
			else q0 <= a2;
	end
	assign q = regsel ? q1 : q0;
endmodule

// 2 input register

module reg_2(a, a2, load, load2, clk, q);
	input [7:0] a, a2;
	input load, load2, clk;
	output [7:0] q;
	reg [7:0] q;
	always @(posedge clk) begin
		if (load) q <= a;
		else if (load2) q <= a2;
	end
endmodule

// 2 input register w/ set

module reg_2s(a, a2, load, load2, set, clk, q);
	input [7:0] a, a2;
	input load, load2, set, clk;
	output [7:0] q;
	reg [7:0] q;
	always @(posedge clk) begin
		if (set) q <= 8'b11111111;
		else if (load) q <= a;
		else if (load2) q <= a2;
	end
endmodule

// 3 input quad register

module reg_quad3(a, a2, a3, load, load2, load3, regsel, i_dd, i_fd, clk, q);
	input [7:0] a, a2, a3;
	input load, load2, load3, regsel, i_dd, i_fd, clk;
	output [7:0] q;
	reg [7:0] q0 = 8'b00000000, q1 = 8'b00000000, qx = 8'b00000000, qy = 8'b00000000;
	function [7:0] select;
		input [1:0] sel;
		input [31:0] a;
		begin
			case (sel) 
				2'h0: select = a[31:24];
				2'h1: select = a[23:16];
				2'h2: select = a[15:8];
				2'h3: select = a[7:0];
			endcase
		end
	endfunction
	always @(posedge clk) begin
		if (load) 
			if (i_dd) qx <= a;
			else if (i_fd) qy <= a;
			else if (regsel) q1 <= a;
			else q0 <= a;
		else if (load2) 
			if (i_dd) qx <= a2;
			else if (i_fd) qy <= a2;
			else if (regsel) q1 <= a2;
			else q0 <= a2;
		else if (load3) 
			if (i_dd) qx <= a3;
			else if (i_fd) qy <= a3;
			else if (regsel) q1 <= a3;
			else q0 <= a3;
	end
	assign q = select({ i_dd | i_fd, ~i_dd & regsel | i_fd }, { q0, q1, qx, qy });
endmodule

// PCH register: 2 input register w/ increment, decrement, clear

module reg_pch(a, a2, load, load2, count, dec, clr, clk, q);
	input [7:0] a, a2;
	input load, load2, count, dec, clr, clk;
	output [7:0] q;
	wire [6:0] c, qa;
	reg [7:0] q;
	wire notload = ~load & ~load2 & ~clr;
	assign qa = q[6:0] ^ { 7 { dec } };
	assign c[0] = qa[0] & count;
	assign c[1] = &qa[1:0] & count;
	assign c[2] = &qa[2:0] & count;
	assign c[3] = &qa[3:0] & count;
	assign c[4] = &qa[4:0] & count;
	assign c[5] = &qa[5:0] & count;
	assign c[6] = &qa[6:0] & count;
	wire [7:0] d = { 8 { load } } & a | { 8 { load2 } } & a2 | { 8 { notload } } & (q ^ { c, count });
	always @(posedge clk) q <= d;
endmodule

// PCL register: 3 input register w/ increment, decrement, clear, load 66

module reg_pcl(a, a2, a3, load, load2, load3, count, dec, clr, load66, clk, q, co);
	input [7:0] a, a2;
	input [2:0] a3;
	input load, load2, load3, count, dec, clr, load66, clk;
	output [7:0] q;
	output co;
	wire [6:0] c;
	wire [7:0] d, qa;
	reg [7:0] q;
	wire notload = ~load & ~load2 & ~load3 & ~load66 & ~clr;
	assign qa = q ^ { 8 { dec } };
	assign c[0] = qa[0] & count;
	assign c[1] = &qa[1:0] & count;
	assign c[2] = &qa[2:0] & count;
	assign c[3] = &qa[3:0] & count;
	assign c[4] = &qa[4:0] & count;
	assign c[5] = &qa[5:0] & count;
	assign c[6] = &qa[6:0] & count;
	assign co = &qa[7:0] & count;
	assign d[0] = load & a[0] | load2 & a2[0] | notload & (q[0] ^ count);
	assign d[1] = load & a[1] | load2 & a2[1] | notload & (q[1] ^ c[0]) | load66;
	assign d[2] = load & a[2] | load2 & a2[2] | notload & (q[2] ^ c[1]) | load66;
	assign d[3] = load & a[3] | load2 & a2[3] | notload & (q[3] ^ c[2]) | load3 & a3[0];
	assign d[4] = load & a[4] | load2 & a2[4] | notload & (q[4] ^ c[3]) | load3 & a3[1];
	assign d[5] = load & a[5] | load2 & a2[5] | notload & (q[5] ^ c[4]) | load3 & a3[2] | load66;
	assign d[6] = load & a[6] | load2 & a2[6] | notload & (q[6] ^ c[5]) | load66;
	assign d[7] = load & a[7] | load2 & a2[7] | notload & (q[7] ^ c[6]);
	always @(posedge clk) q <= d;
endmodule

// R register: up counter

module reg_r(a, load, count, clr, clk, q);
	input [7:0] a;
	input load, count, clr, clk;
	output [7:0] q;
	reg [7:0] q;
	always @(posedge clk) 
		if (clr) q <= 8'b00000000;
		else if (load) q <= a;
		else if (count) q[6:0] <= q[6:0] + 1;
endmodule

