module MrDo_top(
input 		clk_98M,

//input 		clk_20M,
//input 		clk_8M,

input 		reset,
output		[3:0] red,
output		[3:0] green,
output		[3:0] blue,
output		hsync,
output		vsync,
output		hblank,
output		vblank,
output		reg [7:0] sound1_out,
output		reg [7:0] sound2_out,
input 		[7:0] p1,
input 		[7:0] p2,
input 		[7:0] dsw1,
input 		[7:0] dsw2,
output		[14:0] rom_addr,
input 		[7:0] rom_do
);

//divider_by2 gen10( 
//	.out_clk(clk_10M),
//	.clk(clk_20M),
//	.rst(reset)
//);
//
//divider_by2 gen5( 
//	.out_clk(clk_5M),
//	.clk(clk_10M),
//	.rst(reset)
//);
//
//divider_by2 gen4( 
//	.out_clk(clk_4M),
//	.clk(clk_8M),
//	.rst(reset)
//);

//fg_ram0 is driven by 5mhz instead of 4mhz??? check schematics!!!

wire clk_4M, clk_5M, clk_8M, clk_10M;
reg [5:0] clk10_count;
reg [5:0] clk5_count;
reg [5:0] clk8_count;
reg [5:0] clk4_count;

always @ (posedge clk_98M) begin
    if ( reset == 1 ) begin
        clk10_count <= 0;
		  clk8_count <= 0;
        clk5_count <= 0;
        clk4_count <= 0;
        
    end else begin
        if ( clk10_count == 4 ) begin
            clk10_count <= 0;
            clk_10M <= ~ clk_10M ;
        end else begin
            clk10_count <= clk10_count + 1;
        end

        if ( clk8_count == 5 ) begin
            clk8_count <= 0;
            clk_8M <= ~ clk_8M ;
        end else begin
            clk8_count <= clk8_count + 1;
        end

        if ( clk5_count == 9 ) begin
            clk5_count <= 0;
            clk_5M <= ~ clk_5M ;
        end else begin
            clk5_count <= clk5_count + 1;
        end

        if ( clk4_count == 11 ) begin
            clk4_count <= 0;
            clk_4M <= ~ clk_4M ;
        end else begin
            clk4_count <= clk4_count + 1;
        end
    end
end

wire hff;
reg [7:0]v;
reg [7:0]h;

video_timing video_timing (
    .clk_pix(~clk_5M),
    .reset(reset),    
    
    .h(h),
    .v(v),
    
    .hbl(hblank),
    .hff(hff),
    .vbl(vblank),
  
    .hsync(hsync),
    .vsync(vsync)
    );
    
wire [7:0] s8_data;
wire [7:0] u8_data;

wire [7:0] r8_data;
wire [7:0] n8_data;

wire [7:0] f10_data;
reg  [5:0] f10_addr;    

reg [9:0]  fg_char_index ; 
reg [9:0]  bg_char_index ; 

reg [15:0] cpu_addr;
reg  [7:0] cpu_din;
wire [7:0] cpu_dout;

wire [7:0] gfx_fg_tile_data ; 
wire [7:0] gfx_fg_attr_data ; 

wire [7:0] gfx_bg_tile_data ; 
wire [7:0] gfx_bg_attr_data ; 

reg [7:0]  wr_data;
reg [11:0] wr_addr;

reg cpu_ram_w ;

reg gfx_fg_ram0_wr ;
reg gfx_fg_ram1_wr ;
reg gfx_bg_ram0_wr ;
reg gfx_bg_ram1_wr ;

wire [7:0] fg_ram0_data;
wire [7:0] fg_ram1_data;
wire [7:0] bg_ram0_data;
wire [7:0] bg_ram1_data;

wire [7:0] cpu01rom_data;
wire [7:0] cpu02rom_data;
wire [7:0] cpu03rom_data;
wire [7:0] cpu04rom_data;
wire [7:0] cpu_ram_data;

// used to shift out the bitmap
reg [7:0] fg_shift_0;
reg [7:0] fg_shift_1;
reg [7:0] bg_shift_0;
reg [7:0] bg_shift_1;

