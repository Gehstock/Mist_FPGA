package TMS320C1X_PKG; 

	typedef enum bit[2:0] {
		DOS_ACC  = 3'b000,
		DOS_AR   = 3'b001,
		DOS_ST   = 3'b010,
		DOS_NPC  = 3'b011,
		DOS_DM   = 3'b100,
		DOS_PORT = 3'b101
	} DataOutSrc_t; 
	
	typedef enum bit[2:0] {
		DIS_DM    = 3'b000,
		DIS_ACC   = 3'b001,
		DIS_IMM8  = 3'b010,
		DIS_IMM13 = 3'b011,
		DIS_STACK = 3'b100
	} DataInSrc_t; 
	
	typedef enum bit[2:0] {
		AS_SHIFT = 3'b000, 
		AS_SH16  = 3'b001, 
		AS_SH0   = 3'b010, 
		AS_P     = 3'b011,
		AS_ZERO  = 3'b100
	} ALUSrc_t; 
	
	typedef enum bit[3:0] {
		AT_NOP   = 4'b0000, 
		AT_ADD   = 4'b0001, 
		AT_SUBC  = 4'b0011,
		AT_ABS   = 4'b0100,
		AT_LOG   = 4'b0101
	} ALUType_t; 
	
	typedef enum bit[2:0] {
		STU_NONE = 3'b000,
		STU_LD   = 3'b001,
		STU_INT  = 3'b010,
		STU_DP   = 3'b011,
		STU_OVM  = 3'b100,
		STU_OV   = 3'b101
	} STUpdate_t;
	
	typedef enum bit[1:0] {
		PCU_NONE = 2'b00, 
		PCU_DATA = 2'b01, 
		PCU_BR   = 2'b10,
		PCU_ROUT = 2'b11
	} PCUpdate_t; 
	

	typedef struct packed
	{
		DataInSrc_t  DIS; 	//Data bus in source
		DataOutSrc_t DOS; 	//Data bus out source
		ALUSrc_t     ALUS; 	//ALU source
		ALUType_t    ALUOP;	//ALU operation
		bit  [ 1: 0] ALUCD;	//ALU code
		bit          ASH;		//Accumulator out shift
		bit          ACCW;	//Accumulator write 
		bit          ARR;		//ARn read 
		bit          ARW;		//ARn write 
		bit          ARM;		//ARn modify 
		bit          ARD;		//ARn decrement 
		bit          TW;		//T write 
		bit          PW;		//P write 
		STUpdate_t   STU;		//STATUS write 
		PCUpdate_t   PCU;		//PC write 
//		bit          PCW;		//PC write
//		bit          PCB;		//PC brunch 
//		bit          PCR;		//PC routine set
		bit          IWR;		//Instruction word read 
		bit          POP;		//Stack pop 
		bit          PUSH;	//Stack push 
		bit          RAMN;	//RAM next address 
		bit          RAMW;	//RAM write 
		bit          TBLR;	//Table read 
		bit          TBLW;	//Table write 
		bit          PORTR;	//Port read 
		bit          PORTW;	//Port write 
		bit          LST;		//Last state		
		bit          ILI;		//Illegal instruction 
	} DecInstr_t;
	
	function DecInstr_t IDecode(input bit [15:0] IC, input bit [1:0] STATE);
		DecInstr_t DECI;
		
		DECI.DIS = DIS_DM;
		DECI.DOS = DOS_ACC;
		DECI.ALUS = AS_SHIFT;
		DECI.ALUOP = AT_NOP;
		DECI.ALUCD = 2'b00;
		DECI.ASH = 0;
		DECI.ACCW = 0;
		DECI.ARR = 0;
		DECI.ARW = 0;
		DECI.ARM = 0;
		DECI.ARD = 0;
		DECI.TW = 0;
		DECI.PW = 0;
		DECI.STU = STU_NONE;
		DECI.PCU = PCU_NONE;
