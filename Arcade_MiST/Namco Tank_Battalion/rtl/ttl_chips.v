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

module ls74
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
   output qnot
);

assign qnot=~q;
  always @(negedge clk or negedge clear) begin
	if (!clear) q<=1'b0; else
		case ({j, k})
		2'b00: q<=q;
		2'b01: q<=1'b0;
		2'b10: q<=1'b1;
		2'b11: q<=~q;
		endcase
  end
endmodule

//74LS161 Chip pinout:
/*        _____________
        _|             |_
n_clr  |_|1          16|_| VCC
        _|             |_                     
clk    |_|2          15|_| rco
        _|             |_
din(0) |_|3          14|_| q(0)
        _|             |_
din(1) |_|4          13|_| q(1)
        _|             |_
din(2) |_|5          12|_| q(2)
        _|             |_
din(3) |_|6          11|_| q(3)
        _|             |_
enp    |_|7          10|_| ent
        _|             |_
GND    |_|8           9|_| n_load
         |_____________|
*/

module ls161 //asynchronous reset/clear
(
	input        n_clr,
	input        clk,
	input  [3:0] din,
	input        enp, ent,
	input        n_load,
	output [3:0] q,
	output       rco
);

  reg [3:0] data = 4'b0;

always @(posedge clk or negedge n_clr) begin
	if(!n_clr)
		data <= 4'd0;
	else
		if(!n_load)
			data <= din;
		else if(enp && ent)
			data <= data + 4'd1;
end

assign q = data;
assign rco = data[0] & data[1] & data[2] & data[3] & ent;

endmodule

//74LS273 Chip pinout:
/*      _____________
      _|             |_
res  |_|1          20|_| VCC
      _|             |_                     
q(0) |_|2          19|_| q(7)
      _|             |_
d(0) |_|3          18|_| d(7)
      _|             |_
d(1) |_|4          17|_| d(6)
      _|             |_
q(1) |_|5          16|_| q(6)
      _|             |_
q(2) |_|6          15|_| q(5)
      _|             |_
d(2) |_|7          14|_| d(5)
      _|             |_
d(3) |_|8          13|_| d(4)
      _|             |_
q(3) |_|9          12|_| q(4)
      _|             |_
GND  |_|10         11|_| clk
       |_____________|
*/

module ls273
(
	input  [7:0] d,
	input        clk,
	input        res,
	output reg [7:0] q
);

always @(posedge clk or negedge res) begin
	if(!res)
		q <= 8'h00;
	else
		q <= d;
end

endmodule

//74LS166 Chip pinout:
/*            _____________
            _|             |_
serial input |_|1          16|_| VCC
            _|             |_                     
parra in A   |_|2          15|_| shift/load
            _|             |_
parra in B   |_|3          14|_| parra in H
            _|             |_
parra in C   |_|4          13|_| serial output
            _|             |_
parra in D   |_|5          12|_| parra in G
            _|             |_
CLK inhibit  |_|6          11|_| parra in F
            _|             |_
CLK        |_|7          10|_|   parra in E
            _|             |_
GND        |_|8           9|_| clear
             |_____________|
*/

module ls166
(
    input clk,
    input load,
  	input [7:0] in,
    output out	
);
  
reg [7:0]tmp;

