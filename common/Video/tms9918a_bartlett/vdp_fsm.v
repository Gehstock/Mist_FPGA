module vdp_fsm(
	clk40m,
	rst_n,
	g1_mode,
	g2_mode,
	multi_mode,
	gmode,
	text_mode,
	spr_size,
	spr_mag,
	blank_n,
	ntb,
	colb,
	pgb,
	sab,
	spgb,
	hsync,
	vsync,
	start_vblank,
	set_mode,
	visible,
	border,
	vram_req,
	vram_wr,
	vram_ack,
	vram_addr,
	vram_rdata,
	vram_cpu_req,
	vram_cpu_wr,
	vram_cpu_ack,
	vram_cpu_a,
	pattern,
	color,
	load,
	spr_pattern,
	spr_color,
	spr_collide,
	spr_5,
	spr_5num,
	spr_nolimit
);

	input		clk40m;
	input		rst_n;
	
	input		g1_mode;
	input		g2_mode;
	input		multi_mode;
	input		gmode;
	input		text_mode;
	input		spr_size;
	input		spr_mag;
	input		blank_n;
	
	input		[ 3 : 0 ] ntb;
	input		[ 7 : 0 ] colb;
	input		[ 2 : 0 ] pgb;
	input		[ 6 : 0 ] sab;
	input		[ 2 : 0 ] spgb;
	
	output	hsync;
	output	vsync;
	output	start_vblank;
	output	set_mode;
	output	visible;
	output	border;
	
	output	vram_req;
	output	vram_wr;
	input		vram_ack;
	output	[ 13 : 0 ] vram_addr;
	input		[ 7 : 0 ] vram_rdata;
	input		vram_cpu_req;
	input		vram_cpu_wr;
	output	vram_cpu_ack;
	input		[ 13 : 0 ] vram_cpu_a;
	
	output	[ 7 : 0 ] pattern;
	output	[ 7 : 0 ] color;
	output	load;
	
	output	spr_pattern;
	output	[ 3 : 0 ] spr_color;
	output	spr_collide;
	output	spr_5;
	output	[ 4 : 0 ] spr_5num;
	input		spr_nolimit;
	
	// 800x600 @ 60 Hz SVGA, pixel frequency = 40 MHz, +HSYNC, +VSYNC.
	// H: 800 active, 40 front porch, 128 sync, 88 back porch = 1056 pixel clocks per line.
	// V: 600 active, 1 front porch, 4 sync, 23 back porch = 628 lines.
	// TMS9918A pixels are 3x3 SVGA pixels each (768x576 visible non-border).
