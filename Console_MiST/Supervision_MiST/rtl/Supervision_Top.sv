module Supervision_Top(
	input 			clk_sys,//50
	input 			clk_vid,// 25.175
	input 			clk_cpu,//4
	input 			reset,
	output			hsync,
	output			vsync,
	output			hblank,
	output			vblank,
	input 			white,
	output	[7:0]	red,
	output	[7:0]	green,
	output	[7:0]	blue,
	output	[3:0]	audio_ch1,
	output	[3:0]	audio_ch2,	
	input		[7:0]	joystick,
	output	[15:0]cpu_rom_addr,	
	input		[7:0]	cpu_rom_data
);

reg [15:0] nmi_clk;
wire nmi = nmi_clk == 0;
always @(posedge clk_cpu) 
	nmi_clk <= nmi_clk + 16'b1;

reg [7:0] sys_ctl;
reg [7:0] irq_timer; // 2023
reg [7:0] irq_status; // 2027 ??????DT 1=expired/finished
reg irq_tim;
reg irq_dma;

wire [15:0] cpu_addr;
wire [7:0] cpu_dout;
wire [7:0] wram_dout;
wire [7:0] vram_dout;
wire [7:0] rom_dout;
wire [7:0] sys_dout;

reg [7:0] dma_src_lo;
reg [7:0] dma_src_hi;
reg [7:0] dma_dst_lo;
reg [7:0] dma_dst_hi;
reg [7:0] dma_length;
reg [7:0] dma_ctrl;
wire [7:0] dma_dout;
wire [13:0] dma_addr;
wire dma_busy;
wire dma_sel;
wire dma_write;

reg [7:0] lcd_xscroll;
reg [7:0] lcd_yscroll;
reg [7:0] lcd_xsize;
reg [7:0] lcd_ysize;
wire [7:0] lcd_din;
wire lcd_pulse;
wire cpu_rdy = ~dma_busy;
wire dma_rdy = ~lcd_pulse;
wire cpu_we;
wire [15:0] lcd_addr;

reg [7:0] ch1_freq_hi, ch1_freq_low, ch1_length, ch1_vduty;
reg [7:0] ch2_freq_hi, ch2_freq_low, ch2_length, ch2_vduty;
reg [7:0] audio_dma_addr_low, audio_dma_addr_high;
reg [7:0] audio_dma_ctrl, audio_dma_length, audio_dma_trigger;
reg [7:0] noise_ctrl, noise_freq_vol, noise_length;

////////////////////// IRQ //////////////////////////
reg [13:0] timer_div;

