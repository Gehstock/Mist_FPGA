module vdp_cpu(
	clk40m,
	rst_n,
	cpu_vram_port,
	cpu_vdp_port,
	cpu_a,
	cpu_din,
	cpu_dout,
	cpu_doe,
	cpu_in_n,
	cpu_out_n,
	cpu_int_n,
	vram_cpu_req,
	vram_cpu_ack,
	vram_cpu_wr,
	vram_cpu_a,
	vram_cpu_wdata,
	vram_cpu_rdata,
	g1_mode,
	g2_mode,
	multi_mode,
	text_mode,
	gmode,
	blank_n,
	spr_size,
	spr_mag,
	ntb,
	colb,
	pgb,
	sab,
	spgb,
	color1,
	color0,
	spr_nolimit,
	spr_collide,
	spr_5,
	spr_5num,
	start_vblank,
	set_mode
);

	input		clk40m;
	
	input		rst_n;
	input		[ 7 : 0 ] cpu_vram_port;
	input		[ 7 : 0 ] cpu_vdp_port;
	input		[ 7 : 0 ] cpu_a;
	input		[ 7 : 0 ] cpu_din;
	output	[ 7 : 0 ] cpu_dout;
	output	cpu_doe;
	input		cpu_in_n;
	input		cpu_out_n;
	output	cpu_int_n;

	output	vram_cpu_req;
	input		vram_cpu_ack;
	output	vram_cpu_wr;
	output	[ 13 : 0 ] vram_cpu_a;
	output	[ 7 : 0 ] vram_cpu_wdata;
	input		[ 7 : 0 ] vram_cpu_rdata;
	
	output	g1_mode;
	output	g2_mode;
	output	multi_mode;
	output	text_mode;
	output	gmode;
	output	blank_n;
	output	spr_size;
	output	spr_mag;
	output	[ 3 : 0 ] ntb;
	output	[ 7 : 0 ] colb;
	output	[ 2 : 0 ] pgb;
	output	[ 6 : 0 ] sab;
	output	[ 2 : 0 ] spgb;
	output	[ 3 : 0 ] color1;
	output	[ 3 : 0 ] color0;
	output	spr_nolimit;
	
	input		spr_collide;
	input		spr_5;
	input		[ 4 : 0 ] spr_5num;
	input		start_vblank;
	input		set_mode;

	wire in_sel = !cpu_in_n && ( cpu_a == cpu_vram_port || cpu_a == cpu_vdp_port );
	wire out_sel = !cpu_out_n && ( cpu_a == cpu_vram_port || cpu_a == cpu_vdp_port );
	wire mode = ( cpu_a == cpu_vdp_port );

	// Synchronize CPU interface.
	reg in_1, in_2, in_3;
	reg out_1, out_2, out_3;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			in_1 <= 0;
			in_2 <= 0;
			in_3 <= 0;
			out_1 <= 0;
			out_2 <= 0;
			out_3 <= 0;
		end else begin
			in_1 <= in_sel;
			in_2 <= in_1;
			in_3 <= in_2;
			out_1 <= out_sel;
			out_2 <= out_1;
			out_3 <= out_2;
		end
	end
	
	wire cpu_wr = out_2 && !out_3;
	wire cpu_rd = !in_2 && in_3;		// After CPU has read data.
	
	// Freeze status register at beginning of read.
	// Must be sure what value of flags the CPU sees for auto-clearing.
	// spr_5 must always correspond to spr_5num.
	reg stat_f, stat_c, stat_5;
	reg [ 4 : 0 ] stat_5num;
	reg [ 7 : 0 ] stat;
	always @( posedge clk40m ) begin
		if( in_2 && !in_3 ) begin
			stat <= { stat_f, stat_c, stat_5, stat_5num };
		end
	end
	
	// Interrupt status.
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			stat_f <= 0;
			stat_c <= 0;
			stat_5 <= 0;
		end else if( start_vblank ) begin
			stat_f <= 1;
			stat_c <= spr_collide;
			stat_5 <= spr_5;
			stat_5num <= spr_5num;
		end else if( cpu_rd && mode ) begin
			stat_f <= 0;
			stat_c <= 0;
			stat_5 <= 0;
		end
	end
	
	// Register fields.
	reg xm3, xm2, xm1;
	reg xblank_n;
	reg ien;
	reg xspr_size;
	reg xspr_mag;
	reg [ 3 : 0 ] ntb;
	reg [ 7 : 0 ] colb;
	reg [ 2 : 0 ] pgb;
	reg [ 6 : 0 ] sab;
	reg [ 2 : 0 ] spgb;
	reg [ 3 : 0 ] color1;
	reg [ 3 : 0 ] color0;
	
	// Added (nonstandard) functions.
	reg xspr_nolimit;
	
	// Capture CPU write data.
	reg cpu_byte2;
	reg [ 7 : 0 ] vram_cpu_wdata;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			cpu_byte2 <= 0;
			xm3 <= 0;
			xm2 <= 0;
			xm1 <= 0;
			xblank_n <= 0;
			ien <= 0;
			xspr_size <= 0;
			xspr_mag <= 0;
			xspr_nolimit <= 0;
			ntb <= 0;
			colb <= 0;
			pgb <= 0;
			sab <= 0;
			spgb <= 0;
			color1 <= 0;
			color0 <= 0;
		end else begin
			if( cpu_wr ) begin
				if( mode ) begin
					if( cpu_byte2 ) begin
						if( cpu_din[ 7 ] ) begin
							if( cpu_din[ 6 ] == 1'b0 ) begin
								// Register write.
								case( cpu_din[ 5 : 0 ] )
									0: begin
										xm3 <= vram_cpu_a[ 1 ];
									end
									1: begin
										xspr_mag <= vram_cpu_a[ 0 ];
										xspr_size <= vram_cpu_a[ 1 ];
										xm2 <= vram_cpu_a[ 3 ];
										xm1 <= vram_cpu_a[ 4 ];
										ien <= vram_cpu_a[ 5 ];
										xblank_n <= vram_cpu_a[ 6 ];
										end
									2: begin
										ntb <= vram_cpu_a[ 3 : 0 ];
									end
									3: begin
										colb <= vram_cpu_a[ 7 : 0 ];
									end
									4: begin
										pgb <= vram_cpu_a[ 2 : 0 ];
										end
									5: begin
										sab <= vram_cpu_a[ 6 : 0 ];
									end
									6: begin
										spgb <= vram_cpu_a[ 2 : 0 ];
									end
									7: begin
										color1 <= vram_cpu_a[ 7 : 4 ];
										color0 <= vram_cpu_a[ 3 : 0 ];
									end
									31: begin
										xspr_nolimit <= vram_cpu_a[ 0 ];
									end
									default: begin
									end
								endcase
							end
						end
					end
					cpu_byte2 <= !cpu_byte2;
				end else begin
					// VRAM write (malformed if cpu_byte2, but do it anyway).
					vram_cpu_wdata <= cpu_din;
					cpu_byte2 <= 0;
				end
			end else if( cpu_rd ) begin
				cpu_byte2 <= 0;
			end
		end
	end
	
	// Certain register bits mustn't change mid-screen.
	reg g1_mode;
	reg g2_mode;
	reg multi_mode;
	reg text_mode;
	reg gmode;		// Any valid graphics mode.
	reg spr_size;
	reg spr_mag;
	reg spr_nolimit;
	reg blank_n;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			g1_mode <= 1;
			g2_mode <= 0;
			multi_mode <= 0;
			text_mode <= 0;
			gmode <= 1;
			spr_size <= 0;
			spr_mag <= 0;
			spr_nolimit <= 0;
			blank_n <= 0;
		end else if( set_mode ) begin
			g1_mode <= ( { xm1, xm2, xm3 } == 3'b000 );
			g2_mode <= ( { xm1, xm2, xm3 } == 3'b001 );
			multi_mode <= ( { xm1, xm2, xm3 } == 3'b010 );
			text_mode <= ( { xm1, xm2, xm3 } == 3'b100 );
			gmode <= !xm1;
			spr_size <= xspr_size;
			spr_mag <= xspr_mag;
			spr_nolimit <= xspr_nolimit;
			blank_n <= xblank_n;
		end
	end

	wire set_addr_lsb = cpu_wr && mode && !cpu_byte2;
	wire set_addr_msb = cpu_wr && mode && cpu_byte2 && !cpu_din[ 7 ];
		
		// VRAM CPU access state machine.
	reg [ 13 : 0 ] vram_cpu_a;
	reg [ 7 : 0 ] vram_rdata; 
	reg vram_cpu_req;
	reg vram_cpu_wr;
	reg addr_mod;
	wire start_req = ( ( cpu_wr || cpu_rd ) && !mode && ( !vram_cpu_req || vram_cpu_ack ) )
		              || ( set_addr_msb && !cpu_din[ 6 ] && ( !vram_cpu_req || vram_cpu_ack ) );
	wire start_wr = !mode && cpu_wr;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			vram_cpu_a <= 0;
			vram_rdata <= 0;
			vram_cpu_req <= 0;
			vram_cpu_wr <= 0;
			addr_mod <= 0;
		end else begin
			if( vram_cpu_req && vram_cpu_ack ) begin
				if( !start_req ) begin
					vram_cpu_req <= 0;
				end
				if( !addr_mod && !set_addr_lsb && !set_addr_msb ) begin
					// Auto-increment CPU VRAM address.
					vram_cpu_a <= vram_cpu_a + 1'b1;
				end
				addr_mod <= 0;
				if( !vram_cpu_wr ) begin
					vram_rdata <= vram_cpu_rdata;
				end
			end
			if( start_req ) begin
				vram_cpu_req <= 1;
				vram_cpu_wr <= start_wr;
			end
			if( set_addr_lsb ) begin
				if( vram_cpu_req && !vram_cpu_ack ) begin
					addr_mod <= 1;
				end
				vram_cpu_a[ 7 : 0 ] <= cpu_din;
			end
			if( set_addr_msb ) begin
				if( vram_cpu_req && !vram_cpu_ack ) begin
					addr_mod <= 1;
				end
				vram_cpu_a[ 13 : 8 ] <= cpu_din[ 5 : 0 ];
			end
		end
	end
	
	// CPU read data.
	assign cpu_dout = ( mode ? stat : vram_rdata );
	assign cpu_doe = in_sel;
	
	// CPU interrupt.
	assign cpu_int_n = ( stat_f && ien ) ? 1'b0 : 1'bZ;

endmodule
