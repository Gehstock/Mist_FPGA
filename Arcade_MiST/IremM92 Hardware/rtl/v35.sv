module v35(
    input clk,
    input ce, // 4x internal clock
    input ce_cycle, // real internal clock

    input reset,

    output mem_rd,
    output mem_wr,
    output [1:0] mem_be,
    output [19:0] mem_addr,
    output [15:0] mem_dout,
    input [15:0] mem_din,

    input intp0,
    input intp1,
    input intp2,

    input secure,

    input secure_wr,
    input [7:0] secure_addr,
    input [7:0] secure_data
);

wire rd, wr;
wire prefetching;
wire [1:0] be;
wire [19:0] addr;
wire [15:0] dout, din;

reg [2:0] irq_pending = 0;
reg [7:0] irq_vec;
wire irq_ack;
wire irq_fini;

reg [15:0] TM0, MD0, TM1, MD1, WTC;
reg [7:0] P0, PM0, PMC0, P1, PM1, PMC1, P2, PM2;
reg [7:0] PMC2, PT, PMT, INTM, EMS0, EMS1, EMS2, EXIC0;
reg [7:0] EXIC1, EXIC2, ISPR, RXB0, TXB0, SRMS0, STMS0, SCM0;
reg [7:0] SCC0, BRG0, SCE0, SEIC0, SRIC0, STIC0, RXB1, TXB1;
reg [7:0] SRMS1, STMS1, SCM1, SCC1, BRG1, SCE1, SEIC1, SRIC1;
reg [7:0] STIC1, TMC0, TMC1, TMMS0, TMMS1, TMMS2, TMIC0, TMIC1;
reg [7:0] TMIC2, DMAC0, DMAM0, DMAC1, DMAM1, DIC0, DIC1, STBC;
reg [7:0] RFM, FLAG, PRC, TBIC, IDB;

wire RAMEN = PRC[6];
wire [1:0] TB = PRC[3:2];
wire [1:0] PCK = PRC[1:0];
wire ESNMI = INTM[0];
wire ES0 = INTM[2];
wire ES1 = INTM[4];
wire ES2 = INTM[6];


reg [7:0] exi_prio_bit;

reg [15:0] internal_din;
reg [7:0] iram[256];
reg [1:0] wait_cycles = 0;

reg intp0_prev, intp1_prev, intp2_prev;

