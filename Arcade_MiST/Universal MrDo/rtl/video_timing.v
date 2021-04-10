
module video_timing (
    input clk,
    input clk_pix_en, // pixel clock enable
    input reset,      // reset

    output [7:0]v,  // { vd_, vc_, vb_, va_, vd, vc, vb, va }  _ == backtick
    output [7:0]h,  // { hd_, hc_, hb_, ha_, hd, hc, hb, ha }  _ == backtick

    output reg hbl,
    output     hx,
    output     hff,
    output reg vbl,
    
    output reg hsync,     // horizontal sync
    output reg vsync,     // vertical sync
    output reg de         // data enable (low in blanking interval)
    );

// sync is enable low
// screen.set_raw(VIDEO_CLOCK/4, 312, 8, 248, 262, 32, 224);

// horizontal timings
parameter HBLANK_START  = 464-1;
parameter HSYNC_START   = 466;
parameter HSYNC_END     = 486;
parameter HBLANK_END    = 8-1;

// vertical timings
parameter VBLANK_START = 224;
parameter VSYNC_START  = 497;
parameter VSYNC_END    = 500;
parameter VBLANK_END   = 32;

reg [8:0] sx;
reg [8:0] sy;

assign h = sx[7:0];
assign v = sy[7:0];
assign hx = sx[8];
assign hff = sx == 255;

always @ (posedge clk) begin
    hsync <= ~(sx >= HSYNC_START && sx < HSYNC_END);  // invert: negative polarity
    vsync <= ~(sy >= VSYNC_START && sy < VSYNC_END);  // invert: negative polarity
    
    de <=  1;//( sy < VERT_ACTIVE_END && sx < HORZ_ACTIVE_END ) ;
    // adjust de for 1 pixel latency.  character data is not displayed until on pix_clk after begin read
end

always @ (posedge clk) begin
    if (reset) begin
        sx <= 0;
        sy <= 9'd16;
        hbl <= 1;
        vbl <= 0;
    end else if (clk_pix_en) begin
        sx <= sx + 1'd1;
        if (sx[7:0] == 255) begin
            sx <= {~sx[8], sx[8] ? 8'd0 : 8'd200}; // 0-255, 456-511 = 312 pixels
            if (~sx[8]) begin
                sy <= sy + 1'd1;
                if (sy[7:0] == 255) begin
                    sy <= {~sy[8], sy[8] ? 8'd16 : 8'd234}; // 16-255, 490-511 = 262 lines
                end
            end
        end

        case ( sx )
            HBLANK_START:   hbl <= 1;
            HBLANK_END:     hbl <= 0;
        endcase

        case ( sy )
            VBLANK_START:   vbl <= 1;
            VBLANK_END:     vbl <= 0;
        endcase
    end

end

endmodule
