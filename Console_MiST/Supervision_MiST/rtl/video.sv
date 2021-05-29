
module video(

  input 				clk,//vga
  input 				clk7p16,//rgb
  output 			ce_pxl,
  input 				white,
  // from lcd ctrl registers
  input ce,
  input [7:0] 		lcd_xsize,
  input [7:0] 		lcd_ysize,
  input [7:0] 		lcd_xscroll,
  input [7:0] 		lcd_yscroll,
  output 			lcd_pulse,

  // to/from vram
  output [12:0] 	addr,
  input [7:0] 		data,

  // to vga interface
  output 			hsync,
  output 			vsync,
  output 			hblank,
  output 			vblank,
  output reg [7:0] red,
  output reg [7:0] green,
  output reg [7:0] blue
);

reg [9:0] hcount;
reg [9:0] vcount;
assign lcd_pulse = ce_pxl;
// VGA industry standard 640x480@60         800    525      31.5    - -      25.2         16    96   48     10    2   33        MHi modelines table
// visible area | front porch <sync pulse> back porch
//     640      |     32      <    48    >     112
assign hsync = ~((hcount >= 672) && (hcount < 720));
assign vsync = ~((vcount >= 481) && (vcount < 484));
assign hblank = hcount > 639;
assign vblank = vcount > 479;


// convert vga coordinates to lcd coordinates (with borders)
wire [8:0] vgax = hcount < 640 ? hcount[9:1] : 9'd0; // 0 - 319
wire [8:0] vgay = vcount < 480 ? vcount[9:1] : 9'd0; // 0 - 239
wire [7:0] lcdx = vgax >= 80 && vgax < 240 ? vgax - 8'd80 : 8'd0; // 0-79(80)|80-239(160)|240-319(80)
wire [7:0] lcdy = vgay >= 40 && vgay < 200 ? vgay - 8'd40 : 8'd0; // 0-39(40)|40-199(160)|200-239(40)


// calcul vram address (TODO include xsize, ysize, xscroll[1:0] in calculation)
//assign addr = lcd_yscroll * 8'h30 + lcd_xscroll[7:2] + lcdy * 8'h30 + lcdx[7:2];
assign addr = lcdy * 8'h30 + lcdx[7:2];

assign ce_pxl = hcount[0] == 1;

// assign colors
wire [2:0] index = { lcdx[1:0], 1'b0 };

always @(posedge clk)
  if (ce && lcdx != 0 && lcdy != 0) begin
    if (ce_pxl) begin
		 case ({white,data[index+:2]})
			3'b000: { red, green, blue } <= 24'h87BA6B;//lightest colour
			3'b001: { red, green, blue } <= 24'h6BA378;//1/3rd darkness
			3'b010: { red, green, blue } <= 24'h386B82;//2/3rd darkness
			3'b011: { red, green, blue } <= 24'h384052;//dark as possible
			
			3'b100: { red, green, blue } <= 24'hFFFFFF;//white
			3'b101: { red, green, blue } <= 24'hC0C0C0;//light gray
			3'b110: { red, green, blue } <= 24'h808080;//gray
			3'b111: { red, green, blue } <= 24'h000000;//black
		 endcase
	 end
  end
  else
    { red, green, blue } <= 24'h0;

always @(posedge clk) begin
  hcount <= hcount + 10'd1;
  if (hcount == 10'd799) hcount <= 0;
end

always @(posedge clk)
  if (hcount == 10'd799)
    vcount <= vcount + 10'd1;
  else if (vcount == 10'd509)
    vcount <= 0;

endmodule 