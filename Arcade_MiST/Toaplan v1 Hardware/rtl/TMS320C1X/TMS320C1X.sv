module TMS320C1X
(
	input              CLK,
	input              RST_N,
	input              EN,
	
	input              CE_F,
	input              CE_R,
	
	input              RS_N,
	input              INT_N,
	input              BIO_N,
	
	output reg [11: 0] A,
	input      [15: 0] DI,
	output reg [15: 0] DO,
    
    output reg [11: 0] PC,
    input      [15: 0] ROM_Q,
    
	output reg         WE_N,
	output reg         DEN_N,
	output reg         MEN_N
);

	import TMS320C1X_PKG::*;
	
//	bit  [11: 0] PC;
	bit  [11: 0] STACK[4];
	ST_t         ST;
	bit  [15: 0] AR[2];
	bit  [15: 0] T;
	bit  [31: 0] P;
	bit  [31: 0] ACC;
	bit          BIO;
	
	DecInstr_t   DECI;
	bit  [15: 0] IC;
	bit  [15: 0] IW;
	bit  [ 1: 0] STATE;
	bit  [15: 0] DBI;
	bit  [15: 0] DBO;
	bit  [31: 0] ALU_R;
	bit          ALU_V;
	bit          AR_N;
	bit  [15: 0] AR_NEXT;
	bit          WE;
	bit          DEN;
	bit          MEN;
	
//	bit  [15: 0] ROM_Q;
    
//	TMS320C1X_ROM #(rom_file) ROM (
//		.CLK(CLK),
//		.ADDR(PC),
//		.Q(ROM_Q)
//	);
	
	assign DECI = IDecode(IC, STATE);
	
	wire [ 7: 0] RAM_A = !IC[7] ? {ST.DP,IC[6:0]} : AR[ST.ARP][7:0];
	bit  [15: 0] RAM_Q;
    
