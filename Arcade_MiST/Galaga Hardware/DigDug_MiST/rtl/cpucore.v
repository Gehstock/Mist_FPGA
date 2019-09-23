module CPUCORE
(
	input				RESET,
	input				CLK,
	input				IRQ,
	input				NMI,
	output			RD,
	output			WR,
	output [15:0]	AD,
	input	  			DV,
	input	  [7:0]	DI,
	input	  [7:0]	IR,
	output  [7:0]	DO
);
	
wire  [7:0] m_do;
wire [15:0] m_ad;
wire        m_irq, m_nmi, m_me, m_ie, m_rd, m_wr;

wire        m_mx = (~m_me);
wire        m_mr = (~m_rd) & m_mx;
wire        m_mw = (~m_wr) & m_mx;

wire        cs_mrom = ( m_ad[15:14] ==  2'b00 );
wire			cs_nodv = cs_mrom;

wire [7:0]	m_di = cs_mrom ? IR : DV ? DI : 8'hFF;

assign m_irq = ~IRQ;
assign m_nmi = ~NMI;

tv80s core(
	.mreq_n(m_me),
	.iorq_n(m_ie),
	.rd_n(m_rd),
	.wr_n(m_wr),
	.A(m_ad),
	.do(m_do),

	.reset_n(~RESET),
	.clk(CLK),
	.wait_n(1'b1),
	.int_n(m_irq),
	.nmi_n(m_nmi),
	.busrq_n(1'b1),
	.di(m_di)
);

assign RD = m_mr & ~cs_nodv;
assign WR = m_mw & ~cs_nodv;
assign AD = m_ad;
assign DO = m_do;

endmodule


//-----------------------------------------------
//  NMI Ack Control
//-----------------------------------------------
module CPUNMIACK
(
	input				RST,
	input				CL,
	input	[15:0]	AD,
	input				NMI,
	output reg		NMIo
);

reg  pNMI   = 1'b0;
wire NMIACK = ( AD == 16'h0066 );
always @( negedge CL or posedge RST ) begin
	if (RST) begin
		pNMI <= 1'b0;
		NMIo <= 1'b0;
	end
	else begin
		if (NMIACK) NMIo <= 0;
		else if ((pNMI^NMI) & NMI) NMIo <= 1'b1;
		pNMI <= NMI;
	end
end

endmodule

