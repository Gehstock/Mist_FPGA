/***********************************
    FPGA Druaga ( Top module )

      Copyright (c) 2007 MiSTer-X

      Conversion to clock-enable:
        (c) 2019 Slingshot

      Super Pacman Support
        (c) 2021 Jose Tejada, jotego
************************************/
module fpga_druaga
(
    input           RESET,  // RESET
    input           MCLK,       // MasterClock: 49.125MHz
    input           CLKCPUx2, // CPU clock x 2: MCLK/8

    input     [8:0] PH,     // Screen H
    input     [8:0] PV,     // Screen V
    output          PCLK,     // Pixel Clock
    output          PCLK_EN,
    output    [7:0] POUT,     // Pixel Color

    output    [7:0] SOUT,     // Sound Out
    output   [14:0] rom_addr,
    input     [7:0] rom_data,
    output   [12:0] snd_addr,
    input     [7:0] snd_data,
    input     [5:0] INP0,     // 1P {B2,B1,L,D,R,U}
    input     [5:0] INP1,     // 2P {B2,B1,L,D,R,U}
    input     [2:0] INP2,     // {Coin,Start2P,Start1P}

    input     [7:0] DSW0,     // DIPSWs (Active Logic)
    input     [7:0] DSW1,
    input     [7:0] DSW2,

    input  [16:0]   ROMAD,
    input  [ 7:0]   ROMDT,
    input           ROMEN,
    input  [ 2:0]   MODEL,
    input           FLIP_SCREEN
);

// Clock Generator
reg [4:0] CLKS;

wire VCLK_x8  = MCLK;
wire VCLK_x1  = CLKS[2];

wire VCLK_EN   = CLKS[2:0] == 3'b011;
always @( posedge MCLK ) CLKS <= CLKS+1'd1;

// Main-CPU Interface
wire                MCPU_CLK = CLKCPUx2;
wire    [15:0]  MCPU_ADRS;
wire                MCPU_VMA;
wire                MCPU_RW;
wire                MCPU_WE  = ( ~MCPU_RW );
//wire              MCPU_RE  = (  MCPU_RW );
wire    [7:0]       MCPU_DO;
wire    [7:0]       MCPU_DI;

// Sub-CPU Interface
wire                SCPU_CLK    = CLKCPUx2;
wire    [15:0]  SCPU_ADRS;
wire                SCPU_VMA;
wire                SCPU_RW;
wire                SCPU_WE  = ( ~SCPU_RW );
//wire              SCPU_RE  = (  SCPU_RW );
wire    [7:0]       SCPU_DO;
wire    [7:0]       SCPU_DI;

// I/O Interface
wire                MCPU_CS_IO, SCPU_WE_WSG;
wire [7:0]      IO_O;
wire [10:0]     vram_a;
wire [15:0]     vram_d;
wire [6:0]      spra_a;
wire [23:0]     spra_d;
MEMS mems
(
    MCLK,
    CLKCPUx2,
    rom_addr,   rom_data,
    snd_addr, snd_data,
    MCPU_ADRS, MCPU_VMA, MCPU_WE, MCPU_DO, MCPU_DI, MCPU_CS_IO, IO_O,
    SCPU_ADRS, SCPU_VMA, SCPU_WE, SCPU_DO, SCPU_DI, SCPU_WE_WSG,
    vram_a,vram_d,
    spra_a,spra_d,
    ROMAD,ROMDT,ROMEN,
    MODEL
);

// Control Registers
wire oVB;
wire [7:0] SCROLL;
wire MCPU_IRQ, MCPU_IRQEN;
wire SCPU_IRQ, SCPU_IRQEN;
wire SCPU_RESET, IO_RESET;
wire PSG_ENABLE;

REGS regs
(
    CLKCPUx2, RESET, oVB,
    MCPU_ADRS, MCPU_VMA, MCPU_WE,
    SCPU_ADRS, SCPU_VMA, SCPU_WE,
    SCROLL,
    MCPU_IRQ, MCPU_IRQEN,
    SCPU_IRQ, SCPU_IRQEN,
    SCPU_RESET, IO_RESET,
    PSG_ENABLE,
    MODEL
);


