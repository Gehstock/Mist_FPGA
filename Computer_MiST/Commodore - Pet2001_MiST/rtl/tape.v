//
// tape.v
//
// tape implementation for the PET2001 core for the MiST board
//
// Copyright (c) 2017 Sorgelig
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

module tape
(
	input      reset,
	input      clk,
	input      ce_1m,

	input      ioctl_download, 
	input      tape_pause,
	output reg tape_audio,
	output     tape_active,

	output reg        tape_rd,
	output reg [24:0] tape_addr,
	input       [7:0] tape_data
);

reg [23:0] cnt;

assign tape_active = (cnt>0);

always @(posedge clk) begin
	reg [23:0] size;
	//reg  [7:0] version;
	reg [23:0] tmp;
	reg [26:0] bit_cnt, bit_half;
	reg        ioctl_downloadD;
	reg  [2:0] reload32;
	reg        byte_ready;
	reg  [7:0] din;
	reg        play_pause;
	reg        pauseD;

	pauseD <= tape_pause;
	if(tape_pause && ~pauseD) play_pause <= !play_pause;

	if(reset || ioctl_download) begin
		cnt          <= 0;
		reload32     <= 0;
		byte_ready   <= 0;
		play_pause   <= 0;
		tape_rd      <= 0;
		size         <= 0;
		bit_cnt      <= 0;
		ioctl_downloadD <= ioctl_download;

	end else if(ce_1m) begin

		ioctl_downloadD <= ioctl_download;
		tape_rd <= 0;

		if(tape_rd) begin
			byte_ready <= 1;
			din <= tape_data;
		end

		// download complete, start parsing
		if(!ioctl_download && ioctl_downloadD) begin
			cnt       <= 8;
			tape_rd   <= 1;
			tape_addr <= 12;
		end

		if(cnt != 0) begin
			if(byte_ready) begin
				if(tape_addr<20) begin
					cnt        <= cnt - 1'd1;
					tape_addr  <= tape_addr + 1'd1;
					byte_ready <= 0;
					tape_rd    <= 1;
					case(tape_addr)
						//12: version     <= din;
						16: size[7:0]   <= din;
						17: size[15:8]  <= din;
						18: size[23:16] <= din;
						19: cnt         <= size ? size : 24'd0;
						default:;
					endcase
				end else begin
					if(bit_cnt <= 1) begin
						cnt        <= cnt - 1'd1;
						tape_addr  <= tape_addr + 1'd1;
						byte_ready <= 0;
						tape_rd    <= 1;
						if(reload32 != 0) begin
							tmp  <= {din, tmp[23:8]};
							reload32 <= reload32 - 1'd1;
							if(reload32 == 1) begin
								bit_cnt  <= {din, tmp[23:8], 3'd0};
								bit_half <= {din, tmp[23:8], 2'd0};
								tape_audio <= 1;
							end
						end else if(din == 0) begin
							reload32 <= 3;
						end else begin
							bit_cnt    <= {din, 3'd0};
							bit_half   <= {din, 2'd0};
							tape_audio <= 1;
						end
					end
				end
			end
			if(!play_pause && (bit_cnt>1)) begin
				bit_cnt <= bit_cnt - 1'd1;
				if(bit_cnt < bit_half) tape_audio <= 0;
			end
		end
	end
end

endmodule