//reg [8:0] fg_tile;
reg [7:0] fg_attr;
//reg [8:0] bg_tile;
reg [7:0] bg_attr;

reg [11:0] fg_bitmap_addr;
reg [11:0] bg_bitmap_addr;

// fg ----------
//
wire [1:0] fg = { fg_shift_1[0], fg_shift_0[0] };
//
reg [1:0] fg_reg;

reg [7:0] fg_attr_reg;

reg [7:0] fg_red ;
reg [7:0] fg_green ;
reg [7:0] fg_blue ;

// values the same for each channel. put this into a module
always @ ( posedge clk_10M ) begin
    case ({ fg_pal_data_high[1:0] , fg_pal_data_low[1:0] })
        0  : fg_red <= 0;
        1  : fg_red <= 0;
        2  : fg_red <= 0;
        3  : fg_red <= 88;
        4  : fg_red <= 0;
        5  : fg_red <= 112;
        6  : fg_red <= 133;
        7  : fg_red <= 192;
        8  : fg_red <= 60;
        9  : fg_red <= 150;
        10 : fg_red <= 166;
        11 : fg_red <= 212;
        12 : fg_red <= 180;
        13 : fg_red <= 221;
        14 : fg_red <= 229;
        15 : fg_red <= 255;
    endcase
    case ({ fg_pal_data_high[3:2] , fg_pal_data_low[3:2] })
        0  : fg_green <= 0;
        1  : fg_green <= 0;
        2  : fg_green <= 0;
        3  : fg_green <= 88;
        4  : fg_green <= 0;
        5  : fg_green <= 112;
        6  : fg_green <= 133;
        7  : fg_green <= 192;
        8  : fg_green <= 60;
        9  : fg_green <= 150;
        10 : fg_green <= 166;
        11 : fg_green <= 212;
        12 : fg_green <= 180;
        13 : fg_green <= 221;
        14 : fg_green <= 229;
        15 : fg_green <= 255;
    endcase
    case ({ fg_pal_data_high[5:4] , fg_pal_data_low[5:4] })
        0  : fg_blue <= 0;
        1  : fg_blue <= 0;
        2  : fg_blue <= 0;
        3  : fg_blue <= 88;
        4  : fg_blue <= 0;
        5  : fg_blue <= 112;
        6  : fg_blue <= 133;
        7  : fg_blue <= 192;
        8  : fg_blue <= 60;
        9  : fg_blue <= 150;
        10 : fg_blue <= 166;
        11 : fg_blue <= 212;
        12 : fg_blue <= 180;
        13 : fg_blue <= 221;
        14 : fg_blue <= 229;
        15 : fg_blue <= 255;
    endcase
end

//
//// bg ----------
//
wire [1:0] bg = { bg_shift_1[0], bg_shift_0[0] };
//
reg [1:0] bg_reg;
reg [7:0] bg_attr_reg;

reg [4:0] fg_pal_ofs_hi ;
reg [4:0] fg_pal_ofs_low ;

//reg [4:0] bg_pal_ofs_hi ;
//reg [4:0] bg_pal_ofs_low ;

reg [4:0] sp_pal_ofs_hi ;
reg [4:0] sp_pal_ofs_low ;

reg [7:0] bg_scroll_y;

wire [7:0] bg_scroll;
assign bg_scroll = v + bg_scroll_y;

//// ---------- sprites ----------
reg spr_ram_wr;   
reg [7:0] spr_addr;
wire [7:0] spr_ram_data;

reg [7:0] spr_shift_data;

reg [7:0] sprite_tile;
//reg [7:0] sprite_x;
reg [7:0] sprite_y;
reg [7:0] sprite_color;
reg sprite_valid;

wire [7:0] h5_data;
wire [7:0] k5_data;
reg [11:0] spr_bitmap_addr;

//reg [7:0] spr_data_latch;

    // [0] tile #
    // [1] y
    // [2] color
    // [3] x
    
// --------------- fg / bg ------------

reg [5:0] sp_addr_cache[15:0];  
reg [5:0] a7;
reg [3:0] a9;

reg [3:0] f8_buf[256];
reg [7:0] f8_count;

