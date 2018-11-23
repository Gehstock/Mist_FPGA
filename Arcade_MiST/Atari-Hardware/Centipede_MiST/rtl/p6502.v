
//`define no_cpu
`define bc_cpu
//`define sim_cpu

module p6502(
	     input 	   clk, 
	     input 	   reset_n,
	     input 	   nmi,
	     input 	   irq,
	     input 	   so,
	     input 	   rdy,
	     input 	   phi0,
	     output 	   phi2,
	     output 	   rw_n,
	     output [15:0] a,
	     input [7:0]   din,
	     output [7:0]  dout
	     );

`ifdef no_cpu
//   assign rw_n = 1'b1;
//   assign a = 0;
//   assign dout = 0;

   reg cpu_rw_n;
   reg [15:0] cpu_a;
   reg [7:0] cpu_dout;

   reg [7:0] data;

   assign rw_n = cpu_rw_n;
   assign a = cpu_a;
   assign dout = cpu_dout;
   assign phi2 = ~phi0;
   
   task cpu_wr;
      input [15:0] addr;
      input [7:0]  data;
      begin
	 $display("cpu_wr %x <- %x", addr, data);
	 @(posedge phi0);
	 cpu_a = addr;
	 cpu_dout = data;
	 @(posedge phi0);
	 cpu_rw_n = 1'b0;
	 @(posedge phi0);
	 cpu_rw_n = 1'b1;
	 @(posedge phi0);
      end
   endtask
   
   task cpu_rd;
      input [15:0] addr;
      output [7:0]  data;
      begin
	 $display("cpu_rd %x", addr);
	 @(posedge phi0);
	 cpu_a = addr;
	 cpu_dout = data;
	 @(posedge phi0);
	 cpu_rw_n = 1'b1;
	 @(posedge phi0);
	 cpu_rw_n = 1'b1;
	 @(posedge phi0);
      end
   endtask

   task cpu_wr_pf;
      input [7:0] a;
      input [31:0] d;
      reg [5:0]    atop;
      reg [7:0]    b0, b1, b2, b3;
      reg [15:0]   a0, a1, a2, a3;
      begin
	 b0 = d[7:0];
	 b1 = d[15:8];
	 b2 = d[23:16];
	 b3 = d[31:24];

	 atop = 6'b000001;
	 a0 = {atop, a[7:4], 2'd0, a[3:0]};
	 a1 = {atop, a[7:4], 2'd1, a[3:0]};
	 a2 = {atop, a[7:4], 2'd2, a[3:0]};
	 a3 = {atop, a[7:4], 2'd3, a[3:0]};
	 $display("a %x -> a0 %x %x %x %x", a, a0, a1, a2, a3);
	 
	 cpu_wr(a0, b0);
	 cpu_wr(a1, b1);
	 cpu_wr(a2, b2);
	 cpu_wr(a3, b3);
      end
   endtask

`ifdef never
   task cpu_wr_mapped;
      input [12:0] cpu_a;
      input [7:0]  cpu_d;
      reg [7:0]    r_a;
      reg [3:0]    r_w;
      begin
	 r_a = { cpu_a[9:6], cpu_a[3:0] };

	 case (cpu_a[5:4])
	   2'b00: r_w = 4'b1110;
	   2'b01: r_w = 4'b1101;
	   2'b10: r_w = 4'b1011;
	   2'b11: r_w = 4'b0111;
	 endcase
	 $display("%x %x -> %x %b", cpu_a, cpu_d, r_a, r_w);

	 if (~r_w[3])
	   ram3[r_a] = cpu_d;
	 else
	   if (~r_w[2])
	     ram2[r_a] = cpu_d;
	   else
	     if (~r_w[1])
	       ram1[r_a] = cpu_d;
	     else
	       if (~r_w[0])
		 ram0[r_a] = cpu_d;
      end
   endtask
