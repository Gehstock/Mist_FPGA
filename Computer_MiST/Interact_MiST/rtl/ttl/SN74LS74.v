module SN74LS74(
	input			clrn1,	//01
	input			d1,		//02
	input			clk1,		//03
	input			prn1,		//04	
	output reg	q1,		//05
	output		qn1,		//06
	
	output		qn2,		//08
	output reg	q2,		//09
	input			prn2,		//10
	input			clk2,		//11
	input			d2,		//12
	input			clrn2		//13	
);



always@(posedge clk1 or negedge clrn1 or negedge prn1)
begin
if (!clrn1)
	begin
	q1 <= 0;
	end
else
if (!prn1)
	begin
	q1 <= 1;
	end
else
	begin
	q1 <= d1;
	end
end

assign	qn1 =  ~q1;

always@(posedge clk2 or negedge clrn2 or negedge prn2)
begin
if (!clrn2)
	begin
	q2 <= 0;
	end
else
if (!prn2)
	begin
	q2 <= 1;
	end
else
	begin
	q2 <= d2;
	end
end

assign	qn2 =  ~q2;

endmodule
