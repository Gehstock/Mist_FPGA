//============================================================================
//  joy2quad
//
//  Take in digital joystick buttons, and try to estimate a quadrature encoder
//
// 
//  This makes an offset wave pattern for each keyboard stroke.  It might
//  be a good extension to change the size of the wave based on how long the joystick
//  is held down. 
//
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//   
//============================================================================
// digital joystick button to quadrature encoder

module joy2quad
(
	input CLK,
	input [31:0] clkdiv,
	
	input c_right,
	input c_left,
	output reg steerA,
	output reg steerB
);


reg [3:0] state = 0;

always @(posedge CLK) begin
 reg [31:0] count = 0;
 if (count >0)
  begin 
	count=count-1;
 end
 else
 begin
 count=clkdiv;
 casex(state)
	4'b0000: 
	  begin
	    {steerB,steerA} =2'b00;
		 if (c_left==1)
		 begin
			state=4'b0001;
		 end
		 if (c_right==1)
		 begin
			state=4'b0101;
		 end

		 end
	4'b0001: 
	  begin
	    {steerB,steerA}=2'b00;
		 state=4'b0010;
	  end
	4'b0010: 
	  begin
	    {steerB,steerA}=2'b01;
		 state=3'b0011;
	  end
	4'b0011: 
	  begin
	    {steerB,steerA}=2'b11;
		 state=4'b0100;
	  end
	4'b0100: 
	  begin
	    {steerB,steerA}=2'b10;
		 state=4'b000;
	  end
	4'b0101: 
	  begin
	    {steerB,steerA}=2'b00;
		 state=4'b0110;
	  end
	4'b0110: 
	  begin
	    {steerB,steerA}=2'b10;
		 state=4'b0111;
	  end
	4'b0111: 
	  begin
	    {steerB,steerA}=2'b11;
		 state=4'b1000;
	  end
	4'b1000: 
	  begin
	    {steerB,steerA}=2'b01;
		 state=4'b0000;
		 
	  end

 endcase
 end
end

endmodule 