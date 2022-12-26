
module video_timing
(
    input       clk,
    input       clk_pix,
    input       reset,

    input  signed [3:0] hs_offset,
    input  signed [3:0] vs_offset,

    input  signed [3:0] hs_width,
    input  signed [3:0] vs_width,
    input  hbl_shift,

    output [8:0] hc,
    output [8:0] vc,

    output reg  hsync,
    output reg  vsync,

    output reg  hbl,
    output reg  vbl 
);

wire [8:0] h_ofs = 0;
wire [8:0] HBL_START  = hbl_shift ? 9'd262 : 9'd266 ;
wire [8:0] HBL_END    = hbl_shift ? 9'd6 : 9'd10 ;
wire [8:0] HS_START   = HBL_START + 9'd41 + $signed(hs_offset);
wire [8:0] HS_END     = HBL_START + 9'd73 + $signed(hs_offset) + $signed(hs_width);
wire [8:0] HTOTAL     = 9'd383;

wire [8:0] v_ofs = 0;
wire [8:0] VBL_START  = 9'd240 ;
wire [8:0] VBL_END    = 9'd16 ;
wire [8:0] VS_START   = VBL_START + 9'd13 + $signed(vs_offset);
wire [8:0] VS_END     = VBL_START + 9'd21 + $signed(vs_offset) + $signed(vs_width);
wire [8:0] VTOTAL     = 9'd263 ;


reg [8:0] v;
reg [8:0] h;

assign vc = v - v_ofs;
assign hc = h - h_ofs;

always @ (posedge clk) begin
    if (reset) begin
        h <= 0;
        v <= 0;

        hbl <= 0;
        vbl <= 0;

        hsync <= 0;
        vsync <= 0;
    end else if ( clk_pix == 1 ) begin 
        // counter
        if (h == HTOTAL) begin
            h <= 0;
            v <= v + 1'd1;

            if ( v == VTOTAL ) begin
                v <= 0;
            end
        end else begin
            h <= h + 1'd1;
        end

        // h signals
        if ( h == HBL_START ) begin
            hbl <= 1;
        end else if ( h == HBL_END ) begin
            hbl <= 0;
        end

        // v signals
        if ( v == VBL_START ) begin
            vbl <= 1;
        end else if ( v == VBL_END ) begin
            vbl <= 0;
        end
   
        if ( v == (VS_START ) ) begin
            vsync <= 1;
        end else if ( v == (VS_END ) ) begin
            vsync <= 0;
        end

        if ( h == (HS_START ) ) begin
            hsync <= 1;
        end else if ( h == (HS_END ) ) begin
            hsync <= 0;
        end
    end

end

endmodule

