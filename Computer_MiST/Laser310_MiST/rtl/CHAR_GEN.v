module CHAR_GEN(
	// control
	reset,

	char_code,
	subchar_line,
	subchar_pixel,

	pixel_clock,
	pixel_on
);

input			pixel_clock;
input			reset;

input	[7:0]	char_code;
input	[4:0]	subchar_line;			// line number within 12 line block
input	[3:0]	subchar_pixel;			// pixel position within 8 pixel block

output			pixel_on;

reg		[7:0]	latched_data;
reg				pixel_on;

wire	[11:0]	rom_addr = {char_code[7:0], subchar_line[4:1]};
wire	[7:0]	rom_data;
 

// instantiate the character generator ROM
//CHAR_GEN_ROM CHAR_GEN_ROM
//(
//	pixel_clock,
//	rom_addr,
//	rom_data
//);

sprom #(
	.init_file("./roms/charrom_4k.mif"),
	.widthad_a(12),
	.width_a(8))
CHAR_GEN_ROM(
	.address(rom_addr),
	.clock(pixel_clock),
	.q(rom_data)
	);


// serialize the CHARACTER MODE data
always @ (posedge pixel_clock or posedge reset) begin
	if (reset)
 		begin
			pixel_on = 1'b0;
			latched_data  = 8'h00;
		end

	else begin
		case(subchar_pixel)
			4'b0101:
				latched_data [7:0] = {rom_data[0],rom_data[1],rom_data[2],rom_data[3],rom_data[4],rom_data[5],rom_data[6],rom_data[7]};
			default:
			if(subchar_pixel[0]==1'b0)
				{pixel_on,latched_data [7:1]} <= latched_data [7:0];
		endcase
		end

	end

endmodule //CHAR_GEN
