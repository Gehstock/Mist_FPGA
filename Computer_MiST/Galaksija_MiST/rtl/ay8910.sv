// ports are not identical to the actual AY chip - no need for that.
// Also the parallel ports are not very useful, so they are not connected




module ay8910(rst_n,clk,clk_en,asel,wr_n,cs_n,din,dout,A,B,C,audio);
    input rst_n;
    input clk;        // 28 MHz clock from the system
    input clk_en;    // 1.7 (?) clock to run the sound timing
    input asel;
    input wr_n;
    input cs_n;
    input [7:0] din;
    output [7:0] dout;
    output [7:0] A;
    output [7:0] B;
    output [7:0] C;
	 output [7:0] audio;




/////////////////////////////////////////////////////////////////////////////
// Write Register
/////////////////////////////////////////////////////////////////////////////


reg [3:0] addr;


// registers
reg [11:0] period_a,period_b,period_c;
reg [4:0] period_n;
reg [7:0] reg_en;
reg [4:0] vol_a,vol_b,vol_c;
reg [15:0] period_e;
reg [3:0] shape_e;
reg [7:0] pa_r,pb_r;


wire pb_od = reg_en[7];
wire pa_od = reg_en[6];
wire na  = reg_en[5];
wire nb  = reg_en[4];
wire nc  = reg_en[3];
wire ena = reg_en[2];
wire enb = reg_en[1];
wire enc = reg_en[0];


always @(posedge clk)
if(~rst_n) begin 
       vol_a          <= 0;
       vol_b          <= 0;
       vol_c          <= 0;
end else


if(~wr_n  && ~cs_n) begin
   if(asel)
    begin
      // address write
      addr <= din[3:0];
    end else begin
      // register write
      case(addr)
       0:period_a[ 7:0] <= din;
       1:period_a[11:8] <= din[3:0];
       2:period_b[ 7:0] <= din;
       3:period_b[11:8] <= din[3:0];
       4:period_c[ 7:0] <= din;
       5:period_c[11:8] <= din[3:0];
       6:period_n[ 4:0] <= din[4:0];
       7:reg_en         <= din;
       8:vol_a          <= din[4:0];
       9:vol_b          <= din[4:0];
      10:vol_c          <= din[4:0];
      11:period_e[7:0]  <= din;
      12:period_e[15:8] <= din;
      13:shape_e        <= din[3:0];
      14:pa_r        <= din;
      15:pb_r        <= din;
      endcase
    end
end


/////////////////////////////////////////////////////////////////////////////
// Read Register
/////////////////////////////////////////////////////////////////////////////
assign dout = addr==4'h0 ? period_a[7:0] :
            addr==4'h1 ? {4'h0,period_a[11:0]} :
            addr==4'h2 ? period_b[7:0] :
            addr==4'h3 ? {4'h0,period_b[11:0]} :
            addr==4'h4 ? period_c[7:0] :
            addr==4'h5 ? {4'h0,period_c[11:0]} :
            addr==4'h6 ? {3'h0,period_n} :
            addr==4'h7 ? reg_en :
            addr==4'h8 ? {3'h0,vol_a} :
            addr==4'h9 ? {3'h0,vol_b} :
            addr==4'ha ? {3'h0,vol_c} :
            addr==4'hb ? period_e[7:0] :
            addr==4'hc ? period_e[15:8] :
            addr==4'hd ? {4'h0,shape_e} : 8'hff;
            


/////////////////////////////////////////////////////////////////////////////
// PSG
/////////////////////////////////////////////////////////////////////////////


//
// toneA 12bit | 12bit
// toneB 12bit | 12bit
// toneC 12bit | 12bit
// env   15bit | 15bit
//
reg [2:0] pris;
reg [11:0] cnt_a,cnt_b,cnt_c;


reg out_a,out_b,out_c;


always @(posedge clk)
if(clk_en) begin
  pris <= pris + 1;
  if(pris==0)
  begin
    // tone generator
    cnt_a <= cnt_a + 1;
    if(cnt_a==period_a)
    begin
      out_a <= ~out_a;
      cnt_a <= 0;
    end
    cnt_b <= cnt_b + 1;
    if(cnt_b==period_b)
    begin
      out_b <= ~out_b;
      cnt_b <= 0;
    end
    cnt_c <= cnt_c + 1;
    if(cnt_c==period_c)
    begin
      out_c <= ~out_c;
      cnt_c <= 0;
    end
  end
