//============================================================================
// 
//  SystemVerilog implementation of the KONAMI-1 custom chip, a custom MC6809E
//  variant with XOR/XNOR encryption
//  Implements MC6809E core by Greg Miller (synchronous version modified by
//  Sorgelig with further modifications to allow direct injection of opcodes)
//  Copyright (C) 2021 Ace
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//============================================================================

module KONAMI1
(
    input   CLK,
    input   fallE_en,
    input   fallQ_en,

    input   [7:0]  D,
    output  [7:0]  DOut,
    output  [15:0] ADDR,
    output  RnW,
    output  BS,
    output  BA,
    input   nIRQ,
    input   nFIRQ,
    input   nNMI,
    output  AVMA,
    output  BUSY,
    output  LIC,
    input   nHALT,
    input   nRESET
);

//Decrypt XOR/XNOR encrypted opcode
wire [7:0] opcode = D ^ {ADDR[1], 1'b0, ~ADDR[1], 1'b0, ADDR[3], 1'b0, ~ADDR[3], 1'b0};

//Passthrough to modified MC6809is core with direct opcode injection and IS_KONAMI1 parameter set
//to TRUE
mc6809is #(.IS_KONAMI1("TRUE")) cpucore
(
	.CLK(CLK),
	.fallE_en(fallE_en),
	.fallQ_en(fallQ_en),
	.OP(opcode),
	.nHALT(nHALT),
	.nRESET(nRESET),
	.D(D),
	.DOut(DOut),
	.ADDR(ADDR),
	.RnW(RnW),
	.BS(BS),
	.BA(BA),
	.nIRQ(nIRQ),
	.nFIRQ(nFIRQ),
	.nNMI(nNMI),
	.AVMA(AVMA),
	.BUSY(BUSY),
	.LIC(LIC),
	.nDMABREQ(1)
);

endmodule
