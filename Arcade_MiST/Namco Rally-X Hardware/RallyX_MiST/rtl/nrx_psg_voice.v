/**************************************************************
	FPGA New Rally-X (Sound Part)
***************************************************************/
module nrx_psg_voice
(
	input					clk,
	output	[3:0]		out,

	input		[19:0]	freq,
	input		[3:0]		vol,
	input		[2:0]		vn,

	output	[7:0]		waveaddr,
	input		[3:0]		wavedata
);

reg [19:0] counter = 20'h0;
reg  [7:0] outreg0;

assign waveaddr = { vn, counter[19:15] };
assign out = outreg0[7:4];

always @ ( posedge clk ) begin
	outreg0 = ( { 4'b0000, wavedata } * { 4'b0000, vol } );
	counter <= counter + freq;
end

endmodule 