end


/////////////////////////////////////////////////////////////////////////////
// envelope generator
/////////////////////////////////////////////////////////////////////////////
reg [15:0] env_cnt;
reg [3:0] env_phase;
reg env_start;
reg env_en;
reg env_inv;


// write eshape
wire env_clr = (addr==13) & ~cs_n & ~wr_n;


// bit3 = turn reset , 0=on , 1=off
// bit2 = start , 0=up , 1=down(inv)
// bit1 = turn invert, 0=tggle , 1=fix
// bit0 = turn repeat, 0=off, 1=on


wire next_no_reset  = shape_e[3];
wire start_no_inv   = shape_e[2];
wire next_toggle    = shape_e[1];
wire next_repeat    = shape_e[0];


// envelope volume output
wire [3:0] vol_e = env_phase ^ {4{env_inv}};


//
always @(posedge clk or posedge env_clr)
begin
  if(env_clr) env_start <= 1'b1;
  else  if(clk_en) env_start <= 1'b0;
end


always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    env_en    <= 1'b0;
  end else 
      if(clk_en)begin


    // start trigger
    if(env_start)
    begin
      env_cnt   <= 0;
      env_phase <= 0;
      env_inv   <= ~start_no_inv;
      env_en    <= 1'b1;
    end


    // count
    if(pris==0 && env_en)
    begin
      // phase up
      env_cnt <= env_cnt + 1;
      if(env_cnt==period_e)
      begin
        env_cnt <= 0;
        env_phase <= env_phase+1;
        // turn over
        if(env_phase==15)
        begin
          if(~next_no_reset)
          begin
           env_inv <= (env_inv ^ next_toggle) & next_no_reset;
           env_en  <= next_repeat & next_no_reset;
          end
        end
      end
    end
  end
end


/////////////////////////////////////////////////////////////////////////////
// noise generator
/////////////////////////////////////////////////////////////////////////////
reg [16:0] shift_n;
reg [4:0] cnt_n;


always @(posedge clk or negedge rst_n)
begin
  if(~rst_n)
  begin
    shift_n <= 17'b00000000000000001;
  end else if((pris==0) &&(clk_en))
  begin
    cnt_n <= cnt_n +1;
    if(cnt_n == period_n)
    begin
      cnt_n <= 0;
      shift_n <= {shift_n[0]^shift_n[3],shift_n[16:1]};
    end
  end
end


wire out_n = shift_n[0];


/////////////////////////////////////////////////////////////////////////////
// volume table 3db / step
/////////////////////////////////////////////////////////////////////////////
function [7:0] vol_tbl;
input [4:0] vol;
input [3:0] vole;
input out;
begin
  if(~out)
     vol_tbl = 0;
  else case(vol[4]?vole:vol[3:0])
  15:vol_tbl = 255;
  14:vol_tbl = 180;
  13:vol_tbl = 127;
  12:vol_tbl = 90;
  11:vol_tbl = 64;
  10:vol_tbl = 45;
   9:vol_tbl = 32;
   8:vol_tbl = 22;
   7:vol_tbl = 16;
   6:vol_tbl = 11;
   5:vol_tbl = 8;
   4:vol_tbl = 5;
   3:vol_tbl = 4;
   2:vol_tbl = 3;
   1:vol_tbl = 2;
   0:vol_tbl = 0; //1;
  endcase
end
endfunction


/////////////////////////////////////////////////////////////////////////////
// output
/////////////////////////////////////////////////////////////////////////////
assign A = vol_tbl(vol_a,vol_e,(out_a | ena) & (out_n | na) );
assign B = vol_tbl(vol_b,vol_e,(out_b | enb) & (out_n | nb) );
assign C = vol_tbl(vol_c,vol_e,(out_c | enc) & (out_n | nc) );
assign audio = {"00",A} + {"00",B} + {"00",C};//todo gehstock






endmodule 