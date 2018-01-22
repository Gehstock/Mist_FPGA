

module keyboard
(
	input  clk,
	input  reset,
	input  ps2_kbd_clk,
	input  ps2_kbd_data,

	output reg[7:0] joystick
);

reg        pressed;
reg        e0;
wire [7:0] keyb_data;
wire       keyb_valid;

// PS/2 interface
ps2_intf ps2(
	clk,
	!reset,
		
	ps2_kbd_clk,
	ps2_kbd_data,

	// Byte-wide data interface - only valid for one clock
	// so must be latched externally if required
	keyb_data,
	keyb_valid
);




always @(posedge reset or posedge clk) begin
	
	if(reset) begin
		pressed <= 1'b0;
		e0 <= 1'b0;

		joystick <= 8'd0;
	end else begin
		if (keyb_valid) begin
			if (keyb_data == 8'HE0)
				e0 <=1'b1;
			else if (keyb_data == 8'HF0)
				pressed <= 1'b0;
			else begin
				case({e0, keyb_data})
					9'H016: joystick[1] <= pressed; // 1
					9'H01E: joystick[2] <= pressed; // 2

					9'H175: joystick[4] <= pressed; // arrow up
					9'H172: joystick[5] <= pressed; // arrow down
					9'H16B: joystick[6] <= pressed; // arrow left
					9'H174: joystick[7] <= pressed; // arrow right
					
					9'H029: joystick[0] <= pressed; // Space
// 			   9'H011: joystick[1] <= pressed; // Left Alt
//					9'H00d: joystick[2] <= pressed; // Tab
					9'H076: joystick[3] <= pressed; // Escape

				endcase;

				pressed <= 1'b1;
				e0 <= 1'b0;
         end 
      end 
   end 
end	

endmodule
