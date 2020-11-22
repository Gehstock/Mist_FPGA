module MC6803_gen2(
		input logic clk,
		RST,
		hold,
		halt,
		irq,
		nmi,
		input logic[7:0] PORT_A_IN,
		input logic[4:0] PORT_B_IN,
		input logic[7:0] DATA_IN,
		output logic[7:0] PORT_A_OUT,
		output logic[4:0] PORT_B_OUT,
		output logic[15:0] ADDRESS,
		output logic[7:0] DATA_OUT,
		output logic E_CLK, rw);

logic[7:0] DATA_IN_s, PORT_A_IN_s;
logic[4:0] PORT_B_IN_s;
logic[7:0] data_in;
logic hold_s, halt_s, irq_s, nmi_s;

logic DDR1_E, DDR2_E, P1_E, P2_E, TCS_E, CH_E, CL_E, OCRH_E, OCRL_E, iRAM_E;
logic OCF, next_OCF, TOF, next_TOF, EICI, next_EICI, EOCI, next_EOCI, ETOI, next_ETOI, IEDG, next_IEDG, OLVL, next_OLVL;
logic irq_tof, irq_ocf;
logic[7:0] next_port_a, next_DDR1, DDR1;
logic[4:0] next_port_b, next_DDR2, DDR2;
logic[15:0] counter, next_counter;
logic[7:0] OCRH, OCRL, next_OCRH, next_OCRL;
logic REG_RW;
logic[7:0] REG_DATA;
logic TOF_reset, OCF_reset;

mc6801_core cpu01_inst(.clk(clk), .rst(RST), .rw(rw), .vma(E_CLK), .address(ADDRESS), .data_in(data_in), .data_out(DATA_OUT), .hold(hold_s), .halt(halt_s), .irq(irq_s), .nmi(nmi_s), .irq_icf(1'b0), .irq_ocf(irq_ocf), .irq_tof(irq_tof), .irq_sci(1'b0));

MEM_128_8 iMEM(.Clk(clk), .reset(RST), .data_in(DATA_OUT), .data_out(REG_DATA), .RW(REG_RW), .address(ADDRESS[6:0]));

always_ff @(negedge clk)
begin
	if(RST)
	begin
		counter <= 0;
		OCF <= 0;
		EICI <= 0;
		EOCI <= 0;
		ETOI <= 0;
		IEDG <= 0;
		OLVL <= 0;
		OCRH <= 0;
		OCRL <= 0;
	end
	else
	begin
		DATA_IN_s <= DATA_IN;
		PORT_A_IN_s <= PORT_A_IN;
		PORT_B_IN_s <= PORT_B_IN;
		hold_s <= hold;
		halt_s <= halt;
		irq_s <= irq;
		nmi_s <= nmi;
		EICI <= next_EICI;
		EOCI <= next_EOCI;
		ETOI <= next_ETOI;
		IEDG <= next_IEDG;
		OLVL <= next_OLVL;
		PORT_A_OUT <= next_port_a;
		PORT_B_OUT <= next_port_b;
		counter <= next_counter;
		OCRH <= next_OCRH;
		OCRL <= next_OCRL;
		DDR1 <= next_DDR1;
		DDR2 <= next_DDR2;
//timer resets
	end
	if(TCS_E & rw & TOF)
		TOF_reset <= 1'b1;
	if(TOF_reset & rw & CH_E)
	begin
		TOF <= 1'b0;
		TOF_reset <= 1'b0;
	end
	else
		TOF <= next_TOF;
	if(TCS_E & rw & OCF)
		OCF_reset <= 1'b1;
	if(OCF_reset & (~rw) & (OCRH_E | OCRL_E))
	begin
		OCF <= 1'b0;
		OCF_reset <= 1'b0;
	end
	else
		OCF <= next_OCF;
end

