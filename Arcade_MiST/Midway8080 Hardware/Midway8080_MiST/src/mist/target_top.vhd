library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;
use work.target_pkg.all;

entity target_top is
  port
    (

      CLOCK_27      : in std_logic;
      SPI_SCK : in std_logic;
      SPI_DI : in std_logic;
		SPI_SS2 : in std_logic;
		SPI_SS3 : in std_logic;
		SPI_SS4 : in std_logic;
      SPI_DO : out std_logic;
		LED : out std_logic;		
      CONF_DATA0 : in std_logic;
      AUDIO_L           : out std_logic;
      AUDIO_R           : out std_logic;
      VGA_VS        : out std_logic;                        --	VGA H_SYNC
      VGA_HS        : out std_logic;                        --	VGA V_SYNC
      VGA_R         : out std_logic_vector(5 downto 0);     --	VGA Red[3:0]
      VGA_G         : out std_logic_vector(5 downto 0);     --	VGA Green[3:0]
      VGA_B         : out std_logic_vector(5 downto 0)      --	VGA Blue[3:0]

  );    
  
end target_top;

architecture SYN of target_top is

  signal init       	: std_logic := '1';  
  signal clock_50       : std_logic;
  signal clkrst_i       : from_CLKRST_t;
  signal buttons_i      : from_BUTTONS_t;
  signal switches_i     : from_SWITCHES_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;
  signal audio_i        : from_AUDIO_t;
  signal audio_o        : to_AUDIO_t;
  signal project_i      : from_PROJECT_IO_t;
  signal project_o      : to_PROJECT_IO_t;
  signal platform_i     : from_PLATFORM_IO_t;
  signal platform_o     : to_PLATFORM_IO_t;
  signal target_i       : from_TARGET_IO_t;
  signal target_o       : to_TARGET_IO_t;

  signal clk_kb       : std_logic;
  signal joystick1       : std_logic_vector(7 downto 0);
  signal joystick2      : std_logic_vector(7 downto 0);
  signal switches       : std_logic_vector(1 downto 0);
  signal buttons        : std_logic_vector(1 downto 0);
  signal ps2Clk       : std_logic;
  signal ps2Data       : std_logic;
  signal kbd_joy0 		: std_logic_vector(7 downto 0);
  signal osd_pclk       : std_logic;
  signal clk8m       : std_logic;
  signal clk16m       : std_logic;
  signal scandoubler_disable       : std_logic;
  signal hsync_out : std_logic;
  signal vsync_out : std_logic;
  signal csync_out : std_logic;  
  signal VGA_R_O  : std_logic_vector(5 downto 0);
  signal VGA_G_O  : std_logic_vector(5 downto 0);
  signal VGA_B_O  : std_logic_vector(5 downto 0);
  signal VGA_HS_O : std_logic;
  signal VGA_VS_O : std_logic;  
  signal status     : std_logic_vector(7 downto 0);  
  signal reset : std_logic;  


  constant CONF_STR : string := "Midw.8080;;O4,Scanlines,OFF,ON;T5,Reset;V,v1.0 by Gehstock;";
	 
  function to_slv(s: string) return std_logic_vector is
    constant ss: string(1 to s'length) := s;
    variable rval: std_logic_vector(1 to 8 * s'length);
    variable p: integer;
    variable c: integer;
  
  begin  
    for i in ss'range loop
      p := 8 * i;
      c := character'pos(ss(i));
      rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
    end loop;
    return rval;

  end function;
  
  component user_io
	 generic ( STRLEN : integer := 0 );
    port (
      SPI_CLK, SPI_SS_IO, SPI_MOSI :in std_logic;
      SPI_MISO : out std_logic;
      conf_str : in std_logic_vector(8*STRLEN-1 downto 0);
      switches : out std_logic_vector(1 downto 0);
      buttons : out std_logic_vector(1 downto 0);
      scandoubler_disable : out std_logic;
      joystick_0 : out std_logic_vector(7 downto 0);
      joystick_1 : out std_logic_vector(7 downto 0);
      status : out std_logic_vector(7 downto 0);
      ps2_clk : in std_logic;
      ps2_kbd_clk : out std_logic;
      ps2_kbd_data : out std_logic
    );
  end component user_io;

  component osd
    port (
      pclk, sck, ss, sdi, hs_in, vs_in, scanline_ena_h : in std_logic;
      red_in, blue_in, green_in : in std_logic_vector(5 downto 0);
      red_out, blue_out, green_out : out std_logic_vector(5 downto 0);
      hs_out, vs_out : out std_logic
    );
  end component osd;
  
  component keyboard
	PORT(
	  clk : in std_logic;
	  reset : in std_logic;
	  ps2_kbd_clk : in std_logic;
	  ps2_kbd_data : in std_logic;
	  joystick : out std_logic_vector (7 downto 0)
	);
  end component;
  
  
  component pll27
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC;
		c1		: OUT STD_LOGIC;
		c2		: OUT STD_LOGIC 	
	);
  end component;



begin

LED <= '1';

--  OSD
  osd_pclk <= clk16m when scandoubler_disable='0' else clk8m;

  -- a minimig vga->scart cable expects a composite sync signal on the VGA_HS output 
  -- and VCC on VGA_VS (to switch into rgb mode)
  csync_out <= '1' when (hsync_out = vsync_out) else '0';
  VGA_HS <= hsync_out when scandoubler_disable='0' else csync_out;
  VGA_VS <= vsync_out when scandoubler_disable='0' else '1';
  
  osd_inst : osd
    port map (
      pclk => osd_pclk,
      sdi => SPI_DI,
      sck => SPI_SCK,
      ss => SPI_SS3,
      red_in => VGA_R_O,
      green_in => VGA_G_O,
      blue_in => VGA_B_O,
      hs_in => VGA_HS_O,
      vs_in => VGA_VS_O,
      scanline_ena_h => status(4),
      red_out => VGA_R,
      green_out => VGA_G,
      blue_out => VGA_B,
      hs_out => hsync_out,
      vs_out => vsync_out
    );
	 
	  user_io_inst : user_io
 	generic map (STRLEN => CONF_STR'length)
   port map (
      SPI_CLK => SPI_SCK,
      SPI_SS_IO => CONF_DATA0,
      SPI_MOSI => SPI_DI,
      SPI_MISO => SPI_DO,
      conf_str => to_slv(CONF_STR),
      switches => switches,
      buttons  => buttons,
      scandoubler_disable  => scandoubler_disable,
      joystick_1 => joystick2,
      joystick_0 => joystick1,
      status => status,
      ps2_clk => clk_kb,
      ps2_kbd_clk => ps2Clk,
      ps2_kbd_data => ps2Data
    );
	 
	 u_keyboard : keyboard
    port  map(
	clk 				=> clock_50,
	reset 			=> reset,
	ps2_kbd_clk 	=> ps2Clk,
	ps2_kbd_data 	=> ps2Data,
	joystick 		=> kbd_joy0
);


kbclk : pll27
        port map
        (
		inclk0  => CLOCK_27,
				c0 => clk_kb,
				c1 => clk8m,
				c2 => clk16m
	);
    clkrst_i.clk_ref <= CLOCK_27;
  
   pll_27_inst : entity work.pllclk_ez
        port map
        (
          inclk0  => CLOCK_27,
          c0      => clock_50,  -- master clock
          c1      => clkrst_i.clk(1)  -- video clock
        );
		  clkrst_i.clk(0)<=clock_50;

	
  -- FPGA STARTUP
	-- should extend power-on reset if registers init to '0'
	process (clock_50)
		variable count : std_logic_vector (11 downto 0) := (others => '0');
	begin
		if rising_edge(clock_50) then
			if count = X"FFF" then
				init <= '0';
			else
				count := count + 1;
				init <= '1';
			end if;
		end if;
	end process;

  clkrst_i.arst <= init or status(5) or buttons(1);
  clkrst_i.arst_n <= not clkrst_i.arst;

  GEN_RESETS : for i in 0 to 3 generate

    process (clkrst_i.clk(i), clkrst_i.arst)
      variable rst_r : std_logic_vector(2 downto 0) := (others => '0');
    begin
      if clkrst_i.arst = '1' then
        rst_r := (others => '1');
      elsif rising_edge(clkrst_i.clk(i)) then
        rst_r := rst_r(rst_r'left-1 downto 0) & '0';
      end if;
      clkrst_i.rst(i) <= rst_r(rst_r'left);
    end process;

  end generate GEN_RESETS;

 
 		inputs_i.jamma_n.coin(1) <= not (kbd_joy0(3)) or status(2);--ESC
		inputs_i.jamma_n.p(1).start <= not (kbd_joy0(3)) or status(2);--ESC
		
		inputs_i.jamma_n.p(1).up <= not (joystick1(3) or joystick2(3) or kbd_joy0(4));
		inputs_i.jamma_n.p(1).down <= not (joystick1(2) or joystick2(2) or kbd_joy0(5));
		inputs_i.jamma_n.p(1).left <= not (joystick1(1) or joystick2(1) or kbd_joy0(6));
		inputs_i.jamma_n.p(1).right <= not (joystick1(0) or joystick2(0) or kbd_joy0(7));
		
		inputs_i.jamma_n.p(1).button(1) <= not (joystick1(4) or joystick2(4) or kbd_joy0(0)); 
		inputs_i.jamma_n.p(1).button(2) <= '1'; 
		inputs_i.jamma_n.p(1).button(3) <= '1';
		inputs_i.jamma_n.p(1).button(4) <= '1';
		inputs_i.jamma_n.p(1).button(5) <= '1';
		
		inputs_i.jamma_n.p(2).up <= not (joystick1(3) or joystick2(3) or kbd_joy0(4));
		inputs_i.jamma_n.p(2).down <= not (joystick1(2) or joystick2(2) or kbd_joy0(5));
		inputs_i.jamma_n.p(2).left <= not (joystick1(1) or joystick2(1) or kbd_joy0(6));
		inputs_i.jamma_n.p(2).right <= not (joystick1(0) or joystick2(0) or kbd_joy0(7));
		
		inputs_i.jamma_n.p(2).button(1) <= not (joystick1(4) or joystick2(4) or kbd_joy0(0)); 
		inputs_i.jamma_n.p(2).button(2) <= '1';
		inputs_i.jamma_n.p(2).button(3) <= '1';
		inputs_i.jamma_n.p(2).button(4) <= '1';
		inputs_i.jamma_n.p(2).button(5) <= '1';

  
	-- not currently wired to any inputs
	inputs_i.jamma_n.coin_cnt <= (others => '1');
	inputs_i.jamma_n.coin(2) <= '1';
	inputs_i.jamma_n.service <= '1';
	inputs_i.jamma_n.tilt <= '1';
	inputs_i.jamma_n.test <= '1';
		
  BLK_VIDEO : block
  begin

    video_i.clk <= clkrst_i.clk(1);	-- by convention
    video_i.clk_ena <= '1';
    video_i.reset <= clkrst_i.rst(1);
    
    VGA_R_O <= video_o.rgb.r(video_o.rgb.r'left downto video_o.rgb.r'left-5);
    VGA_G_O <= video_o.rgb.g(video_o.rgb.g'left downto video_o.rgb.g'left-5);
    VGA_B_O <= video_o.rgb.b(video_o.rgb.b'left downto video_o.rgb.b'left-5);
    VGA_HS_O <= video_o.hsync;
    VGA_VS_O <= video_o.vsync;
 
  end block BLK_VIDEO;

  BLK_AUDIO : block
  begin
  
    dacl : entity work.sigma_delta_dac
      port map (
        clk     => CLOCK_27,
        din     => audio_o.ldata(15 downto 8),
        dout    => AUDIO_L
      );        

    dacr : entity work.sigma_delta_dac
      port map (
        clk     => CLOCK_27,
        din     => audio_o.rdata(15 downto 8),
        dout    => AUDIO_R
      );        

  end block BLK_AUDIO;
 
 pace_inst : entity work.pace                                            
   port map
   (
     -- clocks and resets
     clkrst_i					=> clkrst_i,

     -- misc inputs and outputs
     buttons_i         => buttons_i,
     switches_i        => switches_i,
     leds_o            => open,
     
     -- controller inputs
     inputs_i          => inputs_i,

       -- VGA video
      video_i           => video_i,
      video_o           => video_o,
      
      -- sound
      audio_i           => audio_i,
      audio_o           => audio_o,

      -- custom i/o
      project_i         => project_i,
      project_o         => project_o,
      platform_i        => platform_i,
      platform_o        => platform_o,
      target_i          => target_i,
      target_o          => target_o
    );
end SYN;
