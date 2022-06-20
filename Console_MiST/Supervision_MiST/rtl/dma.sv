module dma
(
	input clk,
	input ce,
	input reset,
	input [5:0] AB,
	input cpu_rwn,
	input dma_cs,
	input lcd_en,
	input [7:0] data_in,
	output reg [15:0] cbus_addr,
	output reg [12:0] vbus_addr,
	output reg dma_dir,
	output dma_en
);

	reg dma_started;
	reg [7:0] dma_length;
	reg [3:0] dma_phase;
	reg [2:0] lcd_div;

	assign dma_en = dma_started;
	wire lcd_ce = lcd_div == 5 && lcd_en;

	always_ff @(posedge clk) begin
		if (ce) begin
			lcd_div <= lcd_div + 1'd1;
			if (lcd_div == 5)
				lcd_div <= 0;

			if (dma_started && ~lcd_ce) begin
				cbus_addr <= cbus_addr + 1'd1;
				vbus_addr <= vbus_addr + 1'd1;
				dma_phase <= dma_phase - 1'd1;
				if (~|dma_phase) begin
					dma_length <= dma_length - 1'd1;
					if (dma_length == 1) begin
						dma_started <= 0;
					end
				end
			end

			if (~cpu_rwn && dma_cs) begin
				case(AB)
					6'h08: cbus_addr[7:0] <= data_in;
					6'h09: cbus_addr[15:8] <= data_in;
					6'h0A: vbus_addr[7:0] <= data_in;
					6'h0B: {dma_dir, vbus_addr[12:8]} <= {data_in[6], data_in[4:0]};
					6'h0C: dma_length <= data_in;
					6'h0D: if (data_in[7]) begin dma_started <= 1; dma_phase <= 4'd15; end
				endcase
			end
		end
		if (reset) begin
			dma_started <= 0;
			dma_length <= 0;
			vbus_addr <= 0;
			cbus_addr <= 0;
			lcd_div <= 0;
			dma_dir <= 0;
		end
	end
endmodule