`timescale 1ns / 1ps
`include "atari7800.vh"



module Atari7800(
  input  logic       clock_25,
  input  logic       sysclk_7_143,
  input  logic       clock_divider_locked,
  
  input  logic       reset,
  output logic [3:0] RED, GREEN, BLUE,
  output logic       HSync, VSync,
  
  output logic [15:0] aud_signal_out,
  
  input  logic [7:0]  cart_DB_out,
  output logic [15:0] AB,
  output logic        RW,
  output logic        pclk_0,
  
  output logic [7:0] ld,
  
  // Tia inputs
  input  logic [3:0] idump,
  input  logic [1:0] ilatch,
  
  output logic tia_en,
  
  // Riot inputs
  input logic [7:0] PAin, PBin,
  output logic [7:0] PAout, PBout
);

   assign ld[0] = lock_ctrl;

   //////////////
   // Signals //
   ////////////

   // Clock Signals

   logic             pclk_2, tia_clk, sel_slow_clock;


   // VGA Signals
   logic [9:0]             vga_row, vga_col;
   logic tia_hsync, tia_vsync, vga_hsync, vga_vsync;
   
   (* keep = "true" *) logic tia_hsync_kept;
   (* keep = "true" *) logic tia_vsync_kept;
   (* keep = "true" *) logic vga_hsync_kept;
   (* keep = "true" *) logic vga_vsync_kept;
   
   assign tia_hsync_kept = ~tia_hsync;
   assign tia_vsync_kept = ~tia_vsync;
   assign vga_hsync_kept = vga_hsync;
   assign vga_vsync_kept = vga_vsync;

   // MARIA Signals
   logic                   m_int_b, maria_RDY;
   logic                   maria_rw;
   logic                   halt_b, maria_drive_AB;
   logic [7:0]             uv_display, uv_maria, uv_tia;
   logic [15:0]            maria_AB_out;



   // TIA Signals
   logic hblank_tia, vblank_tia, aud0, aud1, tia_RDY;
   logic [3:0] audv0, audv1;
   logic [7:0] tia_db_out;  

   // RIOT Signals
   logic riot_RS_b;

   // 6502 Signals
   logic RDY, IRQ_n, CPU_NMI;
   logic [7:0] core_DB_out;
   logic [15:0] core_AB_out;

   logic cpu_reset, core_halt_b, core_latch_data;
   logic [2:0] cpu_reset_counter; 
   
   assign IRQ_n = 1'b1;

   //ctrl Signals
   logic maria_en, lock_ctrl, bios_en_b;
   logic [1:0] ctrl_writes;

   // Buses
   // AB and RW defined in port declaration
   logic  [7:0]           read_DB, write_DB;

   logic [7:0]            tia_DB_out, riot_DB_out, maria_DB_out,
                          ram0_DB_out, ram1_DB_out, bios_DB_out;

   `chipselect       CS_maria_buf, CS_core_buf, CS_buf, CS;
   
   logic memclk;
   assign memclk = (~halt_b & maria_drive_AB) ? sysclk_7_143 : pclk_0;
   
   /*always_ff @(posedge sysclk_7_143, posedge reset) begin
      if (reset) begin
         CS_maria_buf <= `CS_NONE;
         CS_core_buf <= `CS_NONE;
      end else begin
         CS_maria_buf <= CS;
         CS_core_buf <= CS; 
      end
   end
   
   assign CS_buf = maria_drive_AB ? CS_maria_buf : CS_core_buf;*/
   
   always_ff @(posedge memclk, posedge reset)
      if (reset)
        CS_buf <= `CS_NONE;
      else 
        CS_buf <= CS;
        
   
   //CS LOGIC
   logic ram0_cs, ram1_cs, bios_cs, tia_cs, riot_cs, riot_ram_cs;
   
   always_comb begin
        ram0_cs = 1'b0;
        ram1_cs = 1'b0;
        bios_cs = 1'b0;
        tia_cs = 1'b0;
        riot_cs = 1'b0;
        riot_ram_cs = 1'b0;
        casex (CS)
            `CS_RAM0: ram0_cs = 1'b1;
            `CS_RAM1: ram1_cs = 1'b1;
            `CS_BIOS: bios_cs = 1'b1;
            `CS_TIA: tia_cs = 1'b1;
            `CS_RIOT_IO: riot_cs = 1'b1;
            `CS_RIOT_RAM: begin riot_cs = 1'b1; riot_ram_cs = 1'b1; end
        endcase
    end
   

   always_comb begin
      casex (CS_buf)
          `CS_RAM0: read_DB = ram0_DB_out;
          `CS_RAM1: read_DB = ram1_DB_out;
          `CS_RIOT_IO,
          `CS_RIOT_RAM: read_DB = riot_DB_out;
          `CS_TIA: read_DB = tia_DB_out;
          `CS_BIOS: read_DB = bios_DB_out;
          `CS_MARIA: read_DB = maria_DB_out;
          `CS_CART: read_DB = cart_DB_out;
          // Otherwise, nothing is driving the data bus. THIS SHOULD NEVER HAPPEN
          default: read_DB = 8'h46;
      endcase
      
      write_DB = core_DB_out;
      
      AB = (maria_drive_AB) ? maria_AB_out : core_AB_out;
   end
  /*
 (* ram_style = "distributed" *)
   reg [7:0] ram0 [2047:0];
   (* ram_style = "distributed" *)
   reg [7:0] ram1 [2047:0];  
   integer cnt;
   always_ff @(posedge memclk) begin
     if (reset) begin
        for (cnt = 0; cnt < 2048;cnt = cnt + 1) begin
            ram0[cnt] <= 8'b0;
            ram1[cnt] <= 8'b0;
        end
     end
     else if(ram0_cs)
        if (RW) 
            ram0_DB_out <= ram0[AB[10:0]];
        else
            ram0[AB[10:0]] <= write_DB;
     else if (ram1_cs)
        if (RW) 
            ram1_DB_out <= ram1[AB[10:0]];
        else
            ram1[AB[10:0]] <= write_DB; 
   end */

   ram2k ram0_inst(
      .clock(memclk),
      //.ena(~ram0_cs_b),
      .clken(ram0_cs),
      .wren(~RW),
      .address(AB[10:0]),
      .data(write_DB),
      .q(ram0_DB_out)
   );

   ram2k ram1_inst(
      .clock(memclk),
      //.ena(~ram1_cs_b),
      .clken(ram1_cs),
      .wren(~RW),
      .address(AB[10:0]),
      .data(write_DB),
      .q(ram1_DB_out)
   );
   
  //assign bios_cs_b = ~(AB[15] & ~bios_en_b);

  
  BIOS_ROM BIOS_ROM(
		.clock(memclk),
		.clken(bios_cs),
		.address(AB[11:0]),
		.q(bios_DB_out)
  );

   assign pclk_2 = ~pclk_0;
