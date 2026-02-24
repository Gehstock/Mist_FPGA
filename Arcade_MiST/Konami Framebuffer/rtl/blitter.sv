module blitter (
    input  wire        clk,
    input  wire        rst,
    input  wire        clk_1M5_en,
    input  wire        blitter_cs,
    input  wire [1:0]  cpu_a,
    input  wire [7:0]  cpu_d_o,
    input  wire        cpu_rw,
    input  wire        cpu_ba,
    input  wire        cpu_bs,
    input  wire        vram_cs,
    input  wire        blitter_copy,
    input  wire [7:0]  blitter_d_o,  // VRAM data output
    output reg         cpu_halt,
    output wire [15:0] vram_a,
    output wire [7:0]  vram_d_i,
    output wire [1:0]  vram_wr
);

    // Blitter Registers
    reg [15:0] blitter_src_r;
    reg [15:0] blitter_dst_r;
    reg        blitter_go;
    
    // Internal SM signals
    reg        blitting;
    reg [1:0]  blitter_wr;
    reg [15:0] blitter_src;
    reg [15:0] blitter_dst;
    reg [3:0]  blitter_d_i;
    
    integer x, y;

    // State Encoding
    localparam S_IDLE    = 3'd0,
               S_HALTING = 3'd1,
               S_BLIT_0  = 3'd2,
               S_BLIT    = 3'd3,
               S_INC_0   = 3'd4,
               S_INC     = 3'd5;
    reg [2:0] state;

    // Blitter Register Process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            blitter_src_r <= 16'h0;
            blitter_dst_r <= 16'h0;
            blitter_go    <= 1'b0;
        end else begin
            blitter_go <= 1'b0; // Pulse default
            if (clk_1M5_en) begin
                if (blitter_cs && !cpu_rw) begin
                    case (cpu_a[1:0])
                        2'b00: blitter_dst_r[15:8] <= cpu_d_o;
                        2'b01: blitter_dst_r[7:0]  <= cpu_d_o;
                        2'b10: blitter_src_r[15:8] <= cpu_d_o;
                        2'b11: begin
                            blitter_src_r[7:0] <= cpu_d_o;
                            blitter_go <= 1'b1;
                        end
                    endcase
                end
            end
        end
    end

    // Blitter State Machine Process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cpu_halt   <= 1'b0;
            blitting   <= 1'b0;
            blitter_wr <= 2'b00;
            state      <= S_IDLE;
            x <= 0; y <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    blitting <= 1'b0;
                    if (blitter_go) begin
                        cpu_halt <= 1'b1;
                        state    <= S_HALTING;
                    end
                end

                S_HALTING: begin
                    if (cpu_ba && cpu_bs) begin
                        blitting    <= 1'b1;
                        blitter_src <= {blitter_src_r[15:2], 2'b00} + 16'd1;
                        blitter_dst <= blitter_dst_r;
                        y <= 0;
                        x <= 0;
                        state <= S_BLIT_0;
                    end
                end

                S_BLIT_0: begin
                    blitter_d_i <= blitter_src[0] ? blitter_d_o[7:4] : blitter_d_o[3:0];
                    state <= S_BLIT;
                end

                S_BLIT: begin
                    if (blitter_d_i != 4'h0) begin
                        if (blitter_dst[0]) blitter_wr[1] <= 1'b1;
                        else                blitter_wr[0] <= 1'b1;
                    end
                    state <= S_INC_0;
                end

                S_INC_0: begin
                    blitter_wr <= 2'b00;
                    state      <= S_INC;
                end

                S_INC: begin
                    blitter_src <= blitter_src + 1'b1;
                    blitter_wr  <= 2'b00;
                    if (x == 15) begin
                        if (y == 15) begin
                            cpu_halt <= 1'b0;
                            state    <= S_IDLE;
                        end else begin
                            x <= 0;
                            y <= y + 1;
                            blitter_dst <= blitter_dst + 16'd241;
                            state <= S_BLIT_0;
                        end
                    end else begin
                        x <= x + 1;
                        blitter_dst <= blitter_dst + 16'd1;
                        state <= S_BLIT_0;
                    end
                end

                default: begin
                    cpu_halt <= 1'b0;
                    state    <= S_IDLE;
                end
            endcase
        end
    end

    // Video RAM Data Muxing
    assign vram_a = (!blitting) ? cpu_a : blitter_dst[16:1];
    
    assign vram_d_i = (!blitting) ? cpu_d_o : 
                      (!blitter_copy) ? 8'h00 : {blitter_d_i, blitter_d_i};
                      
    assign vram_wr = (!blitting) ? {2{(vram_cs && clk_1M5_en && !cpu_rw)}} : blitter_wr;

endmodule
