module sample_rom(
    input clk,
    input reset,

    input [7:0] sample_addr_in,
    input [1:0] sample_addr_wr,

    output reg [7:0] sample_data,
    input sample_inc,

    // ioctl
    output reg [24:0] sample_rom_addr,
    input  [63:0] sample_rom_dout,
    output reg sample_rom_req = 0,
    input sample_rom_ack
);

reg [17:0] sample_addr = 0;

always_ff @(posedge clk) begin
    if (sample_inc) begin
        sample_addr <= sample_addr + 18'd1;
        sample_rom_addr <= {REGION_SAMPLES.base_addr[24:18], sample_addr[17:0]};
        if(sample_addr[17:3] != sample_rom_addr[17:3])
            sample_rom_req <= ~sample_rom_req;
    end

    if (sample_addr_wr[0]) sample_addr[12:0] <= {sample_addr_in, 5'd0};
    if (sample_addr_wr[1]) begin
        sample_addr[17:13] <= sample_addr_in[4:0];
        sample_rom_addr <= {REGION_SAMPLES.base_addr[24:18], sample_addr_in[4:0], sample_addr[12:0]};
        sample_rom_req <= ~sample_rom_req;
    end
end

always @(*) begin
    case(sample_rom_addr[2:0])
        3'd0: sample_data = sample_rom_dout[ 7: 0];
        3'd1: sample_data = sample_rom_dout[15: 8];
        3'd2: sample_data = sample_rom_dout[23:16];
        3'd3: sample_data = sample_rom_dout[31:24];
        3'd4: sample_data = sample_rom_dout[39:32];
        3'd5: sample_data = sample_rom_dout[47:40];
        3'd6: sample_data = sample_rom_dout[55:48];
        default: sample_data = sample_rom_dout[63:56];
    endcase;
end

endmodule
