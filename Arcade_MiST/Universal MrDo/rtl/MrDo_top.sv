module MrDo_top(
input 		clk_20M,
input 		reset,
input       user_flip,
output		[3:0] red,
output		[3:0] green,
output		[3:0] blue,
output		hsync,
output		vsync,
output reg  hblank,
output reg  vblank,
output		[7:0] sound1_out,
output		[7:0] sound2_out,
input 		[7:0] p1,
input 		[7:0] p2,
input 		[7:0] dsw1,
input 		[7:0] dsw2,
output		[14:0] rom_addr,
input 		[7:0] rom_do,
input       [15:0] dl_addr,
input       [7:0] dl_data,
input       dl_we
);

reg clk_4M_en, clk_4Mn_en;
reg clk_5M_en, clk_5Mn_en;
reg clk_10M_en;
reg [1:0] clk_cnt;
reg [2:0] clk_4M_cnt;

always @(posedge clk_20M)
if (reset) begin
    clk_4M_en <= 0;
    clk_5M_en <= 0;
    clk_10M_en <= 0;
end else begin
    // 4MHz clock enable
    clk_4M_cnt <= clk_4M_cnt + 1'd1;
    if (clk_4M_cnt == 4) clk_4M_cnt <= 0;
    clk_4M_en <= clk_4M_cnt == 0;
    clk_4Mn_en <= clk_4M_cnt == 2;

    // 5MHz, 10MHz clock enables
    clk_cnt <= clk_cnt + 1'd1;
    clk_5M_en <= clk_cnt == 0;
    clk_5Mn_en <= clk_cnt == 2;
    clk_10M_en <= !clk_cnt[0];
end

wire hff;
wire hx;
reg [7:0]v;
reg [7:0]h;
wire hbl_hx = hbl | hx;
wire hbl, vbl;

