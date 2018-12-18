
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



endmodule // p6502
