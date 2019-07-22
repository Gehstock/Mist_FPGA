module vdp_sram(
	clk40m,
	clk40m_n,
	rst_n,
	vram_req,
	vram_wr,
	vram_ack,
	vram_addr,
	vram_rdata,
	sram_a,
	sram_din,
	sram_doe,
	sram_oe_n,
	sram_we_n
);

	input		clk40m;
	input		clk40m_n;
	input		rst_n;

	input		vram_req;
	input		vram_wr;
	output	vram_ack;
	input		[ 13 : 0 ] vram_addr;
	output	[ 7 : 0 ] vram_rdata;

	output	[ 13 : 0 ] sram_a;
	input		[ 7 : 0 ] sram_din;
	output	sram_doe;
	output	sram_oe_n;
	output	sram_we_n;
	
	// SRAM controller, 3 cycles per access.
	reg [ 7 : 0 ] vram_rdata;
	reg vram_active;
	reg [ 13 : 0 ] sram_a;
	reg sram_doe;
	reg sram_oe_n;
	reg sram_pwe_n;
	reg [ 1 : 0 ] vram_state;
	reg vram_ack;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			vram_active <= 0;
			sram_doe <= 0;
			sram_oe_n <= 1;
			sram_pwe_n <= 1;
			vram_state <= 0;
			vram_ack <= 0;
		end else begin
			case( vram_state )
				0: begin
					if( vram_req ) begin
						vram_active <= 1;
						sram_a <= vram_addr;
						sram_pwe_n <= !vram_wr;
						vram_state <= 1;
					end else begin
						vram_active <= 0;
						sram_pwe_n <= 1;
						vram_state <= 0;
					end
					sram_doe <= 0;
					sram_oe_n <= 1;
					if( vram_active && !sram_oe_n ) begin
						vram_rdata <= sram_din;
					end
					vram_ack <= 0;
				end
				1: begin
					sram_oe_n <= !( vram_active && sram_pwe_n );
					sram_doe <= !sram_pwe_n;
					vram_state <= 2;
					vram_ack <= 0;
				end
				2: begin
					sram_pwe_n <= 1;
					vram_state <= 0;
					vram_ack <= 1;
				end
				3: begin
					// Illegal state.
					vram_active <= 0;
					sram_doe <= 0;
					sram_oe_n <= 1;
					sram_pwe_n <= 1;
					vram_ack <= 0;
					vram_state <= 0;
				end
			endcase
		end
	end

	// WE* on half clock for pulse width, addr setup/hold.
	reg sram_we_n;
	always @( negedge rst_n or posedge clk40m_n ) begin
		if( !rst_n ) begin
			sram_we_n <= 1;
		end else begin
			sram_we_n <= sram_pwe_n;
		end
	end

endmodule
