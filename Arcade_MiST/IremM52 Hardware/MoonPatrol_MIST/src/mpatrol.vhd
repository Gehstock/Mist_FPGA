library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;

use work.build_id.all;

entity mpatrol is
  port
    (
      CLOCK_27      	: in std_logic;
      SPI_SCK 			: in std_logic;
      SPI_DI 			: in std_logic;
		SPI_SS2 			: in std_logic;
		SPI_SS3 			: in std_logic;
		SPI_SS4 			: in std_logic;
      SPI_DO 			: out std_logic;
		LED 				: out std_logic;
      CONF_DATA0 		: in std_logic;
      AUDIO_L        : out std_logic;
      AUDIO_R        : out std_logic;
      VGA_VS        	: out std_logic;
      VGA_HS        	: out std_logic;
      VGA_R         	: out std_logic_vector(5 downto 0);
      VGA_G         	: out std_logic_vector(5 downto 0);
      VGA_B         	: out std_logic_vector(5 downto 0)
  );    
  
end mpatrol;

architecture SYN of mpatrol is

  signal init       		: std_logic := '1';  
  signal clk_sys        : std_logic;
  signal clk_aud        : std_logic;
  signal clk_vid        : std_logic;
  signal rst_audD       : std_logic;
  signal rst_aud        : std_logic;
  signal clkrst_i       : from_CLKRST_t;
  signal buttons_i      : from_BUTTONS_t;
  signal switches_i     : from_SWITCHES_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;
  --MIST
  signal audio       	: std_logic;
  signal status     		: std_logic_vector(31 downto 0); 
  signal joystick1      : std_logic_vector(7 downto 0);
  signal joystick2      : std_logic_vector(7 downto 0);
  signal joystick       : std_logic_vector(7 downto 0);
  signal kbd_joy 			: std_logic_vector(9 downto 0);	 
  signal switches       : std_logic_vector(1 downto 0);
  signal buttons        : std_logic_vector(1 downto 0);
  signal ps2_kbd_clk    : std_logic;
  signal ps2_kbd_data	: std_logic;
  signal scandoubler_disable   : std_logic;
  signal ypbpr  		: std_logic;
  signal reset 			: std_logic;  
  signal audio_out 		: std_logic_vector(11 downto 0);
  signal sound_data     : std_logic_vector(7 downto 0);
  
  signal sd_r         : std_logic_vector(5 downto 0);
  signal sd_g         : std_logic_vector(5 downto 0);
  signal sd_b         : std_logic_vector(5 downto 0);
  signal sd_hs        : std_logic;
  signal sd_vs        : std_logic;

  signal osd_red_i    : std_logic_vector(5 downto 0);
  signal osd_green_i  : std_logic_vector(5 downto 0);
  signal osd_blue_i   : std_logic_vector(5 downto 0);
  signal osd_vs_i     : std_logic;
  signal osd_hs_i     : std_logic;
  signal osd_red_o    : std_logic_vector(5 downto 0);
  signal osd_green_o  : std_logic_vector(5 downto 0);
  signal osd_blue_o   : std_logic_vector(5 downto 0);
  signal vga_y_o      : std_logic_vector(5 downto 0);
  signal vga_pb_o     : std_logic_vector(5 downto 0);
  signal vga_pr_o     : std_logic_vector(5 downto 0);  

  constant CONF_STR : string :=
	"MPATROL;;"&
	"O12,Scandoubler Fx,None,CRT 25%,CRT 50%,CRT 75%;"&
	"O34,Patrol cars,5,3,2,1;"&
	"O56,New car at,10/30/50K,20/40/60K,10K,Never;"&
	"OA,Freeze,Disable,Enable;"&
	"O7,Demo mode,Off,On;"&
	"O8,Sector selection,Off,On;"&
	"O9,Test mode,Off,On;"&
	"T0,Reset;"&
	"V,v"&BUILD_DATE;

  -- convert string to std_logic_vector to be given to user_io
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