//	TMS320C1X_RAM RAM
//    (
//		.CLK(CLK),
//		.WADDR(!DECI.RAMN ? RAM_A : RAM_A + 8'd1),
//		.DATA(DBO),
//		.WREN(DECI.RAMW & EN & CE_R),
//		.RADDR(RAM_A),
//		.Q(RAM_Q)
//	);

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) internal_ram
(
    .clock_a ( CLK ),
    .address_a ( !DECI.RAMN ? RAM_A : RAM_A + 8'd1 ),
    .wren_a ( DECI.RAMW & EN & CE_R ),
    .data_a ( DBO ),
    .q_a ( RAM_Q )   
);
	
	wire [11: 0] PC_NEXT = PC + 12'd1;
	
	assign AR_N = DECI.ARW || DECI.ARD ? IC[8] : ST.ARP;
	always_comb begin
		case (IC[5:4])
			2'b10: AR_NEXT <= AR[AR_N] + 16'd1;
			2'b01: AR_NEXT <= AR[AR_N] - 16'd1;
			default: AR_NEXT <= AR[AR_N];
		endcase
	end
	
	always_comb begin
		bit [15: 0] ACC_SH;
	
		if (DECI.ASH)
			case (IC[10:8])
				default: ACC_SH = ACC[31:16];
				3'b001:  ACC_SH = ACC[30:15];
				3'b100:  ACC_SH = ACC[27:12];
			endcase
		else
			ACC_SH = ACC[15:0];
			
		case (DECI.DOS)
			DOS_ACC: DBO <= ACC_SH;
			DOS_AR:  DBO <= AR_NEXT;
			DOS_ST:  DBO <= ST;
			DOS_NPC: DBO <= PC_NEXT;
			DOS_DM:  DBO <= RAM_Q;
			DOS_PORT:DBO <= DI;
			default: DBO <= '0;
		endcase

		case (DECI.DIS)
			DIS_DM:    DBI <= RAM_Q;
			DIS_ACC:   DBI <= ACC_SH;
			DIS_IMM8:  DBI <= {8'h00,IC[7:0]};
			DIS_IMM13: DBI <= {{3{IC[12]}},IC[12:0]};
			DIS_STACK: DBI <= {4'h0,STACK[0]};
			default:   DBI <= '0;
		endcase
	end
	
	always_comb begin
		bit [31: 0] ALU_S;
		bit [31: 0] ADDER_RES;
		bit         ADDER_Z;
		bit         ADDER_V;
		bit [31: 0] SUBC_RES;
		bit [31: 0] ABS_RES;
		bit [31: 0] LOGER_RES;
		
		case (DECI.ALUS)
			AS_SHIFT: ALU_S = ShiftLeft(DBI, IC[11:8], 1'b1);
			AS_SH16:  ALU_S = ShiftLeft(DBI, 5'd16, 1'b0);
			AS_SH0:   ALU_S = ShiftLeft(DBI, 5'd0, 1'b0);
			AS_P:     ALU_S = P;
			default:  ALU_S = '0;
		endcase
	
		ADDER_RES = CarryAdder(ACC, ALU_S, DECI.ALUCD[0]); 
		ADDER_Z = ~|ADDER_RES;
		ADDER_V = ((ACC[31] ^ ALU_S[31]) ^ ~DECI.ALUCD[0]) & (ACC[31] ^ ADDER_RES[31]);
		SUBC_RES = ~ADDER_RES[31] || ADDER_Z ? {ADDER_RES[30:0],1'b1} : {ACC[30:0],1'b0};
		ABS_RES = ACC ^ {32{ACC[31]}} + {31'h00000000,ACC[31]};
		
		LOGER_RES = Log(ACC, ALU_S, DECI.ALUCD); 
		
		case (DECI.ALUOP)
			AT_ADD:  ALU_R <= ADDER_V && ST.OVM ? {ACC[31],{31{~ACC[31]}}} : ADDER_RES;
			AT_SUBC: ALU_R <= SUBC_RES;
			AT_ABS:  ALU_R <= ABS_RES;
			AT_LOG:  ALU_R <= LOGER_RES;
			default: ALU_R <= ALU_S;
		endcase 
		ALU_V <= ADDER_V;
	end
	
	
	always @(posedge CLK or negedge RST_N) begin		
		if (!RST_N) begin
			ACC <= '0;
			T <= '0;
			AR <= '{2{'0}};
			ST <= ST_INIT;
		end
		else if (!RS_N) begin
			ACC <= '0;
			T <= '0;
			AR <= '{2{'0}};
			ST <= ST_INIT;
		end
		else if (EN && CE_R) begin
			if (DECI.ACCW)
				ACC <= ALU_R;
				
			if (DECI.TW)
				T <= DBI;
				
			if (DECI.PW)
				P <= Mult(T, DBI);
			
			if (DECI.ARW) begin
				AR[AR_N] <= DBI;
			end
			if (DECI.ARD) begin
				AR[AR_N] <= AR[AR_N] - 16'd1;
			end
			if (DECI.ARM && (!DECI.ARW || IC[8])) begin
				AR[AR_N] <= AR_NEXT;
			end
			
			
			if (DECI.ARM && !IC[3]) begin
				ST.ARP <= IC[0];
			end
			
			case (DECI.STU)
				STU_LD:  {ST.OV,ST.OVM,ST.ARP,ST.DP} <= {DBI[15],DBI[14],DBI[8],DBI[0]};
				STU_INT: ST.INTM <= IC[0];
				STU_DP:  ST.DP <= DBI[0];
				STU_OVM: ST.OVM <= IC[0];
				STU_OV:  ST.OV <= ST.OV | ALU_V;
			endcase
			if (DECI.LST && IC == 16'hF500) begin
				ST.OV <= 0;
			end
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin		
		bit ACC_Z,ACC_N,AR_Z;
		bit COND;
		bit INT_N_OLD;
		bit INT_PEND;
		
		if (!RST_N) begin
			IC <= 16'h7F80; // NOP
			IW <= '0;
			PC <= '0;
			STACK <= '{4{'0}};
			BIO <= 0;
			STATE <= '0;
			INT_PEND <= 0;
		end else if (!RS_N) begin
			IC <= 16'h7F80; // NOP
			PC <= '0;
			STATE <= '0;
			INT_PEND <= 0;
		end else if (EN && CE_F) begin
			if (!STATE) begin
				IC <=  ROM_Q;
			end else if (DECI.IWR) begin
				IW <= ROM_Q;
			end
			
			if (!STATE) begin
				if (INT_PEND && !ST.INTM) begin
