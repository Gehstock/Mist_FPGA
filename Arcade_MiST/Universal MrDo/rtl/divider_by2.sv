module divider_by2 ( 

output reg out_clk,
input clk,
input rst
);

always @(posedge clk)
begin
if (rst)
     out_clk <= 1'b0;
else
     out_clk <= ~out_clk;	
end

endmodule 