//		DECI.PCW = 0;
//		DECI.PCB = 0;
//		DECI.PCR = 0;
		DECI.IWR = 0;
		DECI.POP = 0;
		DECI.PUSH = 0;
		DECI.RAMN = 0;
		DECI.RAMW = 0;
		DECI.TBLR = 0;
		DECI.TBLW = 0;
		DECI.PORTR = 0;
		DECI.PORTW = 0;
		DECI.LST = 1;
		DECI.ILI = 0;
		casex (IC[15:12])
			4'b000x: begin	//ADD (ACC+(*DMA<<S)->ACC)/SUB (ACC-(*DMA<<S)->ACC)
				DECI.DIS = DIS_DM;
				DECI.ALUS = AS_SHIFT;
				DECI.ALUOP = AT_ADD;
				DECI.ALUCD = {1'b0,IC[12]};
				DECI.ACCW = 1;
				DECI.STU = STU_OV;
				DECI.ARM = IC[7];
			end
			4'b0010: begin	//LAC ((*DMA<<S)->ACC)
				DECI.DIS = DIS_DM;
				DECI.ALUS = AS_SHIFT;
				DECI.ALUOP = AT_NOP;
				DECI.ACCW = 1;
				DECI.ARM = IC[7];
			end
			4'b0011: begin
				casex (IC[11:8])
					4'b000x: begin	//SAR (ARn->*DMA)
						DECI.DOS = DOS_AR;
						DECI.ARR = 1;
						DECI.ARM = IC[7];
						DECI.RAMW = 1;
					end
					4'b100x: begin	//LAR (*DMA->ARn)
						DECI.DIS = DIS_DM;
						DECI.ARW = 1;
						DECI.ARM = IC[7];
					end
					default: DECI.ILI = 1;
				endcase
			end
			4'b0100: begin
				casex (IC[11:8])
					4'b0xxx: begin	//IN (PORT->*DMA)
						case (STATE)
						2'd0: begin
							DECI.PORTR = 1;
							DECI.LST = 0;
						end
						default: begin
							DECI.DOS = DOS_PORT;
							DECI.ARM = IC[7];
							DECI.RAMW = 1;
							DECI.LST = 1;
						end
						endcase
					end
					4'b1xxx: begin	//OUT (*DMA->PORT)
						case (STATE)
						2'd0: begin
							DECI.DIS = DIS_DM;
							DECI.ARM = IC[7];
							DECI.PORTW = 1;
							DECI.LST = 0;
						end
						default: begin
							DECI.LST = 1;
						end
						endcase
					end
				endcase
			end
			4'b0101: begin
				casex (IC[11:8])
					4'b0000: begin	//SACL (ACC->*DMA)
						DECI.DOS = DOS_ACC;
						DECI.ASH = 0;
						DECI.ARM = IC[7];
						DECI.RAMW = 1;
					end
					4'b1xxx: begin	//SACH ((ACC<<S)>>16->*DMA)
						DECI.DOS = DOS_ACC;
						DECI.ASH = 1;
						DECI.ARM = IC[7];
						DECI.RAMW = 1;
					end
					default: DECI.ILI = 1;
				endcase
			end
			4'b0110: begin
				casex (IC[11:8])
					4'b00x0: begin	//ADDH (ACC+(*DMA<<16)->ACC)/SUBH (ACC-(*DMA<<16)->ACC)
						DECI.DIS = DIS_DM;
						DECI.ALUS = AS_SH16;
						DECI.ALUOP = AT_ADD;
						DECI.ALUCD = {1'b0,IC[9]};
						DECI.ACCW = 1;
						DECI.STU = STU_OV;
						DECI.ARM = IC[7];
					end
					4'b00x1: begin	//ADDS (ACC+*DMA->ACC)/SUBS (ACC-*DMA->ACC)
						DECI.DIS = DIS_DM;
						DECI.ALUS = AS_SH0;
						DECI.ALUOP = AT_ADD;
						DECI.ALUCD = {1'b0,IC[9]};
						DECI.ACCW = 1;
						DECI.STU = STU_OV;
						DECI.ARM = IC[7];
					end
					4'b0100: begin	//SUBC (ACC-(*DMA<<16)->ACC)
						DECI.DIS = DIS_DM;
						DECI.ALUS = AS_SH16;
						DECI.ALUOP = AT_SUBC;
						DECI.ALUCD = 2'b01;
						DECI.ACCW = 1;
						DECI.ARM = IC[7];
					end
					4'b0101: begin //ZALH  ((*DMA<<16)->ACC)
						DECI.DIS = DIS_DM;
						DECI.ALUS = AS_SH16;
						DECI.ALUOP = AT_NOP;
						DECI.ACCW = 1;
						DECI.ARM = IC[7];
					end
					4'b0110: begin //ZALS  (*DMA->ACC)
						DECI.DIS = DIS_DM;
						DECI.ALUS = AS_SH0;
						DECI.ALUOP = AT_NOP;
						DECI.ACCW = 1;
						DECI.ARM = IC[7];
					end
					4'b0111: begin //TBLR 
						case (STATE)
						2'd0: begin	//(PC+1->*TOS,ACC->PC)
							DECI.DOS = DOS_NPC;
							DECI.PUSH = 1;
							DECI.ASH = 0;
							DECI.DIS = DIS_ACC;
							DECI.PCU = PCU_DATA;
							DECI.LST = 0;
						end
						2'd1: begin	//(PORT->*DMA)
							DECI.DOS = DOS_PORT;
							DECI.ARM = IC[7];
							DECI.RAMW = 1;
							DECI.TBLR = 1;
							DECI.LST = 0;
						end
						default: begin //(*TOS->PC)
							DECI.DIS = DIS_STACK;
							DECI.PCU = PCU_DATA;
							DECI.POP = 1;
						end
						endcase
					end
					4'b1000: begin	//MAR 
						DECI.ARM = IC[7];
					end
					4'b1001: begin	//DMOV  (*DMA->*(DMA+1))
						DECI.DOS = DOS_DM;
						DECI.ARM = IC[7];
						DECI.RAMN = 1;
						DECI.RAMW = 1;
					end
					4'b1010: begin	//LT (DB->T)
						DECI.DIS = DIS_DM;
						DECI.TW = 1;
						DECI.ARM = IC[7];
					end
					4'b1011: begin	//LTD (ACC+P->ACC,*DMA->T,*DMA->*(DMA+1))
						DECI.ALUS = AS_P;
						DECI.ALUOP = AT_ADD;
						DECI.ALUCD = 2'b00;
						DECI.ACCW = 1;
						DECI.STU = STU_OV;
						DECI.DIS = DIS_DM;
						DECI.TW = 1;
						DECI.ARM = IC[7];
						DECI.DOS = DOS_DM;
						DECI.RAMN = 1;
						DECI.RAMW = 1;
					end
					4'b1100: begin	//LTA (ACC+P->ACC,*DMA->T)
						DECI.ALUS = AS_P;
						DECI.ALUOP = AT_ADD;
						DECI.ALUCD = 2'b00;
						DECI.ACCW = 1;
						DECI.STU = STU_OV;
						DECI.DIS = DIS_DM;
						DECI.ARM = IC[7];
						DECI.TW = 1;
					end
					4'b1101: begin	//MPY (T * *DMA->P)
						DECI.DIS = DIS_DM;
						DECI.PW = 1;
					end
					4'b1110: begin	//LDPK  (K[0]->DP)
						DECI.DIS = DIS_IMM8;
						DECI.STU = STU_DP;
					end
					4'b1111: begin	//LDP  (*DMA[0]->DP)
						DECI.DIS = DIS_DM;
						DECI.ARM = IC[7];
						DECI.STU = STU_DP;
					end
				endcase
			end
			4'b0111: begin
				casex (IC[11:8])
					4'b000x: begin	//LARK (K->ARn)
						DECI.DIS = DIS_IMM8;
						DECI.ARW = 1;
					end
					4'b1000,			//XOR (ACC^*DMA->ACC)
					4'b1001,			//AND (ACC&*DMA->ACC)
					4'b1010: begin	//OR (ACC|*DMA->ACC)
						DECI.DIS = DIS_DM;
						DECI.ALUS = AS_SH0;
						DECI.ALUOP = AT_LOG;
						DECI.ALUCD = IC[9:8];
						DECI.ACCW = 1;
						DECI.ARM = IC[7];
					end
					4'b1011: begin	//LST (*DMA->ST)
						DECI.DIS = DIS_DM;
						DECI.ARM = IC[7];
						DECI.STU = STU_LD;
					end
					4'b1100: begin	//SST (ST->*DMA)
						DECI.DOS = DOS_ST;
						DECI.ARM = IC[7];
						DECI.RAMW = 1;
					end
					4'b1101: begin //TBLW 
						case (STATE)
						2'd0: begin	//(PC+1->*TOS,ACC->PC)
							DECI.DOS = DOS_NPC;
							DECI.PUSH = 1;
							DECI.ASH = 0;
							DECI.DIS = DIS_ACC;
							DECI.PCU = PCU_DATA;
							DECI.LST = 0;
						end
						2'd1: begin	//(*DMA->PORT)
							DECI.DIS = DIS_DM;
							DECI.ARM = IC[7];
							DECI.TBLW = 1;
							DECI.LST = 0;
						end
						default: begin //(*TOS->PC)
							DECI.DIS = DIS_STACK;
							DECI.PCU = PCU_DATA;
							DECI.POP = 1;
						end
						endcase
					end
					4'b1110: begin	//LACK (K->ACC)
						DECI.DIS = DIS_IMM8;
						DECI.ALUS = AS_SH0;
						DECI.ALUOP = AT_NOP;
						DECI.ACCW = 1;
					end
					4'b1111: begin
						casex (IC[7:0])
							8'b10000000: begin	//NOP
							end
							8'b10000001,			//DINT (1->INTM)
							8'b10000010: begin	//EINT (0->INTM)
								DECI.STU = STU_INT;
							end
							8'b10001000: begin	//ABS  (abs(ACC)->ACC)
								DECI.ALUOP = AT_ABS;
								DECI.ACCW = 1;
							end
							8'b10001001: begin	//ZAC  (0->ACC)
								DECI.ALUS = AS_ZERO;
								DECI.ALUOP = AT_NOP;
								DECI.ACCW = 1;
							end
							8'b10001010: begin	//ROVM  (0->OVM)
								DECI.STU = STU_OVM;
							end
							8'b10001011: begin	//SOVM  (1->OVM)
								DECI.STU = STU_OVM;
							end
							8'b10001100: begin	//CALA  (PC+1->*TOS,ACC->PC)
								case (STATE)
								2'd0: begin
									DECI.DOS = DOS_NPC;
									DECI.PUSH = 1;
									DECI.LST = 0;
								end
								default: begin
									DECI.ASH = 0;
									DECI.DIS = DIS_ACC;
									DECI.PCU = PCU_DATA;
								end
								endcase
							end
							8'b10001101: begin	//RET (*TOS->PC)
								case (STATE)
								2'd0: begin
									DECI.LST = 0;
								end
								default: begin
									DECI.DIS = DIS_STACK;
									DECI.PCU = PCU_DATA;
									DECI.POP = 1;
								end
								endcase
							end
							8'b10001110: begin	//PAC (P->ACC)
								DECI.ALUS = AS_P;
								DECI.ALUOP = AT_NOP;
								DECI.ALUCD = 2'b00;
								DECI.ACCW = 1;
							end
							8'b10001111: begin	//APAC (ACC+P->ACC)
								DECI.ALUS = AS_P;
								DECI.ALUOP = AT_ADD;
								DECI.ALUCD = 2'b00;
								DECI.ACCW = 1;
								DECI.STU = STU_OV;
							end
							8'b10010000: begin	//SPAC (ACC-P->ACC)
								DECI.ALUS = AS_P;
								DECI.ALUOP = AT_ADD;
								DECI.ALUCD = 2'b01;
								DECI.ACCW = 1;
								DECI.STU = STU_OV;
							end
							8'b10011100: begin	//PUSH (ACC[11:0]->*TOS)
								case (STATE)
								2'd0: begin
									DECI.ASH = 0;
									DECI.DOS = DOS_ACC;
									DECI.PUSH = 1;
									DECI.LST = 0;
								end
								default: begin
									
								end
								endcase
							end
							8'b10011101: begin	//POP (*TOS->ACC)
								case (STATE)
								2'd0: begin
									DECI.DIS = DIS_STACK;
									DECI.ALUS = AS_SH0;
									DECI.ALUOP = AT_NOP;
									DECI.ACCW = 1;
									DECI.LST = 0;
								end
								default: begin
									DECI.POP = 1;
								end
								endcase
							end
							default: DECI.ILI = 1;
						endcase
					end
					default: DECI.ILI = 1;
				endcase
			end
			4'b100x: begin	//MPYK (T*K->P)
				DECI.DIS = DIS_IMM13;
				DECI.PW = 1;
			end
			4'b1111: begin
				casex (IC[11:8])
					4'b0000: begin //ISR
						case (STATE)
						2'd0: begin
							DECI.STU = STU_INT;
							DECI.LST = 0;
						end
						default: begin
							DECI.PCU = PCU_ROUT;
							DECI.DOS = DOS_NPC;
							DECI.PUSH = 1;
						end
						endcase
					end
					4'b0100, 		//BANZ addr
					4'b0101, 		//BV addr
					4'b0110, 		//BIOZ addr
					4'b1000, 		//CALL addr  (PC+2->*TOS,addr->PC)
					4'b1001, 		//B addr
					4'b1010, 		//BLZ addr
					4'b1011, 		//BLEZ addr
					4'b1100, 		//BGZ addr
					4'b1101, 		//BGEZ addr
					4'b1110, 		//BNZ addr
					4'b1111: begin //BZ addr
						case (STATE)
						2'd0: begin
							DECI.LST = 0;
						end
						default: begin
							DECI.IWR = 1;
							DECI.PCU = PCU_BR;
							DECI.DOS = DOS_NPC;
							DECI.PUSH = (IC[11:8] == 4'b1000);
							DECI.ARD = (IC[11:8] == 4'b0100);
						end
						endcase
					end
					default: DECI.ILI = 1;
				endcase
			end
			default: DECI.ILI = 1;
		endcase
	
		return DECI;
	endfunction 
	
	typedef struct packed		
	{
		bit         OV;		
		bit         OVM;			
		bit         INTM;			
		bit [ 3: 0] ONE;
		bit         ARP;			
		bit [ 5: 0] ONE2;
		bit         ZERO;			
		bit         DP;			
	} ST_t;
	parameter bit [15:0] ST_INIT = 16'h1EFC; 
	
	function bit [31:0] CarryAdder(input bit [31:0] a, input bit [31:0] b, input bit sub);
		bit [31: 0] b2;
		bit [31: 0] res;
		
		b2 = b ^ {32{sub}};
		res = a + b2 + {{31{1'b0}},sub};
		
		return res;
	endfunction
	
	function bit [31:0] Log(input bit [31:0] a, input bit [31:0] b, input bit [1:0] code);
		bit [31: 0] res;
		
		case (code)
			2'b00: res =  a ^ b;
			2'b01: res =  a & b;
			2'b10: res =  a | b;
			2'b11: res =  ~b;
		endcase
		return res;
	endfunction
	
	function bit [31:0] ShiftLeft(input bit [15:0] val, input bit [4:0] sa, input bit sext);
		bit [31: 0] val0, tmp0, tmp1, tmp2, tmp3, tmp4;
		
		val0 = {{16{val[15]&sext}},val};
		tmp0 = !sa[0] ? val0 : {val0[30:0],{ 1{1'b0}} };
		tmp1 = !sa[1] ? tmp0 : {tmp0[29:0],{ 2{1'b0}} };
		tmp2 = !sa[2] ? tmp1 : {tmp1[27:0],{ 4{1'b0}} };
		tmp3 = !sa[3] ? tmp2 : {tmp2[23:0],{ 8{1'b0}} };
		tmp4 = !sa[4] ? tmp3 : {tmp3[15:0],{16{1'b0}} };
		return tmp4;
	endfunction
	
	function bit [31:0] Mult(input bit [15:0] a, input bit [15:0] b);
		return $signed(a) * $signed(b);
	endfunction
	
endpackage