//					IC <= 16'hFF01;  // BZ  branch
                    IC <= 16'h7F80; // NOP
                    STACK[0] <= PC[11:0];
                    STACK[1] <= STACK[0];
                    STACK[2] <= STACK[1];
                    STACK[3] <= STACK[2];
                    PC <= 16'h0022;
					INT_PEND <= 0;
				end
			end
		end else if (EN && CE_R) begin
			ACC_Z = ~|ACC;
			ACC_N = ACC[31];
			AR_Z = ~|AR[ST.ARP][8:0];
			case (IC[11:8])
				4'h4: COND = !AR_Z; //BANZ
				4'h5: COND = ST.OV; //BV
				4'h6: COND = BIO; //BIOZ
				4'h8: COND = 1; //CALL
				4'h9: COND = 1; //B
				4'hA: COND =  ACC_N; //BLZ
				4'hB: COND =  ACC_N || ACC_Z; //BLEZ
				4'hC: COND = !ACC_N; //BGZ
				4'hD: COND = !ACC_N || ACC_Z; //BGEZ
				4'hE: COND = !ACC_Z; //BNZ
				4'hF: COND =  ACC_Z; //BZ
				default: COND = 1;
			endcase
			
			
			if (!DECI.TBLR && !DECI.TBLW && !DECI.PORTR && !DECI.PORTW)
				PC <= PC_NEXT;
				
//			if (DECI.PCW)
//				PC <= DBI[11:0];
//			else if (DECI.PCB && COND)
//				PC <= IW[11:0];
//			else if (DECI.PCR)
//				PC <= 12'h002;

//	typedef enum bit[1:0] {
//		PCU_NONE = 2'b00, 
//		PCU_DATA = 2'b01, 
//		PCU_BR   = 2'b10,
//		PCU_ROUT = 2'b11
//	} PCUpdate_t; 
    
			case (DECI.PCU)
				PCU_DATA: PC <= DBI[11:0];
				PCU_BR: if (COND) PC <= IW[11:0];
				PCU_ROUT: PC <= 12'h002;
			endcase
				
			STATE <= STATE + 2'd1;
			if (DECI.LST) begin
				STATE <= '0;
			end
			
			if (DECI.POP) begin
				STACK[0] <= STACK[1];
				STACK[1] <= STACK[2];
				STACK[2] <= STACK[3];
			end
			if (DECI.PUSH) begin
				STACK[0] <= DBO[11:0];
				STACK[1] <= STACK[0];
				STACK[2] <= STACK[1];
				STACK[3] <= STACK[2];
			end
			
			INT_N_OLD <= INT_N;
			if (!INT_N && INT_N_OLD)
				INT_PEND <= 1;
				
			BIO <= ~BIO_N;
		end
	end
	
	always @(posedge CLK or negedge RST_N) begin		
		if (!RST_N) begin
			DO <= '0;
			WE <= 0;
			DEN <= 0;
			MEN <= 0;
		end
		else if (!RS_N) begin
			WE <= 0;
			DEN <= 0;
			MEN <= 0;
		end
		else if (EN && CE_R) begin
			WE = 0;
			if (DECI.PORTW || DECI.TBLW) begin
				DO <= RAM_Q;
				WE <= 1;
			end
				
			DEN <= 0;
			if (DECI.PORTR)
				DEN <= 1;
				
			MEN <= 0;
			if (DECI.TBLR)
				MEN <= 1;
		end
	end
	
	assign A = DEN || WE ? {9'b000000000,IC[10:8]} : PC;
	assign WE_N = ~WE;
	assign DEN_N = ~DEN;
	assign MEN_N = ~MEN;
	
endmodule
