// Get current OP from row & col
module aluGetOp( input [15:0] row, input [2:0] col, input isCorf,
	output logic [4:0] aluOp);
	
	always_comb begin
		aluOp = 'X;
		unique case( col)  
		1:   aluOp = OP_AND;
		5:   aluOp = OP_EXT;

		default:
			unique case( 1'b1)
				row[1]:
					unique case( col)
					2: aluOp = OP_SUB;
					3: aluOp = OP_SUBC;
					4,6: aluOp = OP_SLAA;
					endcase
				
				row[2]:
					unique case( col)
					2: aluOp = OP_ADD;
					3: aluOp = OP_ADDC;
					4: aluOp = OP_ASR;
					endcase

				row[3]:
					unique case( col)
					2: aluOp = OP_ADDX;
					3: aluOp = isCorf ? OP_ABCD : OP_ADD;
					4: aluOp = OP_ASL;
					endcase
                  
				row[4]:
					aluOp = ( col == 4) ? OP_LSL : OP_AND;
				
				row[5],
				row[6]:
					unique case( col)
					2: aluOp = OP_SUB;
					3: aluOp = OP_SUBC;
					4: aluOp = OP_LSR;
					endcase
				
				row[7]:					// MUL
					unique case( col)
					2: aluOp = OP_SUB;
					3: aluOp = OP_ADD;
					4: aluOp = OP_ROXR;
					endcase
               
				row[8]:
					// OP_AND For EXT.L
					// But would be more efficient to change ucode and use column 1 instead of col3 at ublock extr1!				
					unique case( col)
					2: aluOp = OP_EXT;
					3: aluOp = OP_AND;
					4: aluOp = OP_ROXR;
					endcase
               
				row[9]:
					unique case( col)
					2: aluOp = OP_SUBX;
					3: aluOp = OP_SBCD;
					4: aluOp = OP_ROL;
					endcase

				row[10]:
					unique case( col)
					2: aluOp = OP_SUBX;
					3: aluOp = OP_SUBC;
					4: aluOp = OP_ROR;
					endcase
                
				row[11]:
					unique case( col)
					2: aluOp = OP_SUB0;
					3: aluOp = OP_SUB0;
					4: aluOp = OP_ROXL;
					endcase
                
				row[12]:	aluOp = OP_ADDX;               
				row[13]:	aluOp = OP_EOR;
				row[14]:	aluOp = (col == 4) ? OP_EOR : OP_OR;
				row[15]:	aluOp = (col == 3) ? OP_ADD : OP_OR;		// OP_ADD used by DBcc
				
			endcase         
		endcase
	end
endmodule 