wire internal_rq = ~prefetching && ( addr[19:9] == { IDB, 3'b111 } || addr[19:0] == 20'hfffff );
wire internal_ram_rq = RAMEN & internal_rq & ~addr[8];
wire sfr_area_rq = internal_rq & addr[8];

reg internal_rq_latch;

assign mem_rd = rd & ~internal_rq;
assign mem_wr = wr & ~internal_rq;
assign mem_be = be;
assign mem_addr = addr;
assign mem_dout = dout;
assign din = internal_rq_latch ? internal_din : mem_din;

always_ff @(posedge clk) begin
    if (reset) begin
        PM0 <= 8'hff;
        PMC0 <= 8'h00;
        PM1 <= 8'hff;
        PMC1 <= 8'h00;
        PM2 <= 8'hff;
        PMC2 <= 8'h00;
        PMT <= 8'h00;
        INTM <= 8'h00;
        EXIC0 <= 8'h47;
        EXIC1 <= 8'h47;
        EXIC2 <= 8'h47;
        ISPR <= 8'h00;
        SCM0 <= 8'h00;
        SCC0 <= 8'h00;
        BRG0 <= 8'h00;
        SCE0 <= 8'h00;
        SEIC0 <= 8'h47;
        SRIC0 <= 8'h47;
        STIC0 <= 8'h47;
        SCM1 <= 8'h00;
        SCC1 <= 8'h00;
        BRG1 <= 8'h00;
        SCE1 <= 8'h00;
        SEIC1 <= 8'h47;
        SRIC1 <= 8'h47;
        STIC1 <= 8'h47;
        TMC0 <= 8'h00;
        TMC1 <= 8'h00;
        TMIC0 <= 8'h47;
        TMIC1 <= 8'h47;
        TMIC2 <= 8'h47;
        DMAM0 <= 8'h00;
        DMAM1 <= 8'h00;
        DIC0 <= 8'h47;
        DIC1 <= 8'h47;
        STBC <= 8'h00;
        RFM <= 8'hfc;
        WTC <= 16'hffff;
        FLAG <= 8'h00;
        PRC <= 8'h4e;
        TBIC <= 8'h47;
        IDB <= 8'hff;

        irq_pending <= 0;
        wait_cycles <= 2'd0;
    end else begin
        if (sfr_area_rq) begin
            if (wr) begin
                case(addr[7:0])
                8'h00: P0 <= dout[7:0];
                8'h01: PM0 <= dout[7:0];
                8'h02: PMC0 <= dout[7:0];
                8'h08: P1 <= dout[7:0];
                8'h09: PM1 <= dout[7:0];
                8'h0a: PMC1 <= dout[7:0];
                8'h10: P2 <= dout[7:0];
                8'h11: PM2 <= dout[7:0];
                8'h12: PMC2 <= dout[7:0];
                8'h3b: PMT <= dout[7:0];
                8'h40: INTM <= dout[7:0];
                8'h44: EMS0 <= dout[7:0];
                8'h45: EMS1 <= dout[7:0];
                8'h46: EMS2 <= dout[7:0];
                8'h4c: EXIC0 <= dout[7:0];
                8'h4d: EXIC1 <= dout[7:0];
                8'h4e: EXIC2 <= dout[7:0];
                8'h62: TXB0 <= dout[7:0];
                8'h65: SRMS0 <= dout[7:0];
                8'h66: STMS0 <= dout[7:0];
                8'h68: SCM0 <= dout[7:0];
                8'h69: SCC0 <= dout[7:0];
                8'h6a: BRG0 <= dout[7:0];
                8'h6c: SEIC0 <= dout[7:0];
                8'h6d: SRIC0 <= dout[7:0];
                8'h6e: STIC0 <= dout[7:0];
                8'h72: TXB1 <= dout[7:0];
                8'h75: SRMS1 <= dout[7:0];
                8'h76: STMS1 <= dout[7:0];
                8'h78: SCM1 <= dout[7:0];
                8'h79: SCC1 <= dout[7:0];
                8'h7a: BRG1 <= dout[7:0];
                8'h7c: SEIC1 <= dout[7:0];
                8'h7d: SRIC1 <= dout[7:0];
                8'h7e: STIC1 <= dout[7:0];
                8'h80: begin
                    if (be[0]) TM0[7:0] <= dout[7:0];
                     if (be[1]) TM0[15:8] <= dout[15:8];
                end
                8'h81: TM0[15:8] <= dout[7:0];
                8'h82: begin
                    if (be[0]) MD0[7:0] <= dout[7:0];
                    if (be[1]) MD0[15:8] <= dout[15:8];
                end
                8'h83: MD0[15:8] <= dout[7:0];
                8'h88: begin
                    if (be[0]) TM1[7:0] <= dout[7:0];
                    if (be[1]) TM1[15:8] <= dout[15:8];
                end
                8'h89: TM1[15:8] <= dout[7:0];
                8'h8a: begin
                    if (be[0]) MD1[7:0] <= dout[7:0];
                    if (be[1]) MD1[15:8] <= dout[15:8];
                end
                8'h8b: MD1[15:8] <= dout[7:0];
                8'h90: TMC0 <= dout[7:0];
                8'h91: TMC1 <= dout[7:0];
                8'h94: TMMS0 <= dout[7:0];
                8'h95: TMMS1 <= dout[7:0];
                8'h96: TMMS2 <= dout[7:0];
                8'h9c: TMIC0 <= dout[7:0];
                8'h9d: TMIC1 <= dout[7:0];
                8'h9e: TMIC2 <= dout[7:0];
                8'ha0: DMAC0 <= dout[7:0];
                8'ha1: DMAM0 <= dout[7:0];
                8'ha2: DMAC1 <= dout[7:0];
                8'ha3: DMAM1 <= dout[7:0];
                8'hac: DIC0 <= dout[7:0];
                8'had: DIC1 <= dout[7:0];
                8'he0: STBC <= dout[7:0];
                8'he1: RFM <= dout[7:0];
                8'he8: begin
                    if (be[0]) WTC[7:0] <= dout[7:0];
                    if (be[1]) WTC[15:8] <= dout[15:8];
                end
                8'he9: WTC[15:8] <= dout[7:0];
                8'hea: FLAG <= dout[7:0];
                8'heb: PRC <= dout[7:0];
                8'hec: TBIC <= dout[7:0];
                8'hff: IDB <= dout[7:0];
                endcase
            end else if (rd) begin
                case(addr[7:0])
                8'h00: internal_din <= { 8'd0, P0 };
                8'h08: internal_din <= { 8'd0, P1 };
                8'h10: internal_din <= { 8'd0, P2 };
                8'h38: internal_din <= { 8'd0, PT };
                8'h3b: internal_din <= { 8'd0, PMT };
                8'h40: internal_din <= { 8'd0, INTM };
                8'h44: internal_din <= { 8'd0, EMS0 };
                8'h45: internal_din <= { 8'd0, EMS1 };
                8'h46: internal_din <= { 8'd0, EMS2 };
                8'h4c: internal_din <= { 8'd0, EXIC0 };
                8'h4d: internal_din <= { 8'd0, EXIC1 };
                8'h4e: internal_din <= { 8'd0, EXIC2 };
                8'hfc: internal_din <= { 8'd0, ISPR };
                8'h60: internal_din <= { 8'd0, RXB0 };
                8'h65: internal_din <= { 8'd0, SRMS0 };
                8'h66: internal_din <= { 8'd0, STMS0 };
                8'h68: internal_din <= { 8'd0, SCM0 };
                8'h69: internal_din <= { 8'd0, SCC0 };
                8'h6a: internal_din <= { 8'd0, BRG0 };
                8'h6b: internal_din <= { 8'd0, SCE0 };
                8'h6c: internal_din <= { 8'd0, SEIC0 };
                8'h6d: internal_din <= { 8'd0, SRIC0 };
                8'h6e: internal_din <= { 8'd0, STIC0 };
                8'h70: internal_din <= { 8'd0, RXB1 };
                8'h75: internal_din <= { 8'd0, SRMS1 };
                8'h76: internal_din <= { 8'd0, STMS1 };
                8'h78: internal_din <= { 8'd0, SCM1 };
                8'h79: internal_din <= { 8'd0, SCC1 };
                8'h7a: internal_din <= { 8'd0, BRG1 };
                8'h7b: internal_din <= { 8'd0, SCE1 };
                8'h7c: internal_din <= { 8'd0, SEIC1 };
                8'h7d: internal_din <= { 8'd0, SRIC1 };
                8'h7e: internal_din <= { 8'd0, STIC1 };
                8'h80: internal_din <= TM0;
                8'h81: internal_din <= { 8'd0, TM0[15:8] };
                8'h82: internal_din <= MD0;
                8'h83: internal_din <= { 8'd0, MD0[15:8] };
                8'h88: internal_din <= TM1;
                8'h89: internal_din <= { 8'd0, TM1[15:8] };
                8'h8a: internal_din <= MD1;
                8'h8b: internal_din <= { 8'd0, MD1[15:8] };
                8'h90: internal_din <= { 8'd0, TMC0 };
                8'h91: internal_din <= { 8'd0, TMC1 };
                8'h94: internal_din <= { 8'd0, TMMS0 };
                8'h95: internal_din <= { 8'd0, TMMS1 };
                8'h96: internal_din <= { 8'd0, TMMS2 };
                8'h9c: internal_din <= { 8'd0, TMIC0 };
                8'h9d: internal_din <= { 8'd0, TMIC1 };
                8'h9e: internal_din <= { 8'd0, TMIC2 };
                8'ha0: internal_din <= { 8'd0, DMAC0 };
                8'ha1: internal_din <= { 8'd0, DMAM0 };
                8'ha2: internal_din <= { 8'd0, DMAC1 };
                8'ha3: internal_din <= { 8'd0, DMAM1 };
                8'hac: internal_din <= { 8'd0, DIC0 };
                8'had: internal_din <= { 8'd0, DIC1 };
                8'he0: internal_din <= { 8'd0, STBC };
                8'he1: internal_din <= { 8'd0, RFM };
                8'he8: internal_din <= WTC;
                8'he9: internal_din <= { 8'd0, WTC[15:8] };
                8'hea: internal_din <= { 8'd0, FLAG };
                8'heb: internal_din <= { 8'd0, PRC };
                8'hec: internal_din <= { 8'd0, TBIC };
                8'hff: internal_din <= { 8'd0, IDB };
                endcase
            end
        end else if (internal_ram_rq) begin
