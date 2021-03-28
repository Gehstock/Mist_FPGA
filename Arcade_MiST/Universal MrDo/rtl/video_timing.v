
module video_timing (
    input clk_pix,   // pixel clock
    input reset,     // reset

    output reg [7:0]v,  // { vd_, vc_, vb_, va_, vd, vc, vb, va }  _ == backtick
    output reg [7:0]h,  // { hd_, hc_, hb_, ha_, hd, hc, hb, ha }  _ == backtick

    output reg hbl,
//    output reg hx,
    output reg hff,
    output reg vbl,
    
    output reg hsync,     // horizontal sync
    output reg vsync,     // vertical sync
    output reg de         // data enable (low in blanking interval)
    );
    
// sync is enable low
// screen.set_raw(VIDEO_CLOCK/4, 312, 8, 248, 262, 32, 224);

// horizontal timings
parameter HBLANK_START  = 256;
parameter HSYNC_START   = 264;
parameter HSYNC_END     = 304;
parameter HBLANK_END    = 8;
parameter H_TOTAL       = 312;

// vertical timings
parameter VBLANK_START = 224;
parameter VSYNC_START  = 256;
parameter VSYNC_END    = 258;
parameter VBLANK_END   = 32;
parameter V_TOTAL      = 262;

reg [9:0] sx;
reg [9:0] sy;

always @ (posedge clk_pix) begin
    hsync <= ~(sx >= HSYNC_START && sx < HSYNC_END);  // invert: negative polarity
    vsync <= ~(sy >= VSYNC_START && sy < VSYNC_END);  // invert: negative polarity
    
    de <=  1;//( sy < VERT_ACTIVE_END && sx < HORZ_ACTIVE_END ) ;
    // adjust de for 1 pixel latency.  character data is not displayed until on pix_clk after begin read
end

always @ (posedge clk_pix) begin
    if (reset) begin
        sx <= 0;
        sy <= 0;
        hbl <= 1;
        vbl <= 0;
    end else begin
        if ( sx < H_TOTAL ) begin
            sx <= sx + 1;
        end else begin
            sx <= 0;
            if ( sy < V_TOTAL ) begin
                sy <= sy + 1;
            end else begin
                sy <= 0;
            end
        end
    end
    
    case ( sx )
        HBLANK_START-1: hff <= 1;
        HBLANK_START:   hbl <= 1;
        HBLANK_END-1:   hff <= 0;
        HBLANK_END:     hbl <= 0;
    endcase
    
    case ( sy )
        VBLANK_START:   vbl <= 1;
        VBLANK_END:     vbl <= 0;
    endcase
    
    h <= sx[7:0];
    v <= sy[7:0];
    
end

endmodule