component keyboard
   port  (
		clk						:in STD_LOGIC;
		reset						:in STD_LOGIC;
		ps2_kbd_clk				:in STD_LOGIC;
		ps2_kbd_data			:in STD_LOGIC;
		joystick					:out STD_LOGIC_VECTOR(9 downto 0));
end component;
  
component user_io
	generic ( STRLEN : integer := 0 );
	port  (
		clk_sys             :  in STD_LOGIC;
		conf_str            :  in std_logic_vector(8*STRLEN-1 downto 0);
		SPI_CLK             :  in STD_LOGIC;
		SPI_SS_IO           :  in STD_LOGIC;
		SPI_MOSI            :  in STD_LOGIC;
		SPI_MISO            : out STD_LOGIC;
		switches            : out STD_LOGIC_VECTOR(1 downto 0);
		buttons             : out STD_LOGIC_VECTOR(1 downto 0);
		scandoubler_disable : out STD_LOGIC;
		ypbpr  				: out STD_LOGIC;
		joystick_1          : out STD_LOGIC_VECTOR(7 downto 0);
		joystick_0          : out STD_LOGIC_VECTOR(7 downto 0);
		status              : out STD_LOGIC_VECTOR(31 downto 0);
		ps2_kbd_clk         : out STD_LOGIC;
		ps2_kbd_data        : out STD_LOGIC);
end component;

component scandoubler
	port (
		clk_sys     : in std_logic;
		scanlines   : in std_logic_vector(1 downto 0);

		hs_in       : in std_logic;
		vs_in       : in std_logic;
		r_in        : in std_logic_vector(5 downto 0);
		g_in        : in std_logic_vector(5 downto 0);
		b_in        : in std_logic_vector(5 downto 0);

		hs_out      : out std_logic;
		vs_out      : out std_logic;
		r_out       : out std_logic_vector(5 downto 0);
		g_out       : out std_logic_vector(5 downto 0);
		b_out       : out std_logic_vector(5 downto 0)
	);
end component scandoubler;

component osd
	generic ( OSD_COLOR : integer := 1 );  -- blue
	port (
		clk_sys     : in std_logic;

		R_in        : in std_logic_vector(5 downto 0);
		G_in        : in std_logic_vector(5 downto 0);
		B_in        : in std_logic_vector(5 downto 0);
		HSync       : in std_logic;
		VSync       : in std_logic;

		R_out       : out std_logic_vector(5 downto 0);
		G_out       : out std_logic_vector(5 downto 0);
		B_out       : out std_logic_vector(5 downto 0);

		SPI_SCK     : in std_logic;
		SPI_SS3     : in std_logic;
		SPI_DI      : in std_logic
	);
end component osd;

COMPONENT rgb2ypbpr
	PORT (
		red     :        IN std_logic_vector(5 DOWNTO 0);
		green   :        IN std_logic_vector(5 DOWNTO 0);
		blue    :        IN std_logic_vector(5 DOWNTO 0);
		y       :        OUT std_logic_vector(5 DOWNTO 0);
		pb      :        OUT std_logic_vector(5 DOWNTO 0);
		pr      :        OUT std_logic_vector(5 DOWNTO 0)
	);
END COMPONENT;

begin

--CLOCK
Clock_inst : entity work.Clock
	port map (
		inclk0  => CLOCK_27,
		c0      => clk_aud,    -- 3.58/4
		c1      => clk_sys,    -- 6
		c2      => clk_vid     -- 24
	);

	clkrst_i.clk(0)	<=	clk_sys;
	clkrst_i.clk(1)	<=	clk_sys;

	video_i.clk     <= clk_sys;
	video_i.clk_ena <= '1';
	video_i.reset 	<= clkrst_i.rst(1);