`define H_ACT		800
`define H_FP		40
`define H_SYNC		128
`define H_BP		88
`define H_WIDTH	`H_ACT+`H_FP+`H_SYNC+`H_BP
`define V_ACT		600
`define V_FP		1
`define V_SYNC		4
`define V_BP		23
`define V_HEIGHT	`V_ACT+`V_FP+`V_SYNC+`V_BP
	reg [ 10 : 0 ] h;
	reg [ 9 : 0 ] v;
	reg hsync;
	reg vsync;
	reg start_vblank;
	reg line_end;
	reg set_mode;
	reg visible;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			h <= 0;
			v <= 0;
			hsync <= 0;
			vsync <= 0;
			start_vblank <= 0;
			line_end <= 0;
			set_mode <= 0;
			visible <= 1;
		end else begin
			hsync <= ( h >= `H_ACT+`H_FP-1 && h < `H_ACT+`H_FP+`H_SYNC-1 );
			line_end <= ( h == `H_WIDTH-2 );
			set_mode <= ( h == `H_WIDTH-3 ) && ( v == `V_HEIGHT-1 );
			start_vblank <= ( h == `H_WIDTH-2 ) && ( v == `V_ACT-1 );
			visible <= ( h >= `H_WIDTH-2 && ( v == `V_HEIGHT-1 || v < `V_ACT-1 ) )
			           || ( h < `H_ACT-2 && v <= `V_ACT-1 );
			if( line_end ) begin
				h <= 0;
				if( v >= `V_ACT+`V_FP-1 && v < `V_ACT+`V_FP+`V_SYNC-1 ) begin
					vsync <= 1;
				end else begin
					vsync <= 0;
				end
				if( v == `V_HEIGHT-1 ) begin
					v <= 0;
				end else begin
					v <= v + 1'b1;
				end
			end else begin
				h <= h + 1'b1;
			end
		end
	end

`define BORD_TOP 12
`define BORD_BOT 12
	reg [ 1 : 0 ] vrep;			// Vertical line repeat x3.
	reg [ 7 : 0 ] scan_line;	// Active scan line, 0-191+.
	reg [ 7 : 0 ] scan_next;	// Scan line + 1.
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			vrep <= 0;
			scan_line <= 192;
			scan_next <= 193;
		end else if( line_end ) begin
			if( v == `BORD_TOP-4 ) begin
				// For sprite setup vrep must be valid for 3 scan lines before active region.
				vrep <= 0;
				scan_line <= 8'hFF;	// Bit 3 must be odd for sprites.
				scan_next <= 0;
			end else if( vrep == 2 ) begin
				vrep <= 0;
				scan_line <= scan_next;
				scan_next <= scan_next + 1'b1;
			end else begin
				vrep <= vrep + 1'b1;
			end
		end
	end
	
	wire [ 2 : 0 ] line = scan_line[ 2 : 0 ];			// Scan line within pattern, 0-7.
	wire [ 5 : 0 ] multi_row = scan_line[ 7 : 2 ];	// Multicolor block row, 0-47.
	wire [ 4 : 0 ] row = scan_line[ 7 : 3 ];			// Pattern row, 0-23.

  // Border delineation.
  // Top and bottom borders are 12 SVGA lines each.
  // In text mode, left and right borders are 40 SVGA pixels each.
  // In graphics modes, left and right borders are 16 SVGA pixels each.
