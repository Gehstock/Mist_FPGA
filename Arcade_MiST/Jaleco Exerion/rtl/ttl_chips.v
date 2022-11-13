`timescale 1ns/1ps

`define ASSIGN_UNPACK_ARRAY(PK_LEN, PK_WIDTH, UNPK_DEST, PK_SRC) wire [PK_LEN*PK_WIDTH-1:0] PK_IN_BUS; assign PK_IN_BUS=PK_SRC; generate genvar unpk_idx; for (unpk_idx=0; unpk_idx<PK_LEN; unpk_idx=unpk_idx+1) begin: gen_unpack assign UNPK_DEST[unpk_idx][PK_WIDTH-1:0]=PK_IN_BUS[PK_WIDTH*unpk_idx+:PK_WIDTH]; end endgenerate
`define PACK_ARRAY(PK_LEN, PK_WIDTH, UNPK_SRC) PK_OUT_BUS; wire [PK_LEN*PK_WIDTH-1:0] PK_OUT_BUS; generate genvar pk_idx; for (pk_idx=0; pk_idx<PK_LEN; pk_idx=pk_idx+1) begin: gen_pack assign PK_OUT_BUS[PK_WIDTH*pk_idx+:PK_WIDTH]=UNPK_SRC[pk_idx][PK_WIDTH-1:0]; end endgenerate

//74LS74 Chip pinout:
/*        _____________
        _|             |_
n_clr1 |_|1          14|_| VCC
        _|             |_                     
d1     |_|2          13|_| n_clr2
        _|             |_
clk1   |_|3          12|_| d2
        _|             |_
n_pre1 |_|4          11|_| clk2
        _|             |_
q1     |_|5          10|_| n_pre2
        _|             |_
n_q1   |_|6           9|_| q2
        _|             |_
GND    |_|7           8|_| n_q2
         |_____________|
*/

module ls74  //not used
(
	input  n_pre1, n_pre2,
	input  n_clr1, n_clr2,
	input  clk1, clk2,
	input  d1, d2,
	output reg q1, q2,
    output n_q1, n_q2
);

always @(posedge clk1 or negedge n_pre1 or negedge n_clr1) begin
	if(!n_pre1)
		q1 <= 1;
	else if(!n_clr1)
		q1 <= 0;
	else
		q1 <= d1;
end
assign n_q1 = ~q1;
	
always @(posedge clk2 or negedge n_pre2 or negedge n_clr2) begin
	if(!n_pre2)
		q2 <= 1;
	else if(!n_clr2)
		q2 <= 0;
	else
		q2 <= d2;
end
assign n_q2 = ~q2;

endmodule

//74LS107 Chip pinout:
/*     _____________
     _|             |_
1J  |_|1          14|_| VCC
     _|             |_                     
1nQ |_|2          13|_| 1nCLR
     _|             |_
1Q  |_|3          12|_| 1CK
     _|             |_
1K  |_|4          11|_| 2K
     _|             |_
2Q  |_|5          10|_| 2nCLR
     _|             |_
2nQ |_|6           9|_| 2CK
     _|             |_
GND |_|7           8|_| 2J
      |_____________|
*/

module ls107(
   input clear, 
   input clk, 
   input j, 
   input k, 
   output reg q, 
   output qnot,
	output reg q_immediate
);

assign qnot=~q;
  always @(posedge clk or negedge clear) begin
	if (!clear) q_immediate<=1'b0; else
		case ({j, k})
		2'b00: q_immediate<=q;
		2'b01: q_immediate<=1'b0;
		2'b10: q_immediate<=1'b1;
		2'b11: q_immediate<=~q;
		endcase
  end
  always @(negedge clk) begin
			q<=q_immediate;
  end
endmodule


//74LS139 Chip pinout:
/*      _____________
      _|             |_
1n_G |_|1          16|_| VCC
      _|             |_                     
1A   |_|2          15|_| 2n_G
      _|             |_
1B   |_|3          14|_| 2A
      _|             |_
1Y0  |_|4          13|_| 2B
      _|             |_
1Y1  |_|5          12|_| 2Y0
      _|             |_
1Y2  |_|6          11|_| 2Y1
      _|             |_
1Y3  |_|7          10|_| 2Y2
      _|             |_
GND  |_|8           9|_| 2Y3
       |_____________|
*/

module ls139 //used
(
	input  		 a,
    input  		 b,
  	input  		 n_g,
  	output [3:0] y
);

  assign y = (!n_g && !a && !b) ? 4'b1110:
    (!n_g && a && !b)  ? 4'b1101:
    (!n_g && !a && b)  ? 4'b1011:
    (!n_g && a && b)   ? 4'b0111:
	4'b1111;
		
endmodule



//Chip pinout:
/*       _____________  
       _|             |_
 D(3) |_|1          16|_| VCC
       _|             |_
 D(2) |_|2          15|_| D(4)
       _|             |_
 D(1) |_|3          14|_| D(5)
       _|             |_
 D(0) |_|4          13|_| D(6)
       _|             |_
   Y  |_|5          12|_| D(7)
       _|             |_
   W  |_|6          11|_| A
       _|             |_
   S  |_|7          10|_| B
       _|             |_
  GND |_|8           9|_| C
        |_____________|
*/

module ttl_74283 #(parameter WIDTH = 4, DELAY_RISE = 0, DELAY_FALL = 0) //used
(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  input c_in,
  output [WIDTH-1:0] sum,
  output c_out
);

//------------------------------------------------//
reg [WIDTH-1:0] Sum_computed;
reg C_computed;

always @(*)
begin
  {C_computed, Sum_computed} = {1'b0, a} + {1'b0, b} + c_in;
end
//------------------------------------------------//

assign #(DELAY_RISE, DELAY_FALL) sum = Sum_computed;
assign #(DELAY_RISE, DELAY_FALL) c_out = C_computed;

endmodule


module ls138x ( //used
	input  [2:0] A,
  	input		 nE1,
  	input		 nE2,	
   input		 E3,
  	output [7:0] Y
);

reg [7:0] Q;
wire trigger;
assign trigger = !nE1 & !nE2 & E3;

always @(*) begin

	 if (trigger) begin 
		case (A)
		  3'b000: Q[7:0]=8'b11111110;
		  3'b001: Q[7:0]=8'b11111101;   
		  3'b010: Q[7:0]=8'b11111011;
		  3'b011: Q[7:0]=8'b11110111;    
		  3'b100: Q[7:0]=8'b11101111;
		  3'b101: Q[7:0]=8'b11011111;
		  3'b110: Q[7:0]=8'b10111111;
		  3'b111: Q[7:0]=8'b01111111;           
		  //default: Q[7:0]=8'b11111111;
		endcase

	 end
	 else begin //
		Q[7:0] = 8'b11111111;
	 end
end

assign Y = Q;

endmodule

	



// Dual D flip-flop with set and clear; positive-edge-triggered

// Note: Preset_bar is synchronous, not asynchronous as specified in datasheet for this device,
//       in order to meet requirements for FPGA circuit design (see IceChips Technical Notes)

module ttl_7474 #(parameter BLOCKS = 2, DELAY_RISE = 0, DELAY_FALL = 0)
(
  input [BLOCKS-1:0] n_pre,
  input [BLOCKS-1:0] n_clr,
  input [BLOCKS-1:0] d,
  input [BLOCKS-1:0] clk,
  output [BLOCKS-1:0] q,
  output [BLOCKS-1:0] n_q
);

//------------------------------------------------//
reg [BLOCKS-1:0] Q_current;
reg [BLOCKS-1:0] Preset_bar_previous;

generate
  genvar i;
  for (i = 0; i < BLOCKS; i = i + 1)
  begin: gen_blocks
    always @(posedge clk[i] or negedge n_clr[i])
    begin
      if (!n_clr[i])
        Q_current[i] <= 1'b0;
      else if (!n_pre[i] && Preset_bar_previous[i])  // falling edge has occurred
        Q_current[i] <= 1'b1;
      else
      begin
        Q_current[i] <= d[i];
        Preset_bar_previous[i] <= n_pre[i];
      end
    end
  end
endgenerate
//------------------------------------------------//

assign #(DELAY_RISE, DELAY_FALL) q = Q_current;
assign #(DELAY_RISE, DELAY_FALL) n_q = ~Q_current;

endmodule

//ls175 
module ls175(
	input			nMR,
	input			clk,
	input 	[3:0]	D,
	output	[3:0]	Q,
	output	[3:0]	nQ
);

reg [3:0] latch = 4'b0;
assign Q = ~nMR ? latch : 4'b0;
assign nQ = ~nMR ? !latch : 4'b0;

always @(posedge clk)
begin
		latch = D[3:0];
end

endmodule


module mux4_1 (
    input EN_n,
    input A, B,
    input D0, D1, D2, D3,
    output Y
);

/* KEEP THE OUTPUT VALUE */
wire [1:0] S;
reg Y_reg;

assign S = {B, A};

always @(*) begin
    if (EN_n)
        Y_reg = 1'bz;
    else
        case (S)
            2'b00: Y_reg <= D0;
            2'b01: Y_reg <= D1;
            2'b10: Y_reg <= D2;
            2'b11: Y_reg <= D3;
        endcase
end

assign Y = Y_reg;

endmodule

module mux4_1n (
    input EN_n,
    input A, B,
    input D0, D1, D2, D3,
    output Y
);

/* KEEP THE OUTPUT VALUE */
wire [1:0] S;
reg Y_reg;

assign S = {B, A};

always @(*) begin
    if (EN_n)
        Y_reg <= 1'b0;
    else
        case (S)
            2'b00: Y_reg <= D0;
            2'b01: Y_reg <= D1;
            2'b10: Y_reg <= D2;
            2'b11: Y_reg <= D3;
        endcase
end

assign Y = Y_reg;

endmodule


module mux4_2n (
    input EN_n,
    input A, B,
    input  [1:0] D0, D1, D2, D3,
    output [1:0] Y
);

/* KEEP THE OUTPUT VALUE */
wire [1:0] S;
reg [1:0] Y_reg;

assign S = {B, A};

always @(*) begin
    if (EN_n)
        Y_reg <= 2'b00;
    else
        case (S)
            2'b00: Y_reg <= D0;
            2'b01: Y_reg <= D1;
            2'b10: Y_reg <= D2;
            2'b11: Y_reg <= D3;
        endcase
end

assign Y = Y_reg;

endmodule

module mux4_4n (
    input EN_n,
    input A, B,
    input [3:0] D0, D1, D2, D3,
    output [3:0] Y
);

/* KEEP THE OUTPUT VALUE */
wire [1:0] S;
reg [3:0] Y_reg;

assign S = {B, A};

always @(*) begin
    if (EN_n)
        Y_reg <= 4'b0000;
    else
        case (S)
            2'b00: Y_reg <= D0;
            2'b01: Y_reg <= D1;
            2'b10: Y_reg <= D2;
            2'b11: Y_reg <= D3;
        endcase
end

assign Y = Y_reg;

endmodule

module mux4_1x (
    input EN_n,
	 input DIS_n,
    input A, B,
    input D0, D1, D2, D3,
    output Y
);

/* KEEP THE OUTPUT VALUE */
wire [1:0] S;
reg Y_reg;
reg active;

always @(EN_n,DIS_n) begin

	if (!EN_n & DIS_n) active = 1;
	else if (!DIS_n) active =0;

end

assign S = {B, A};

always @(*) begin
    if (!active)
        Y_reg <= 1'b0;
    else
        case (S)
            2'b00: Y_reg <= D0;
            2'b01: Y_reg <= D1;
            2'b10: Y_reg <= D2;
            2'b11: Y_reg <= D3;
        endcase
end

assign Y = Y_reg;

endmodule

module top_74ls153 (
    input A, B,
    input [1:0] EN_n,
    input D1_0, D1_1, D1_2, D1_3,
    input D2_0, D2_1, D2_2, D2_3,
    output Y1, Y2
);

/* LEFT MUX 4 - 1 */
mux4_1n left_74ls153 (
    .EN_n(EN_n[0]),
    .A(A),
    .B(B),
    .D0(D1_0),
    .D1(D1_1),
    .D2(D1_2),
    .D3(D1_3),
    .Y(Y1)
);

/* RIGHT MUX 4 - 1 */
mux4_1n right_74ls153 (
    .EN_n(EN_n[1]),
    .A(A),
    .B(B),
    .D0(D2_0),
    .D1(D2_1),
    .D2(D2_2),
    .D3(D2_3),
    .Y(Y2)
);

endmodule
