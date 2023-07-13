module ToaplanV1_Top(
	input					clk_sys,
	input					pll_locked,
	input					reset,
	input		[6:0]  	core_mod,
	input					pause_cpu,
	input					turbo_68k,
//------------------------------------
	input					scrollDBG,
	input		[7:0]  	p1_in,
	input		[7:0]  	p2_in,
	input		[1:0] 	start,
	input		[1:0] 	coin,
	input					b_pause,
	input					service,
	input					key_tilt,
	input					key_service,
	input		[7:0] 	sw0,
	input		[7:0] 	sw1,
	input		[7:0] 	sw2,
//------------------------------------
	output				hsync,
	output				vsync,
	output				hblank,
	output				vblank,
	input		[3:0] 	hs_offset,
	input		[3:0] 	vs_offset,
	input		[3:0] 	hs_width,
	input		[3:0] 	vs_width,
	input					refresh_mod,
	output	[4:0] 	r,
	output	[4:0] 	g,
	output	[4:0] 	b,
	input					ntsc,
	input 	[1:0] 	opl2_level,
//------------------------------------	
	output	[15:0] 	audio_l,
	output	[15:0] 	audio_r,
//------------------------------------	
    input         ioctl_download,
    input         ioctl_index,
    input  [23:0] ioctl_addr,
    input         ioctl_wr,
    input   [7:0] ioctl_dout,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE
);

//		CoreMod 		Game
//		0				Demons World
//		1				Rally Bike
//		2				Vimana
//		3				Same! Same! Same!
//		4				Zerowing
//		5				Truxton
//		6				Out Zone
//		7				Out Zone Conversation
//		8				HellFire

wire        tile_priority_type;
wire [15:0] scroll_y_offset;
wire [15:0] scroll_x_offset = 30;
reg [7:0] p1;
reg [7:0] p2;
reg [7:0] z80_dswa;
reg [7:0] z80_dswb;
reg [7:0] z80_tjump;
reg [7:0] system;


