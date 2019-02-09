//============================================================================
//  gearshift
//
//  Turn gearup and geardown buttons into state that can flip the correct switches
//  for sprint
//
//
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//   
//============================================================================

module gearshift
(
	input CLK,
	
	input gearup,
	input geardown,
	
	output gear1,
	output gear2,
	output gear3
);

reg [2:0] gear=3'b0;

always @(posedge CLK) begin
  	reg old_gear_up;
	reg old_gear_down;
	
	if (gearup==1)
	begin
	   if (old_gear_up==0)
		begin
			old_gear_up=1;
			if (gear<4)
			begin
				gear=gear+1;
			end
		end
	end
	else
	begin
		old_gear_up=0;
	end
	if (geardown==1)
	begin
	   if (old_gear_down==0)
		begin
			old_gear_down=1;
			if (gear>0)
			begin
			gear=gear-1;
			end
		end
	end
	else
	begin
		old_gear_up=0;
	end

	
	casex(gear)
	3'b000: 
	begin
		gear1=0;
		gear2=1;
		gear3=1;
	end
	3'b001:
	begin
		gear1=1;
		gear2=0;
		gear3=1;

	end
	3'b010: 
	begin
		gear1=1;
		gear2=1;
		gear3=0;
	end
	3'b011:
	begin
		gear1=1;
		gear2=1;
		gear3=1;
	end
		endcase

end


endmodule