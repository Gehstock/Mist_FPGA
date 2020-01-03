// Provides ucode routine entries (A1/A3) for each opcode
// Also checks for illegal opcode and priv violation

// This is one of the slowest part of the processor.
// But no need to optimize or pipeline because the result is not needed until at least 4 cycles.
// IR updated at the least one microinstruction earlier.
// Just need to configure the timing analizer correctly.

module uaddrDecode( 
	input [15:0] opcode,
	output [UADDR_WIDTH-1:0] a1, a2, a3,
	output logic isPriv, isIllegal, isLineA, isLineF,
	output [15:0] lineBmap);
	
	wire [3:0] line = opcode[15:12];
	logic [3:0] eaCol, movEa;

	onehotEncoder4 irLineDecod( line, lineBmap);
	
	assign isLineA = lineBmap[ 'hA];
	assign isLineF = lineBmap[ 'hF];
	
	pla_lined pla_lined( .movEa( movEa), .col( eaCol),
		.opcode( opcode), .lineBmap( lineBmap),
		.palIll( isIllegal), .plaA1( a1), .plaA2( a2), .plaA3( a3) );
	
	// ea decoding   
	assign eaCol = eaDecode( opcode[ 5:0]);
	assign movEa = eaDecode( {opcode[ 8:6], opcode[ 11:9]} );

	// EA decode
	function [3:0] eaDecode;
	input [5:0] eaBits;
	begin
	unique case( eaBits[ 5:3])
	3'b111:
		case( eaBits[ 2:0])
		3'b000:   eaDecode = 7;            // Absolute short
		3'b001:   eaDecode = 8;            // Absolute long
		3'b010:   eaDecode = 9;            // PC displacement
		3'b011:   eaDecode = 10;           // PC offset
		3'b100:   eaDecode = 11;           // Immediate
		default:  eaDecode = 12;           // Invalid
		endcase
         
	default:   eaDecode = eaBits[5:3];      // Register based EAs
	endcase
	end
	endfunction
	
	
	/*
	Privileged instructions:

	ANDI/EORI/ORI SR
	MOVE to SR
	MOVE to/from USP
	RESET
	RTE
	STOP
	*/
	
	always_comb begin
		unique case( lineBmap)
           
		// ori/andi/eori SR      
		'h01:   isPriv = ((opcode & 16'hf5ff) == 16'h007c);
      
		'h10:
			begin
			// No priority !!!
				if( (opcode & 16'hffc0) == 16'h46c0)        // move to sr
					isPriv = 1'b1;
				
				else if( (opcode & 16'hfff0) == 16'h4e60)   // move usp
					isPriv = 1'b1;
		
				else if(	opcode == 16'h4e70 ||			// reset
							opcode == 16'h4e73 ||			// rte
							opcode == 16'h4e72)				// stop
					isPriv = 1'b1;
				else
					isPriv = 1'b0;
			end
         
		default:   isPriv = 1'b0;
		endcase
	end

	
endmodule 