always_comb
begin
	if(ADDRESS > 16'h7f && ADDRESS < 16'h100 && E_CLK)
		iRAM_E = 1'b1;
	else
		iRAM_E = 0;
	DDR1_E = 1'b0;
	DDR2_E = 1'b0;
	P1_E = 1'b0;
	P2_E = 1'b0;
	TCS_E = 1'b0;
	CH_E = 1'b0;
	CL_E = 1'b0;
	OCRH_E = 1'b0;
	OCRL_E = 1'b0;
	//ICRH_E = 1'b0;
	//ICRL_E = 1'b0;
	data_in = DATA_IN_s;
	next_port_a = PORT_A_OUT;
	next_port_b = PORT_B_OUT;
	next_DDR1 = DDR1;
	next_DDR2 = DDR2;
	irq_tof = 1'b0;
	irq_ocf = 1'b0;
	next_EICI = EICI;
	next_OCRH = OCRH;
	next_OCRL = OCRL;
	next_EOCI = EOCI;
	next_ETOI = ETOI;
	next_IEDG = IEDG;
	next_OLVL = OLVL;
	REG_RW = 1'b1;

	case (ADDRESS)
		16'h00: DDR1_E = 1'b1;
		16'h01: DDR2_E = 1'b1;
		16'h02: P1_E = 1'b1;
		16'h03: P2_E = 1'b1;
		16'h08: TCS_E = 1'b1;
		16'h09: CH_E = 1'b1;
		16'h0A: CL_E = 1'b1;
		16'h0B: OCRH_E = 1'b1;
		16'h0C: OCRL_E = 1'b1;
//		16'h0D: ICRH_E = 1'b1;
//		16'h0E: ICRL_E = 1'b1;
		default: ;
	endcase

// port A
	if(P1_E)
	begin
		data_in = (PORT_A_IN_s & (~DDR1))|(PORT_A_OUT & (DDR1));
		if(E_CLK & (~rw))
			next_port_a = DATA_OUT;
		else
			next_port_a = PORT_A_OUT;
	end
	if(DDR1_E)
	begin
		data_in = DDR1;
		if(E_CLK & (~rw))
			next_DDR1 = DATA_OUT;
		else
			next_DDR1 = DDR1;
	end
//port B
	if(P2_E)
	begin
		data_in = 8'b0100_0000 | (PORT_B_IN_s & (~DDR2))|(PORT_B_OUT & (DDR2));
		if(E_CLK & (~rw))
			next_port_b = DATA_OUT[4:0];
		else
			next_port_b = PORT_B_OUT;
	end
	if(DDR2_E)
	begin
		data_in = DDR2;
		if(E_CLK & (~rw))
			next_DDR2 = DATA_OUT[4:0];
		else
			next_DDR2 = DDR2;
	end
// programmable timer
//counter
	next_counter = counter + 16'h01;
	if(CH_E & E_CLK & (~rw))
		next_counter = 16'hFFF8;
	if(counter == 16'hFFFF)
	begin
		next_TOF = 1'b1;
		irq_tof = ETOI;
	end
	else
		next_TOF = TOF;
	if(CH_E)
		data_in = counter[15:8];
	if(CL_E)
		data_in = counter[7:0];
// output compare
	if(OCRH_E)
	begin
		data_in = OCRH;
		if(E_CLK & (~rw))
			next_OCRH = DATA_OUT;
		else
			next_OCRH = OCRH;
	end
	if(OCRL_E)
	begin
		data_in = OCRL;
		if(E_CLK & (~rw))
			next_OCRL = DATA_OUT;
		else
			next_OCRL = OCRL;
	end
	if(next_counter == {OCRH, OCRL})
	begin
		next_OCF = 1'b1;
		irq_ocf = EOCI;
	end
	else
		next_OCF = OCF;
// control and status
	if(TCS_E)
	begin
		data_in = {1'b0, OCF, TOF, EICI, EOCI, ETOI, IEDG, OLVL};
		if(E_CLK & (~rw))
		begin
			next_EICI = DATA_OUT[4];
			next_EOCI = DATA_OUT[3];
			next_ETOI = DATA_OUT[2];
			next_IEDG = DATA_OUT[1];
			next_OLVL = DATA_OUT[0];
		end
		else
		begin
			next_EICI = EICI;
			next_EOCI = EOCI;
			next_ETOI = ETOI;
			next_IEDG = IEDG;
			next_OLVL = OLVL;
		end
	end
//internal memory
	if(iRAM_E)
	begin
		data_in = REG_DATA;
		REG_RW = rw;
	end
end

endmodule

module MEM_128_8(input logic[6:0] address, input logic RW, Clk, reset, input logic[7:0] data_in, output logic[7:0] data_out);
logic[7:0] REGS[127:0];
integer i;
always_ff @ (posedge Clk)
begin
if(reset)
	for(i=0; i<128; i=i+1)
		REGS[i]=0;
else if(~RW)
	REGS[address] <= data_in;
end
assign data_out = REGS[address];
endmodule