// I/O Controler
wire IsMOTOS;
IOCTRL ioctrl(
    CLKCPUx2, oVB, IO_RESET, MCPU_CS_IO, MCPU_WE, MCPU_ADRS[5:0],
    MCPU_DO,
    IO_O,
    {INP1,INP0},INP2,
    {DSW2,DSW1,DSW0},
    IsMOTOS,
    MODEL
);


// Video Core
wire [7:0] oPOUT;
DRUAGA_VIDEO video
(
    .VCLKx8(VCLK_x8),.VCLK(VCLK_x1),
    .VCLK_EN(VCLK_EN),
    .PH(PH),.PV(PV),
    .PCLK(PCLK),.PCLK_EN(PCLK_EN),.POUT(oPOUT),.VB(oVB),
    .VRAM_A(vram_a), .VRAM_D(vram_d),
    .SPRA_A(spra_a), .SPRA_D(spra_d),
    .SCROLL({1'b0,SCROLL}),
    .ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN),
    .MODEL(MODEL),
    .FLIP_SCREEN(FLIP_SCREEN)
);

// This prevents a glitch in the sprites for the first line
// but it hides the top line of the CRT test screen
assign POUT = (IsMOTOS && (PV==0)) ? 8'h0 : oPOUT;


// MainCPU
cpucore main_cpu
(
    .clk(MCPU_CLK),
    .rst(RESET),
    .rw(MCPU_RW),
    .vma(MCPU_VMA),
    .address(MCPU_ADRS),
    .data_in(MCPU_DI),
    .data_out(MCPU_DO),
    .halt(1'b0),
    .hold(1'b0),
    .irq(MCPU_IRQ),
    .firq(1'b0),
    .nmi(1'b0)
);


// SubCPU
cpucore sub_cpu
(
    .clk(SCPU_CLK),
    .rst(SCPU_RESET),
    .rw(SCPU_RW),
    .vma(SCPU_VMA),
    .address(SCPU_ADRS),
    .data_in(SCPU_DI),
    .data_out(SCPU_DO),
    .halt(1'b0),
    .hold(1'b0),
    .irq(SCPU_IRQ),
    .firq(1'b0),
    .nmi(1'b0)
);


// SOUND
wire          WAVE_CLK;
wire [7:0] WAVE_AD;
wire [3:0] WAVE_DT;

dpram #(4,8) wsgwv(.clk_a(MCLK), .addr_a(WAVE_AD), .q_a(WAVE_DT),
                   .clk_b(MCLK), .addr_b(ROMAD[7:0]), .we_b(ROMEN & (ROMAD[16:8]=={1'b1,8'h35})), .d_b(ROMDT[3:0]));

WSG_8CH wsg(
    .MCLK(MCLK),
    .ADDR(SCPU_ADRS[5:0]),
    .DATA(SCPU_DO),
    .WE(SCPU_WE_WSG),
    .SND_ENABLE(PSG_ENABLE),
    .WAVE_CLK(WAVE_CLK),
    .WAVE_AD(WAVE_AD),
    .WAVE_DT(WAVE_DT),
    .SOUT(SOUT)
);

endmodule

module MEMS
(
    input           MCLK,
    input           CPUCLKx2,
    output  [14:0]  rom_addr,
    input    [7:0]  rom_data,
    output  [12:0]  snd_addr,
    input    [7:0]  snd_data,
    input   [15:0]  MCPU_ADRS,
    input           MCPU_VMA,
    input           MCPU_WE,
    input    [7:0]  MCPU_DO,
    output   [7:0]  MCPU_DI,
    output          IO_CS,
    input    [7:0]  IO_O,

    input   [15:0]  SCPU_ADRS,
    input           SCPU_VMA,
    input           SCPU_WE,
    input    [7:0]  SCPU_DO,
    output   [7:0]  SCPU_DI,
    output          SCPU_WSG_WE,

    input  [10:0]   vram_a,
    output [15:0]   vram_d,
    input   [6:0]   spra_a,
    output [23:0]   spra_d,

    input  [16:0]   ROMAD,
    input  [ 7:0]   ROMDT,
    input           ROMEN,
    input  [2:0]    MODEL
);

`include "param.v"

wire [7:0] mrom_d, srom_d;
//DLROM #(15,8) mcpui( CPUCLKx2, MCPU_ADRS[14:0], mrom_d, ROMCL,ROMAD[14:0],ROMDT,ROMEN & (ROMAD[16:15]==2'b0_0));
assign rom_addr = MCPU_ADRS[14:0];
assign mrom_d = rom_data;
assign snd_addr = SCPU_ADRS[12:0];
assign srom_d = snd_data;

//dpram #(8,13) scpui(.clk_a(CPUCLKx2), .addr_a(SCPU_ADRS[12:0]), .q_a(srom_d),
//                    .clk_b(MCLK), .addr_b(ROMAD[12:0]), .we_b(ROMEN & (ROMAD[16:13]==4'b1_000)), .d_b(ROMDT));

reg  mram_cs0, mram_cs1,
     mram_cs2, mram_cs3,
     mram_cs4, mram_cs5;

reg    [10:0] cram_ad;
wire   [10:0] mram_ad = MCPU_ADRS[10:0];

assign IO_CS  = ( MCPU_ADRS[15:11] == 5'b01001  ) & MCPU_VMA;    // $4800-$4FFF
wire mrom_cs  = ( MCPU_ADRS[15] ) & MCPU_VMA;    // $8000-$FFFF

always @(*) begin
    cram_ad = mram_ad;
    if( MODEL == SUPERPAC || MODEL == GROBDA || MODEL == PACNPAL) begin
        mram_cs0 = ( MCPU_ADRS[15:10] == 6'b000000 ) && MCPU_VMA;    // $0000-$03FF
        mram_cs1 = ( MCPU_ADRS[15:10] == 6'b000001 ) && MCPU_VMA;    // $0400-$07FF
        mram_cs2 = ( MCPU_ADRS[15:11] == 5'b00001  ) && MCPU_VMA;    // $1000-$17FF
        mram_cs3 = ( MCPU_ADRS[15:11] == 5'b00010  ) && MCPU_VMA;    // $1800-$1FFF
        mram_cs4 = ( MCPU_ADRS[15:11] == 5'b00011  ) && MCPU_VMA;    // $2000-$27FF
        if( mram_cs0 | mram_cs1 ) cram_ad[10]=0;
    end else begin
        mram_cs0 = ( MCPU_ADRS[15:11] == 5'b00000  ) && MCPU_VMA;    // $0000-$07FF
        mram_cs1 = ( MCPU_ADRS[15:11] == 5'b00001  ) && MCPU_VMA;    // $0800-$0FFF
        mram_cs2 = ( MCPU_ADRS[15:11] == 5'b00010  ) && MCPU_VMA;    // $1000-$17FF
        mram_cs3 = ( MCPU_ADRS[15:11] == 5'b00011  ) && MCPU_VMA;    // $1800-$1FFF
        mram_cs4 = ( MCPU_ADRS[15:11] == 5'b00100  ) && MCPU_VMA;    // $2000-$27FF
    end
    mram_cs5 = ( MCPU_ADRS[15:10] == 6'b010000 ) && MCPU_VMA;    // $4000-$43FF
end

wire mram_w0  = ( mram_cs0 & MCPU_WE );
wire mram_w1  = ( mram_cs1 & MCPU_WE );
wire mram_w2  = ( mram_cs2 & MCPU_WE );
wire mram_w3  = ( mram_cs3 & MCPU_WE );
wire mram_w4  = ( mram_cs4 & MCPU_WE );
wire mram_w5  = ( mram_cs5 & MCPU_WE );

wire [7:0] mram_o0, mram_o1, mram_o2, mram_o3, mram_o4, mram_o5;

assign          MCPU_DI  = mram_cs0 ? mram_o0 :
                           mram_cs1 ? mram_o1 :
                           mram_cs2 ? mram_o2 :
                           mram_cs3 ? mram_o3 :
                           mram_cs4 ? mram_o4 :
                           mram_cs5 ? mram_o5 :
                           mrom_cs  ? mrom_d  :
                           IO_CS    ? IO_O    :
                           8'h0;

dpram #(8,11) main_ram0( .clk_a(CPUCLKx2), .addr_a(cram_ad), .d_a(MCPU_DO), .q_a(mram_o0), .we_a(mram_w0), .clk_b(MCLK), .addr_b(vram_a), .q_b(vram_d[ 7:0]));
dpram #(8,11) main_ram1( .clk_a(CPUCLKx2), .addr_a(cram_ad), .d_a(MCPU_DO), .q_a(mram_o1), .we_a(mram_w1), .clk_b(MCLK), .addr_b(vram_a), .q_b(vram_d[15:8]));

dpram #(8,11) main_ram2( .clk_a(CPUCLKx2), .addr_a(mram_ad), .d_a(MCPU_DO), .q_a(mram_o2), .we_a(mram_w2), .clk_b(MCLK), .addr_b({ 4'b1111, spra_a }), .q_b(spra_d[ 7: 0]));
dpram #(8,11) main_ram3( .clk_a(CPUCLKx2), .addr_a(mram_ad), .d_a(MCPU_DO), .q_a(mram_o3), .we_a(mram_w3), .clk_b(MCLK), .addr_b({ 4'b1111, spra_a }), .q_b(spra_d[15: 8]));
dpram #(8,11) main_ram4( .clk_a(CPUCLKx2), .addr_a(mram_ad), .d_a(MCPU_DO), .q_a(mram_o4), .we_a(mram_w4), .clk_b(MCLK), .addr_b({ 4'b1111, spra_a }), .q_b(spra_d[23:16]));

                                                                                                // (SCPU ADRS)
wire                SCPU_CS_SREG = ( ( SCPU_ADRS[15:13] == 3'b000 ) & ( SCPU_ADRS[9:6] == 4'b0000 ) ) & SCPU_VMA;
wire                srom_cs  = ( SCPU_ADRS[15:13] == 3'b111 ) & SCPU_VMA;       // $E000-$FFFF
wire                sram_cs0 = (~SCPU_CS_SREG) & (~srom_cs) & SCPU_VMA;     // $0000-$03FF
wire    [7:0]       sram_o0;

assign          SCPU_DI  =  sram_cs0 ? sram_o0 :
                                    srom_cs  ? srom_d  :
                                    8'h0;

assign          SCPU_WSG_WE = SCPU_CS_SREG & SCPU_WE;

dpram #(8,11) share_ram( .clk_a(CPUCLKx2), .addr_a(mram_ad), .d_a(MCPU_DO), .q_a(mram_o5), .we_a(mram_w5),
                         .clk_b(CPUCLKx2), .addr_b(SCPU_ADRS[9:0]), .d_b(SCPU_DO), .q_b(sram_o0), .we_b(sram_cs0 & SCPU_WE) );


endmodule

module REGS
(
    input               MCPU_CLK,
    input               RESET,
    input               VBLANK,

    input    [15:0]     MCPU_ADRS,
    input               MCPU_VMA,
    input               MCPU_WE,

    input    [15:0]     SCPU_ADRS,
    input               SCPU_VMA,
    input               SCPU_WE,

    output reg [7:0]    SCROLL,
    output              MCPU_IRQ,
    output reg          MCPU_IRQEN,
    output              SCPU_IRQ,
    output reg          SCPU_IRQEN,
    output              SCPU_RESET,
    output              IO_RESET,
    output reg          PSG_ENABLE,
    input  [2:0]        MODEL
);

`include "param.v"
// BG Scroll Register
wire    MCPU_SCRWE = ( ( MCPU_ADRS[15:11] == 5'b00111 ) & MCPU_VMA & MCPU_WE );

always @ ( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) SCROLL <= 8'h0;
    else begin
        if( MODEL==SUPERPAC || MODEL==GROBDA || MODEL==PACNPAL)
            SCROLL <= 8'd0;
        else if ( MCPU_SCRWE )
            SCROLL <= MCPU_ADRS[10:3];
    end
end

// MainCPU IRQ Generator
wire    MCPU_IRQWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000001 ) & MCPU_VMA & MCPU_WE );
//wire  MCPU_IRQWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000001 ) & SCPU_VMA & SCPU_WE );
assign MCPU_IRQ    = MCPU_IRQEN & VBLANK;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        MCPU_IRQEN <= 1'b0;
    end
    else begin
        if ( MCPU_IRQWE  ) MCPU_IRQEN <= MCPU_ADRS[0];
//      if ( MCPU_IRQWES ) MCPU_IRQEN <= SCPU_ADRS[0];
    end
end


// SubCPU IRQ Generator
wire    SCPU_IRQWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000000 ) & MCPU_VMA & MCPU_WE );
wire    SCPU_IRQWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000000 ) & SCPU_VMA & SCPU_WE );
assign SCPU_IRQ    = SCPU_IRQEN & VBLANK;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        SCPU_IRQEN <= 1'b0;
    end
    else begin
        if ( SCPU_IRQWE  ) SCPU_IRQEN <= MCPU_ADRS[0];
        if ( SCPU_IRQWES ) SCPU_IRQEN <= SCPU_ADRS[0];
    end
end


// SubCPU RESET Control
reg SCPU_RSTf   = 1'b0;
wire    SCPU_RSTWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000101 ) & MCPU_VMA & MCPU_WE );
wire    SCPU_RSTWES = ( ( SCPU_ADRS[15:1] == 15'b001000000000101 ) & SCPU_VMA & SCPU_WE );
assign SCPU_RESET  = ~SCPU_RSTf;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        SCPU_RSTf <= 1'b0;
    end
    else begin
        if ( SCPU_RSTWE  ) SCPU_RSTf <= MCPU_ADRS[0];
        if ( SCPU_RSTWES ) SCPU_RSTf <= SCPU_ADRS[0];
    end
end


// I/O CHIP RESET Control
reg IOCHIP_RSTf   = 1'b0;
wire    IOCHIP_RSTWE  = ( ( MCPU_ADRS[15:1] == 15'b010100000000100 ) & MCPU_VMA & MCPU_WE );
assign IO_RESET     = ~IOCHIP_RSTf;

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        IOCHIP_RSTf <= 1'b0;
    end
    else begin
        if ( IOCHIP_RSTWE ) IOCHIP_RSTf <= MCPU_ADRS[0];
    end
end


// Sound Enable Control
wire    PSG_ENAWE   = ( ( MCPU_ADRS[15:1] == 15'b010100000000011 ) & MCPU_VMA & MCPU_WE );
wire    PSG_ENAWES  = ( ( SCPU_ADRS[15:1] == 15'b001000000000011 ) & SCPU_VMA & SCPU_WE );

always @( negedge MCPU_CLK or posedge RESET ) begin
    if ( RESET ) begin
        PSG_ENABLE <= 1'b0;
    end
    else begin
        if ( PSG_ENAWE  ) PSG_ENABLE <= MCPU_ADRS[0];
        if ( PSG_ENAWES ) PSG_ENABLE <= SCPU_ADRS[0];
    end
end

endmodule


module cpucore
(
    input               clk,
    input               rst,
    output          rw,
    output          vma,
    output [15:0]   address,
    input   [7:0]   data_in,
    output  [7:0]   data_out,
    input               halt,
    input               hold,
    input               irq,
    input               firq,
    input               nmi
);


mc6809 cpu
(
   .D(data_in),
    .DOut(data_out),
   .ADDR(address),
   .RnW(rw),
//  .E(vma),
   .nIRQ(~irq),
   .nFIRQ(~firq),
   .nNMI(~nmi),
   .EXTAL(clk),
   .nHALT(~halt),
   .nRESET(~rst),

    .XTAL(1'b0),
    .MRDY(1'b1),
    .nDMABREQ(1'b1)
);
assign vma = 1;

endmodule

