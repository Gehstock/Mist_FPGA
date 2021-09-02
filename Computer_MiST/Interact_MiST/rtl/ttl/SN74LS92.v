module SN74LS92(
	input			clkb,		//01
	input			clra,		//06
	input			clrb,		//07
	output reg	qd,		//08
	output reg	qc,		//09
	output reg	qa,		//12
	output reg	qb,		//13
	input			clka		//14
);

wire	reset;
assign	reset = clra & clrb;

always@(negedge clka or posedge reset)
begin
if (reset)
	begin
	qa <= 0;
	end
else
	begin
	qa <= ~qa;
	end
end

always@(negedge clkb or posedge reset)
begin
if (reset)
	begin
	qb <= 0;
	end
else
	begin
	qb <= ~(qb | qc);
	end
end

always@(negedge clkb or posedge reset)
begin
if (reset)
	begin
	qc <= 0;
	end
else
	begin
	qc <= qb;
	end
end

always@(negedge clkb or posedge reset)
begin
if (reset)
	begin
	qd <= 0;
	end
else
	begin
	qd <= qd ^ qc;
	end
end

endmodule