`endif

   integer i;
   
   initial
     begin
	cpu_rw_n = 1'b1;
	cpu_a = 0;
	cpu_dout = 0;
	
`ifdef never
	for (i = 'h400; i < 'h7c0; i = i + 1)
	  cpu_wr(i, 8'h00);
`endif
	
	#1000;
	$display("nocpu: init");

`ifdef never
	cpu_wr(16'h07c0, 8'h01);
	cpu_rd(16'h07c0, data);
	cpu_wr(16'h07d0, 8'h02);
	cpu_rd(16'h07d0, data);
	cpu_wr(16'h07e0, 8'h03);
	cpu_rd(16'h07e0, data);

	cpu_wr(16'h0400, 8'haa);
	cpu_rd(16'h0400, data);
	cpu_wr(16'h0410, 8'hbb);
	cpu_rd(16'h0410, data);
	#20;
	$finish;
`endif

`ifdef never	
	cpu_wr(16'h0400, 8'h00);
	cpu_wr(16'h0401, 8'h01);
	cpu_wr(16'h0402, 8'h02);
	cpu_wr(16'h0403, 8'h03);

	cpu_wr(16'h0400, 8'h00);
	cpu_wr(16'h0410, 8'h11);
	cpu_wr(16'h0420, 8'h22);
	cpu_wr(16'h0430, 8'h33);

	cpu_rd(16'h0400, data);
	cpu_rd(16'h0401, data);
	cpu_rd(16'h0402, data);
	cpu_rd(16'h0403, data);

	cpu_rd(16'h0400, data);
	cpu_rd(16'h0410, data);
	cpu_rd(16'h0420, data);
	cpu_rd(16'h0430, data);
`endif
	
`ifdef never
	cpu_wr_pf(8'd240, 32'h39f08606);
	cpu_wr_pf(8'd241, 32'h3df27e0d);
	cpu_wr_pf(8'd242, 32'h3df88384);
	cpu_wr_pf(8'd243, 32'h3df88b83);
	cpu_wr_pf(8'd244, 32'h3df89382);
	cpu_wr_pf(8'd245, 32'h3df89b81);
	cpu_wr_pf(8'd246, 32'h3df8a380);
	cpu_wr_pf(8'd247, 32'h3df8ab87);
	cpu_wr_pf(8'd248, 32'h3df8b386);
	cpu_wr_pf(8'd249, 32'h3df8bb85);
	cpu_wr_pf(8'd250, 32'h3df8c384);
	cpu_wr_pf(8'd251, 32'h3df8cb83);
	cpu_wr_pf(8'd252, 32'h39f8dc1c);
	cpu_wr_pf(8'd253, 32'h7960fff8);
	cpu_wr_pf(8'd254, 32'h39388211);
	cpu_wr_pf(8'd255, 32'h390f8710);
`endif
	
	cpu_wr_pf(8'hf0, 32'h39f08606);
	cpu_wr_pf(8'hf1, 32'h3df27e0d);
	cpu_wr_pf(8'hf2, 32'h39e88384);
	cpu_wr_pf(8'hf3, 32'h39e88b83);
	cpu_wr_pf(8'hf4, 32'h39e89382);
	cpu_wr_pf(8'hf5, 32'h39e8a986);
	cpu_wr_pf(8'hf6, 32'h39e8a380);
	cpu_wr_pf(8'hf7, 32'h39e8ab87);
	cpu_wr_pf(8'hf8, 32'h39e8b386);
	cpu_wr_pf(8'hf9, 32'h39e8bb85);
	cpu_wr_pf(8'hfa, 32'h39e8c384);
	cpu_wr_pf(8'hfb, 32'h39e8cb83);
	cpu_wr_pf(8'hfc, 32'h39e8dc1c);
	cpu_wr_pf(8'hfd, 32'h7960fff8);
	cpu_wr_pf(8'hfe, 32'h39388211);
	cpu_wr_pf(8'hff, 32'h390f8710);

	cpu_wr(16'h501, 8'h01);
	cpu_wr(16'h521, 8'h14);
	cpu_wr(16'h541, 8'h01);
	cpu_wr(16'h561, 8'h12);
	cpu_wr(16'h581, 8'h09);

	cpu_wr(16'h502, 8'h14);
	cpu_wr(16'h522, 8'h05);
	cpu_wr(16'h542, 8'h13);
	cpu_wr(16'h562, 8'h14);
	cpu_wr(16'h582, 8'h00);

	cpu_wr(16'h503, 8'h1b);
	cpu_wr(16'h523, 8'h21);
	cpu_wr(16'h543, 8'h29);
	cpu_wr(16'h563, 8'h28);
	cpu_wr(16'h583, 8'h20);
	
	#10000;
#100000000;
	$finish;
	
`ifdef never
	cpu_wr(16'h07c5, 8'h11);
	cpu_wr(16'h07d5, 8'hb7);
	cpu_wr(16'h07e5, 8'hf0);
	cpu_wr(16'h07f5, 8'h39);

	cpu_wr(16'h07c4, 8'h11);
	cpu_wr(16'h07d4, 8'h10);
	cpu_wr(16'h07e4, 8'hf0);
	cpu_wr(16'h07f4, 8'h39);
	
	cpu_wr(16'h07c3, 8'h11);
	cpu_wr(16'h07d3, 8'h40);
	cpu_wr(16'h07e3, 8'h2c);
	cpu_wr(16'h07f3, 8'h39);
	
	cpu_wr(16'h07c2, 8'h10);
	cpu_wr(16'h07d2, 8'h60);
	cpu_wr(16'h07e2, 8'hf8);
	cpu_wr(16'h07f2, 8'h3d);

	cpu_wr(16'h07c1, 8'h12);
	cpu_wr(16'h07d1, 8'h80);
	cpu_wr(16'h07e1, 8'h02);
	cpu_wr(16'h07f1, 8'h39);
`endif
	
`ifdef never
	cpu_wr(16'h07ee, 8'h2c);
	cpu_wr(16'h07de, 8'hb7);
	cpu_wr(16'h07ce, 8'h11);
	cpu_wr(16'h07fe, 8'h39);

	cpu_wr(16'h07ed, 8'h60);
	cpu_wr(16'h07dd, 8'hff);
	cpu_wr(16'h07cd, 8'hf8);
	cpu_wr(16'h07fd, 8'h79);

	cpu_wr(16'h07ec, 8'hf8);
	cpu_wr(16'h07dc, 8'h14);
	cpu_wr(16'h07cc, 8'h1c);
	cpu_wr(16'h07fc, 8'h39);

	cpu_wr(16'h07eb, 8'hf0);
	cpu_wr(16'h07db, 8'h8e);
	cpu_wr(16'h07cb, 8'h03);
	cpu_wr(16'h07fb, 8'h3d);

	cpu_wr(16'h07ea, 8'hf0);
	cpu_wr(16'h07da, 8'h96);
	cpu_wr(16'h07ca, 8'h04);
	cpu_wr(16'h07fa, 8'h3d);

	cpu_wr(16'h07e9, 8'hf0);
	cpu_wr(16'h07d9, 8'h9e);
	cpu_wr(16'h07c9, 8'h05);
	cpu_wr(16'h07f9, 8'h3d);

	cpu_wr(16'h07e8, 8'hf0);
	cpu_wr(16'h07d8, 8'ha6);
	cpu_wr(16'h07c8, 8'h06);
	cpu_wr(16'h07f8, 8'h3d);

	cpu_wr(16'h07e7, 8'hf0);
	cpu_wr(16'h07d7, 8'hae);
	cpu_wr(16'h07c7, 8'h07);
	cpu_wr(16'h07f7, 8'h3d);

	cpu_wr(16'h07e6, 8'hf0);
	cpu_wr(16'h07d6, 8'hb6);
	cpu_wr(16'h07c6, 8'h00);
	cpu_wr(16'h07f6, 8'h3d);

	cpu_wr(16'h07e5, 8'hf0);
	cpu_wr(16'h07d5, 8'hbe);
	cpu_wr(16'h07c5, 8'h01);
	cpu_wr(16'h07f5, 8'h3d);

	cpu_wr(16'h07e4, 8'hf0);
	cpu_wr(16'h07d4, 8'hc6);
	cpu_wr(16'h07c4, 8'h02);
	cpu_wr(16'h07f4, 8'h3d);

	cpu_wr(16'h07e3, 8'hf0);
	cpu_wr(16'h07d3, 8'hce);
	cpu_wr(16'h07c3, 8'h03);
	cpu_wr(16'h07f3, 8'h3d);

	cpu_wr(16'h07e2, 8'hf0);
	cpu_wr(16'h07d2, 8'hd6);
	cpu_wr(16'h07c2, 8'h04);
	cpu_wr(16'h07f2, 8'h3d);

	cpu_wr(16'h07e1, 8'hf0);
	cpu_wr(16'h07d1, 8'hde);
	cpu_wr(16'h07c1, 8'h05);
	cpu_wr(16'h07f1, 8'h3d);

	cpu_wr(16'h07e0, 8'hf0);
	cpu_wr(16'h07d0, 8'he6);
	cpu_wr(16'h07c0, 8'h06);
	cpu_wr(16'h07f0, 8'h39);
`endif
	
	$display("nocpu: done");
     end
`endif

`ifdef bc_cpu
   wire [15:0] ma;
   wire        reset;
   wire        rw;

   wire        rw_nxt;
   wire [15:0] ma_nxt;
   wire        sync;
   wire [31:0] state;
   wire [4:0]  flags;
   
   bc6502 bc6502(reset, phi0, ~nmi, ~irq, rdy, so, din, dout, rw, ma,
		 rw_nxt, ma_nxt, sync, state, flags);

   assign reset = ~reset_n;
   assign a = ma;
   assign rw_n = rw;
//   assign phi2 = clk;
   assign phi2 = ~phi0;

`ifdef SIMULATION
   //
   integer     pccount;
   initial
     pccount = 0;

   always @(posedge clk)
     begin
	if (bc6502.s_sync)
	  begin
	     pccount = pccount + 1;
	     if (pccount == 1000/* || $time > 9999999*/)
	       begin
		  pccount = 0;
`ifdef debug_cpu
		  $display("%t; cpu: pc %x; a=%x x=%x", $time, bc6502.pc_reg, bc6502.a_reg, bc6502.x_reg);
`ifndef verilator
		  $fflush;
		  $flushlog;
`endif
`endif
	       end

	     if (^bc6502.pc_reg === 1'bX ||
		 ^bc6502.a_reg === 1'bX ||
		 ^bc6502.x_reg === 1'bX ||
		 ^bc6502.y_reg === 1'bX)
	       begin
		  $display("%t; cpu: x's in pc, a, x or y", $time);
		  $finish;
	       end

	     if (^a === 1'bX || ^din === 1'bX || ^dout === 1'bX)
	       begin
		  $display("%t; cpu: x's in addr bus or data bus", $time);
		  $finish;
	       end
	  end
     end
`endif // SIMULATION
`endif // bc_cpu

`ifdef sim_cpu
   reg cpu_rw_n;
   reg [15:0] cpu_a;
   reg [7:0] cpu_dout;

   reg [7:0] data;

   assign rw_n = cpu_rw_n;
   assign a = cpu_a;
   assign dout = cpu_dout;
   assign phi2 = ~phi0;
   
`endif

endmodule // p6502
