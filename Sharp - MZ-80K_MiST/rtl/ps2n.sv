module ps2n(
	input  clk,
	input  reset,
	input  ps2_clk, 
	input  ps2_data,
	input  cs, 
	input  rd,
	input  [7:0] addr,
	output [7:0] data);
	
	reg [7:0]key_tbl0 = 8'b11111111,
				key_tbl1 = 8'b11111111,
				key_tbl2 = 8'b11111111,
				key_tbl3 = 8'b11111111,
				key_tbl4 = 8'b11111111,
				key_tbl5 = 8'b11111111,
				key_tbl6 = 8'b11111111,
				key_tbl7 = 8'b11111111,
				key_tbl8 = 8'b11111111,
				key_tbl9 = 8'b11111111,
				key_tbla = 8'b11111111,
				key_tblb = 8'b11111111,
				key_tblc = 8'b11111111,
				key_tbld = 8'b11111111,
				key_tble = 8'b11111111;
		
		
		
		
	always @(posedge clk ) begin
		if ( cs & rd ) begin
			begin
				case (addr[3:0])
					4'h0: data <= key_tbl0;
					4'h1: data <= key_tbl1;
					4'h2: data <= key_tbl2;
					4'h3: data <= key_tbl3;
					4'h4: data <= key_tbl4;
					4'h5: data <= key_tbl5;
					4'h6: data <= key_tbl6;
					4'h7: data <= key_tbl7;
					4'h8: data <= key_tbl8;
					4'h9: data <= key_tbl9;
					4'ha: data <= key_tbla;
					4'hb: data <= key_tblb;
					4'hc: data <= key_tblc;
					4'hd: data <= key_tbld;
					4'he: data <= key_tble;
					default: data <= 8'hzz;
				endcase
			end
		end
	end
	
	always @(posedge clk ) begin	
		key_tbl0 <= 8'b11111111;
		key_tbl1 <= 8'b11111111;
		key_tbl2 <= 8'b11111111;
		key_tbl3 <= 8'b11111111;
		key_tbl4 <= 8'b11111111;
		key_tbl5 <= 8'b11111111;
		key_tbl6 <= 8'b11111111;
		key_tbl7 <= 8'b11111111;
		key_tbl8 <= 8'b11111111;
		key_tbl9 <= 8'b11111111;
		case ( kdata )
			8'h1C: begin key_tbl4[0] = 1'b0; end//A
			8'h32: begin key_tbl6[2] = 1'b0; end//B
			default: begin  end
		endcase
	end	
	
	wire  dten;
	wire [7:0] kdata;
	ps2_recieve ps2_recieve1(
		.clk(clk), 
		.reset(reset),
		.ps2_clk(ps2_clk), 
		.ps2_data(ps2_data),
		.dten(dten), 
		.kdata(kdata)
		);	
	
	
	
	
	
	
	
	
	
	
endmodule 	