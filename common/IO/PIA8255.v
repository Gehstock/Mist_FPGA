/****************************************************************************
	PIA 8255

	Version 050111

	Copyright(C) 2004,2005 Tatsuyuki Satoh

	This software is provided "AS IS", with NO WARRANTY.
	NON-COMMERCIAL USE ONLY

	Histry:
		2005. 1.11 Ver.0.1

	Note:

	Distributing all and a part is prohibited. 
	Because this version is developer-alpha version.

	mode 0,1,2 handshake is not supported , mode 3 bit I/O only
****************************************************************************/
module PIA8255(
  I_RESET,
  I_A,
  I_CS,
  I_RD,
  I_WR,
  I_D,
  O_D,
//
  I_PA,O_PA,
//
  I_PB,O_PB,
//
  I_PC,O_PC
);
input I_RESET;
input [1:0] I_A;
input I_CS;
input I_WR;
input I_RD;
input [7:0] I_D;
output [7:0] O_D;

input [7:0]  I_PA,I_PB,I_PC;
output [7:0] O_PA,O_PB,O_PC;

////////////////////////////////////////////////////////////////////////////
reg [7:0] pa_o,pb_o,pc_o;
reg pa_dir , pb_dir , pcl_dir , pch_dir;
reg [1:0] pa_mode;
reg pb_mode;

// wirte data
always @(negedge I_WR or posedge I_RESET)
begin
  if(I_RESET) begin
    pa_o <= 8'h00;
    pb_o <= 8'h00;
    pc_o <= 8'h00;
    pa_mode <= 2'b00;
    pa_dir  <= 1'b1;
    pcl_dir <= 1'b1;
    pb_mode <= 1'b0;
    pb_dir  <= 1'b1;
    pch_dir <= 1'b1;
  end else if(I_CS) begin
    case(I_A)
    2'b00:pa_o <= I_D;
    2'b01:pb_o <= I_D;
    2'b10:pc_o <= I_D;
    2'b11:begin
          if(I_D[7])
          begin
            // mode set
            pa_mode <= I_D[6:5];
            pa_dir  <= I_D[4];
            pch_dir <= I_D[3];
            pb_mode <= I_D[2];
            pb_dir  <= I_D[1];
            pcl_dir <= I_D[0];
          end else begin
            // bit operation
            pc_o[I_D[3:1]] <= I_D[0];
          end
      end
    endcase
  end
end

// read data
//wire read_gate = I_CS & I_RD;
wire [7:0] pa_r = pa_dir ? I_PA : pa_o;
wire [7:0] pb_r = pb_dir ? I_PB : pb_o;
wire [7:0] pc_r = { pch_dir ? I_PC[7:4] : pc_o[7:4] , pcl_dir ? I_PC[3:0] : pc_o[3:0] };
wire [7:0] ct_r = {1'b0,pa_mode,pa_dir,pcl_dir,pb_mode,pb_dir,pch_dir};

assign O_D = (I_A==2'b00) ? pa_r  :
             (I_A==2'b01) ? pb_r  :
             (I_A==2'b10) ? pc_r  :
                            ct_r;

// port output
assign O_PA = pa_o;
assign O_PB = pb_o;
assign O_PC = pc_o;

endmodule