// irq_tim
always @(posedge clk_sys)
  if (sys_ctl[1]) begin // irq enable flag
    if (irq_timer == 0 && ~irq_status[0]) irq_tim <= 1;
    else if (sys_cs && cpu_we && AB[2:0] == 3'h3 && cpu_dout == 0) irq_tim <= 1;
    else irq_tim <= 0;
  end

// irq status
always @(posedge clk_sys)
  if (sys_cs && ~cpu_we && AB[2:0] == 3'h4) // write to irq timer ack
    irq_status[0] <= 1'b0;
  else if (irq_tim) // change status on irq
    irq_status[0] <= 1'b1;

// timer prescaler
always @(posedge clk_cpu)
  if (timer_div > 0)
    timer_div <= timer_div - 14'b1;
  else if (sys_ctl[4])
    timer_div <= 14'h3fff;
  else
    timer_div <= 14'hff;

 irq_timer
always @(posedge clk_cpu)
  if (sys_cs && cpu_we && AB[2:0] == 3'h3)
    irq_timer <= cpu_dout;
  else if (timer_div == 0 && irq_timer > 0)
    irq_timer <= irq_timer - 8'b1;


/////////////////////////// MEMORY MAP /////////////////////

// 0000 - 1FFF - WRAM
// 2000 - 202F - CTRL
// 2030 - 3FFF - CTRL - mirrors ??
// 4000 - 5FFF - VRAM ??
// 6000 - 7FFF - VRAM - mirrors ??
// 8000 - BFFF - banks
// C000 - FFFF - last 16k of cartridge


wire wram_cs = AB ==? 16'b000x_xxxx_xxxx_xxxx;
wire lcd_cs  = AB ==? 16'b0010_0000_0000_0xxx; // match 2000-2007 LCD control registers
wire dma_cs  = AB ==? 16'b0010_0000_0000_1xxx; // match 2008-200F DMA control registers
wire snd_cs  = AB ==? 16'b0010_0000_0001_xxxx; // match 2010-201F sound registers
wire sys_cs  = AB ==? 16'b0010_0000_0010_0xxx; // match 2020-2027 sys registers
wire noi_cs  = AB ==? 16'b0010_0000_0010_1xxx; // match 2028-202F sound registers (noise)
wire vram_cs = AB ==? 16'b01xx_xxxx_xxxx_xxxx;
wire rom_cs  = AB ==? 16'b1xxx_xxxx_xxxx_xxxx;
wire rom_hi  = AB ==? 16'b11xx_xxxx_xxxx_xxxx;

wire [15:0] AB = dma_busy  ? { 2'b0, dma_addr } : cpu_addr;

reg [7:0] DI;

wire [7:0] DO = dma_busy ? dma_dout : cpu_dout;
wire wram_we = wram_cs ? dma_busy ? ~dma_write : ~cpu_we : 1'b1;
wire vram_we = vram_cs ? dma_busy ? ~dma_write : ~cpu_we : 1'b1;

wire [15:0] rom_addr = rom_hi ? AB : { sys_ctl[6:5], AB[13:0] };

always @(posedge clk_cpu)
  DI <= sys_cs ? sys_dout :
  wram_cs ? wram_dout :
  vram_cs ? vram_dout :
  rom_cs ? rom_dout : 8'hff;

// write to lcd registers
always @(posedge clk_sys)
  if (lcd_cs && cpu_we) begin
    case (AB[1:0])
      2'h0: lcd_xsize <= cpu_dout;
      2'h1: lcd_ysize <= cpu_dout;
      2'h2: lcd_xscroll <= cpu_dout;
      2'h3: lcd_yscroll <= cpu_dout;
    endcase
  end

// write to audio registers
always @(posedge clk_sys)
  if (snd_cs && cpu_we) begin
    case (AB[3:0])
      4'h0: ch1_freq_low <= cpu_dout;
      4'h1: ch1_freq_hi <= cpu_dout;
      4'h2: ch1_vduty <= cpu_dout;
      4'h3: ch1_length <= cpu_dout;
      4'h4: ch2_freq_low <= cpu_dout;
      4'h5: ch2_freq_hi <= cpu_dout;
      4'h6: ch2_vduty <= cpu_dout;
      4'h7: ch2_length <= cpu_dout;
      4'h8: audio_dma_addr_low <= cpu_dout;
      4'h9: audio_dma_addr_high <= cpu_dout;
      4'ha: audio_dma_length <= cpu_dout;
      4'hb: audio_dma_ctrl <= cpu_dout;
      4'hc: audio_dma_trigger <= cpu_dout;
    endcase
  end

// write to noise registers
always @(posedge clk_sys)
  if (noi_cs && cpu_we) begin
    case (AB[2:0])
      3'h0: noise_freq_vol <= cpu_dout;
      3'h1: noise_length <= cpu_dout;
      3'h2: noise_ctrl <= cpu_dout;
    endcase
  end


// write to dma registers
//CAUTION:  This DMA can only be used to move data from WRAM/cartridge ROM to VRAM!  
//Attempting to move data to a non-VRAM address will cause serious problems to occur. 
//See my findings at the bottom of the document in the DMA timing section.

always @(posedge clk_sys)
  if (dma_cs && cpu_we)
    case (AB[2:0])
      3'h0: dma_src_lo <= cpu_dout;//DMA Source low
      3'h1: dma_src_hi <= cpu_dout;//DMA Source high
      3'h2: dma_dst_lo <= cpu_dout;//DMA Destination low
      3'h3: dma_dst_hi <= cpu_dout;//DMA Destination high
      3'h4: dma_length <= cpu_dout;//DMA Length
      3'h5: dma_ctrl   <= cpu_dout;//DMA Control
      default:
        dma_ctrl <= 8'd0;
    endcase

// write to sys registers
always @(posedge clk_sys)
  if (sys_cs && cpu_we)
    case (AB[2:0])
//      3'h3: irq_timer = cpu_dout;
      3'h6: sys_ctl <= cpu_dout;
    endcase

// read sys registers
always @(posedge clk_sys)
  if (sys_cs && ~cpu_we)
    case (AB[2:0])
      3'h0: sys_dout <= {
          ~joystick[7],
          ~joystick[6],
          ~joystick[5],
          ~joystick[4],
          ~joystick[3],
          ~joystick[2],
          ~joystick[1],
          ~joystick[0]
        };
      3'h3: sys_dout <= irq_timer;
      3'h6: sys_dout <= sys_ctl;
    endcase


////////////////////////////////////////////////


//rom cart(
//  .clk(clk_sys),
//  .addr(rom_addr),
//  .dout(rom_dout),
//  .cs(~rom_cs),
//  .rom_init(ioctl_download),
//  .rom_init_clk(clk_sys),
//  .rom_init_address(ioctl_addr),
//  .rom_init_data(ioctl_dout)
//);

assign cpu_rom_addr = rom_addr;	
assign rom_dout = rom_cs ? cpu_rom_data : 8'hff;


ram88 wram(
  .clk(clk_sys),
  .addr(AB[12:0]),
  .din(DO), // <= cpu or dma
  .dout(wram_dout),
  .we(wram_we),
  .cs(~wram_cs)
);

// dual port ram
ram88 vram(
  .clk(clk_sys),
  .addr(AB[12:0]),
  .din(DO), // <= cpu or dma
  .dout(vram_dout),
  .addrb(lcd_addr),
  .doutb(lcd_din),
  .we(vram_we),
  .cs(~vram_cs)
);

dma dma(
  .clk(clk_sys),
  .rdy(dma_rdy),
  .irq_dma(irq_dma),
  .ctrl(dma_ctrl),
  .src_addr({ dma_src_hi, dma_src_lo }),
  .dst_addr({ dma_dst_hi, dma_dst_lo }),
  .addr(dma_addr), // => to AB
  .din(DI),
  .dout(dma_dout),
  .length(dma_length),
  .busy(dma_busy),
  .sel(dma_sel),
  .write(dma_write)
);

audio audio(
  .clk(clk_sys),
  .CH1_freq({ ch1_freq_hi[2:0], ch1_freq_low }),
  .CH1_vduty(ch1_vduty),
  .CH1_length(ch1_length),
  .CH2_freq({ ch2_freq_hi[2:0], ch2_freq_low }),
  .CH2_vduty(ch2_vduty),
  .CH2_length(ch2_length),
  .DMA_addr({ audio_dma_addr_high, audio_dma_addr_low }),
  .DMA_length(audio_dma_length),
  .DMA_ctrl(audio_dma_ctrl),
  .DMA_trigger(audio_dma_trigger),
  .noise_freq_vol(noise_freq_vol),
  .noise_length(noise_length),
  .noise_ctrl(noise_ctrl),
  .CH1(audio_ch1),
  .CH2(audio_ch2)
);

video video(
  .clk(clk_vid),
  .ce(sys_ctl[3]),
  .white(white),
  .lcd_xsize(lcd_xsize),
  .lcd_ysize(lcd_ysize),
  .lcd_xscroll(lcd_xscroll),
  .lcd_yscroll(lcd_yscroll),
  .lcd_pulse(lcd_pulse),
  .addr(lcd_addr),
  .data(lcd_din),
  .hsync(hsync),
  .vsync(vsync),
  .hblank(hblank),
  .vblank(vblank),
  .red(red),
  .green(green),
  .blue(blue)
);

cpu_65c02 cpu(
  .clk(clk_cpu),
  .reset(reset),
  .AB(cpu_addr),
  .DI(DI),
  .DO(cpu_dout),
  .WE(cpu_we),
  .IRQ(irq_tim | irq_dma),
  .NMI(nmi),
  .RDY(cpu_rdy)
);


endmodule 