reg [3:0] g8_buf[256];
reg [7:0] g8_count;

reg [7:0] pad ;
reg [1:0] pic ;
reg [7:0] h10 ; // counter h10 LS393 drives timing prom J10
reg [3:0] k6;
reg [3:0] j6;
reg load_shift;
reg dec_a9;

wire sp_bank = ( sprite_tile[6] == 1 );
wire flip_x  = ( sprite_color[4] == 1 );
wire flip_y  = ( sprite_color[5] == 1 );
reg flip_screen;

// hbl is made 64 clocks
always @ (posedge clk_10M) begin
    if ( hblank ) begin
        // clocked on the rising edge of HA. ie h[0]
        if ( clk_5M == 1 && h[0] == 1 ) begin
            // if tile is visible and still room in address stack
            if ( j7[7:4] == 0 && a9 < 15 && h < 8'hff) begin
                sp_addr_cache[a9][5:0] <= a7;
                a9 <= a9 + 1;
            end 
            a7 <= a7 + 1;
        end
        h10 <= 0;
    end else begin
        // reset a9 on last pixel of playfield
        // should be zero anyways if a9 counted down correctly
        if ( hff == 1 ) begin
            a9 <= 0;
        end else if ( dec_a9 == 1 ) begin
            // a9 counts down on falling edge of pic1 when a9 > 0 and ~hbl 
            if ( a9 > 0 ) begin
                 a9 <= a9 - 1;
            end
        end

        h10 <= h10 + 1;
        a7 <= 0;
    end
end

always @ ( posedge clk_10M ) begin // neg
    // load new nibbles into the shifters
    // if not loading then shifting out
    if ( load_shift == 1 ) begin
        // select rom bank
        if ( sp_bank == 0 ) begin
            // cheat and swizzle the nibble before shifting
            if ( flip_x == 0 ) begin
                k6 <= h5_data[3:0];
                j6 <= h5_data[7:4];
                f10_addr <= {sprite_color[2:0], h5_data[0], h5_data[4]};
            end else begin
                k6 <= { h5_data[0], h5_data[1], h5_data[2], h5_data[3] };
                j6 <= { h5_data[4], h5_data[5], h5_data[6], h5_data[7] };
                f10_addr <= {sprite_color[2:0], h5_data[3], h5_data[7]};
            end
        end else begin
            if ( flip_x == 0 ) begin
                k6 <= k5_data[3:0];
                j6 <= k5_data[7:4];
                f10_addr <= {sprite_color[2:0], k5_data[0], k5_data[4]};
            end else begin
                k6 <= { k5_data[0], k5_data[1], k5_data[2], k5_data[3] };
                j6 <= { k5_data[4], k5_data[5], k5_data[6], k5_data[7] };
                f10_addr <= {sprite_color[2:0], k5_data[3], k5_data[7]};
            end
        end
    end else begin
        // the flip_x bit doesn't matter since the bits were re-ordered at load.
        k6 <= { 1'b0, k6[3:1]  };
        j6 <= { 1'b0, j6[3:1]  };
        // get one clock early.  not sure this works.
        f10_addr <= {sprite_color[2:0], k6[1], j6[1]};
    end
    
    // counters are always cleared during hbl
    // one will free count and the other will count the x offset in the current blitter
    // v[0] (schematic VADLAY) determines which buffer is blitting and which is streaming
    if ( hblank ) begin
        f8_count <= 0;
        g8_count <= 0;
    end else if ( pad[1:0] == 2'b11 ) begin
        // mux G9 gives LA4 ( L9 nand pad 1+0 ) to F8 or G8 load line
        // load one from sprite x pos, increment the other
        if ( v[0] == 1 ) begin
            //f8_count <= sprite_x;
            f8_count <= spr_ram_data ;
            g8_count <= g8_count + 1;
        end else begin
            //g8_count <= sprite_x;
            g8_count <= spr_ram_data ;
            f8_count <= f8_count + 1;
        end
    end else begin 
        // increment both
        if ( v[0] == 1 ) begin
            if ( sprite_valid ) begin
                f8_count <= f8_count + 1;
            end
            g8_count <= g8_count + 1;
        end else begin
            if ( sprite_valid ) begin
                g8_count <= g8_count + 1;
            end
            f8_count <= f8_count + 1;
        end
    end
end

always @ ( posedge clk_10M ) begin
    // odd / even lines each have their own sprite line buffer
    if ( v[0] == 1 ) begin
        // if the pixel color is 0 then the ram cs is not asserted and no write happens
        if ( k6[0] | j6[0] ) begin
            if ( sprite_valid ) begin
                // sprite_color[3] selects high or low nibble of sprite color lookup
                if ( sprite_color[3] == 0 ) begin
                    f8_buf[f8_count][3:0] <= f10_data[3:0];
                end else begin
                    f8_buf[f8_count][3:0] <= f10_data[7:4];
                end
            end
        end
        if ( clk_5M == 0 ) begin
            // hack. buffer on pcb is cleared by pull-downs on the output bus
            // the ram we is asserted after the output is latched then the zero value is written on the opposite 10MHz edge.
            // address clock on the streaming buffer is at 5M.  It writes 0 when the clock is low
            g8_buf[h-1][3:0] <= 0;
        end
        
    end else begin
        if ( k6[0] | j6[0] ) begin
            if ( sprite_valid ) begin
                // sprite_color[3] selects high or low nibble of sprite color lookup
                if ( sprite_color[3] == 0 ) begin
                    g8_buf[g8_count][3:0] <= f10_data[3:0];
                end else begin
                    g8_buf[g8_count][3:0] <= f10_data[7:4];
                end
            end
        end

        if ( clk_5M == 0  ) begin
            // same as g8 above
            f8_buf[h-1][3:0] <= 0;
        end
        
    end
end

always @ (posedge clk_10M) begin     // neg   
    // data in spr_ram_data
    // { pad[7:2], pad[1:0] } on the schematic.  pad counter
    // is h counter really reset and the same time as pad counter (A7)?
    if ( hblank ) begin
        // 64 cycles of checking if y active and storing a7 if it is
        spr_addr <= { a7[5:0], 2'b01 };  // only y
    end else begin
        //spr_addr <= { 6'b0, pad[1:0] };  // only y 63-0
        //spr_addr <= { sp_addr_cache[3][5:0], pad[1:0] };  // only y 63-0
        spr_addr <= { sp_addr_cache[a9], pad[1:0] };  // only y 63-0
    end
    
    if ( ~hblank ) begin
    
        // set the current position into the bitmap rom based on the tile, 
        // y offset and bitmap byte offset
         // last 2 bits are from timing prom pad[0] & pad[1] 
         // if ( sprite_color[5] == 0 ) begin
         if ( flip_y == 0 ) begin
            if ( flip_x == 0 ) begin
                spr_bitmap_addr <= { sprite_tile[5:0], sprite_y[3:0], pic[1:0] } ; 
            end else begin
                spr_bitmap_addr <= { sprite_tile[5:0], sprite_y[3:0], ~pic[1:0] } ; 
            end
         end else begin
            if ( flip_x == 0 ) begin
                spr_bitmap_addr <= { sprite_tile[5:0], ~sprite_y[3:0], pic[1:0] } ; 
            end else begin
                spr_bitmap_addr <= { sprite_tile[5:0], ~sprite_y[3:0], ~pic[1:0] } ; 
            end
         end
         
     end
end

// sprites are added to a visible list during the hblank of the previous line
wire [7:0]j7 = spr_ram_data + (v+1);

always @ (posedge clk_10M) begin

    // J10 logic
    if ( ~hblank ) begin
        // 8 clocks per sprite
        // even is falling 5M clk
        case ( h10[4:0] )
            0:  begin
                    pad <= 2'b00;
                    pic <= 2'b00;
                    load_shift <= 0;
                end
            2:  begin
                    sprite_tile <= spr_ram_data;
                    //sprite_tile <= 8'h06;
                    pad <= 2'b01;
                end
            4:  begin
                    sprite_y <= j7;//spr_ram_data + v ; 

                    if ( spr_ram_data !== 0 && j7 < 16 ) begin
                        sprite_valid <= 1;
                    end else begin
                        sprite_valid <= 0;
                    end
                    pad <= 2'b10;
                end
            6:  begin
                    sprite_color <= spr_ram_data ;
                    //sprite_color <= 8'h02 ;
                    pad <= 2'b11;
                end
            8:  begin
 //                   sprite_x <= spr_ram_data ;
                    //sprite_x <= 8'h68 ;
//                    pad <= 2'b00; // different than prom value
                end
            10: begin
                    // this should be at 8
                    pad <= 2'b00;            
                    load_shift <= 1;
                end
            11: begin
                    load_shift <= 0;
                    pic <= 2'b01;
                end
            14: begin
                    load_shift <= 1;
                end
            15: begin
                    load_shift <= 0;
                    pic <= 2'b10;
                end
            18: begin
                    load_shift <= 1;
                end
            19: begin
                    load_shift <= 0;
                    pic <= 2'b11;
                end
            22: begin
                    load_shift <= 1;
                end
            23: begin
                    load_shift <= 0;
                end
            26: begin
                    dec_a9 <= 1;
                end
            27: begin
                    dec_a9 <= 0;
                    pic <= 2'b00;
                                    
                end
        endcase
    end
end   

reg draw;

reg [3:0] spr_pal_ofs_hi_1 ;
reg [3:0] spr_pal_ofs_low_1 ;

reg [3:0] spr_pal_ofs_hi_2 ;
reg [3:0] spr_pal_ofs_low_2 ;

    // tiles
always @ (posedge clk_10M) begin   
    if ( clk_5M == 1 ) begin
        // sprite
        // load palette - calculate rom offsets
        // check if bg or fg asserted priority

        // register the sprite output or it will be off by one since the tiles are registered.
        spr_pal_ofs_hi_2 <= spr_pal_ofs_hi_1;
        spr_pal_ofs_low_2 <= spr_pal_ofs_low_1;
        
        if ( ( v[0] == 1 && g8_buf[h] > 0) || (v[0] == 0 && f8_buf[h] > 0) ) begin
            if ( v[0] == 1 ) begin
                spr_pal_ofs_hi_1  <= { 1'b0, g8_buf[h] };
                spr_pal_ofs_low_1 <= { 1'b0, g8_buf[h][3:2], g8_buf[h][1:0] };
            end else begin
                spr_pal_ofs_hi_1  <= { 1'b0, f8_buf[h] };
                spr_pal_ofs_low_1 <= { 1'b0, f8_buf[h][3:2], f8_buf[h][1:0] };
            end
        end else begin
            spr_pal_ofs_hi_1 <= 0;
            spr_pal_ofs_low_1 <= 0;
        end 
        
        if ( spr_pal_ofs_hi_2 > 0) begin
            fg_pal_ofs_hi  <= spr_pal_ofs_hi_2;
            fg_pal_ofs_low <= spr_pal_ofs_low_2;
            draw <= 1;
        end else if ( fg !== 0 || fg_attr[6] == 1 ) begin
            // fg
            fg_pal_ofs_hi  <= { fg_attr[2:0] , fg_shift_1[0], fg_shift_0[0] };
            fg_pal_ofs_low <= { fg_attr[5:3] , fg_shift_1[0], fg_shift_0[0] };
            draw <= 1;
            
        end else if ( bg != 0 || bg_attr[6] == 1 ) begin
            // bg
            fg_pal_ofs_hi  <= { bg_attr[2:0] , bg_shift_1[0], bg_shift_0[0] };
            fg_pal_ofs_low <= { bg_attr[5:3] , bg_shift_1[0], bg_shift_0[0] };
            draw <= 1;
        end else begin
            draw <= 0;
        end

        if ( h[2:0] !== 2 ) begin
            // unless we are loading the shift register then shift it.
            fg_shift_0 <= { fg_shift_0[0], fg_shift_0[7:1] };
            fg_shift_1 <= { fg_shift_1[0], fg_shift_1[7:1] };

            bg_shift_0 <= { bg_shift_0[0], bg_shift_0[7:1] };
            bg_shift_1 <= { bg_shift_1[0], bg_shift_1[7:1] };
            
        end
    
        case ( { flip_screen, h[2:0] } )
            0:  begin
                    fg_char_index <= { v[7:3] , h[7:3] }  ; // 32*32 characters
                    bg_char_index <= { bg_scroll[7:3] , h[7:3] }  ; // 32*32 characters
                end
            1:  begin
                    fg_bitmap_addr <= { gfx_fg_attr_data[7], gfx_fg_tile_data, v[2:0] };
                    bg_bitmap_addr <= { gfx_bg_attr_data[7], gfx_bg_tile_data, bg_scroll[2:0] };
                end
            2:  begin 
                    fg_shift_0 <= u8_data;
                    fg_shift_1 <= s8_data;
            
                    bg_shift_0 <= n8_data ;
                    bg_shift_1 <= r8_data ;
                    
                    // these are good for the width of the tile
//                    fg_tile <= { gfx_fg_attr_data[7], gfx_fg_tile_data };
                    fg_attr <= gfx_fg_attr_data;
                    
//                    bg_tile <= { gfx_bg_attr_data[7], gfx_bg_tile_data };
                    bg_attr <= gfx_bg_attr_data; 
                end
            8:  begin
                    fg_char_index <= ~{ v[7:3] , h[7:3] }  ; // 32*32 characters
                    bg_char_index <= ~{ bg_scroll[7:3] , h[7:3] }  ; // 32*32 characters
                end
            9:  begin
                    fg_bitmap_addr <= { gfx_fg_attr_data[7], gfx_fg_tile_data, ~v[2:0] };
                    bg_bitmap_addr <= { gfx_bg_attr_data[7], gfx_bg_tile_data, ~bg_scroll[2:0] };
                end
            10: begin
                    fg_shift_0 <= { u8_data[0], u8_data[1], u8_data[2], u8_data[3], u8_data[4], u8_data[5], u8_data[6], u8_data[7]} ;
                    fg_shift_1 <= { s8_data[0], s8_data[1], s8_data[2], s8_data[3], s8_data[4], s8_data[5], s8_data[6], s8_data[7]} ;
            
                    bg_shift_0 <= { n8_data[0], n8_data[1], n8_data[2], n8_data[3], n8_data[4], n8_data[5], n8_data[6], n8_data[7]} ;
                    bg_shift_1 <= { r8_data[0], r8_data[1], r8_data[2], r8_data[3], r8_data[4], r8_data[5], r8_data[6], r8_data[7]} ;

                    // these are good for the width of the tile
//                    fg_tile <= { gfx_fg_attr_data[7], gfx_fg_tile_data };
                    fg_attr <= gfx_fg_attr_data;
                    
//                    bg_tile <= { gfx_bg_attr_data[7], gfx_bg_tile_data };
                    bg_attr <= gfx_bg_attr_data; 
                end
             
        endcase
    end
end


wire [7:0] fg_pal_data_high;  // read from palette prom
wire [7:0] fg_pal_data_low;

wire [7:0] bg_pal_data_high;
wire [7:0] bg_pal_data_low;

always @ (posedge clk_5M ) begin
    if ( ~hblank & ~vblank ) begin
        if ( draw ) begin
				red <= fg_red[7:4];
				green <= fg_green[7:4];
				blue <= fg_blue[7:4];
        end
    end else begin
        // vblank / hblank
				red <= 0;
				green <= 0;
				blue <= 0;
    end
end    


always @ (posedge clk_4M ) begin
    
    if ( rd_n == 0 ) begin
	     /*if (cpu_addr == 16'h049a )
            // patch rom to bypass "secret" pal protection
            // cpu tries to read val from 0x9803 which is state machine pal
            // written to on all tile ram access. should try converting pal logic to verilog.
				 cpu_din <= 0;
        else*/ if ( cpu_addr >= 16'h0000 && cpu_addr < 16'h8000 )
             cpu_din <= rom_do;
        else if ( cpu_addr >= 16'h8000 && cpu_addr < 16'h8400 )  
            cpu_din <= bg_ram0_data;
        else if ( cpu_addr >= 16'h8400 && cpu_addr < 16'h8800 )  
            cpu_din <= bg_ram1_data;
        else if ( cpu_addr >= 16'h8800 && cpu_addr < 16'h8c00 ) 
            cpu_din <= fg_ram0_data;
        else if ( cpu_addr >= 16'h8c00 && cpu_addr < 16'h9000 )  
            cpu_din <= fg_ram1_data;        
        else if ( cpu_addr == 16'h9803 ) 
            cpu_din <= 0;
        else if ( cpu_addr == 16'ha000 ) 
            cpu_din <= p1;
        else if ( cpu_addr == 16'ha001 )
            cpu_din <= p2;
        else if ( cpu_addr == 16'ha002 )  
            cpu_din <= dsw1;
        else if ( cpu_addr == 16'ha003 )          
            cpu_din <= dsw2;      
        else if ( cpu_addr >= 16'he000 && cpu_addr < 16'hf000 )   
            cpu_din <= cpu_ram_data;
    end else begin
    
        if ( cpu_addr[15:12] == 4'he ) begin
            // 0xe000-0xefff z80 ram
            cpu_ram_w <= ~wr_n ;
        end else if ( cpu_addr[15:12] == 4'h8 ) begin
                case ( cpu_addr[11:10] )
                    6'b00 :  gfx_bg_ram0_wr <= ~wr_n;
                    6'b01 :  gfx_bg_ram1_wr <= ~wr_n;
                    6'b10 :  gfx_fg_ram0_wr <= ~wr_n;
                    6'b11 :  gfx_fg_ram1_wr <= ~wr_n;
                endcase 
        end else if (cpu_addr >= 16'h9000 && cpu_addr < 16'h9800 ) begin 
            // 0x9000-0x90ff sprite ram
            if ( ~vblank ) begin
                spr_ram_wr <=  ~wr_n ;
            end
        end else if (cpu_addr[15:11] == 5'b11111 ) begin 
            // 0xF800-0xffff horz scroll latch
            if ( wr_n == 0 ) begin
                bg_scroll_y <= cpu_dout;
            end
        end else if (cpu_addr == 16'h9800 ) begin         
            if ( wr_n == 0 ) begin
                flip_screen <= cpu_dout[0];
            end
        end else if (cpu_addr == 16'h9801 ) begin 
            sound1_wr <= ~wr_n;
            sound1_en <= 1;
        end else if (cpu_addr == 16'h9802 ) begin 
            sound2_wr <= ~wr_n;
            sound2_en <= 1;        
        end else begin
            // no valid write address
            cpu_ram_w <= 0 ;
            
            gfx_fg_ram0_wr <= 0 ;
            gfx_fg_ram1_wr <= 0 ;
            
            gfx_bg_ram0_wr <= 0 ;
            gfx_bg_ram1_wr <= 0 ;
            
            sound1_wr <= 0;
            sound1_en <= 0;    

            sound2_wr <= 0;
            sound2_en <= 0;    
        end
    end
end

// first 256 bytes are attribute data
// bit 7 of attr == MSB of tile 
// bit 6 tile flip
// bit 5-0 == 64 colors from palette
// bytes 256-511 are tile index

    
wire wr_n;
wire rd_n;

reg vert_int_n;
always @ (posedge clk_4M ) begin
    vert_int_n <= (v !== 200 ) ;
end
    
T80pa u_cpu(
    .RESET_n    ( ~reset   ),
	 .CLK      	 ( clk_8M  ),
    .CEN_p      ( clk_4M  ),
    .CEN_n      ( 1'b1     ),
    .WAIT_n     ( 1'b1     ),
    .INT_n      ( vert_int_n ),  
    .NMI_n      ( 1'b1     ),
    .BUSRQ_n    ( 1'b1     ),
    .RD_n       ( rd_n     ),
    .WR_n       ( wr_n     ),
    .A          ( cpu_addr ),
    .DI         ( cpu_din  ),
    .DO         ( cpu_dout )
);

reg sound1_wr;
reg sound1_en ;

reg sound2_wr;
reg sound2_en ;

SN76496 sound1(
	.clk(clk_4M),
	.cpuclk(clk_4M),
	.reset(reset),
	.ce(sound1_en),
	.we(sound1_wr),
	.data(cpu_dout),
	.chmsk(4'b1111),
	.sndout(sound1_out)
);

SN76496 sound2(
	.clk(clk_4M),
	.cpuclk(clk_4M),
	.reset(reset),
	.ce(sound2_en),
	.we(sound2_wr),
	.data(cpu_dout),
	.chmsk(4'b1111),
	.sndout(sound2_out)
);
 
assign rom_addr = cpu_addr[14:0];
    
cpu_ram    cpu_ram_inst (
    .address ( cpu_addr[11:0] ),
    .clock ( ~clk_4M ),
    .data ( cpu_dout ),
    .wren ( cpu_ram_w ),
    .q ( cpu_ram_data )
    );

// foreground tile attributes
ram_dp_1k gfx_fg_ram0_inst (
	.clock_a ( ~clk_5M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_fg_ram0_wr ),
	.q_a ( fg_ram0_data ),

	.clock_b ( ~clk_10M ),
	.address_b ( fg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_fg_attr_data )
	);

// foreground tile index
ram_dp_1k gfx_fg_ram1_inst (
	.clock_a ( ~clk_4M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_fg_ram1_wr ),
	.q_a ( fg_ram1_data ),

	.clock_b ( ~clk_10M ),
	.address_b ( fg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_fg_tile_data )
	);
    
// background tile attributes    
ram_dp_1k gfx_bg_ram0_inst (
	.clock_a ( ~clk_4M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_bg_ram0_wr ),
	.q_a ( bg_ram0_data ),

	.clock_b ( ~clk_10M ),
	.address_b ( bg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_bg_attr_data )
	);
    
// background tile index    
ram_dp_1k gfx_bg_ram1_inst (
	.clock_a ( ~clk_4M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_bg_ram1_wr ),
	.q_a ( bg_ram1_data ),

	.clock_b ( ~clk_10M ),
	.address_b ( bg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_bg_tile_data )
	);
    
// sprite ram - hardware uses 2x6148 = 1k, only 256 bytes can be addressed
ram_dp_1k spr_ram (
	.clock_a ( ~clk_4M ),
	.address_a ( { 2'b00, cpu_addr[7:0] } ),
	.data_a ( cpu_dout ),
	.wren_a ( spr_ram_wr ),
//	.q_a ( ), // cpu can't read sprite ram

	.clock_b ( ~clk_10M ),
	.address_b ( spr_addr ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( spr_ram_data )
	);
	
// Programm Roms
//cpu_rom cpu_rom(
//	.clk(~clk_4M),
//	.addr(cpu_addr[14:0]),
//	.data(cpu01rom_data)
//);	
	

// FG Roms
fg1_rom fg1_rom(
	.clk(~clk_10M),
	.addr(fg_bitmap_addr),
	.data(s8_data)
);

fg2_rom fg2_rom(
	.clk(~clk_10M),
	.addr(fg_bitmap_addr),
	.data(u8_data)
);

// BG Roms
bg1_rom bg1_rom(
	.clk(~clk_10M),
	.addr(bg_bitmap_addr ),
	.data(r8_data)
);

bg2_rom bg2_rom(
	.clk(~clk_10M),
	.addr(bg_bitmap_addr ),
	.data(n8_data)
);

// Sprite Roms
spr1_rom spr1_rom(
	.clk(~clk_10M),
	.addr(spr_bitmap_addr),
	.data(h5_data)
);
    
spr2_rom spr2_rom(
	.clk(~clk_10M),
	.addr(spr_bitmap_addr),
	.data(k5_data)
);

//Patette
pal_high_prom pal_high_prom(
	.clk(~clk_10M),
	.addr(fg_pal_ofs_hi),
	.data(fg_pal_data_high)
);

pal_low_prom pal_low_prom(
	.clk(~clk_10M),
	.addr(fg_pal_ofs_low),
	.data(fg_pal_data_low)
);

//Sprite LUT
spr_col_lut_prom spr_col_lut_prom(
	.clk(~clk_10M),
	.addr(f10_addr),
	.data(f10_data)
);

    
endmodule