video_timing video_timing (
    .clk(clk_20M),
    .clk_pix_en(clk_5Mn_en),
    .reset(reset),    

    .h(h),
    .v(v),
    
    .hbl(hbl),
    .hff(hff),
    .hx(hx),
    .vbl(vbl),
  
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
always @ ( posedge clk_20M ) begin
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

reg [4:0] sp_pal_ofs_hi ;
reg [4:0] sp_pal_ofs_low ;

reg [7:0] bg_scroll_y;
reg [7:0] bg_scroll_x;

wire [7:0] bg_scroll;
assign bg_scroll = user_flip ? (v + ~bg_scroll_y) : v + bg_scroll_y;

//// ---------- sprites ----------
reg spr_ram_wr;   
reg [7:0] spr_addr;
wire [7:0] spr_ram_data;

reg [7:0] spr_shift_data;

reg [7:0] sprite_tile;
reg [7:0] sprite_x;
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

reg [1:0] pad ;
reg [1:0] pic ;
reg [7:0] h10 ; // counter h10 LS393 drives timing prom J10
reg [3:0] k6;
reg [3:0] j6;
reg load_shift;
reg dec_a9;

wire sp_bank = ( sprite_tile[6] == 1 );
wire flip_x  = ( sprite_color[4] == 1 );
wire flip_y  = ( sprite_color[5] == 1 );
reg cocktail_flip;

// hbl is made 64 clocks
always @ (posedge clk_20M) begin
    if ( hbl_hx ) begin
        // clocked on the rising edge of HA. ie h[0]
        if ( clk_5M_en && h[0] == 1 ) begin
            // if tile is visible and still room in address stack
            if ( j7[7:4] == 0 && a9 < 15 && h < 8'hff) begin
                sp_addr_cache[a9][5:0] <= a7;
                a9 <= a9 + 1'd1;
            end 
            a7 <= a7 + 1'd1;
        end
        h10 <= 0;
    end else if (clk_10M_en) begin
        // reset a9 on last pixel of playfield
        // should be zero anyways if a9 counted down correctly
        if ( hff == 1 ) begin
            a9 <= 0;
        end else if ( dec_a9 == 1 ) begin
            // a9 counts down on falling edge of pic1 when a9 > 0 and ~hbl 
            if ( a9 > 0 ) begin
                 a9 <= a9 - 1'd1;
            end
        end

        h10 <= h10 + 1'd1;
        a7 <= 0;
    end
end

always @ ( posedge clk_20M ) begin // neg
  if (clk_10M_en) begin
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
    if ( hbl ) begin
        f8_count <= 0;
        g8_count <= 0;
    end else if ( pad[1:0] == 2'b11 ) begin
        // mux G9 gives LA4 ( L9 nand pad 1+0 ) to F8 or G8 load line
        // load one from sprite x pos, increment the other
        if ( v[0] == 1 ) begin
            f8_count <= spr_ram_data ;
            if ( clk_5M_en ) begin
                g8_count <= g8_count + 1'd1;
            end
        end else begin
            g8_count <= spr_ram_data ;
            if ( clk_5M_en ) begin
                f8_count <= f8_count + 1'd1;
            end
        end
    end else begin 
        // increment both
        if ( v[0] == 1 ) begin
            if ( sprite_valid ) begin
                f8_count <= f8_count + 1'd1;
            end
            if ( clk_5M_en ) begin
                g8_count <= g8_count + 1'd1;
            end
        end else begin
            if ( sprite_valid ) begin
                g8_count <= g8_count + 1'd1;
            end
            if ( clk_5M_en ) begin
                f8_count <= f8_count + 1'd1;
            end
        end
    end
  end
end

always @ ( posedge clk_20M ) begin
  if (clk_10M_en) begin
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
        
        // buffer on pcb is cleared by pull-downs on the output bus
        // the ram we is asserted after the output is latched then the zero value is written on the opposite 10MHz edge.
        // address clock on the streaming buffer is at 5M.  It writes when the clock is high because clock gets inverted by L9
        
        if ( clk_5M_en && ~hbl_hx ) begin
            g8_buf[g8_count_flip][3:0] <= 0;
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
        if ( clk_5M_en == 1 && ~hbl_hx ) begin
            f8_buf[f8_count_flip][3:0] <= 0;
        end
    end 
  end
end

reg [4:0] spr_pal_ofs_hi;
reg [4:0] spr_pal_ofs_low;

wire [7:0] g8_count_flip;
assign g8_count_flip = user_flip ? ~g8_count : g8_count;

wire [7:0] f8_count_flip;
assign f8_count_flip = user_flip ? ~f8_count : f8_count;

// sprite buffer handling
always @ (posedge clk_20M) begin   
    if ( clk_5Mn_en ) begin
        // default to clear
        spr_pal_ofs_hi <= 0;
        spr_pal_ofs_low <= 0;
        
        if ( v[0] == 1 && g8_buf[g8_count_flip] > 0 ) begin
            spr_pal_ofs_hi  <= { 1'b0, g8_buf[g8_count_flip] };
            spr_pal_ofs_low <= { 1'b0, g8_buf[g8_count_flip][3:2], g8_buf[g8_count_flip][1:0] };
        end 
        if ( v[0] == 0 && f8_buf[f8_count_flip] > 0 ) begin
            spr_pal_ofs_hi  <= { 1'b0, f8_buf[f8_count_flip] };
            spr_pal_ofs_low <= { 1'b0, f8_buf[f8_count_flip][3:2], f8_buf[f8_count_flip][1:0] };
        end
    end 
end

always @ (posedge clk_20M) begin     // neg
  if (clk_10M_en) begin
    // data in spr_ram_data
    // { pad[7:2], pad[1:0] } on the schematic.  pad counter
    // is h counter really reset and the same time as pad counter (A7)?
    if ( hbl_hx ) begin
        // 64 cycles of checking if y active and storing a7 if it is
        spr_addr <= { a7[5:0], 2'b01 };  // only y
    end else begin
        spr_addr <= { sp_addr_cache[a9], pad[1:0] };  // only y 63-0
    end
    
    if ( ~hbl_hx ) begin
    
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
            if (  flip_x == 0 ) begin
                spr_bitmap_addr <= { sprite_tile[5:0], ~sprite_y[3:0], pic[1:0] } ; 
            end else begin
                spr_bitmap_addr <= { sprite_tile[5:0], ~sprite_y[3:0], ~pic[1:0] } ; 
            end
         end
         
     end
   end
end

// sprites are added to a visible list during the hblank of the previous line
wire [7:0]j7 = user_flip ? (spr_ram_data + ~(v+1'd1)) : spr_ram_data + (v+1'd1);

always @ (posedge clk_20M) begin
  if (clk_10M_en) begin
    // J10 logic
    // 8 clocks per sprite
    // even is falling 5M clk
    // timing altered from prom to deal with async/sync differences 
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
                sprite_y <= j7; // spr_ram_data + v ; 

                if ( spr_ram_data !== 0 && j7 < 16 ) begin
                    sprite_valid <= 1;
                end else begin
                    sprite_valid <= 0;
                end
                pad <= 2'b10;
            end
        6:  begin
                sprite_color <= spr_ram_data ;
                pad <= 2'b11;
            end
        8:  begin
                sprite_x <= spr_ram_data ;
//                    pad <= 2'b00; // different than prom value
            end
        9:  begin
                load_shift <= 1; 
            end
        10: begin
                        load_shift <= 0;
                // this should be at 8
                pad <= 2'b00;            
            end
        11: begin
                pic <= 2'b01;
            end
        13: begin
                load_shift <= 1; 
            end
        14: begin
                load_shift <= 0; 
            end
        15: begin
                pic <= 2'b10;
            end
        17: begin
                load_shift <= 1; 
            end
        18: begin
                load_shift <= 0; 
            end
        19: begin
                pic <= 2'b11;
            end
        21: begin
                load_shift <= 1;
            end
        22: begin
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

// tiles
always @ (posedge clk_20M) begin   
    if ( clk_5M_en ) begin
        // load palette - calculate rom offsets
        // check if bg or fg asserted priority

        if ( spr_pal_ofs_hi > 0 && ( h > 16 || ~user_flip ) ) begin
            // the h > 16 condition is a screen flip hack.  not in original hardware
            fg_pal_ofs_hi  <= spr_pal_ofs_hi;
            fg_pal_ofs_low <= spr_pal_ofs_low;
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

        if ( h[2:0] !== 7 ) begin
            // unless we are loading the shift register then shift it.
            fg_shift_0 <= { fg_shift_0[0], fg_shift_0[7:1] };
            fg_shift_1 <= { fg_shift_1[0], fg_shift_1[7:1] };

            bg_shift_0 <= { bg_shift_0[0], bg_shift_0[7:1] };
            bg_shift_1 <= { bg_shift_1[0], bg_shift_1[7:1] };
            
        end
    
        // load / shift tiles
        case ( { cocktail_flip ^ user_flip, h[2:0] } )
            5:  begin
                    fg_char_index <= { v[7:3] , h[7:3] }  ; // 32*32 characters
                    bg_char_index <= { bg_scroll[7:3] , h[7:3] }  ; // 32*32 characters
                end
            6:  begin
                    fg_bitmap_addr <= { gfx_fg_attr_data[7], gfx_fg_tile_data, v[2:0] };
                    bg_bitmap_addr <= { gfx_bg_attr_data[7], gfx_bg_tile_data, bg_scroll[2:0] };
                end
            7:  begin 
                    // latched by N9/P9 & U9 & S9 on h[2:0] == 111 R6 creates latch clock
                    fg_shift_0 <= u8_data;
                    fg_shift_1 <= s8_data;
            
                    bg_shift_0 <= n8_data ;
                    bg_shift_1 <= r8_data ;
                    
                    fg_attr <= gfx_fg_attr_data;
                    bg_attr <= gfx_bg_attr_data; 
                end
            13:  begin
                    fg_char_index <= ~{ v[7:3] , h[7:3] }  ; // 32*32 characters
                    bg_char_index <= ~{ bg_scroll[7:3] , h[7:3] }  ; // 32*32 characters
                end
            14:  begin
                    fg_bitmap_addr <= { gfx_fg_attr_data[7], gfx_fg_tile_data, ~v[2:0] };
                    bg_bitmap_addr <= { gfx_bg_attr_data[7], gfx_bg_tile_data, ~bg_scroll[2:0] };
                end
            15: begin
                    fg_shift_0 <= { u8_data[0], u8_data[1], u8_data[2], u8_data[3], u8_data[4], u8_data[5], u8_data[6], u8_data[7]} ;
                    fg_shift_1 <= { s8_data[0], s8_data[1], s8_data[2], s8_data[3], s8_data[4], s8_data[5], s8_data[6], s8_data[7]} ;
            
                    bg_shift_0 <= { n8_data[0], n8_data[1], n8_data[2], n8_data[3], n8_data[4], n8_data[5], n8_data[6], n8_data[7]} ;
                    bg_shift_1 <= { r8_data[0], r8_data[1], r8_data[2], r8_data[3], r8_data[4], r8_data[5], r8_data[6], r8_data[7]} ;

                    fg_attr <= gfx_fg_attr_data;
                    bg_attr <= gfx_bg_attr_data; 
                end
             
        endcase
    end
end


wire [7:0] fg_pal_data_high;  // read from palette prom
wire [7:0] fg_pal_data_low;

wire [7:0] bg_pal_data_high;
wire [7:0] bg_pal_data_low;

always @ (posedge clk_20M ) begin
    if (clk_5M_en) begin
        hblank <= hbl_hx;
        vblank <= vbl;

        if ( ~hbl_hx & ~vbl ) begin
            if ( draw ) begin
                red <= fg_red[7:4];
                green <= fg_green[7:4];
                blue <= fg_blue[7:4];
            end else begin
                {red, green, blue} <= 0;
            end
        end else begin
            // vblank / hblank
            {red, green, blue} <= 0;
        end
    end
end

reg [15:0] unhandled_addr ;

always @ (posedge clk_20M ) begin
    
    if ( rd_n == 0 ) begin
        // read program rom
        if ( cpu_addr >= 16'h0000 && cpu_addr < 16'h8000 ) begin
            cpu_din <= rom_do; // 0x0000
        end else if ( cpu_addr >= 16'h8000 && cpu_addr < 16'h8400 ) begin   
            cpu_din <= bg_ram0_data;
        end else if ( cpu_addr >= 16'h8400 && cpu_addr < 16'h8800 ) begin    
            cpu_din <= bg_ram1_data;
        end else if ( cpu_addr >= 16'h8800 && cpu_addr < 16'h8c00 ) begin   
            cpu_din <= fg_ram0_data;
        end else if ( cpu_addr >= 16'h8c00 && cpu_addr < 16'h9000 ) begin   
            cpu_din <= fg_ram1_data;
        end else if ( cpu_addr == 16'h9803 ) begin   
            cpu_din <= u001_dout;
        end else if ( cpu_addr == 16'ha000 ) begin   
            cpu_din <= p1;
        end else if ( cpu_addr == 16'ha001 ) begin
            cpu_din <= p2;
        end else if ( cpu_addr == 16'ha002 ) begin   
            cpu_din <= dsw1;
        end else if ( cpu_addr == 16'ha003 ) begin           
            cpu_din <= dsw2;
        end else if ( cpu_addr >= 16'he000 && cpu_addr < 16'hf000 ) begin   
            cpu_din <= cpu_ram_data;
        end else begin
            unhandled_addr <= cpu_addr;
        end
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
                cocktail_flip <= cpu_dout[0];
            end
        end else if (cpu_addr == 16'h9801 ) begin 
            sound1_en <= 1;
        end else if (cpu_addr == 16'h9802 ) begin 
            sound2_en <= 1;        
        end else begin
            // no valid write address
            cpu_ram_w <= 0 ;
            
            gfx_fg_ram0_wr <= 0 ;
            gfx_fg_ram1_wr <= 0 ;
            
            gfx_bg_ram0_wr <= 0 ;
            gfx_bg_ram1_wr <= 0 ;
            
            sound1_en <= 0;    
            sound2_en <= 0;    
        end
    end
end

// u001 "secret" pal protection
// cpu tries to read val from 0x9803 which is state machine pal
// written to on all tile ram access..

wire [7:0] u001_dout ;

reg gfx_ram_wr_old;
always @(posedge clk_20M) gfx_ram_wr_old <= gfx_fg_ram0_wr | gfx_fg_ram1_wr;
wire secret_pal_clk_en = ~gfx_ram_wr_old & (gfx_fg_ram0_wr | gfx_fg_ram1_wr);

secret_pal u001
(
	.clk( clk_20M ),
	.clk_en( secret_pal_clk_en ),
	.din( cpu_dout ),
	.dout( u001_dout )
);

// first 256 bytes are attribute data
// bit 7 of attr == MSB of tile 
// bit 6 tile flip
// bit 5-0 == 64 colors from palette
// bytes 256-511 are tile index

    
wire wr_n;
wire rd_n;

reg vert_int_n;
always @ (posedge clk_20M ) begin
    vert_int_n <= (v !== 208 ) ;
end
    
T80pa u_cpu(
    .RESET_n    ( ~reset     ),
    .CLK        ( clk_20M    ),
    .CEN_p      ( clk_4M_en  ),
    .CEN_n      ( clk_4Mn_en ),
    .WAIT_n     ( sound1_wait & sound2_wait ),
    .INT_n      ( vert_int_n ),  
    .NMI_n      ( 1'b1       ),
    .BUSRQ_n    ( 1'b1       ),
    .RD_n       ( rd_n       ),
    .WR_n       ( wr_n       ),
    .A          ( cpu_addr   ),
    .DI         ( cpu_din    ),
    .DO         ( cpu_dout   )
);

reg sound1_en;
wire sound1_wait;

reg sound2_en;
wire sound2_wait;

sn76489_top psg0(
    .clock_i(clk_20M),
    .clock_en_i(clk_4M_en),
    .res_n_i(~reset),
    .ce_n_i(~sound1_en),
    .we_n_i(wr_n),
    .d_i(cpu_dout),
    .ready_o(sound1_wait),
    .aout_o(sound1_out)
);

sn76489_top psg1(
    .clock_i(clk_20M),
    .clock_en_i(clk_4M_en),
    .res_n_i(~reset),
    .ce_n_i(~sound2_en),
    .we_n_i(wr_n),
    .d_i(cpu_dout),
    .ready_o(sound2_wait),
    .aout_o(sound2_out)
);

assign rom_addr = cpu_addr[14:0];
    
cpu_ram    cpu_ram_inst (
    .address ( cpu_addr[11:0] ),
    .clock (clk_20M ),
    .data ( cpu_dout ),
    .wren ( cpu_ram_w ),
    .q ( cpu_ram_data )
    );

// foreground tile attributes
ram_dp_1k gfx_fg_ram0_inst (
	.clock_a ( clk_20M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_fg_ram0_wr ),
	.q_a ( fg_ram0_data ),

	.clock_b ( clk_20M ),
	.address_b ( fg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_fg_attr_data )
	);

// foreground tile index
ram_dp_1k gfx_fg_ram1_inst (
	.clock_a ( clk_20M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_fg_ram1_wr ),
	.q_a ( fg_ram1_data ),

	.clock_b ( clk_20M ),
	.address_b ( fg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_fg_tile_data )
	);
    
// background tile attributes    
ram_dp_1k gfx_bg_ram0_inst (
	.clock_a ( clk_20M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_bg_ram0_wr ),
	.q_a ( bg_ram0_data ),

	.clock_b ( clk_20M ),
	.address_b ( bg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_bg_attr_data )
	);
    
// background tile index    
ram_dp_1k gfx_bg_ram1_inst (
	.clock_a ( clk_20M ),
	.address_a ( cpu_addr[9:0] ),
	.data_a ( cpu_dout ),
	.wren_a ( gfx_bg_ram1_wr ),
	.q_a ( bg_ram1_data ),

	.clock_b ( clk_20M ),
	.address_b ( bg_char_index ),
	.data_b ( 0 ),
	.wren_b ( 0 ),
	.q_b ( gfx_bg_tile_data )
	);
    
// sprite ram - hardware uses 2x6148 = 1k, only 256 bytes can be addressed
ram_dp_1k spr_ram (
	.clock_a ( clk_20M ),
	.address_a ( { 2'b00, cpu_addr[7:0] } ),
	.data_a ( cpu_dout ),
	.wren_a ( spr_ram_wr ),
//	.q_a ( ), // cpu can't read sprite ram

	.clock_b ( clk_20M ),
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
	
// foreground tile bitmap S8   
wire s8_cs = (dl_addr[15:12] == 4'b1000);

dpram #(8,12) gfx_s8 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[11:0] ),
    .we_a(dl_we & s8_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(fg_bitmap_addr),
    .q_b(s8_data)
	);

// foreground tile bitmap u8  
wire u8_cs = (dl_addr[15:12] == 4'b1001);

dpram #(8,12) gfx_u8 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[11:0] ),
    .we_a(dl_we & u8_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(fg_bitmap_addr),
    .q_b(u8_data)
	);


// background tile bitmap r8
wire r8_cs = (dl_addr[15:12] == 4'b1010);

dpram #(8,12) gfx_r8 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[11:0] ),
    .we_a(dl_we & r8_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(bg_bitmap_addr),
    .q_b(r8_data)
	);

// background tile bitmap n8
wire n8_cs = (dl_addr[15:12] == 4'b1011);

dpram #(8,12) gfx_n8 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[11:0] ),
    .we_a(dl_we & n8_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(bg_bitmap_addr),
    .q_b(n8_data)
	);


// sprite bitmap h5
wire h5_cs = (dl_addr[15:12] == 4'b1100);

dpram #(8,12) gfx_h5 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[11:0] ),
    .we_a(dl_we & h5_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(spr_bitmap_addr),
    .q_b(h5_data)
	);

// sprite bitmap k5
wire k5_cs = (dl_addr[15:12] == 4'b1101);

dpram #(8,12) gfx_k5 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[11:0] ),
    .we_a(dl_we & k5_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(spr_bitmap_addr),
    .q_b(k5_data)
	);


// palette high bits
wire u02_cs = (dl_addr[15:5] == 11'b11100000000 );

dpram #(8,5) gfx_u02 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[4:0] ),
    .we_a(dl_we & u02_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(fg_pal_ofs_hi),
    .q_b(fg_pal_data_high)
	);

// palette low bits
wire t02_cs = (dl_addr[15:5] == 11'b11100000001 );

dpram #(8,5) gfx_t02 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[4:0] ),
    .we_a(dl_we & t02_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(fg_pal_ofs_low),
    .q_b(fg_pal_data_low)
	);

// sprite palette lookup F10
wire f10_cs = (dl_addr[15:5] == 11'b11100000010 );

dpram #(8,5) gfx_f10 (
    .clk_a(clk_20M),
    .addr_a(dl_addr[4:0] ),
    .we_a(dl_we & f10_cs),
    .d_a(dl_data),

    .clk_b(clk_20M),
    .addr_b(f10_addr),
    .q_b(f10_data)
	);

endmodule
