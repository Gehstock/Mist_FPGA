//===============================================================================
// FPGA DONKEY KONG WAVE SOUND
//
// Version : 4.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
// 2004- 9 -7  Added Gorilla roar sound. K.degawa
// 2005- 2 -9  removed Gorilla roar sound. K.degawa
//             It was optimized to become the smallest.
//================================================================================


module dkong_wav_sound(

O_ROM_AB,
I_ROM_DB,

I_CLK,
I_RSTn,
I_SW

);

output [18:0]O_ROM_AB;
input  [7:0]I_ROM_DB;

input  I_CLK,I_RSTn;
input  [2:0]I_SW; 

parameter Sample_cnt = 2228;

parameter Walk_cnt = 13'h07d0; // 10000 - 10FFF
parameter Jump_cnt = 13'h1e20; // 11000 - 12FFF
parameter Foot_cnt = 13'h1750; // 13000 - 14FFF

reg   [11:0]sample;
reg   sample_pls;

always@(posedge I_CLK or negedge I_RSTn)
begin
  if(! I_RSTn)begin
    sample <= 0;
    sample_pls <= 0;
  end else begin
    sample <= (sample == Sample_cnt - 1'b1) ? 0 : sample+1;
    sample_pls <= (sample == Sample_cnt - 1'b1)? 1 : 0 ;
  end
end

//-----------  WALK SOUND ------------------------------------------
reg    [1:0]sw0,sw1,sw2;
reg    [2:0]status0;
reg    [2:0]status1;
reg    [1:0]status2;
reg    [12:0]ad_cnt;
reg    [12:0]end_cnt;

always@(posedge I_CLK or negedge I_RSTn)
begin
  if(! I_RSTn)begin
    sw0 <= 0;
    sw1 <= 0;
    sw2 <= 0;
    status0 <= 0;
    status1 <= 0;
    status2 <= 1;
    end_cnt <= Foot_cnt;
    ad_cnt  <= 0;
  end else begin
    sw0[0] <= ~I_SW[2]; // Foot
    sw0[1] <= sw0[0];
    status0[0] <= ~sw0[1]&sw0[0];
    sw1[0] <= ~I_SW[0]; // Walk
    sw1[1] <= sw1[0];
    status0[1] <= ~sw1[1]&sw1[0];
    sw2[0] <= ~I_SW[1]; // Jump
    sw2[1] <= sw2[0];
    status0[2] <= ~sw2[1]&sw2[0];
    if(status0 > status1)begin
      ad_cnt <= 0;
  	 if(status0[2])begin
	   status1 <= 3'b111;
        status2 <= 2'b11;
        end_cnt <= Jump_cnt;
      end	else if(status0[1])begin
        status1 <= 3'b011;
        status2 <= 2'b10;
        end_cnt <= Walk_cnt;
      end	else begin
        status1 <= 3'b001;
        status2 <= 2'b01;
        end_cnt <= Foot_cnt;
      end
    end else begin
      if(sample_pls)begin
        if(ad_cnt >= end_cnt)begin
          status1 <= 3'b000;
          ad_cnt <= ad_cnt;
        end else begin
          ad_cnt <= ad_cnt+1 ;
        end
      end
    end
  end
end

reg   [15:0]wav_ad;
wire  [3:0]jump_offset = {3'b000,ad_cnt[12]} + 4'h1;
wire  [3:0]foot_offset = {3'b000,ad_cnt[12]} + 4'h3;

always@(posedge I_CLK)
begin
  case(status2)
    2'b01: wav_ad <= {foot_offset,ad_cnt[11:0]} ;
    2'b10: wav_ad <= {3'b000,ad_cnt} ;
    2'b11: wav_ad <= {jump_offset,ad_cnt[11:0]} ;
    default:;
  endcase
end

assign O_ROM_AB  = {3'b001,wav_ad};


endmodule
