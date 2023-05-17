
module decrypt_mcpu(
  input  [7:0] encryption,
  input  [7:0] data_in,
  input  [15:0] addr,
  output reg [7:0] data_out
);

always @* begin

  case (encryption)
    8'd0: data_out = data_in;
    8'd1: data_out = {
      addr[13] ? (~addr[2] ? ~data_in[0] : data_in[0]) : ~data_in[7],
      data_in[2],
      data_in[5],
      data_in[1],
      data_in[3],
      data_in[6],
      data_in[4],
      addr[13] ? (~addr[2] ? ~data_in[7] : data_in[7]) : ~data_in[0]
    };
    8'd2: data_out = {
      addr[13] ? (~addr[2] ? ~data_in[0] : data_in[0]) : ~data_in[7],
      data_in[2],
      data_in[5],
      data_in[1],
      data_in[3],
      data_in[6],
      data_in[4],
      addr[13] ? (~addr[2] ? ~data_in[7] : data_in[7]) : ~data_in[0]
    };
	 default;
  endcase

end

endmodule
