// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
//
// Modified for b2m: Ivan Gorodetsky


module SDRAM_Controller(
	input			clk100,				//  Clock 100MHz
	input			reset,					//  System reset
	inout	[15:0]	DRAM_DQ,				//	SDRAM Data bus 16 Bits
	output	reg[11:0]	DRAM_ADDR,			//	SDRAM Address bus 12 Bits
	output	reg		DRAM_LDQM,				//	SDRAM Low-byte Data Mask 
	output	reg		DRAM_UDQM,				//	SDRAM High-byte Data Mask
	output	reg		DRAM_WE_N,				//	SDRAM Write Enable
	output	reg		DRAM_CAS_N,				//	SDRAM Column Address Strobe
	output	reg		DRAM_RAS_N,				//	SDRAM Row Address Strobe
	output			DRAM_CS_N,				//	SDRAM Chip Select
	output			DRAM_BA_0,				//	SDRAM Bank Address 0
	output			DRAM_BA_1,				//	SDRAM Bank Address 0
	input	[21:0]	iaddr,
	input	[7:0]	idata,
	input			rd,
	input			we_n,
	output	reg [15:0]	odata,
	input ub_n,
	input lb_n,
	output reg memvidbusy,
	output reg memcpubusy,
	input rdv
);

parameter ST_RESET0 = 4'd0;
parameter ST_RESET1 = 4'd1;
parameter ST_IDLE   = 4'd2;
parameter ST_RAS0   = 4'd3;
parameter ST_RAS1   = 4'd4;
parameter ST_READ0  = 4'd5;
parameter ST_READ1  = 4'd6;
parameter ST_READ2  = 4'd7;
parameter ST_WRITE0 = 4'd8;
parameter ST_WRITE1 = 4'd9;
parameter ST_WRITE2 = 4'd10;
parameter ST_REFRESH0 = 4'd11;
parameter ST_REFRESH1 = 4'd12;
parameter ST_REFRESH2 = 4'd13;
parameter ST_REFRESH3 = 4'd14;

reg[3:0] state;
reg[21:0] addr;
reg[15:0] data;
reg exrd,exwen;
reg ubn,lbn,rdvid;

assign DRAM_DQ[7:0] = (state==ST_WRITE0) ? data : 8'bZZZZZZZZ;
assign DRAM_DQ[15:8] = (state == ST_WRITE0) ? data : 8'bZZZZZZZZ;
assign DRAM_CS_N = 1'b0;
assign DRAM_BA_0 = addr[20];
assign DRAM_BA_1 = addr[21];

always @(*) begin
	case (state)
	ST_RESET0: DRAM_ADDR = 12'b100000;
	ST_RAS0:   DRAM_ADDR = addr[19:8];
	default:   DRAM_ADDR = {4'b0100,addr[7:0]};
	endcase
	case (state)
	ST_RESET0:   {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b000;
	ST_RAS0:     {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b011;
	ST_READ0:    {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N,DRAM_UDQM,DRAM_LDQM} = 5'b10100;
	ST_WRITE0:   {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N,DRAM_UDQM,DRAM_LDQM} = {3'b100,ubn,lbn};
	ST_WRITE2:   {DRAM_UDQM,DRAM_LDQM} = 2'b00;
	ST_REFRESH0: {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b001;
	default:     {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b111;
	endcase
end

always @(posedge clk100) begin
	if (reset) begin
		state <= ST_RESET0; exrd <= 0; exwen <= 1'b1;
	end else begin
		case (state)
		ST_RESET0: state <= ST_RESET1;
		ST_RESET1: state <= ST_IDLE;
		ST_IDLE:
		begin
			if(rdv==0) begin exrd <= rd; exwen <= we_n; end
			addr <= iaddr; data <= idata;
			ubn<=ub_n;lbn<=lb_n;rdvid<=rdv;
			{memcpubusy,memvidbusy}<=2'b00;
			casex ({rd,exrd,we_n,exwen,rdv})
			5'b10110: {state,memcpubusy} <= {ST_RAS0,1'b1};
			5'b00010: {state,memcpubusy} <= {ST_RAS0,1'b1};
			5'bxxxx1: {state,memvidbusy} <= {ST_RAS0,1'b1};
			default: state <= ST_IDLE;
			endcase
		end
		ST_RAS0: state <= ST_RAS1;
		ST_RAS1:
			casex ({exrd,exwen,rdvid})
			3'b110: state <= ST_READ0;
			3'b000: state <= ST_WRITE0;
			3'bxx1: state <= ST_READ0;
			default: state <= ST_IDLE;
			endcase
		ST_READ0: state <= ST_READ1;
		ST_READ1: state <= ST_READ2;
		ST_READ2: case (rdvid)
		1'b0: {state,odata[7:0]} <= {ST_IDLE,lbn?DRAM_DQ[15:8]:DRAM_DQ[7:0]};
		1'b1:	{state,odata[15:0]} <= {ST_REFRESH0,DRAM_DQ[15:0]};
		endcase
		ST_WRITE0: state <= ST_WRITE1;
		ST_WRITE1: state <= ST_WRITE2;
		ST_WRITE2: state <= ST_IDLE;
		ST_REFRESH0: state <= ST_REFRESH1;
		ST_REFRESH1: state <= ST_REFRESH2;
		ST_REFRESH2: state <= ST_REFRESH3;
		ST_REFRESH3: state <= ST_IDLE;
		default: state <= ST_IDLE;
		endcase
	end
end
	
endmodule