--RESET
	process (clk_sys)
		variable count : std_logic_vector (11 downto 0) := (others => '0');
	begin
		if rising_edge(clk_sys) then
			if count = X"FFF" then
				init <= '0';
			else
				count := count + 1;
				init <= '1';
			end if;
		end if;
	end process;

	process (clk_sys) begin
		if rising_edge(clk_sys) then
			clkrst_i.arst    <= init or status(0) or buttons(1);
			clkrst_i.arst_n  <= not clkrst_i.arst;
		end if;
	end process;

	process (clk_aud) begin
		if rising_edge(clk_aud) then
			rst_audD <= clkrst_i.arst;
			rst_aud  <= rst_audD;
		end if;
	end process;

  GEN_RESETS : for i in 0 to 3 generate

    process (clkrst_i)
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
	 
user_io_inst : user_io
	generic map (STRLEN => CONF_STR'length)
	port map (
		clk_sys             => clk_sys,
		conf_str            => to_slv(CONF_STR),
		SPI_CLK             => SPI_SCK,
		SPI_SS_IO           => CONF_DATA0,
		SPI_MOSI            => SPI_DI,
		SPI_MISO            => SPI_DO,
		switches            => switches,
		buttons             => buttons,
		scandoubler_disable => scandoubler_disable,
		ypbpr               => ypbpr,
		joystick_1          => joystick2,
		joystick_0          => joystick1,
		status              => status,
		ps2_kbd_clk         => ps2_kbd_clk,
		ps2_kbd_data        => ps2_kbd_data
    );

u_keyboard : keyboard
	port  map(
		clk 				=> clk_sys,
		reset 			=> '0',
		ps2_kbd_clk 	=> ps2_kbd_clk,
		ps2_kbd_data 	=> ps2_kbd_data,
		joystick 		=> kbd_joy
);

		joystick <= joystick1 or joystick2;

		inputs_i.jamma_n.coin(1) <= not (joystick(6) or kbd_joy(3));--ESC
		inputs_i.jamma_n.p(1).start <= not (kbd_joy(1) or joystick1(7));--KB 1
		inputs_i.jamma_n.p(1).up <= not (joystick(3) or kbd_joy(4));
		inputs_i.jamma_n.p(1).down <= not (joystick(2) or kbd_joy(5));
		inputs_i.jamma_n.p(1).left <= not (joystick(1) or kbd_joy(6));
		inputs_i.jamma_n.p(1).right <= not (joystick(0) or kbd_joy(7));
		inputs_i.jamma_n.p(1).button(1) <= not (joystick(4) or kbd_joy(0));--Fire
		inputs_i.jamma_n.p(1).button(2) <= not (joystick(5) or kbd_joy(8) or joystick(3) or kbd_joy(4));--Jump
		inputs_i.jamma_n.p(1).button(3) <= '1';
		inputs_i.jamma_n.p(1).button(4) <= '1';
		inputs_i.jamma_n.p(1).button(5) <= '1';		
		inputs_i.jamma_n.p(2).start <= not (kbd_joy(2) or joystick2(7));--KB 2
		inputs_i.jamma_n.p(2).up <= not (joystick(3) or kbd_joy(4));
		inputs_i.jamma_n.p(2).down <= not (joystick(2) or kbd_joy(5));
		inputs_i.jamma_n.p(2).left <= not (joystick(1) or kbd_joy(6));
		inputs_i.jamma_n.p(2).right <= not (joystick(0) or kbd_joy(7));
		inputs_i.jamma_n.p(2).button(1) <= not (joystick(4) or kbd_joy(0));--Fire
		inputs_i.jamma_n.p(2).button(2) <= not (joystick(5) or kbd_joy(8) or joystick(3) or kbd_joy(4)); --Jump
		inputs_i.jamma_n.p(2).button(3) <= '1';
		inputs_i.jamma_n.p(2).button(4) <= '1';
		inputs_i.jamma_n.p(2).button(5) <= '1';
		-- not currently wired to any inputs
		inputs_i.jamma_n.coin_cnt <= (others => '1');
		inputs_i.jamma_n.coin(2) <= '1';
		inputs_i.jamma_n.service <= '1';
		inputs_i.jamma_n.tilt <= '1';
		inputs_i.jamma_n.test <= '1';

  LED <= '1';
  
moon_patrol_sound_board : entity work.moon_patrol_sound_board
	port map(
		clock_E    		=> clk_aud,
		reset     		=> rst_aud,
		select_sound  	=> sound_data,
		audio_out     	=> audio_out,
		dbg_cpu_addr  	=> open
	);  
  
dac : entity work.dac
	port map (
		clk_i     => clk_aud,
		res_n_i   => not rst_aud,
		dac_i     => audio_out,
		dac_o     => audio
   );

AUDIO_R <= audio;
AUDIO_L <= audio; 		

switches_i(15) <= not status(9); -- Test mode
switches_i(14) <= not status(7);
switches_i(13) <= not status(8); -- Sector select
switches_i(12) <= not status(10);-- Freeze enable
switches_i(11 downto 8) <= "1100";
switches_i( 7 downto 4) <= "1111";
switches_i( 1 downto 0) <= not status(4 downto 3); -- Patrol cars
switches_i( 3 downto 2) <= not status(6 downto 5); -- New car

pace_inst : entity work.pace                                            
	port map (
		clkrst_i				=> clkrst_i,
		buttons_i         => buttons_i,
		switches_i        => switches_i,
		leds_o            => open,
		inputs_i          => inputs_i,
		video_i           => video_i,
		video_o           => video_o,
		sound_data_o 		=> sound_data
	);

scandoubler_inst: scandoubler
	port map (
		clk_sys     => clk_vid,
		scanlines   => status(2 downto 1),

		hs_in       => video_o.hsync,
		vs_in       => video_o.vsync,
		r_in        => video_o.rgb.r(9 downto 4),
		g_in        => video_o.rgb.g(9 downto 4),
		b_in        => video_o.rgb.b(9 downto 4),

		hs_out      => sd_hs,
		vs_out      => sd_vs,
		r_out       => sd_r,
		g_out       => sd_g,
		b_out       => sd_b
	);

osd_inst: osd
	port map (
		clk_sys     => clk_vid,

		SPI_SCK     => SPI_SCK,
		SPI_SS3     => SPI_SS3,
		SPI_DI      => SPI_DI,

		R_in        => osd_red_i,
		G_in        => osd_green_i,
		B_in        => osd_blue_i,
		HSync       => osd_hs_i,
		VSync       => osd_vs_i,

		R_out       => osd_red_o,
		G_out       => osd_green_o,
		B_out       => osd_blue_o
	);

rgb2component: component rgb2ypbpr
	port map (
		red => osd_red_o,
		green => osd_green_o,
		blue => osd_blue_o,
		y => vga_y_o,
		pb => vga_pb_o,
		pr => vga_pr_o
	);

osd_red_i   <= video_o.rgb.r(9 downto 4) when scandoubler_disable = '1' else sd_r;
osd_green_i <= video_o.rgb.g(9 downto 4) when scandoubler_disable = '1' else sd_g;
osd_blue_i  <= video_o.rgb.b(9 downto 4) when scandoubler_disable = '1' else sd_b;
osd_hs_i    <= video_o.hsync when scandoubler_disable = '1' else sd_hs;
osd_vs_i    <= video_o.vsync when scandoubler_disable = '1' else sd_vs;

 -- If 15kHz Video - composite sync to VGA_HS and VGA_VS high for MiST RGB cable
VGA_HS <= not (video_o.hsync xor video_o.vsync) when scandoubler_disable='1' else not (sd_hs xor sd_vs) when ypbpr='1' else sd_hs;
VGA_VS <= '1' when scandoubler_disable='1' or ypbpr='1' else sd_vs;
VGA_R <= vga_pr_o when ypbpr='1' else osd_red_o;
VGA_G <= vga_y_o  when ypbpr='1' else osd_green_o;
VGA_B <= vga_pb_o when ypbpr='1' else osd_blue_o;
--
end SYN;
