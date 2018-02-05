// ====================================================================
//                Bashkiria-2M FPGA REPLICA
//
//            Copyright (C) 2010 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Bashkiria-2M home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Design File: k580wn59.v
//
// Programmable interrupt controller k580wn59 design file of Bashkiria-2M replica.
//
// Warning: Interrupt level shift not supported.

module k580wn59(
	input clk, input reset, input addr, input we_n,
	input[7:0] idata, output reg[7:0] odata,
	output intr, input inta_n, input[7:0] irq);

reg[1:0] state;
reg[7:0] irqmask;
reg[7:0] smask;
reg[7:0] serviced;
reg[2:0] addr0;
reg[7:0] addr1;
reg init;
reg addrfmt;
reg exinta_n;

wire[7:0] r = irq & ~(irqmask | smask);
assign intr = |r;

reg[2:0] x;
always @(*)
	casex (r)
	8'bxxxxxxx1: x = 3'b000;
	8'bxxxxxx10: x = 3'b001;
	8'bxxxxx100: x = 3'b010;
	8'bxxxx1000: x = 3'b011;
	8'bxxx10000: x = 3'b100;
	8'bxx100000: x = 3'b101;
	8'bx1000000: x = 3'b110;
	default:     x = 3'b111;
	endcase
	
always @(*)
	casex ({inta_n,state})
	3'b000: odata = 8'hCD;
	3'bx01: odata = addrfmt ? {addr0,x,2'b00} : {addr0[2:1],x,3'b000};
	3'bx1x: odata = addr1;
	3'b100: odata = addr ? irqmask : irq;
	endcase

always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= 0; init <= 0; irqmask <= 8'hFF; smask <= 8'hFF; serviced <= 0; exinta_n <= 1'b1;
	end else begin
		exinta_n <= inta_n;
		smask <= smask & (irq|serviced);
		case (state)
		2'b00: begin
			if (~we_n) begin
				init <= 0;
				casex ({addr,idata[4:3]})
				3'b000:
					case (idata[7:5])
					3'b001: serviced <= 0;
					3'b011: serviced[idata[2:0]] <= 0;
					endcase
				3'b01x: begin init <= 1'b1; addr0 <= idata[7:5]; addrfmt <= idata[2]; end
				3'b1xx: if (init) addr1 <= idata; else irqmask <= idata;
				endcase
			end
			if (inta_n&~exinta_n) state <= 2'b01;
		end
		2'b01: begin
			if (inta_n&~exinta_n) state <= 2'b10;
		end
		2'b10: begin
			if (inta_n&~exinta_n) begin
				state <= 2'b00;
				smask[x] <= 1'b1;
				serviced[x] <= 1'b1;
			end
		end
		endcase
	end
end

endmodule