always @ (posedge clk_sys ) begin
			p1        <= { 1'b0, p1_in[6:4], p1_in[3], p1_in[2], p1_in[1], p1_in[0] };
			p2        <= { 1'b0, p2_in[6:4], p2_in[3], p2_in[2], p2_in[1], p2_in[0] };
case (core_mod)
	0,1:	begin	//Demons World, Rally Bike

			z80_dswa  <= sw0;
			z80_dswb  <= sw1;
			z80_tjump <= sw2;
				if ( scrollDBG == 1 ) begin
					system    <= { vblank, start[1] | p1_in[7], start[0] | p1_in[7], coin[1], coin[0], service | scrollDBG, 	key_tilt, key_service };
				end else begin
					system    <= { vblank, start[1],            start[0],            coin[1], coin[0], service,             	key_tilt, key_service };
				end
			end		
	2,3:	begin	//Vimana, Same Same Same
			z80_dswa  <= sw0;
			z80_tjump <= sw2;
				if ( scrollDBG == 1 ) begin
					z80_dswb  <= { sw1[7], sw1[6] | scrollDBG, sw1[5:0] };
					system    <= { vblank, start[1] | p1_in[7], start[0] | p1_in[7], coin[1], coin[0], service, 					key_tilt, key_service };
				end else begin
					z80_dswb  <= sw1;
					system    <= { vblank, start[1],            start[0],            coin[1], coin[0], service, 					key_tilt, key_service };
				end
			end
	4,5,6,7,8:	begin
			z80_tjump <= sw2;
				if ( core_mod == 4 || core_mod == 6 || core_mod == 7 || core_mod == 8 && scrollDBG == 1 ) begin
        // zerowing, hellfire, outzone, outzone conversion debug options
					z80_dswa  <= sw0;
					z80_dswb  <= { sw1[7], sw1[6] | scrollDBG, sw1[5:0] };
					system    <= { vblank, start[1] | p1_in[7], start[0] | p1_in[7], coin[1], coin[0], service, 					key_tilt, key_service };
				end else if ( core_mod == 5 && scrollDBG == 1 ) begin
        // truxton debug options
					z80_dswa  <= { sw0[7:3], sw0[2] | scrollDBG, sw0[1:0] };
					z80_dswb  <= sw1;
					system    <= { vblank, start[1], 			  start[0], 			  coin[1], coin[0], service, 					key_tilt, key_service };
				end else begin
        // default
					z80_dswa  <= sw0;
					z80_dswb  <= sw1;
					system    <= { vblank, start[1], 			  start[0], 			  coin[1], coin[0], service, 					key_tilt, key_service };
				end
			end
endcase

end

//demon
reg  clk_3_5M, clk_7M, clk_10M, clk_14M, clk_14M_N;

reg [5:0] clk14_count;
reg [5:0] clk10_count;
reg [5:0] clk7_count;
reg [5:0] clk_3_5_count;

always @ (posedge clk_sys ) begin
    clk_10M <= 0;
    if ( turbo_68k == 0 ) begin
        // standard speed 20MHz = 10MHz 68k
        case (clk10_count)
            1: clk_10M <= 1;
            3: clk_10M <= 1;
        endcase
        if ( clk10_count == 6 ) begin
            clk10_count <= 0;
        end else if ( pause_cpu == 0 ) begin
            clk10_count <= clk10_count + 1;
        end
    end else begin
        // standard speed 35MHz = 17.5MHz 68k
        case (clk10_count)
            1: clk_10M <= 1;
        endcase
        if ( clk10_count == 1 ) begin
            clk10_count <= 0;
        end else if ( pause_cpu == 0 ) begin
            clk10_count <= clk10_count + 1;
        end
    end
    clk_7M <= ( clk7_count == 0);
    if ( clk7_count == 9 ) begin
        clk7_count <= 0;
    end else begin
        clk7_count <= clk7_count + 1;
    end
    clk_14M <= ( clk14_count == 0);
    clk_14M_N <= ( clk14_count == 2);
    if ( clk14_count == 4 ) begin
        clk14_count <= 0;
    end else begin
        clk14_count <= clk14_count + 1;
    end
    clk_3_5M <= ( clk_3_5_count == 0);
    if ( clk_3_5_count == 19 ) begin
        clk_3_5_count <= 0;
    end else if ( pause_cpu == 0 ) begin
        clk_3_5_count <= clk_3_5_count + 1;
    end
end

wire [8:0] hc, vc;

video_timing video_timing (
    .clk(clk_7M),
    .reset(reset),
    .crtc0(crtc[0]),
    .crtc1(crtc[1]),
    .crtc2(crtc[2]),
    .crtc3(crtc[3]),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hs_width(hs_width),
    .vs_width(vs_width),
    .refresh_mod(refresh_mod),
    .hc(hc),
    .vc(vc),
    .hbl_delay(hblank),
    .vbl(vblank),
    .hsync(hsync),
    .vsync(vsync)
);

wire [9:0] sprite_adj_x = 0;
wire [9:0] sprite_adj_y = 0;
wire bcu_flip_cs;
wire fcu_flip_cs;

reg [1:0] adj_layer;
reg [15:0] scroll_adj_x [3:0];
reg [15:0] scroll_adj_y [3:0];
reg layer_en [3:0];


// flip is done in the rendering so leave screen_rotate flip off
wire flip = 0;

reg tile_flip;
reg sprite_flip;

// ===============================================================
// 68000 CPU
// ===============================================================

// clock generation
reg  fx68_phi1 = 0;
wire fx68_phi2 = !fx68_phi1;

// phases for 68k clock
always @(posedge clk_sys) begin
    if ( clk_10M == 1 ) begin
        fx68_phi1 <= ~fx68_phi1;
    end
end

// CPU outputs
wire cpu_rw;        // Read = 1, Write = 0
wire cpu_as_n;      // Address strobe
wire cpu_lds_n;     // Lower byte strobe
wire cpu_uds_n;     // Upper byte strobe
wire cpu_E;
wire [2:0]cpu_fc;   // Processor state
wire cpu_reset_n_o; // Reset output signal
wire cpu_halted_n;  // Halt output

// CPU busses
wire [15:0] cpu_dout;
wire [23:0] cpu_a /* synthesis keep */;
reg  [15:0] cpu_din;

// CPU inputs
reg  dtack_n;    // Data transfer ack (always ready)
reg  ipl1_n, ipl2_n;

wire reset_n;
wire vpa_n = ~ ( cpu_lds_n == 0 && cpu_fc == 3'b111 );    // from outzone schematic

assign cpu_a[0] = reset;    // debug hack odd memory address should cause cpu exception

cc_shifter cc_reset (
    .clk_out(clk_10M),
    .i(reset_z80_n),
    .o(reset_n)
);

fx68k fx68k (
    // input
    .clk( clk_10M ),
    .enPhi1(fx68_phi1),
    .enPhi2(fx68_phi2),
    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(cpu_rw),
    .ASn( cpu_as_n),
    .LDSn(cpu_lds_n),
    .UDSn(cpu_uds_n),
//    .E(cpu_E),
//    .VMAn(),
    .FC0(cpu_fc[0]),
    .FC1(cpu_fc[1]),
    .FC2(cpu_fc[2]),
//    .BGn(),
    .oRESETn(cpu_reset_n_o),
    .oHALTEDn(cpu_halted_n),

    // input
    .VPAn( vpa_n ),
    .DTACKn(dtack_n ),
    .BERRn(1'b1),
    .BRn(1'b1),
    .BGACKn(1'b1),

    .IPL0n(1'b1),
//    .IPL1n(1'b1),
	 .IPL1n((core_mod == 2 | core_mod == 3) ? ipl1_n : 1'b1),
    .IPL2n(ipl2_n),

    // busses
    .iEdb(cpu_din),
    .oEdb(cpu_dout),
    .eab(cpu_a[23:1])
);

////////////////////////////////////////////////////
//Progress here

//todo
//
//add Vimana HW
////////////////////////////////////////////////////
always @ (posedge clk_sys) begin
    if ( clk_10M == 1 ) begin
        // tell 68k to wait for valid data. 0=ready 1=wait
        // always ack when it's not program rom
        dtack_n <= prog_rom_cs ? !prog_rom_data_valid : 0;
        // add dsp_ctrl_cs to cpu_din
        // select cpu data input based on what is active
			if (core_mod == 1) begin 
				cpu_din <= prog_rom_cs ? prog_rom_data :
            m68k_ram_cs ? ram_dout :// ram_cs
            tile_palette_cs ?  tile_palette_cpu_dout :
            sprite_palette_cs ?  sprite_palette_cpu_dout :
            shared_ram_cs ? cpu_shared_dout :
            tile_ofs_cs ? curr_tile_ofs :
            sprite_ofs_cs ? curr_sprite_ofs :
            tile_attr_cs ? cpu_tile_dout_attr :
				vblank_cs ? { 15'b0, vblank } :
				tile_attr_cs ? ( cpu_tile_dout_attr | { 4'b0, cpu_tile_dout_attr[15:12], cpu_tile_dout_attr[5:4], 6'b0 } ) :
				sprite_ram_cs ? sprite_ram_dout :
				int_en_cs ? { 15'b0, int_en } : 16'hffff;	
			end else begin					
				cpu_din <= prog_rom_cs ? prog_rom_data :
            m68k_ram_cs ? ram_dout :
            tile_palette_cs ?  tile_palette_cpu_dout :
            sprite_palette_cs ?  sprite_palette_cpu_dout :
            shared_ram_cs ? cpu_shared_dout :
            tile_ofs_cs ? curr_tile_ofs :
            sprite_ofs_cs ? curr_sprite_ofs :
            tile_attr_cs ? cpu_tile_dout_attr :
				vblank_cs ? { 15'b0, vblank } :
				tile_num_cs ? cpu_tile_dout_num :
				sprite_0_cs ? sprite_0_dout :
				sprite_1_cs ? sprite_1_dout :
				sprite_2_cs ? sprite_2_dout :
				sprite_3_cs ? sprite_3_dout :
				sprite_size_cs ? sprite_size_cpu_dout :
				frame_done_cs ? { 16 { vblank } } : // get vblank state 			
				int_en_cs ? 16'hffff :	16'hffff;	
			end
    end
end

wire        tms_reset;
reg   [7:0] tms_reset_count;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        tms_reset_count <= 0;
        tms_reset <= 1 ;
    end else begin
        if ( tms_reset_count < 50 ) begin
            tms_reset_count <= tms_reset_count + 1;
        end else begin
            tms_reset <= 0 ;
        end
    end
end

TMS320C1X dsp
(
    .CLK(clk_sys),          // (X2/CLKIN) Crystal input internal oscillator or external system clock input
    .RST_N(~reset),
    .EN(1),                 // (DEN) Data enable for device input data on D15-D0

    .CE_F(clk_14M),         // Phased clocks for chip enable
    .CE_R(clk_14M_N),       // Chip enable clock phase

    .RS_N(~tms_reset),  // (RS) Reset for initializing the device
    .INT_N(tms_int_n),  // (INT) External interrupt input
    .BIO_N(tms_bio),  // (BIO) External polling input

    .A(tms_addr),
    .DI(tms_din),
    .DO(tms_dout),

    .PC(tms_rom_addr),      // output reg [11:0] PC,
    .ROM_Q(tms_rom_dout),   // input      [15:0] ROM_Q,

    .WE_N(tms_we_n),        // (WE) Write enable for device output data on D15-D0 (OUT instruction)
    .DEN_N(tms_den_n),      // (DEN) Data enable for device input data on D15-D0 (IN instruction)
    .MEN_N(tms_men_n)       // (MEN) Memory enable indicates that D15-D0 will accept external memory instruction. (External instruction)
);

wire [11:0] tms_addr ;
reg  [15:0] tms_din ;
wire [15:0] tms_dout ;
wire        tms_we_n;
wire        tms_den_n;
wire        tms_men_n;
wire        tms_bio;
reg         tms_int_n;

wire [15:0] cpu_shared_dout;
wire  [7:0] z80_shared_dout;
reg  [15:0] z80_a;

wire [15:0] z80_addr;
reg   [7:0] z80_din;
wire  [7:0] z80_dout;

wire z80_wr_n;
wire z80_rd_n;
reg  z80_wait_n;

wire IORQ_n;
wire MREQ_n;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        z80_wait_n <= 0;
        sound_wr <= 0;
    end else if ( clk_3_5M == 1 ) begin
        z80_wait_n <= 1;
        if ( ioctl_download | ( z80_rd_n == 0 && sound_rom_1_data_valid == 0 && sound_rom_1_cs == 1 ) ) begin
            // wait if rom is selected and data is not yet available
            z80_wait_n <= 0;
        end
        if ( z80_rd_n == 0 ) begin
            if ( sound_rom_1_cs ) begin
                if ( sound_rom_1_data_valid ) begin
                    z80_din <= sound_rom_1_data;
                end else begin
                    z80_wait_n <= 0;
                end
            end else if ( sound_ram_1_cs ) begin
                z80_din <= z80_shared_dout;
            end else if ( z80_p1_cs ) begin
                z80_din <= p1;
            end else if ( z80_p2_cs ) begin
                z80_din <= p2;
            end else if ( z80_dswa_cs ) begin
                z80_din <= z80_dswa;
            end else if ( z80_dswb_cs ) begin
                z80_din <= z80_dswb;
            end else if ( z80_tjump_cs ) begin
                z80_din <= z80_tjump;
            end else if ( z80_system_cs ) begin
                z80_din <= system;
            end else if ( z80_sound0_cs ) begin
                z80_din <= opl_dout;
            end else begin
                z80_din <= 8'h00;
            end
        end
        sound_wr <= 0;
        if ( z80_wr_n == 0 ) begin
            if ( z80_sound0_cs | z80_sound1_cs ) begin
                sound_data  <= z80_dout;
                sound_addr <= { 1'b0, z80_sound1_cs }; // pad for opl3.  opl2 is single bit address
                sound_wr <= 1;
            end
        end
    end
end

reg  [1:0] sound_addr;
reg  [7:0] sound_data;
reg sound_wr;

wire [7:0] opl_dout;
wire opl_irq_n;

reg signed [15:0] sample;


wire opl_sample_clk;

jtopl #(.OPL_TYPE(2)) jtopl2
(
    .rst(~reset_n),
    .clk(clk_sys),
    .cen(clk_3_5M),
    .din(sound_data),
    .addr(sound_addr),
    .cs_n('0),
    .wr_n(~sound_wr),
    .dout(opl_dout),
    .irq_n(opl_irq_n),
    .snd(sample),
    .sample(opl_sample_clk)
);

reg  [7:0] opl2_mult;

// set the multiplier for each channel from menu

always @( posedge clk_sys, posedge reset ) begin
    if (reset) begin
        opl2_mult<=0;
    end else begin
        case( opl2_level )
            0: opl2_mult <= 8'h0c;    // 75%
            1: opl2_mult <= 8'h08;    // 50%
            2: opl2_mult <= 8'h04;    // 25%
            3: opl2_mult <= 8'h00;    // 0%
        endcase
    end
end

wire signed [15:0] mono;

jtframe_mixer #(.W0(16), .WOUT(16)) u_mix_mono(
    .rst    ( reset        ),
    .clk    ( clk_sys      ),
    .cen    ( 1'b1         ),
    // input signals
    .ch0    ( sample       ),
    .ch1    ( 16'd0        ),
    .ch2    ( 16'd0        ),
    .ch3    ( 16'd0        ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( opl2_mult    ),
    .gain1  ( 8'd0         ),
    .gain2  ( 8'd0         ),
    .gain3  ( 8'd0         ),
    .mixed  ( mono         ),
    .peak   (              )
);

always @ (posedge clk_sys ) begin
    if ( pause_cpu == 1 ) begin
        audio_l <= 0;
		  audio_r <= 0;
    end else if ( pause_cpu == 0 ) begin
        // mix audio
        audio_l <= {mono[15:0]};
		  audio_r <= {mono[15:0]};
    end
end


T80pa u_cpu(
    .RESET_n    ( reset_n & reset_z80_n ),
    .CLK        ( clk_sys ),
    .CEN_p      ( clk_3_5M ),
    .CEN_n      ( ~clk_3_5M ),

    .WAIT_n     ( z80_wait_n ), // don't wait if data is valid or rom access isn't selected
    .INT_n      ( opl_irq_n ),  // opl timer
    .NMI_n      ( 1'b1 ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_rd_n ),
    .WR_n       ( z80_wr_n ),
    .A          ( z80_addr ),
    .DI         ( z80_din  ),
    .DO         ( z80_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     (),
    .IORQ_n     ( IORQ_n ),
    .M1_n       (),
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_n ),
    .Stop       (),
    .REG        ()
);

// Chip select mux
wire prog_rom_cs;
wire scroll_ofs_x_cs;
wire scroll_ofs_y_cs;
wire ram_cs;
wire vblank_cs;
wire int_en_cs;
wire crtc_cs;
wire tile_ofs_cs;
wire tile_attr_cs;
wire tile_num_cs;
wire scroll_cs;
wire shared_ram_cs;
wire frame_done_cs; // word
wire tile_palette_cs;
wire sprite_palette_cs;
wire sprite_ofs_cs;
wire sprite_cs; // *** offset needs to be auto-incremented
wire sprite_size_cs; // *** offset needs to be auto-incremented
wire sprite_ram_cs;

wire dsp_ctrl_cs;
wire dsp_addr_cs;
wire dsp_r_cs;
wire dsp_bio_cs;

//TMS32010 mapping may not be necessary here or the chipselect
//wire dsp_rom_1_cs;    // map(0x000, 0x7ff).rom();

wire z80_p1_cs;
wire z80_p2_cs;
wire z80_dswa_cs;
wire z80_dswb_cs;
wire z80_system_cs;
wire z80_tjump_cs;
wire z80_sound0_cs;
wire z80_sound1_cs;

chip_select cs (.*);

wire sprite_0_cs      = ( curr_sprite_ofs[1:0] == 2'b00 ) & sprite_cs;
wire sprite_1_cs      = ( curr_sprite_ofs[1:0] == 2'b01 ) & sprite_cs;
wire sprite_2_cs      = ( curr_sprite_ofs[1:0] == 2'b10 ) & sprite_cs;
wire sprite_3_cs      = ( curr_sprite_ofs[1:0] == 2'b11 ) & sprite_cs;

reg reset_z80_n;
wire reset_z80_cs;
wire sound_rom_1_cs   = ( MREQ_n == 0 && z80_addr <= 16'h7fff );
wire sound_ram_1_cs   = ( MREQ_n == 0 && z80_addr >= 16'h8000 && z80_addr <= 16'h87ff );

reg int_en;
reg int_ack;

reg [1:0] vbl_sr;

// vblank interrupt on rising vbl
always @ (posedge clk_sys ) begin
    if ( reset == 1 ) begin
        ipl2_n <= 1;
        int_ack <= 0;
    end else begin
        vbl_sr <= { vbl_sr[0], vblank };
        // vbl_sr <= { vbl_sr[0], ( vc == 224 ) };
        if ( clk_10M == 1 ) begin
            int_ack <= ( cpu_as_n == 0 ) && ( cpu_fc == 3'b111 ); // cpu acknowledged the interrupt
        end
        if ( vbl_sr == 2'b01 ) begin// rising edge
            ipl2_n <= ~int_en;
        end else if ( int_ack == 1 || vbl_sr == 2'b10 ) begin
            ipl2_n <= 1;
        end
    end
end

reg [15:0] scroll_x [3:0];
reg [15:0] scroll_y [3:0];

reg [15:0] scroll_x_latch [3:0];
reg [15:0] scroll_y_latch [3:0];

reg inc_sprite_ofs;

reg [15:0] crtc[4];

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        int_en <= 0;
        reset_z80_n <= 1;
        tms_int_n <= 1;
        tms_bio <= 1 ;
    end else begin
        // if the pcb uses the 68k reset pin to drive the reset line
        //reset_z80_n <= cpu_reset_n_o;
        
//        if ( clk_14M == 1 ) begin
//            shared_dsp_ram_w <= 0;
//            if ( tms_we_n == 0 ) begin // tms port write
            
//                case ( tms_addr[2:0] ) 
//                    3'h0 : shared_dsp_ram_addr <= tms_dout[11:0] ;
//                    3'h1 : begin
//                                shared_dsp_ram_din <= tms_dout ;
//                                shared_dsp_ram_w <= 1;
//                             end
//                    3'h3 : begin
//                                if ( tms_dout[15] == 1 ) begin
//                                    // clear
//                                    tms_bio <= 1 ;
//                                end else if ( tms_dout == 0 ) begin
//                                    // assert
//                                    tms_bio <= 0 ;
//                                end
//                             end
//                endcase
//            end
//        end
        
        // write asserted and rising cpu clock
        if (  clk_10M == 1 && cpu_rw == 0 ) begin
            if ( tile_ofs_cs ) begin
                curr_tile_ofs <= cpu_dout;
            end
            
            if ( int_en_cs ) begin
                int_en <= cpu_dout[0];
            end
            
            if ( crtc_cs ) begin
                crtc[ cpu_a[2:1] ] <= cpu_dout;
            end
            
            if ( bcu_flip_cs ) begin
                tile_flip <= cpu_dout[0];
            end
            
            if ( fcu_flip_cs ) begin
                sprite_flip <= cpu_dout[15];
            end
            
            if ( sprite_ofs_cs ) begin
                // mask out valid range
                curr_sprite_ofs <= { 6'b0, cpu_dout[9:0] };
            end
            
            if ( scroll_ofs_x_cs ) begin
                scroll_ofs_x <= cpu_dout;
            end
            
            if ( scroll_ofs_y_cs ) begin
                scroll_ofs_y <= cpu_dout;
            end
            
            // x layer values are even addresses
            if ( scroll_cs ) begin
                if ( cpu_a[1] == 0 ) begin
                    scroll_x[ cpu_a[3:2] ] <= cpu_dout[15:7];
                end else begin
                    scroll_y[ cpu_a[3:2] ] <= cpu_dout[15:7];
                end
            end
            
            // offset needs to be auto-incremented
            if ( sprite_cs | sprite_size_cs ) begin
                inc_sprite_ofs <= 1;
            end
            
            if ( reset_z80_cs ) begin
                // the pcb writes to a latch to control the reset 
                reset_z80_n <= cpu_dout[0];
            end
            
            if ( dsp_ctrl_cs ) begin
                // set/clear dsp interrupt line
                tms_int_n <= cpu_dout[0];
            end
            
        end
        
        // write lasts multiple cpu clocks so limit to one increment per write signal
        if ( inc_sprite_ofs == 1 && cpu_rw == 1 ) begin
            curr_sprite_ofs <= curr_sprite_ofs + 1;
            inc_sprite_ofs <= 0;
        end
    end
end

reg         dsp_int_en;

//wire [15:0] shared_dsp_ram_dout ;
//reg  [15:0] shared_dsp_ram_din ;
//reg  [11:0] shared_dsp_ram_addr ;
//reg         shared_dsp_ram_w ;

reg [15:0] scroll_x_total [3:0];
reg [15:0] scroll_y_total [3:0];

wire [15:0] ram_dout;
wire [9:0]  tile_palette_addr;
wire [15:0] tile_palette_cpu_dout;
wire [15:0] tile_palette_dout;

wire [9:0]  sprite_palette_addr;
wire [15:0] sprite_palette_cpu_dout;
wire [15:0] sprite_palette_dout;

reg [15:0] curr_tile_ofs;
reg [15:0] curr_sprite_ofs;

reg [15:0] scroll_ofs_x;
reg [15:0] scroll_ofs_y;

wire [15:0] cpu_tile_dout_attr;
wire [15:0] cpu_tile_dout_num;

wire [15:0] sprite_0_dout;
wire [15:0] sprite_1_dout;
wire [15:0] sprite_2_dout;
wire [15:0] sprite_3_dout;
wire [15:0] sprite_size_dout;
wire [15:0] sprite_size_cpu_dout;

wire [31:0] tile_attr_dout;
wire [15:0] sprite_attr_0_dout;
wire [15:0] sprite_attr_1_dout;
wire [15:0] sprite_attr_2_dout;
wire [15:0] sprite_attr_3_dout;

wire [15:0] sprite_size_buf_dout;
wire [15:0] sprite_attr_0_buf_dout;
wire [15:0] sprite_attr_1_buf_dout;
wire [15:0] sprite_attr_2_buf_dout;
wire [15:0] sprite_attr_3_buf_dout;

reg [15:0] sprite_buf_din;

reg [14:0] tile;

reg [7:0] sprite_num;
reg [7:0] sprite_num_copy;

reg [3:0] tile_draw_state;

reg [2:0] layer;    // 4 layers + 1 for initial background

wire [14:0] tile_idx         = tile_attr[14:0];
wire  [3:0] tile_priority    = tile_attr[31:28];
wire  [5:0] tile_palette_idx = tile_attr[21:16];
wire        tile_hidden      = tile_attr[15];

reg  [15:0] fb_dout;
wire [15:0] tile_fb_out;
wire [15:0] sprite_fb_out;
reg  [15:0] fb_din;
reg  [15:0] sprite_fb_din;

reg tile_fb_w;
reg sprite_fb_w;
reg sprite_buf_w;
reg sprite_size_buf_w;

dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) tile_line_buffer (
    .clock_a ( clk_sys ),
    .address_a ( tile_fb_addr_w ),
    .wren_a ( tile_fb_w ),
    .data_a ( fb_din ),
    .q_a ( ),

    .clock_b ( clk_sys ),
    .address_b ( fb_addr_r ),
    .wren_b ( 0 ),
//    .data_b ( ),
    .q_b ( tile_fb_out )
    );
    
dual_port_ram #(.LEN(1024), .DATA_WIDTH(16)) sprite_line_buffer (
    .clock_a ( clk_sys ),
    .address_a ( sprite_fb_addr_w ),
    .wren_a ( sprite_fb_w ),
    .data_a ( sprite_fb_din ),
    .q_a ( ),

    .clock_b ( clk_sys ),
    .address_b ( fb_addr_r ),
    .wren_b ( 0 ),
//    .data_b ( ),
    .q_b ( sprite_fb_out )
    );

reg [9:0] x_ofs;
reg [9:0] x;

reg [9:0] y_ofs;
// y needs to be one line ahaed of the visible line
// render the first line at the end of the previous frame
// this depends on the timing that the sprite list is valid
// sprites values are copied at the start of vblank (line 240)

// global offsets
wire [9:0] x_ofs_dx         = 495 + { ~layer[1:0], 1'b0 };
wire [9:0] y_ofs_dx         = 257;
wire [9:0] x_ofs_dx_flipped =  17 - { ~layer[1:0], 1'b0 };
wire [9:0] y_ofs_dx_flipped = 255;

// calculate scrolling
wire [9:0] tile_x_unflipped = scroll_x_latch[layer[1:0]] + x_ofs_dx;
wire [9:0] tile_y_unflipped = scroll_y_latch[layer[1:0]] + y_ofs_dx + scroll_y_offset;
wire [9:0] tile_x_flipped   = 319 + scroll_x_latch[layer[1:0]] + x_ofs_dx_flipped; 
wire [9:0] tile_y_flipped   = 239 + scroll_y_latch[layer[1:0]] + y_ofs_dx_flipped + scroll_y_offset;

// reverse tiles when flipped
wire [9:0] curr_x = tile_flip ? tile_x_flipped - x :  tile_x_unflipped + x;
wire [9:0] curr_y = tile_flip ? tile_y_flipped - y :  tile_y_unflipped + y;

reg  [9:0] y;
wire [9:0] y_flipped = ( sprite_flip ? (240 - y ) + scroll_y_offset : y + scroll_y_offset);
wire [9:0] sprite_buf_x = sprite_flip ? 320 - (sprite_x + sprite_pos_x ) : sprite_x + sprite_pos_x;    // offset from left of frame

reg [3:0] draw_state;
reg [3:0] sprite_state;
reg [3:0] sprite_copy_state;

// pixel 4 bit colour
wire [3:0] tile_pix;
assign tile_pix = { tile_data[7-curr_x[2:0]], tile_data[15-curr_x[2:0]], tile_data[23-curr_x[2:0]], tile_data[31-curr_x[2:0]] };

wire [2:0] sprite_bit = sprite_x[2:0];
wire [3:0] sprite_pix;
assign sprite_pix = { sprite_data[7-sprite_bit], sprite_data[15-sprite_bit], sprite_data[23-sprite_bit], sprite_data[31-sprite_bit] };

// two lines of buffer alternate
reg  [9:0] tile_fb_addr_w;
wire [9:0] fb_addr_r = {vc[0], 9'b0 } + hc;

reg [9:0] sprite_fb_addr_w;

reg [31:0] tile_attr;

// two lines worth for 4 layers (~8k)
// [15:14] = layer.
// [13:10] = prioity
// [9:4] = palette offset
// [3:0] = tile colour index.

reg [3:0] tile_priority_buf   [327:0];
reg [4:0] sprite_priority_buf [327:0];

reg  [9:0] sprite_x;         // offset from left side of sprite
reg  [9:0] sprite_y;

wire [14:0] sprite_index    = sprite_attr_0_buf_dout[14:0] /* synthesis keep */;
wire        sprite_hidden   = sprite_attr_0_buf_dout[15] /* synthesis keep */;

wire [5:0] sprite_pal_addr  = sprite_attr_1_buf_dout[5:0] /* synthesis keep */;
wire [5:0] sprite_size_addr = sprite_attr_1_buf_dout[11:6] /* synthesis keep */;
wire [3:0] sprite_priority  = sprite_attr_1_buf_dout[15:12] /* synthesis keep */;

wire [9:0] sprite_pos_x  = sprite_adj_x + (( sprite_attr_2_buf_dout[15:7] < 9'h180 ) ? sprite_attr_2_buf_dout[15:7]  : ( sprite_attr_2_buf_dout[15:7] - 10'h200));
wire [9:0] sprite_pos_y  = sprite_adj_y + (( sprite_attr_3_buf_dout[15:7] < 9'h180 ) ? sprite_attr_3_buf_dout[15:7]  : ( sprite_attr_3_buf_dout[15:7] - 10'h200));

// valid 1 cycle after sprite attr ready
wire [8:0] sprite_height    = { sprite_size_buf_dout[7:4], 3'b0 } /* synthesis keep */;    // in pixels
wire [8:0] sprite_width     = { sprite_size_buf_dout[3:0], 3'b0 } /* synthesis keep */;

reg [7:0] sprite_buf_num;

reg [1:0] vtotal_282_flag; 

always @ (posedge clk_sys) begin // Check System Vcount flag for 60Hz mode
    if ({crtc[2][7:0], 1'b1 } == 269)
        vtotal_282_flag <= 0;
    else
        vtotal_282_flag <= 1;
end

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        sprite_state <= 0;
        draw_state <= 0;
        sprite_rom_cs <= 0;
        tile_rom_cs <= 0;
        sprite_copy_state <= 0;
        tile_draw_state <= 0;
    end else begin
        // render sprites 
        // triggered when the tile rendering starts
        if ( sprite_state == 0 && draw_state > 0 ) begin
            sprite_num <= 8'h00;
            sprite_x <= 0;
            sprite_fb_w <= 1;
            sprite_state <= 1;
            sprite_fb_din <= 0;
            sprite_fb_addr_w <= { y[0], 9'b0 };
        end else if ( sprite_state == 1 ) begin
            // erase line buffer
            sprite_fb_addr_w <= { y[0], 9'b0 } + sprite_x;
            sprite_priority_buf[sprite_x] <= 0;
            if ( sprite_x < 320 ) begin
                sprite_x <= sprite_x + 1;
            end else begin
                sprite_x <= 0;
                sprite_fb_w <= 0;
                sprite_state <= 2;
            end
        end else if ( sprite_state == 2 ) begin
            // sprite num is valid now
            sprite_state <= 3;
        end else if ( sprite_state == 3 ) begin
            // sprite attr valid now.
            // delay one more cycle to read sprite size
            sprite_state <= 4;
        end else if ( sprite_state == 4 ) begin
            // start loop
            sprite_rom_cs <= 0;
            sprite_fb_w <= 0;
            sprite_y <=  y_flipped - sprite_pos_y;
            // is sprite visible and is current y in sprite y range
            // sprite pos can be negative?
        if ( sprite_hidden == 0 && sprite_width > 0 && ( $signed(y_flipped) >= $signed(sprite_pos_y) ) && $signed(y_flipped) < ( $signed(sprite_pos_y) + $signed(sprite_height) ) ) begin
                sprite_state <= 5;
            end else if ( sprite_num < 8'hff ) begin
                sprite_num <= sprite_num + 1;
                sprite_state <= 2;
            end else begin
                sprite_state <= 15;
            end
        end else if ( sprite_state == 5 ) begin
            sprite_rom_addr <= { sprite_index, 3'b0 } + { sprite_x[8:3], 3'b0 } + ( sprite_y[8:3] * sprite_width ) + sprite_y[2:0];
            sprite_rom_cs <= 1;
            sprite_state <= 6;
        end else if ( sprite_state == 6 ) begin
            // wait for sprite bitmap ready
            if ( sprite_rom_data_valid ) begin
                // latch data and deassert cs
                sprite_data <= sprite_rom_data;
                sprite_rom_cs <= 0;
                sprite_state <= 7;
            end
        end else if ( sprite_state == 7 ) begin
            sprite_fb_w <= 0;
            // draw if pixel value not zero and priority >= previous sprite data
            if ( sprite_pix != 0 ) begin 
                sprite_fb_din <= { 2'b11, sprite_priority[3:0], sprite_pal_addr, sprite_pix };
                sprite_fb_addr_w <= { y[0], 9'b0 } + sprite_buf_x;
                sprite_priority_buf[sprite_buf_x] <= { 1'b0, sprite_priority };
                sprite_fb_w <= 1;
            end
            if ( sprite_x < ( sprite_width - 1 ) ) begin
                sprite_x <= sprite_x + 1;
                if ( sprite_x[2:0] == 7 ) begin
                    // do recalc bitmap address
                    sprite_state <= 5;
                end
            end else if ( sprite_num < 8'hff ) begin
                sprite_num <= sprite_num + 1;
                sprite_x <= 0;
                // need to load new attributes and size
                sprite_state <= 2;
            end else begin
                // tile state machine will reset sprite_state when line completes.
                sprite_state <= 15; // done
            end
        end
        // copy sprite attr/size to buffer
        if (  sprite_copy_state == 0 && vc == 240  ) begin
            sprite_copy_state <= 1;
            sprite_buf_w <= 0;
            sprite_num_copy <= 8'h00;
        end else if ( sprite_copy_state == 1 ) begin
            sprite_num_copy <= sprite_num_copy + 1;
            sprite_buf_num <= sprite_num_copy;
            sprite_buf_w <= 1;
            // wait for read from source
            if ( sprite_num_copy == 8'hff ) begin
                sprite_copy_state <= 2;
            end
        end else if ( sprite_copy_state == 2 ) begin
            sprite_buf_w <= 0;
            sprite_copy_state <= 0;
        end
        // tile state machine
        if ( draw_state == 0 && vc == ({ crtc[2][7:0], 1'b1 } - (ntsc ? (vtotal_282_flag ? 5'd19 : 4'd7) : 3'd0)) ) begin // 282 Lines standard (263 Lines for 60Hz)
            scroll_x_latch[0] <= scroll_x[0] - scroll_ofs_x;
            scroll_x_latch[1] <= scroll_x[1] - scroll_ofs_x;
            scroll_x_latch[2] <= scroll_x[2] - scroll_ofs_x;
            scroll_x_latch[3] <= scroll_x[3] - scroll_ofs_x;
            scroll_y_latch[0] <= scroll_y[0] - scroll_ofs_y;
            scroll_y_latch[1] <= scroll_y[1] - scroll_ofs_y;
            scroll_y_latch[2] <= scroll_y[2] - scroll_ofs_y;
            scroll_y_latch[3] <= scroll_y[3] - scroll_ofs_y;
            layer <= 4; // layer 4 is layer 0 but draws hidden and transparent
            y <= 0;
            draw_state <= 2;
            sprite_state <= 0;
        end else if ( draw_state == 2 ) begin
            x <= 0;
            x_ofs <= scroll_x_latch[layer[1:0]];
            y_ofs <= scroll_y_latch[layer[1:0]];
            // latch offset info
            draw_state <= 3;
            tile_draw_state <= 0;
        end else if ( draw_state == 3 ) begin
            if ( tile_draw_state == 0 ) begin
                tile <=  { layer[1:0], curr_y[8:3], curr_x[8:3] };  // works
                tile_draw_state <= 4'h1;
            end else if ( tile_draw_state == 1 ) begin
                tile_draw_state <= 2;
            end else if ( tile_draw_state == 2 ) begin
                // latch attribute
                // tile_attr <= tile_attr_dout;
                tile_attr <= tile_buf_dout ;
                if ( layer == 4 || tile_buf_dout[15] == 0 ) begin
                    tile_draw_state <= 3;
                end else begin
                    if ( x < 320 ) begin// 319
                        tile_draw_state <= 3;
                        // do we need to read another tile?
                        // last pixel of this tile changes based on flip direction
                        if ( curr_x[2:0] == ( tile_flip ? 0 : 7)  ) begin
                            draw_state <= 3; 
                            tile_draw_state <= 0;
                        end
                        x <= x + 1;
                    end else if ( layer > 0 ) begin
                        layer <= layer - 1;
                        tile_fb_w <= 0;
                        draw_state <= 2;
                    end else begin
                        // done
                        tile_draw_state <= 7;
                        tile_fb_w <= 0;
                    end
                end
            end else if ( tile_draw_state == 3 ) begin
                // read bitmap info
                tile_rom_cs <= 1;
                tile_rom_addr <= { tile_idx, curr_y[2:0] };
                tile_draw_state <= 4;
            end else if ( tile_draw_state == 4 ) begin
                // wait for bitmap ram ready
                if ( tile_rom_data_valid ) begin
                    // latch data and deassert cs
                    tile_data <= tile_rom_data;
                    tile_draw_state <= 5;
                    tile_rom_cs <= 0;
                end
            end else if ( tile_draw_state == 5 ) begin
                tile_fb_w <= 0; 
                tile_fb_addr_w   <= { y[0], 9'b0 } + x;
                // force render of first layer.
                // if layer == 4 then tile_pix == 0 is not transparent
                // layer 4 is really layer 0
                if ( layer == 4 ) begin
                    tile_priority_buf[x] <= 0; //tile_pix == 0 ? 0  : tile_priority;
                    //fb_din <= { layer[1:0], tile_priority, tile_palette_idx,  tile_pix };
                    fb_din <= { layer[1:0], 4'b0, tile_palette_idx,  tile_pix };
                    tile_fb_w <= 1;
                //end else if (tile_hidden == 0 && tile_pix > 0 && tile_priority > 0 && tile_priority >= tile_priority_buf[x] ) begin
                end else if (tile_hidden == 0 && tile_pix > 0 && tile_priority > tile_priority_buf[x] ) begin
                    tile_priority_buf[x] <= tile_priority;
                    // if tile hidden then make the pallette index 0. ie transparent
                    fb_din <= { layer[1:0], tile_priority, tile_palette_idx,  tile_pix };
                    tile_fb_w <= 1;
                end
                if ( x < 320 ) begin// 319
                    // do we need to read another tile?
                    // last pixel of this tile changes based on flip direction
                    if ( curr_x[2:0] == ( tile_flip ? 0 : 7)  ) begin
                        draw_state <= 3; 
                        tile_draw_state <= 0;
                    end 
                    x <= x + 1;
                end else if ( layer > 0 ) begin
                    layer <= layer - 1;
                    tile_fb_w <= 0;
                    draw_state <= 2;
                end else begin
                    // done
                    tile_draw_state <= 7;
                    tile_fb_w <= 0;
                end
            end else if ( tile_draw_state == 7 ) begin
                // wait for next line or quit
                if ( y == 239 ) begin
                    draw_state <= 0;
                end else if ( hc ==  (ntsc ? 9'd444 : 9'd449) ) begin // 450 Lines standard (445 Lines for NTSC standard 15.73kHz line freq)
                    y <= y + 1;
                    draw_state <= 2;
                    sprite_state <= 0;
                    layer <= 4;
                end
            end
        end
    end
end

// render
reg draw_sprite;

// two lines worth for 4 layers (~8k)
// [15:14] = layer.
// [13:10] = prioity
// [9:4] = palette offset
// [3:0] = tile colour index.

// there are 10 70MHz cycles per pixel. clk7_count from 0-9
// 

// dac values based on 120 ohm driver for the resistor dac and 75 ohm output.  4.7k, 2.2k, 1k, 470, 220
// modeled in spice
wire [7:0] dac [0:31] = '{0,12,25,36,50,61,73,83,91,100,111,120,131,139,149,157,145,154,162,170,180,187,195,202,208,214,222,228,236,242,249,255};

always @ (posedge clk_sys) begin
    if ( clk7_count == 4 ) begin
        tile_palette_addr  <= tile_fb_out[9:0];
        sprite_palette_addr <= sprite_fb_out[9:0];
    end else if ( clk7_count == 6 ) begin
        // if palette index is zero then it's from layer 3 and is transparent render as blank (black).
			r <= dac[tile_palette_dout[4:0]];
			g <= dac[tile_palette_dout[9:5]];
			b <= dac[tile_palette_dout[14:10]];
        // if not transparent and sprite is higher priority 
        if ( sprite_fb_out[3:0] > 0 && (sprite_fb_out[13:10] > tile_fb_out[13:10]) ) begin
            // draw sprite
			r <= dac[sprite_palette_dout[4:0]];
			g <= dac[sprite_palette_dout[9:5]];
			b <= dac[sprite_palette_dout[14:10]];
        end
    end
end

reg         download_en;
reg [15:0]  download_index;
reg [11:0]  download_addr;
reg [7:0]   download_data;
reg         download_wr;
wire        download_wait;

// download tms32010 internal rom
always @ (posedge clk_sys) begin

    download_en    <= ioctl_download & (download_index == 0) ; 
    download_index <= ioctl_index ;

    if ( ioctl_addr >= 26'h208000 && ioctl_addr < 26'h209000 ) begin
        // dsp rom is 16 bits wide
        download_addr <= ioctl_addr[11:1] ;
        tms_rom_w     <= ioctl_wr & ioctl_addr[0];
        tms_rom_din[ { ~ioctl_addr[0], 3'b111 } -: 8 ] <= ioctl_dout ;
    end
end

reg         tms_rom_w;
wire [11:0] tms_rom_addr ;
wire [15:0] tms_rom_din ;
wire [15:0] tms_rom_dout ;

dual_port_ram #(.LEN(4096), .DATA_WIDTH(16)) dsp_rom
(
    .clock_a( clk_sys ), // rom download. ioctl stuff. 
    .address_a( download_addr ),
    .wren_a( tms_rom_w ), // 
    .data_a( tms_rom_din ), // 16 bit wide
    .q_a( ),

    .clock_b( clk_14M ),  // tms clock
    .address_b( tms_rom_addr ),
    .wren_b( 0 ),
    .data_b( ),
    .q_b( tms_rom_dout )
);

//    // copy sprite attr/size to buffer
//    if (  sprite_copy_state == 0 && vc == 240  ) begin
//        sprite_copy_state <= 1;
//        sprite_buf_w <= 0;
//        sprite_num_copy <= 8'h00;
//    end else if ( sprite_copy_state == 1 ) begin
//        sprite_num_copy <= sprite_num_copy + 1;
//        sprite_buf_num <= sprite_num_copy;
//        sprite_buf_w <= 1;
//        // wait for read from source
//        if ( sprite_num_copy == 8'hff ) begin
//            sprite_copy_state <= 2;
//        end
//    end else if ( sprite_copy_state == 2 ) begin
//        sprite_buf_w <= 0;
//        sprite_copy_state <= 0;
//    end

// tile data buffer

reg         tile_buf_w;
reg  [31:0] tile_buf_din;
reg  [31:0] tile_buf_dout;
reg  [13:0] tile_buf_count;
reg  [13:0] tile_buf_addr;

reg   [2:0] tile_copy_state;

always @ (posedge clk_sys) begin
    if ( vc < 240 ) begin
        tile_buf_count <= 0;
        tile_copy_state <= 0;
        tile_buf_w <= 0;
    end else if ( tile_copy_state == 0 ) begin
        tile_buf_count <= tile_buf_count + 1;

        tile_buf_addr <= tile_buf_count ;
        tile_buf_w <= 1 ;

        if ( &tile_buf_count ) begin
            tile_copy_state <= 1;
        end
    end else if ( tile_copy_state == 1 ) begin
        tile_buf_w <= 0;
    end
end

dual_port_ram #(.LEN(16384), .DATA_WIDTH(32)) ram_tile_buf
(
    .clock_a( clk_sys ),
    .address_a( tile_buf_addr ),
    .wren_a( tile_buf_w ),
    .data_a( tile_attr_dout ),

    .clock_b( clk_sys ),
    .address_b( tile[13:0] ),    // only read the tile # for now
    .wren_b( 0 ),
    .q_b( tile_buf_dout )
);

// tile attribute ram.  each tile attribute is 2 16bit words
// pppp ---- --cc cccc httt tttt tttt tttt = Tile number (0 - $7fff)
// indirect access through offset register
dual_port_ram #(.LEN(16384), .DATA_WIDTH(16)) tile_ram_h (
    .clock_a ( clk_10M ),
    .address_a ( curr_tile_ofs ),
    .wren_a ( tile_attr_cs & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( cpu_tile_dout_attr ),

    .clock_b ( clk_sys ),
    .address_b ( tile[13:0] ),    // only read the tile # for now
    .wren_b ( 0 ),
    .q_b ( tile_attr_dout[31:16] )
    );
    
dual_port_ram #(.LEN(16384), .DATA_WIDTH(16)) tile_ram_l (
    .clock_a ( clk_10M ),
    .address_a ( curr_tile_ofs ),
    .wren_a ( tile_num_cs & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( cpu_tile_dout_num ),

    .clock_b ( clk_sys ),
//    .address_b ( tile[13:0] ),    // only read the tile # for now
    .address_b( tile_buf_count ),
    .wren_b ( 0 ),
    .q_b ( tile_attr_dout[15:0] )
    );

// sprite attribute ram.  each tile attribute is 4 16bit words
// indirect access through offset register
// split up so 64 bits can be read in a single clock
dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_0 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_0_cs  & !cpu_rw),
    .data_a ( cpu_dout ),
    .q_a ( sprite_0_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_0_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_0_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_0_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_0_buf_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_1 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_1_cs  & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( sprite_1_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_1_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_1_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_1_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_1_buf_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_2 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_2_cs  & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( sprite_2_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_2_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_2_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_2_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_2_buf_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_3 (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs[9:2] ),
    .wren_a ( sprite_3_cs  & !cpu_rw ),
    .data_a ( cpu_dout ),
    .q_a ( sprite_3_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_3_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_3_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_attr_3_dout[15:0] ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num ),
    .wren_b ( 0 ),
    .q_b ( sprite_attr_3_buf_dout[15:0] )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_size (
    .clock_a ( clk_10M ),
    .address_a ( curr_sprite_ofs ),
    .wren_a ( sprite_size_cs  & !cpu_rw),
    .data_a ( cpu_dout ),
    .q_a ( sprite_size_cpu_dout ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_num_copy ),
    .wren_b ( 0 ),
    .q_b ( sprite_size_dout )
    );

dual_port_ram #(.LEN(256), .DATA_WIDTH(16)) sprite_ram_size_buf (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buf_num ),
    .wren_a ( sprite_buf_w ),
    .data_a ( sprite_size_dout ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_size_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_size_buf_dout )
    
    );


// tiles  1024 15 bit values.  index is ( 6 bits from tile attribute, 4 bits from bitmap )
// background palette ram low
// does this need to be byte addressable?
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) tile_palram_l (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( tile_palette_cs & !cpu_rw & !cpu_lds_n),
    .data_a ( cpu_dout[7:0]  ),
    .q_a ( tile_palette_cpu_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( tile_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( tile_palette_dout[7:0] )
    );

// background palette ram high
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) tile_palram_h (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( tile_palette_cs & !cpu_rw & !cpu_uds_n),
    .data_a ( cpu_dout[15:8]  ),
    .q_a ( tile_palette_cpu_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( tile_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( tile_palette_dout[15:8] )
    );

// sprite palette ram low
// does this need to be byte addressable?
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) sprite_palram_l (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( sprite_palette_cs & !cpu_rw & !cpu_lds_n),
    .data_a ( cpu_dout[7:0]  ),
    .q_a ( sprite_palette_cpu_dout[7:0] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_palette_dout[7:0] )
    );

// background palette ram high
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) sprite_palram_h (
    .clock_a ( clk_10M ),
    .address_a ( cpu_a[10:1] ),
    .wren_a ( sprite_palette_cs & !cpu_rw & !cpu_uds_n),
    .data_a ( cpu_dout[15:8]  ),
    .q_a ( sprite_palette_cpu_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_palette_addr ),
    .wren_b ( 0 ),
    .q_b ( sprite_palette_dout[15:8] )
    );

wire [15:0] shared_dsp_ram_dout ;
reg  [15:0] shared_dsp_ram_din ;
reg  [11:0] shared_dsp_ram_addr ;
reg         shared_dsp_ram_w ;

// main 68k ram high
//dual_port_ram #(.LEN(16384), .DATA_WIDTH(8)) ram16kx8_H 
//(
//    .clock_a ( clk_10M ),
//    .address_a ( cpu_a[14:1] ),
//    .wren_a ( !cpu_rw & ram_cs & !cpu_uds_n ),
//    .data_a ( cpu_dout[15:8]  ),
//    .q_a (  ram_dout[15:8] ),
//    
//    .clock_b( clk_14M ),
//    .address_b( shared_dsp_ram_addr[11:0] ),
//    .wren_b( shared_dsp_ram_w ),
//    .data_b( shared_dsp_ram_din[15:8] ),
//    .q_b( shared_dsp_ram_dout[15:8] )
//);
//
//// main 68k ram low
//dual_port_ram #(.LEN(16384), .DATA_WIDTH(8)) ram16kx8_L
//(
//    .clock_a( clk_10M ),
//    .address_a( cpu_a[14:1] ),
//    .wren_a( !cpu_rw & ram_cs & !cpu_lds_n ),
//    .data_a( cpu_dout[7:0]  ),
//    .q_a(  ram_dout[7:0] ),
//    
//    .clock_b( clk_14M ),
//    .address_b( shared_dsp_ram_addr[11:0] ),
//    .wren_b( shared_dsp_ram_w ),
//    .data_b( shared_dsp_ram_din[7:0] ),
//    .q_b( shared_dsp_ram_dout[7:0] )
//);



//wire [15:0] z80_shared_addr = z80_addr - 16'h8000;
//wire [23:0] m68k_shard_addr = cpu_a    - 24'h040000;

// z80 and 68k shared ram
// 4k
//dual_port_ram #(.LEN(4096), .DATA_WIDTH(8))  shared_ram 
//(
//    .clock_a( clk_10M ),
//    .address_a( cpu_a[12:1] ),
//    .wren_a( shared_ram_cs & !cpu_rw & !cpu_lds_n),
//    .data_a( cpu_dout[7:0]  ),
//    .q_a( cpu_shared_dout[7:0] ),
//
//    .clock_b( clk_3_5M ),  // z80 clock is 3.5M
//    .address_b( z80_addr[11:0] ),
//    .data_b( z80_dout ),
//    .wren_b( sound_ram_1_cs & ~z80_wr_n ),
//    .q_b( z80_shared_dout )
//    );

reg [11:0] sprite_rb_addr;
wire [15:0] sprite_rb_dout;

dual_port_ram #(.LEN(4096), .DATA_WIDTH(8)) sprite_ram_rb_l
(
    .clock_a( clk_10M ),
    .address_a( cpu_a[12:1] ),
    .wren_a( sprite_ram_cs & !cpu_rw & !cpu_lds_n),
    .data_a( cpu_dout[7:0]  ),
    .q_a( sprite_rb_dout[7:0] ),

    .clock_b( clk_sys ),
    .address_b( sprite_rb_addr ),
    .wren_b( 0 ),
    .q_b( sprite_rb_dout[7:0] )
    );

dual_port_ram #(.LEN(4096), .DATA_WIDTH(8)) sprite_ram_rb_h
(
    .clock_a( clk_10M ),
    .address_a( cpu_a[12:1] ),
    .wren_a( sprite_ram_cs & !cpu_rw & !cpu_uds_n),
    .data_a( cpu_dout[15:8]  ),
    .q_a( cpu_shared_dout[15:8] ),

    .clock_b( clk_sys ),
    .address_b( sprite_rb_addr ),
    .wren_b( 0 ),
    .q_b( sprite_rb_dout[15:8] )
    );

reg  [22:0] sdram_addr;
reg  [31:0] sdram_data;
reg         sdram_we;
reg         sdram_req;

wire        sdram_ack;
wire        sdram_valid;
wire [31:0] sdram_q;

//sdram #(.CLK_FREQ(70.0)) sdram
//(
//  .reset(~pll_locked),
//  .clk(clk_sys),
//
//  // controller interface
//  .addr(sdram_addr),
//  .data(sdram_data),
//  .we(sdram_we),
//  .req(sdram_req),
//  
//  .ack(sdram_ack),
//  .valid(sdram_valid),
//  .q(sdram_q),
//
//  // SDRAM interface
//  .sdram_a(SDRAM_A),
//  .sdram_ba(SDRAM_BA),
//  .sdram_dq(SDRAM_DQ),
//  .sdram_cke(SDRAM_CKE),
//  .sdram_cs_n(SDRAM_nCS),
//  .sdram_ras_n(SDRAM_nRAS),
//  .sdram_cas_n(SDRAM_nCAS),
//  .sdram_we_n(SDRAM_nWE),
//  .sdram_dqml(SDRAM_DQML),
//  .sdram_dqmh(SDRAM_DQMH)
//);

wire        prog_cache_rom_cs;
wire [22:0] prog_cache_addr;
wire [15:0] prog_cache_data;
wire        prog_cache_valid;

wire [15:0] prog_rom_data;
wire        prog_rom_data_valid;

reg         tile_rom_cs;
reg  [17:0] tile_rom_addr;
wire [31:0] tile_rom_data;
wire        tile_rom_data_valid;

wire        tile_cache_cs;
wire [17:0] tile_cache_addr;
wire [31:0] tile_cache_data;
wire        tile_cache_valid;

reg  [31:0] tile_data;

wire        sprite_rom_cs;
wire [17:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
wire        sprite_rom_data_valid;

reg  [31:0] sprite_data;

wire [15:0] sound_rom_1_addr;
wire  [7:0] sound_rom_1_data;
wire        sound_rom_1_data_valid;




// sdram priority based rom controller
// is a oe needed?
rom_controller rom_controller
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM interface
    .prog_rom_cs(prog_cache_rom_cs),
    .prog_rom_oe(1),
    .prog_rom_addr(prog_cache_addr),
    .prog_rom_data(prog_cache_data),
    .prog_rom_data_valid(prog_cache_valid),

    // character ROM interface
    .tile_rom_cs(tile_cache_cs),
    .tile_rom_oe(1),
    .tile_rom_addr(tile_cache_addr),
    .tile_rom_data(tile_cache_data),
    .tile_rom_data_valid(tile_cache_valid),


    // sprite ROM interface
    .sprite_rom_cs(sprite_rom_cs),
    .sprite_rom_oe(1),
    .sprite_rom_addr(sprite_rom_addr),
    .sprite_rom_data(sprite_rom_data),
    .sprite_rom_data_valid(sprite_rom_data_valid),

    // sound ROM #1 interface
    .sound_rom_1_cs(sound_rom_1_cs),
    .sound_rom_1_oe(1),
    .sound_rom_1_addr(z80_addr),
    .sound_rom_1_data(sound_rom_1_data),
    .sound_rom_1_data_valid(sound_rom_1_data_valid),

    // IOCTL interface
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_dout),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_download(ioctl_download),

    // SDRAM interface
    .sdram_addr(sdram_addr),
    .sdram_data(sdram_data),
    .sdram_we(sdram_we),
    .sdram_req(sdram_req),
    .sdram_ack(sdram_ack),
    .sdram_valid(sdram_valid),
    .sdram_q(sdram_q)
  );


cache prog_cache
(
    .reset(reset),
    .clk(clk_sys),

    // client
    .cache_req(prog_rom_cs),
    .cache_addr(cpu_a[23:1]),
    .cache_valid(prog_rom_data_valid),
    .cache_data(prog_rom_data),

    // to rom controller
    .rom_req(prog_cache_rom_cs),
    .rom_addr(prog_cache_addr),
    .rom_valid(prog_cache_valid),
    .rom_data(prog_cache_data)

); 

tile_cache tile_cache
(
    .reset(reset),
    .clk(clk_sys),

    // client
    .cache_req(tile_rom_cs),
    .cache_addr(tile_rom_addr),
    .cache_data(tile_rom_data),
    .cache_valid(tile_rom_data_valid),

    // to rom controller
    .rom_req(tile_cache_cs),
    .rom_addr(tile_cache_addr),
    .rom_data(tile_cache_data),
    .rom_valid(tile_cache_valid)

);

endmodule 

module cc_shifter
(
    input clk_out,
    input i,
    output o
);

// We use a two-stages shift-register to synchronize SignalIn_clkA to the clkB clock domain
reg [1:0] r;

assign o = r[1];    // new signal synchronized to (=ready to be used in) clkB domain

always @(posedge clk_out) begin
    r[0] <= i;
    r[1] <= r[0];    // notice that we use clkB
end

endmodule 