/*  Atari on an FPGA
Masters of Engineering Project
Cornell University, 2007
Daniel Beer
    RIOT.v
Redesign of the MOS 6532 chip. Provides RAM, I/O and timers to the Atari.
*/
`timescale 1ns / 1ps

`include "riot.vh"
module RIOT(A, // Address bus input
	    Din, // Data bus input
	    Dout, // Data bus output
	    CS, // Chip select input
	    CS_n, // Active low chip select input
	    R_W_n, // Active low read/write input
	    RS_n, // Active low rom select input
	    RES_n, // Active low reset input
	    IRQ_n, // Active low interrupt output
	    CLK,   // Clock input
	    PAin,  // 8 bit port A input
	    PAout, // 8 bit port A output
	    PBin,  // 8 bit port B input
	    PBout);// 8 bit port B output
   input [6:0] A;
   input [7:0] Din;
   output [7:0] Dout;
   input 	CS, CS_n, R_W_n, RS_n, RES_n, CLK;
   output 	IRQ_n;
   input [7:0] 	PAin, PBin;
   output [7:0] PAout, PBout; // Output register
   reg [7:0] 	Dout; // RAM allocation
   reg [7:0] 	RAM[127:0]; // I/O registers
   reg [7:0] 	DRA, DRB; // Data registers
   reg [7:0] 	DDRA, DDRB; // Data direction registers
   wire 	PA7;
   reg 		R_PA7;
   assign PA7 = (PAin[7] & ~DDRA[7]) | (DRA[7] & DDRA[7]);
   assign PAout = DRA & DDRA;
   assign PBout = DRB & DDRB;
   // Timer registers
   reg [8:0] 	Timer;
   reg [9:0] 	Prescaler;
   reg [1:0] 	Timer_Mode;
   reg 		Timer_Int_Flag, PA7_Int_Flag, Timer_Int_Enable, PA7_Int_Enable, PA7_Int_Mode; // Timer prescaler constants
   wire [9:0] 	PRESCALER_VALS[3:0];
   assign PRESCALER_VALS[0] = 10'd0;
   assign PRESCALER_VALS[1] = 10'd7;
   assign PRESCALER_VALS[2] = 10'd63;
   assign PRESCALER_VALS[3] = 10'd1023;
   // Interrupt
   assign IRQ_n = ~(Timer_Int_Flag & Timer_Int_Enable | PA7_Int_Flag & PA7_Int_Enable);
   // Operation decoding
   wire [6:0] 	op;
   reg [6:0] 	R_op;
   assign op = {RS_n, R_W_n, A[4:0]};
   // Registered data in
   reg [7:0] 	R_Din;
   integer 	cnt;
   // Software operations
   always @(posedge CLK)
     begin
	// Reset operation
	if (~RES_n) begin
	   DRA <= 8'b0;
	   DDRA <= 8'b0;
	   DRB <= 8'b00010100;
	   DDRB <= 8'b00010100;
	   Timer_Int_Flag <= 1'b0;
	   PA7_Int_Flag <= 1'b0;
	   PA7_Int_Enable <= 1'b0;
	   PA7_Int_Mode <= 1'b0;
	   // Fill RAM with 0s
	   for (cnt = 0; cnt < 128; cnt = cnt + 1)
	     RAM[cnt] <= 8'b0;
	   R_PA7 <= 1'b0;
	   R_op <= `NOP;
	   R_Din <= 8'b0;
	end
	// If the chip is enabled, execute an operation
	else if (CS & ~CS_n) begin
	   // Register inputs for use later
	   R_PA7 <= PA7;
	   R_op <= op;
	   R_Din <= Din;
	   // Update the timer interrupt flag
	   casex (op)
	     `WRITE_TIMER: Timer_Int_Flag <= 1'b0;
	     `READ_TIMER: Timer_Int_Flag <= 1'b0;
	     default: if (Timer == 9'b111111111) Timer_Int_Flag <= 1'b1;
	   endcase
	   // Update the port A interrupt flag
	   casex (op)
	     `READ_INT_FLAG: PA7_Int_Flag <= 1'b0;
	     default: PA7_Int_Flag <= PA7_Int_Flag | (PA7 != R_PA7 & PA7 == PA7_Int_Mode);
	   endcase
	   // Process the current operation
	   casex(op) // RAM access
	     `READ_RAM: Dout <= RAM[A];
	     `WRITE_RAM: RAM[A] <= Din;
	     // Port A data access
	     `READ_DRA : Dout <= (PAin & ~DDRA) | (DRA & DDRA);
	     `WRITE_DRA: DRA <= Din;
	     // Port A direction register access
	     `READ_DDRA: Dout <= DDRA;
	     `WRITE_DDRA: DDRA <= Din;
	     // Port B data access
	     `READ_DRB: Dout <= (PBin & ~DDRB) | (DRB & DDRB);
	     `WRITE_DRB: DRB <= Din;
	     // Port B direction register access
	     `READ_DDRB: Dout <= DDRB;
	     `WRITE_DDRB: DDRB <= Din;
	     // Timer access
	     `READ_TIMER: Dout <= Timer[7:0];
	     // Status register access
	     `READ_INT_FLAG: Dout <= {Timer_Int_Flag, PA7_Int_Flag, 6'b0};
	     // Enable the port A interrupt
	     `WRITE_EDGE_DETECT: begin
		PA7_Int_Mode <= A[0]; PA7_Int_Enable <= A[1];
	     end
	   endcase
	end
	// Even if the chip is not enabled, update background functions
	else begin
	   // Update the timer interrupt
	   if (Timer == 9'b111111111)
	     Timer_Int_Flag <= 1'b1;
	   // Update the port A interrupt
	   R_PA7 <= PA7;
	   PA7_Int_Flag <= PA7_Int_Flag | (PA7 != R_PA7 & PA7 == PA7_Int_Mode);
	   // Set the operation to a NOP
	   R_op <=`NOP;
	end
     end
   // Update the timer at the negative edge of the clock
   always @(negedge CLK)begin
      // Reset operation
      if (~RES_n) begin
	 Timer <= 9'b0;
	 Timer_Mode <= 2'b0;
	 Prescaler <= 10'b0;
	 Timer_Int_Enable <= 1'b0;
      end
      // Otherwise, process timer operations
      else
	casex
	  (R_op)
	  // Write value to the timer and update the prescaler based on the address
	  `WRITE_TIMER:begin
	     Timer <= {1'b0, R_Din};
	     Timer_Mode <= R_op[1:0];
	     Prescaler <= PRESCALER_VALS[R_op[1:0]];
	     Timer_Int_Enable <= R_op[3];
	  end
	  // Otherwise decrement the prescaler and if necessary the timer.
	  // The prescaler holds a variable number of counts that must be
	  // run before the timer is decremented
	  default:if (Timer != 9'b100000000) begin
	     if (Prescaler != 10'b0)
	       Prescaler <= Prescaler - 10'b1;
	     else begin
		if (Timer == 9'b0)
		  begin
		     Prescaler <= 10'b0;
		     Timer_Mode <= 2'b0;
		  end
		else
		  Prescaler <= PRESCALER_VALS[Timer_Mode];
		Timer <= Timer - 9'b1;
	     end
	  end
	endcase
   end
endmodule