`define BORD_GRAPH 16
`define BORD_TEXT 40
	reg border;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			border <= 1;
		end else if( v < `BORD_TOP || v >= `V_ACT-`BORD_BOT ) begin
			border <= 1;
		end else if( blank_n && text_mode ) begin
			border <= !( h >= `BORD_TEXT-2 && h < `H_ACT-`BORD_TEXT-2 );
		end else if( blank_n && gmode ) begin
			border <= !( h >= `BORD_GRAPH-2 && h < `H_ACT-`BORD_GRAPH-2 );
		end else begin
			border <= 1;
		end
  end

	// Horizontal pattern counter, all modes.
	wire ghnext, thnext;
	reg [ 5 : 0 ] col;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			col <= 0;
		end else if( line_end ) begin
			col <= 0;
		end else if( ghnext || thnext ) begin
			col <= col + 1'b1;
		end
	end
	
	// Graphics modes horizontal counter.
	reg [ 4 : 0 ] ghcount;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			ghcount <= 0;
		end else if( line_end || ghnext || !gmode ) begin
			ghcount <= 0;
		end else begin
			ghcount <= ghcount + 1'b1;
		end
	end

	assign ghnext = ( ghcount == 23 );
	wire ghload = ( ghcount == 14 );
	
	// Text mode horizontal counter.
	reg [ 4 : 0 ] thcount;
	reg [ 9 : 0 ] text_pos;		// 40*pattern row + column.
	reg [ 9 : 0 ] save_pos;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			thcount <= 0;
			text_pos <= 0;
			save_pos <= 0;
		end else if( !text_mode ) begin
			thcount <= 0;
		end else if( line_end ) begin
			thcount <= 0;
			if( v == `BORD_TOP-1 ) begin
				text_pos <= 0;
				save_pos <= 0;
			end else if( vrep != 2 || line != 7 ) begin
				// For 23 additional lines in text row, restore text position.
				text_pos <= save_pos;
			end else begin
				save_pos <= text_pos;
			end
		end else if( thnext ) begin
			thcount <= 0;
			text_pos <= text_pos + 1'b1;
		end else if( thcount == 3 && ( h < 24 || h >= 744 || v < `BORD_TOP || v >= `V_ACT-`BORD_BOT ) ) begin
			// Allow more CPU accesses during non-active time.
			thcount <= 0;
		end else begin
			thcount <= thcount + 1'b1;
		end
	end
	
	assign thnext = ( thcount == 17 );
	wire thload = ( thcount == 14 );
	
	// Load pattern into pixel shifter.
	assign load = ( ghload || thload );
	
	reg [ 4 : 0 ] spr_num;
	always @( vrep or col ) begin
		spr_num = 5'hXX;
		if( vrep == 0 ) begin
			spr_num = { 1'b0, col[ 4 : 1 ] };
		end else if( vrep == 1 ) begin
			spr_num = { 1'b1, col[ 4 : 1 ] };
		end else if( vrep == 2 ) begin
			spr_num = col[ 4 : 0 ];
		end
	end

	reg [ 31 : 0 ] spr_xvld;
	reg spr_load;

	// VRAM requests.  Must be mutually exclusive and at least 4 clocks apart.
	wire pre_gnreq = ( ghcount == 0 ) && ( col < 32 ) && gmode;
	wire pre_gpreq = ( ghcount == 4 ) && ( col < 32 ) && gmode;
	wire pre_gcreq = ( ghcount == 8 ) && ( col < 32 ) && ( g1_mode || g2_mode );
	wire pre_gxreq = ( ghcount == 20 ) && gmode;
	
	// Sprite data is read from VRAM during the three SVGA lines prior to the corresponding three VDP lines.
	// Sprite 0 is read on v = 9,10,11 for the first active VDP line at v = 12,13,14.
	// Sprite 31 is read on v = 582,583,584 for the last active VDP line at v = 585,586,587.
	wire pre_svreq = ( ghcount == 12 ) && !col[ 0 ] && ( col < 32 )
	                 && ( v > 8 ) && ( v < 585 ) && ( vrep == 0 || vrep == 1 )
						  && spr_load && blank_n && gmode;
	wire pre_snreq = ( ghcount == 16 ) && !col[ 0 ] && ( col < 32 )
                    && ( v > 8 ) && ( v < 585 ) && ( vrep == 0 || vrep == 1 )
						  && spr_load && blank_n && gmode;
	wire pre_sp0req = ( ghcount == 12 ) && col[ 0 ] && ( col < 32 )
	                  && ( v > 8 ) && ( v < 585 ) && ( vrep == 0 || vrep == 1 )
							&& spr_xvld[ spr_num ] && blank_n && gmode;
	wire pre_sp1req = ( ghcount == 16 ) && col[ 0 ] && ( col < 32 )
                     && ( v > 8 ) && ( v < 585 ) && ( vrep == 0 || vrep == 1 )
							&& spr_xvld[ spr_num ] && blank_n && gmode && spr_size;
	wire pre_sareq = ( ghcount == 12 ) && ( col < 32 )
                    && ( v > 8 ) && ( v < 585 ) && vrep == 2
	                 && spr_xvld[ spr_num ] && blank_n && gmode;
	wire pre_shreq = ( ghcount == 16 ) && ( col < 32 )
	                 && ( v > 8 ) && ( v < 585 ) && vrep == 2
	                 && spr_xvld[ spr_num ] && blank_n && gmode;

	wire pre_tnreq = ( thcount == 4 ) && text_mode;
	wire pre_tpreq = ( thcount == 8 ) && text_mode;
	wire pre_txreq = ( thcount == 0 || thcount == 12 ) && text_mode;
	
	reg nreq, preq, creq, ureq, xureq;
	reg svreq, shreq, snreq, sareq, sp0req, sp1req;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			nreq <= 0;
			preq <= 0;
			creq <= 0;
			ureq <= 0;
			svreq <= 0;
			shreq <= 0;
			snreq <= 0;
			sareq <= 0;
			sp0req <= 0;
		end else begin
			nreq <= blank_n && ( scan_line < 192 ) && ( pre_gnreq || pre_tnreq );
			preq <= blank_n && ( scan_line < 192 ) && ( pre_gpreq || pre_tpreq );
			creq <= blank_n && ( scan_line < 192 ) && pre_gcreq;
			ureq <= ( v >= `BORD_TOP-4 && v < `V_ACT-`BORD_BOT ) && blank_n && ( pre_gxreq || pre_txreq );
			xureq <= ( h[ 1 : 0 ] == 2'b00 ) && ( !blank_n
				                                   || ( !gmode && !text_mode )
				                                   || ( v < `BORD_TOP-4 || v >= `V_ACT-`BORD_BOT ) );
			svreq <= pre_svreq;
			shreq <= pre_shreq;
			snreq <= pre_snreq;
			sareq <= pre_sareq;
			sp0req <= pre_sp0req;
			sp1req <= pre_sp1req;
		end
	end

	wire xreq = vram_cpu_req && ( ureq || xureq ) && !vram_cpu_ack;
	
	wire vram_req = ( nreq || preq || creq || svreq || shreq || snreq || sareq || sp0req || sp1req || xreq );
	wire vram_wr = ( xreq && vram_cpu_wr );

	// With the 3-state SRAM controller, ACK is asserted one clock before valid read data.
	reg vram_ack2;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			vram_ack2 <= 0;
		end else begin
			vram_ack2 <= vram_ack;
		end
	end
	
	reg [ 9 : 0 ] reqs;
	always @( posedge clk40m ) begin
		if( vram_req ) begin
			// Store each req so we know what to do with the ack.
			reqs <= { svreq, shreq, snreq, sareq, sp0req, sp1req, nreq, preq, creq, xreq };
		end else	if( vram_ack2 ) begin
			reqs <= 0;
		end
	end

	assign vram_cpu_ack = reqs[ 0 ] && vram_ack2;

	// Sprite data RAM, 256 x 8-bit words.
	// Synchronous inputs and outputs.
	reg [ 7 : 0 ] spr_addr;
	wire spr_wren;
	wire [ 7 : 0 ] spr_rdata;
	vdp_sprdata sprdata(
		spr_addr,
		clk40m,
		vram_rdata,
		spr_wren,
		spr_rdata
	);
	
	// Sprite data RAM address.
	always @( col or scan_line or reqs or vrep or ghcount or spr_num ) begin
		if( col < 32 ) begin
			// Write data address.
			spr_addr[ 7 : 2 ] = { !scan_line[ 0 ], spr_num };
			spr_addr[ 1 : 0 ] = 2'bXX;
			if( reqs[ 5 ] ) begin
				spr_addr[ 1 : 0 ] = 2'b00;	// Pattern 0.
			end else if( reqs[ 4 ] ) begin
				spr_addr[ 1 : 0 ] = 2'b01;	// Pattern 1.
			end else if( reqs[ 6 ] ) begin
				spr_addr[ 1 : 0 ] = 2'b10;	// Early clock/color.
			end else if( reqs[ 8 ] ) begin
				spr_addr[ 1 : 0 ] = 2'b11;	// Horizontal position.
			end
		end else begin
			// Read data address.
			spr_addr = { ( vrep[ 1 ] ^ scan_line[ 0 ] ), col[ 2 : 0 ], ghcount[ 3 : 0 ] };
		end
	end
	
	// Sprite RAM data write enable.
	assign spr_wren = vram_ack2 && ( reqs[ 4 ] || reqs[ 5 ] || reqs[ 6 ] || reqs[ 8 ] );
	
	// Sprite arithmetic.
	wire [ 5 : 0 ] spr_side = spr_size ? ( spr_mag ? 6'd32 : 6'd16 ) : ( spr_mag ? 6'd16 : 6'd8 );
	wire [ 7 : 0 ] spr_min = vram_rdata;
	wire [ 7 : 0 ] spr_max = vram_rdata + spr_side;
	wire spr_start = ( h == `H_WIDTH-1+`BORD_GRAPH-32*3-4 );
	wire spr_setup = ( spr_start && vrep == 2 );
	
	// Store VRAM read data.
	reg [ 7 : 0 ] name;
	reg [ 7 : 0 ] pattern;
	reg [ 7 : 0 ] color;
	reg [ 4 : 0 ] spr_line;
	reg [ 7 : 0 ] spr_name;
	reg spr_5;
	reg [ 4 : 0 ] spr_5num;
	reg [ 2 : 0 ] spr_count;
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			spr_5 <= 0;
		end else if( start_vblank ) begin
			spr_5 <= 0;
		end else if( spr_setup ) begin
			spr_load <= 1;
			spr_xvld <= 0;
			spr_count <= 0;
		end else if( vram_ack2 ) begin
			if( reqs[ 3 ] ) begin
				name <= vram_rdata;
			end 
			if( reqs[ 2 ] ) begin
				if( !multi_mode ) begin
					pattern <= vram_rdata;
				end else begin
					pattern <= 8'hF0;
					color <= vram_rdata;
				end
			end
			if( reqs[ 1 ] ) begin
				color <= vram_rdata;
			end
			if( reqs[ 9 ] ) begin
				if( vram_rdata == 208 ) begin
					spr_load <= 0;
				end else if( !spr_nolimit && spr_count == 4 ) begin
					if( !spr_5 ) begin
						spr_5num <= spr_num;
					end
					spr_5 <= 1;
					spr_load <= 0;
				end else if( scan_next+8'd32 > spr_min+8'd32 && scan_next+8'd32 <= spr_max+8'd32 ) begin
					spr_xvld[ spr_num ] <= 1;
					spr_line <= scan_next[ 4 : 0 ]-vram_rdata[ 4 : 0 ]-5'h1;
					spr_count <= spr_count + 1'b1;
				end
			end
			if( reqs[ 7 ] ) begin
				spr_name <= vram_rdata;
			end
		end
	end
	
	// VRAM address MUX.  Big MUX.
	reg [ 13 : 0 ] vram_addr;
	always @( xreq or vram_cpu_a
		       or nreq or ntb or text_mode or row or col
		       or preq or g1_mode or g2_mode or multi_mode or pgb or name or line or multi_row or text_pos
				 or creq or colb or vram_rdata
				 or svreq or shreq or snreq or sareq or sp0req or sp1req
				 or spr_num or spr_size or spr_mag or spr_name or spr_line or spgb or sab ) begin
		vram_addr = 14'hXXXX;
		if( xreq ) begin
			vram_addr = vram_cpu_a;
		end
		if( nreq ) begin
			vram_addr[ 13 : 10 ] = ntb;
			if( text_mode ) begin
				vram_addr[ 9 : 0 ] = text_pos;
			end else begin
				vram_addr[ 9 : 0 ] = { row, col[ 4 : 0 ] };
			end
		end
		if( preq ) begin
			// Name is not set until next clock, use vram_rdata instead.
			if( g1_mode || text_mode ) begin
				vram_addr = { pgb, vram_rdata, line };
			end else if( g2_mode ) begin
				vram_addr = { pgb[ 2 ], row[ 4 : 3 ], vram_rdata, line };
			end else if( multi_mode ) begin
				vram_addr = { pgb, vram_rdata, multi_row[ 2 : 0 ] };
			end
		end
		if( creq ) begin
			if( g1_mode ) begin
				vram_addr = { colb, 1'b0, name[ 7 : 3 ] };
			end else if( g2_mode ) begin
				vram_addr = { colb[ 2 ], row[ 4 : 3 ], name, line };
			end
		end
		if( svreq ) begin
			vram_addr = { sab, spr_num, 2'b00 };
		end
		if( shreq ) begin
			vram_addr = { sab, spr_num, 2'b01 };
		end
		if( snreq ) begin
			vram_addr = { sab, spr_num, 2'b10 };
		end
		if( sareq ) begin
			vram_addr = { sab, spr_num, 2'b11 };
		end
		if( sp0req ) begin
			if( !spr_size ) begin
				if( !spr_mag ) begin
					vram_addr = { spgb, spr_name, spr_line[ 2 : 0 ] };
				end else begin
					vram_addr = { spgb, spr_name, spr_line[ 3 : 1 ] };
				end
			end else begin
				if( !spr_mag ) begin
					vram_addr = { spgb, spr_name[ 7 : 2 ], 1'b0, spr_line[ 3 : 0 ] };
				end else begin
					vram_addr = { spgb, spr_name[ 7 : 2 ], 1'b0, spr_line[ 4 : 1 ] };
				end
			end
		end
		if( sp1req ) begin
			if( !spr_mag ) begin
				vram_addr = { spgb, spr_name[ 7 : 2 ], 1'b1, spr_line[ 3 : 0 ] };
			end else begin
				vram_addr = { spgb, spr_name[ 7 : 2 ], 1'b1, spr_line[ 4 : 1 ] };
			end
		end
	end

	// Sprite state machine.
	integer i;
	reg spr_found;
	reg spr_active;
	reg [ 1 : 0 ] spr_hrep;
	reg spr_pattern;
	reg [ 3 : 0 ] spr_color;
	reg spr_collide;
	reg [ 8 : 0 ] spr_hcount;
	reg [ 31 : 0 ] spr_odd;
	reg [ 4 : 0 ] snum;
	reg early;
	reg [ 31 : 0 ] spr_vld;
	reg [ 3 : 0 ] spr_col [ 0 : 31 ];
	reg [ 8 : 0 ] spr_dly [ 0 : 31 ];
	reg [ 15 : 0 ] spr_pat [ 0 : 31 ];
	always @( negedge rst_n or posedge clk40m ) begin
		if( !rst_n ) begin
			spr_collide <= 0;
			spr_active <= 0;
		end else if( start_vblank ) begin
			spr_collide <= 0;
			spr_vld <= 0;
		end else if( col >= 32 && col < 40 && ghcount >= 2 && ghcount < 18 ) begin
			spr_active <= 0;
			// Unload sprite data from RAM.
			snum = ( ( ghcount - 2'd2 ) & 4'b1100 ) >> 2;
			snum[ 4 : 2 ] = col[ 2 : 0 ];
			case( ghcount[ 1 : 0 ] )
				0: begin
					spr_col[ snum ] <= spr_rdata[ 3 : 0 ];
					early <= spr_rdata[ 7 ];
				end
				1: begin
					if( early ) begin
						spr_dly[ snum ] <= { 1'b0, spr_rdata };
					end else begin
						spr_dly[ snum ] <= 9'd32 + spr_rdata;
					end
				end
				2: begin
					spr_pat[ snum ][ 15 : 8 ] <= spr_rdata;
				end
				3: begin
					if( spr_size ) begin
						spr_pat[ snum ][ 7 : 0 ] <= spr_rdata;
					end else begin
						spr_pat[ snum ][ 7 : 0 ] <= 8'h00;
					end
				end
			endcase
		end else if( spr_start ) begin
			spr_hrep <= 2;
			spr_pattern <= 0;
			spr_odd <= 0;
			spr_hcount <= 0;
			spr_active <= 1;
			if( spr_setup ) begin
				spr_vld <= spr_xvld;
			end
		end else if( spr_active && spr_hrep == 1 ) begin
			// Multicycle path:
			// Count, pattern, color, collide clocked in when hrep 1->2 only.
			spr_found = 0;
			for( i = 0; i <= 31; i = i + 1 ) begin
				if( spr_hcount >= spr_dly[ i ] ) begin
					if( spr_vld[ i ] ) begin
						if( spr_pat[ i ][ 15 ] ) begin
							if( spr_found ) begin
								// Sprite collision.
								spr_collide <= 1;
							end else begin
								spr_color <= spr_col[ i ];
							end
							spr_found = 1;
						end
						if( !spr_mag || spr_odd[ i ] ) begin
							// Shift pattern, zero backfill.
							spr_pat[ i ] <= { spr_pat[ i ][ 14 : 0 ], 1'b0 };
						end
					end
					spr_odd[ i ] <= ~spr_odd[ i ];
				end
			end
			spr_pattern <= spr_found;
			spr_hrep <= 2;
			spr_hcount <= spr_hcount + 1'b1;
		end else if( spr_hrep == 2 ) begin
			spr_hrep <= 0;
		end else begin
			spr_hrep <= 1;
		end
	end
	
endmodule
