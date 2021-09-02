// based on TI SN74LS195 datasheet
module SN74LS195(
	input			clrn,		//01
	input			j,			//02
	input			kn,		//03
	input			a,			//04
	input			b,			//05
	input			c,			//06
	input			d,			//07
	
	input			sh_ldn,	//09
	input			clk,		//10
	output		qdn,		//11
	output reg	qd,		//12
	output reg	qc,		//13
	output reg	qb,		//14
	output reg	qa			//15	
);

always@(posedge clk or negedge clrn)
begin
if (!clrn)
	begin
	qa <= 0;
	end
else
	begin
	qa <= (~qa & j & sh_ldn) | (sh_ldn & kn & qa) | (~sh_ldn & a);
	end
end


always@(posedge clk or negedge clrn)
begin
if (!clrn)
	begin
	qb <= 0;
	end
else
	begin
	qb <= (qa & sh_ldn) | (~sh_ldn & b);
	end
end


always@(posedge clk or negedge clrn)
begin
if (!clrn)
	begin
	qc <= 0;
	end
else
	begin
	qc <= (qb & sh_ldn) | (~sh_ldn & c);
	end
end


always@(posedge clk or negedge clrn)
begin
if (!clrn)
	begin
	qd <= 0;
	end
else
	begin
	qd <= (qc & sh_ldn) | (~sh_ldn & d);
	end
end

assign	qdn =  ~qd;

endmodule