/*
            if (wr) begin
                if (be[0]) iram[addr[7:0]] <= dout[7:0];
                if (be[1]) iram[addr[7:0] + 8'd1] <= dout[15:8];
            end else if (rd) begin
                internal_din <= { iram[addr[7:0] + 8'd1], iram[addr[7:0]] };
            end
*/
        end

        if (rd) internal_rq_latch <= internal_rq;

        if (rd | wr) begin
            case(addr[19:16])
            4'h0, 4'h1: wait_cycles <= WTC[1:0];
            4'h2, 4'h3: wait_cycles <= WTC[3:2];
            4'h4, 4'h5: wait_cycles <= WTC[5:4];
            4'h6, 4'h7: wait_cycles <= WTC[7:6];
            4'h8, 4'h9: wait_cycles <= WTC[9:8];
            4'ha, 4'hb: wait_cycles <= WTC[11:10];
            4'hc, 4'hf: wait_cycles <= WTC[13:12];
            endcase
        end

        if (ce_cycle) begin
            if (wait_cycles != 2'd0) wait_cycles <= wait_cycles - 2'd1;

            /////////////////////////////////////////////
            //// General CE processing
            if (irq_ack) begin
                ISPR <= ISPR | exi_prio_bit;
                case(irq_pending)
                1: EXIC0[7] <= 0;
                2: EXIC1[7] <= 0;
                3: EXIC2[7] <= 0;
                endcase
                irq_pending <= 0;
            end

            if (irq_fini) begin
                casex(ISPR)
                8'bxxxxxxx1: ISPR <= ISPR & 8'b11111110;
                8'bxxxxxx10: ISPR <= ISPR & 8'b11111100;
                8'bxxxxx100: ISPR <= ISPR & 8'b11111000;
                8'bxxxx1000: ISPR <= ISPR & 8'b11110000;
                8'bxxx10000: ISPR <= ISPR & 8'b11100000;
                8'bxx100000: ISPR <= ISPR & 8'b11000000;
                8'bx1000000: ISPR <= ISPR & 8'b10000000;
                8'b10000000: ISPR <= ISPR & 8'b00000000;
                endcase
            end

            intp0_prev <= intp0;
            intp1_prev <= intp1;
            intp2_prev <= intp2;

            if (intp0 != intp0_prev && intp0 == ES0) EXIC0[7] <= 1;
            if (intp1 != intp1_prev && intp1 == ES1) EXIC1[7] <= 1;
            if (intp2 != intp2_prev && intp2 == ES2) EXIC2[7] <= 1;

            if (irq_pending == 0 && (ISPR & exi_prio_bit) == 8'd0) begin
                if (EXIC0[7] & ~EXIC0[6]) begin
                    irq_pending <= 2'd1;
                    irq_vec <= 8'd24;                
                end else if (EXIC1[7] & ~EXIC1[6]) begin
                    irq_pending <= 2'd2;
                    irq_vec <= 8'd25;                
                end else if (EXIC2[7] & ~EXIC2[6]) begin
                    irq_pending <= 2'd3;
                    irq_vec <= 8'd26;                
                end
            end
        end
    end

    exi_prio_bit <= 8'd1 << EXIC0[2:0];
end

v30 core(
    .clk(clk),
    .ce(ce_cycle & (wait_cycles == 2'd0)),
    .ce_4x(ce & (wait_cycles == 2'd0)),
    .reset(reset),
    .turbo(1),
    .SLOWTIMING(),

    .cpu_idle(),
    .cpu_halt(),
    .cpu_irqrequest(),
    .cpu_prefix(),
    .cpu_done(),
         
    .bus_read(rd),
    .bus_write(wr),
    .bus_prefetch(prefetching),
    .bus_be(be),
    .bus_addr(addr),
    .bus_datawrite(dout),
    .bus_dataread(din),
         
    .irqrequest_in(irq_pending != 0),
    .irqvector_in({irq_vec, 2'b00}),
    .irqrequest_ack(irq_ack),
    .irqrequest_fini(irq_fini),

    .secure(secure),
    .secure_wr(secure_wr),
    .secure_addr(secure_addr),
    .secure_data(secure_data),

    // TODO - m92 doesn't use IO ports, but we want to merge these with data anyway
    .RegBus_Din(),
    .RegBus_Adr(),
    .RegBus_wren(),
    .RegBus_rden(),
    .RegBus_Dout(0)
);

endmodule