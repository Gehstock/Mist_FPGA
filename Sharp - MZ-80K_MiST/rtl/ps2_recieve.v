module ps2_recieve(
	input   clk,
	input   reset,
	input   ps2_clk, 
	input   ps2_data,
	output  dten,
	output [7:0] kdata);

	reg  [10:0] key_data;
	reg  [3:0]  clk_data;

	always @(posedge clk or posedge reset) begin
		if( reset ) begin
			key_data <= 11'b11111111111;
			dten <= 1'b0;
		end else begin
			clk_data <= {clk_data[2:0], ps2_clk};
			if ( clk_data == 4'b0011 )
				key_data <= {ps2_data, key_data[10:1]};
			if ( !key_data[0] & key_data[10] ) begin
				dten <= 1'b1;
				kdata <= key_data[8:1];
				key_data <= 11'b11111111111;
			end else
				dten <= 1'b0;
		end

	end

endmodule




module keyboard (
  input clock,
  input ps2_data,
  input ps2_clk,
  output reg [7:0] led_g
);


parameter idle    = 2'b01;
parameter receive = 2'b10;
parameter ready   = 2'b11;


reg [1:0]  state=idle;
reg [15:0] rxtimeout=16'b0000000000000000;
reg [10:0] rxregister=11'b11111111111;
reg [1:0]  datasr=2'b11;
reg [1:0]  clksr=2'b11;
reg [7:0]  rxdata;


reg datafetched;
reg rxactive;
reg dataready;


always @(posedge clock ) 
begin 
  if(datafetched==1)
    led_g <=rxdata;
end  
  
always @(posedge clock ) 
begin 
  rxtimeout<=rxtimeout+1;
  datasr <= {datasr[0],ps2_data};
  clksr  <= {clksr[0],ps2_clk};


  if(clksr==2'b10)
    rxregister<= {datasr[1],rxregister[10:1]};


  case (state) 
    idle: 
    begin
      rxregister <=11'b11111111111;
      rxactive   <=0;
      dataready  <=0;
      rxtimeout  <=16'b0000000000000000;
      if(datasr[1]==0 && clksr[1]==1)
      begin
        state<=receive;
        rxactive<=1;
      end   
    end
    
    receive:
    begin
      if(rxtimeout==50000)
        state<=idle;
      else if(rxregister[0]==0)
      begin
        dataready<=1;
        rxdata<=rxregister[8:1];
        state<=ready;
        datafetched<=1;
      end
    end
    
    ready: 
    begin
      if(datafetched==1)
      begin
        state     <=idle;
        dataready <=0;
        rxactive  <=0;
      end  
    end  
  endcase
end 
endmodule
