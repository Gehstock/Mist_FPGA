module SN74LS73(
	input			clk1,		//01
	input			clrn1,	//02
	input			k1,		//03
	
	input			clk2,		//05
	input			clrn2,	//06
	input			j2,		//07
	output 		qn2,		//08
	output reg	q2,		//09
	input			k2,		//10
	
	output reg	q1,		//12
	output 		qn1,		//13
	input			j1			//14
);

always@(posedge clk1 or negedge clrn1)
begin
if (!clrn1)
	begin
	q1 <= 0;
	end
else
	begin
	q1 <= ~q1 & j1 | q1 & ~k1;
	end
end

assign	qn1 =  ~q1;

always@(posedge clk2 or negedge clrn2)
begin
if (!clrn2)
	begin
	q2 <= 0;
	end
else
	begin
	q2 <= ~q2 & j2 | q2 & ~k2;
	end
end

assign	qn2 =  ~q2;

endmodule
