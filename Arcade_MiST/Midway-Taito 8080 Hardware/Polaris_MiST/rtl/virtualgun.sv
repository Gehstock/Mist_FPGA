
module virtualgun
(
	input        CLK,
	input        HDE,VDE,
	input        CE_PIX,
	output [9:0] H_COUNT,
	output [8:0] V_COUNT
);

always @(posedge CLK) begin
	reg old_pix, old_hde, old_vde, old_ms;
	reg [9:0] hcnt;
	reg [8:0] vcnt;
	reg [8:0] vtotal;
	reg [15:0] hde_d;

	reg sensor_pend;
	reg [7:0] sensor_time;
	reg reload_pressed;
	reg [2:0] reload_pend;
	reg [2:0] reload;

	if(CE_PIX) begin
		hde_d <= {hde_d[14:0],HDE};
		old_hde <= hde_d[15];
		if(~&hcnt) hcnt <= hcnt + 1'd1;
		if(~old_hde & ~HDE) hcnt <= 0;
		if(old_hde & ~hde_d[15]) begin
			if(~VDE) begin
				vcnt <= 0;
				if(vcnt) vtotal <= vcnt - 1'd1;
			end
			else if(~&vcnt) vcnt <= vcnt + 1'd1;
		end
		
		
	H_COUNT <= hcnt;
	V_COUNT <= vcnt;
end

end

endmodule 