always @(posedge clk)
begin
	if (!load)
		tmp <= in;
	else
		tmp <= {tmp[6:0], 1'b0};
end
assign out = tmp[7];

endmodule

//74LS174 Chip pinout:
/*      _____________
      _|             |_
mr   |_|1          16|_| VCC
      _|             |_                     
q(0) |_|2          15|_| q(5)
      _|             |_
d(0) |_|3          14|_| d(5)
      _|             |_
d(1) |_|4          13|_| d(4)
      _|             |_
q(1) |_|5          12|_| q(4)
      _|             |_
d(2) |_|6          11|_| d(3)
      _|             |_
q(2) |_|7          10|_| q(3)
      _|             |_
GND  |_|8           9|_| clk
       |_____________|
*/

module ls174 
(
	input  [5:0] d,
	input        clk,
	input        mr,
	output reg [5:0] q
);

always @(posedge clk or negedge mr) begin
	if(!mr)
		q <= 6'b000000;
	else
		q <= d;
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

module ls139
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
s     |_|1          16|_| VCC
       _|             |_                     
i0(0) |_|2          15|_| n_e
       _|             |_
i1(0) |_|3          14|_| i0(2)
       _|             |_
z(0)  |_|4          13|_| i1(2)
       _|             |_
i0(1) |_|5          12|_| z(2)
       _|             |_
i1(1) |_|6          11|_| i0(3)
       _|             |_
z(1)  |_|7          10|_| i1(3)
       _|             |_
GND   |_|8           9|_| z(3)
        |_____________|
*/

module ls157 
(
	input  [3:0] i0,
	input  [3:0] i1,
	input        n_e,
	input        s,
	output [3:0] z
);

assign z = (!n_e && !s) ? i0:
	(!n_e && s)     ? i1:
	4'b0000;	
	
endmodule

module ls42
(
    input  [3:0] in,
  output reg [9:0] out
);
  // in = [DCBA]
  // out = [9876543210]
  
  always @ (*)
    case (in)
    	4'b0000: out = 10'b1111111110;
        4'b0001: out = 10'b1111111101;
        4'b0010: out = 10'b1111111011;
        4'b0011: out = 10'b1111110111;
        4'b0100: out = 10'b1111101111;
		4'b0101: out = 10'b1111011111;
        4'b0110: out = 10'b1110111111;
        4'b0111: out = 10'b1101111111;
        4'b1000: out = 10'b1011111111;
        4'b1001: out = 10'b0111111111;
        4'b1010: out = 10'b1111111111;
        4'b1011: out = 10'b1111111111;
        4'b1100: out = 10'b1111111111;
        4'b1101: out = 10'b1111111111;
        4'b1110: out = 10'b1111111111;
        4'b1111: out = 10'b1111111111;      
        default: out = 10'b1111111111;
    endcase
		
endmodule

//New Modules
//Chip pinout:
/*        _____________
        _|             |_
n_clr  |_|1          16|_| VCC
        _|             |_                     
clk    |_|2          15|_| rco
        _|             |_
din(0) |_|3          14|_| q(0)
        _|             |_
din(1) |_|4          13|_| q(1)
        _|             |_
din(2) |_|5          12|_| q(2)
        _|             |_
din(3) |_|6          11|_| q(3)
        _|             |_
enp    |_|7          10|_| ent
        _|             |_
GND    |_|8           9|_| n_load
         |_____________|
*/

module ls163 //synchronous reset/clear
(
	input        n_clr,
	input        clk,
	input  [3:0] din,
	input        enp, ent,
	input        n_load,
	output [3:0] q,
	output       rco
);

  reg [3:0] data = 4'b0;

always @(posedge clk) begin
	if(!n_clr)
		data <= 4'd0;
	else
		if(!n_load)
			data <= din;
		else if(enp && ent)
			data <= data + 4'd1;
end

assign q = data;
assign rco = data[0] & data[1] & data[2] & data[3] & ent;

endmodule

//Chip pinout:
/*     _____________
     _|             |_
a1  |_|1          14|_| VCC
     _|             |_                     
b1  |_|2          13|_| c1
     _|             |_
a2  |_|3          12|_| y1
     _|             |_
b2  |_|4          11|_| a3
     _|             |_
c2  |_|5          10|_| b3
     _|             |_
y2  |_|6           9|_| c3
     _|             |_
GND |_|7           8|_| y3
      |_____________|
*/

module ls10
(
	input  a1, a2, a3,
	input  b1, b2, b3,
    input  c1, c2, c3,
	output y1, y2, y3
);

  assign y1 = ~(a1 & b1 & c1);
  assign y2 = ~(a2 & b2 & c2);
  assign y3 = ~(a3 & b3 & c3);
	
endmodule

//Chip pinout:
/*     _____________
     _|             |_
a1  |_|1          14|_| VCC
     _|             |_                     
b1  |_|2          13|_| a4
     _|             |_
y1  |_|3          12|_| b4
     _|             |_
a2  |_|4          11|_| y4
     _|             |_
b2  |_|5          10|_| a3
     _|             |_
y2  |_|6           9|_| b3
     _|             |_
GND |_|7           8|_| y3
      |_____________|
*/

module ls08
(
	input  a1, a2, a3, a4,
	input  b1, b2, b3, b4,
	output y1, y2, y3, y4
);

assign y1 = a1 & b1;
assign y2 = a2 & b2;
assign y3 = a3 & b3;
assign y4 = a4 & b4;
	
endmodule

//Chip pinout:
/*        _____________
        _|             |_
sum(1) |_|1          16|_| VCC
        _|             |_                     
b(1)   |_|2          15|_| b(2)
        _|             |_
a(1)   |_|3          14|_| a(2)
        _|             |_
sum(0) |_|4          13|_| sum(2)
        _|             |_
a(0)   |_|5          12|_| a(3)
        _|             |_
b(0)   |_|6          11|_| b(3)
        _|             |_
c_in   |_|7          10|_| sum(3)
        _|             |_
GND    |_|8           9|_| c_out
         |_____________|
*/

module ls283
(
	input  [3:0] a,
	input  [3:0] b,
	input        c_in,
	output [3:0] sum,
	output       c_out
);

wire [4:0] sum_int;

assign sum_int = {1'b0, a} + {1'b0, b} + {4'b0000, c_in};
assign sum = sum_int[3:0];
assign c_out = sum_int[4];

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

module ls251
(
  	input  [2:0] CBA,
  	input		 s,
  	input  [7:0] D,
	output reg 	 Y,W
);

  always @ (CBA,s)
        begin
          if (!s) begin
          	case (CBA)
            	3'b000: Y=D[0];
            	3'b001: Y=D[1];    
            	3'b010: Y=D[2];    
            	3'b011: Y=D[3];    
            	3'b100: Y=D[4];
            	3'b101: Y=D[5];
            	3'b110: Y=D[6];
            	3'b111: Y=D[7];            
          		default: Y=1'bZ;
        	endcase
            W <=!Y;
          end
  		  else begin
        		Y <= 1'bZ;
            	W <= 1'bZ;
    	  end
	end
endmodule

module ls259
(
  	input  [2:0] A,
  	input		 nE,
    input		 nC,
  	input  		 D,
  	output reg [7:0] Q
);

    always @ (nE,nC,D,A)
        begin
          if (!nC && nE) begin
            Q[7:0] <= 8'b00000000;
          end
          else if (!nC && !nE && !D) begin
            Q[7:0] <= 8'b00000000;
          end
          else if (!nC && !nE && D) begin
            case (A)
              3'b000: Q[7:0]=8'b00000001;
              3'b001: Q[7:0]=8'b00000010;   
              3'b010: Q[7:0]=8'b00000100;
              3'b011: Q[7:0]=8'b00001000;    
              3'b100: Q[7:0]=8'b00010000;
              3'b101: Q[7:0]=8'b00100000;
              3'b110: Q[7:0]=8'b01000000;
              3'b111: Q[7:0]=8'b10000000;           
              default: Q[7:0]=8'bZZZZZZZZ;
        	endcase
          end
          else if (nC && nE) begin
          //no change
          end
          else if (nC && !nE) begin
            case (A)
              3'b000: Q[0]=D;
              3'b001: Q[1]=D;    
              3'b010: Q[2]=D;    
              3'b011: Q[3]=D;    
              3'b100: Q[4]=D;
              3'b101: Q[5]=D;
              3'b110: Q[6]=D;
              3'b111: Q[7]=D;            
              default: Q[7:0]=8'bZZZZZZZZ;
        	endcase          
          end
		end
endmodule