//   console_pll console_pll (
//     .inclk0(CLOCK_PLL),
//     .c0(clock_100),
//     .c1(clock_25),        // 25 MHz
//     .c2(sysclk_7_143), // 7.143 MHz. Divide to 1.79 MHz
//     .locked(clock_divider_locked)
//   );
   
   assign VSync = vga_vsync;
   assign HSync = vga_hsync;

   // VGA
   uv_to_vga vga_out(
      .clk(clock_25), .reset(reset),
      .uv_in(uv_display),
      .row(vga_row), .col(vga_col),
      .RED(RED), .GREEN(GREEN), .BLUE(BLUE),
      .HSync(vga_hsync), .VSync(vga_vsync),
      .tia_en(tia_en),
      .tia_hblank(hblank_tia),
      .tia_vblank(vblank_tia),
      .tia_clk(tia_clk)
   );

   // VIDEO
   always_comb case ({maria_en, tia_en})
       2'b00: uv_display = uv_maria;
       2'b01: uv_display = uv_tia;
       2'b10: uv_display = uv_maria;
       2'b11: uv_display = uv_tia;
       default: uv_display = uv_maria;
   endcase

   // MARIA
   maria maria_inst(
      .AB_in(AB),
      .AB_out(maria_AB_out),
      .drive_AB(maria_drive_AB),
      .read_DB_in(read_DB),
      .write_DB_in(write_DB),
      .DB_out(maria_DB_out),
      .bios_en(~bios_en_b),
      .reset(reset), 
      .sysclk(sysclk_7_143),
      .pclk_2(pclk_2), 
      .sel_slow_clock(sel_slow_clock),
      .core_latch_data(core_latch_data),
      .tia_en(tia_en),
      .tia_clk(tia_clk), 
      .pclk_0(pclk_0),
      .CS(CS),
      //.ram0_b(ram0_cs_b), 
      //.ram1_b(ram1_cs_b),
      //.p6532_b(riot_cs_b), 
      //.tia_b(tia_cs_b),
      //.riot_ram_b(riot_RS_b),
      .RW(RW), 
      .enable(maria_en),
      .vga_row(vga_row), 
      .vga_col(vga_col),
      .UV_out(uv_maria),
      .int_b(m_int_b), 
      .halt_b(halt_b), 
      .ready(maria_RDY)
   );

   // TIA
   TIA tia_inst(.A({(AB[5] & tia_en), AB[4:0]}), // Address bus input
      .Din(write_DB), // Data bus input
      .Dout(tia_DB_out), // Data bus output
      .CS_n({2'b0,~tia_cs}), // Active low chip select input
      .CS(tia_cs), // Chip select input
      .R_W_n(RW), // Active low read/write input
      .RDY(tia_RDY), // CPU ready output
      .MASTERCLK(tia_clk), // 3.58 Mhz pixel clock input
      .CLK2(pclk_0), // 1.19 Mhz bus clock input
      .idump_in(idump), // Dumped I/O
      .Ilatch(ilatch), // Latched I/O
      .HSYNC(tia_hsync),        // Video horizontal sync output
      .HBLANK(hblank_tia), // Video horizontal blank output
      .VSYNC(tia_vsync),        // Video vertical sync output
      .VBLANK(vblank_tia), // Video vertical sync output
      .COLOROUT(uv_tia), // Indexed color output
      .RES_n(~reset), // Active low reset input
      .AUD0(aud0), //audio pin 0
      .AUD1(aud1), //audio pin 1
      .audv0(audv0), //audio volume for use with external xformer module
      .audv1(audv1) //audio volume for use with external xformer module
   );

  audio_xformer audio_xform(.AUD0(aud0), .AUD1(aud1), .AUDV0(audv0),
                            .AUDV1(audv1), .AUD_SIGNAL(aud_signal_out));

  //RIOT
  RIOT riot_inst(.A(AB[6:0]),     // Address bus input
      .Din(write_DB),              // Data bus input
      .Dout(riot_DB_out),    // Data bus output
      .CS(riot_cs),       // Chip select input
      .CS_n(~riot_cs),      // Active low chip select input
      .R_W_n(RW),            // Active high read, active low write input
      .RS_n(~riot_ram_cs),      // Active low rom select input
      .RES_n(~reset),        // Active low reset input
      .IRQ_n(),              // Active low interrupt output
      .CLK(pclk_0),          // Clock input
      .PAin(PAin),           // 8 bit port A input
      .PAout(PAout),         // 8 bit port A output
      .PBin(PBin),           // 8 bit port B input
      .PBout(PBout));        // 8 bit port B output

  //6502
  assign cpu_reset = cpu_reset_counter != 3'b111;
  
  always_ff @(posedge pclk_0, posedge reset) begin
     if (reset) begin
        cpu_reset_counter <= 3'b0;
     end else begin
        if (cpu_reset_counter != 3'b111)
           cpu_reset_counter <= cpu_reset_counter + 3'b001;
     end
  end
  
  
  assign RDY = maria_en ? maria_RDY : ((tia_en) ? tia_RDY : clock_divider_locked);
  
  assign core_halt_b = (ctrl_writes == 2'd2) ? halt_b : 1'b1;
  
  /// DEBUG  ///////////////////////////////////////////
  `ifndef SIM
  
  (* keep = "true" *)
  logic [15:0] pc_temp;
  
  assign ld[1] = pc_reached_230a;
  assign ld[2] = pc_reached_26bc;
  //assign ld[3] = pc_reached_fbad;
  assign ld[4] = pc_reached_fbbd;
  assign ld[5] = pc_reached_faaf;
  
  
  assign ld[6] = tia_en;
  assign ld[7] = maria_en;
  
  logic pc_reached_230a; // Beginning of RAM code
  logic pc_reached_26bc; // Exit BIOS
  logic pc_reached_fbad; // waiting for VSYNC
  logic pc_reached_fbbd; // done waiting for VSYNC
  logic pc_reached_faaf; // NMI handler
  
  always_ff @(posedge sysclk_7_143, posedge reset) begin
     if (reset) begin
        pc_reached_230a <= 1'b0;
        pc_reached_26bc <= 1'b0;
        pc_reached_fbad <= 1'b0;
        pc_reached_fbbd <= 1'b0;
        pc_reached_faaf <= 1'b0;
     end else begin
        if (pc_temp == 16'h230a)
           pc_reached_230a <= 1'b1;
        if (pc_temp == 16'h23ee)
           pc_reached_26bc <= 1'b1;
        if (pc_temp == 16'hfbad)
           pc_reached_fbad <= 1'b1;
        if (pc_temp == 16'hfbbd)
           pc_reached_fbbd <= 1'b1;
        if (pc_temp == 16'hfaaf)
           pc_reached_faaf <= 1'b1;
     end
  end
  `endif
  //////////////////////////////////////////////////////
  
  assign CPU_NMI = (lock_ctrl) ? (~m_int_b) : (~m_int_b & ~bios_en_b);
  
  cpu_wrapper cpu_inst(.clk(pclk_0),
    .core_latch_data(core_latch_data),
    .sysclk(sysclk_7_143),
    .reset(cpu_reset),
    .AB(core_AB_out),
    .DB_IN(read_DB),
    .DB_OUT(core_DB_out),
    .RD(RW),
    .IRQ(~IRQ_n),
    .NMI(CPU_NMI),
    .RDY(RDY),
    .halt_b(core_halt_b),
    .pc_temp(pc_temp));



  ctrl_reg ctrl(.clk(pclk_0),
                .lock_in(write_DB[0]),
                .maria_en_in(write_DB[1]),
                .bios_en_in(write_DB[2]),
                .tia_en_in(write_DB[3]),
                .latch_b(RW | ~tia_cs  | lock_ctrl),
                .rst(reset),
                .lock_out(lock_ctrl),
                .maria_en_out(maria_en),
                .bios_en_out(bios_en_b),
                .tia_en_out(tia_en),
                .writes(ctrl_writes));


endmodule

module ctrl_reg(input logic clk, lock_in, maria_en_in, bios_en_in, tia_en_in, latch_b, rst,
                output logic lock_out, maria_en_out, bios_en_out, tia_en_out, 
                output logic [1:0] writes);


  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      lock_out <= 0;
      maria_en_out <= 0;
      bios_en_out <= 0;
      tia_en_out <= 0;
      writes <= 0;
    end
    else if (~latch_b) begin
      lock_out <= lock_in;
      maria_en_out <= maria_en_in;
      bios_en_out <= bios_en_in;
      tia_en_out <= tia_en_in;
      if (writes < 2'd2)
        writes <= writes + 1;
    end
  end
endmodule
