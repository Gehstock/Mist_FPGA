---------------------------------------------------------------------------------
-- DE2-35 Top level for Phoenix by Dar (darfpga@aol.fr) (April 2016)
-- http://darfpga.blogspot.fr
--
-- Main features
--  PS2 keyboard input
--  wm8731 sound output
--  NO board SRAM used
--
-- sw 0: on/off hdmi-audio
--
-- Board switch : ---- todo fixme switches note
--   1 - 4 : dip switch
--             0-1 : lives 3-6
--             3-2 : bonus life 30K-60K
--               4 : coin 1-2
--             6-5 : unkonwn
--               7 : upright-cocktail  
--   8 -10 : sound_select
--             0XX : all mixed (normal)
--             100 : sound1 only 
--             101 : sound2 only
--             110 : sound3 only
--             111 : melody only 
-- Board key :
--      0 : reset
--   
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix_mist is
port
(
	CLOCK_27			: in std_logic;
	LED				: out std_logic;
	VGA_R				: out std_logic_vector(5 downto 0); 
	VGA_G				: out std_logic_vector(5 downto 0);
	VGA_B				: out std_logic_vector(5 downto 0);
	VGA_HS			: out std_logic;
	VGA_VS			: out std_logic;
	SPI_SCK 			: in std_logic;
	SPI_DI 			: in std_logic;
	SPI_DO 			: out std_logic;
	SPI_SS2 			: in std_logic;
	SPI_SS3 			: in std_logic;
	CONF_DATA0		: in std_logic;
	AUDIO_L 			: out std_logic;
	AUDIO_R 			: out std_logic
);
end;

architecture struct of phoenix_mist is

  signal clk          : std_logic;
  signal clk_88m      : std_logic;
  signal reset        : std_logic;
  signal clock_stable : std_logic;

  signal audio        : std_logic_vector(11 downto 0);
  signal video_r, video_g, video_b: std_logic_vector(1 downto 0);
  signal vsync, hsync : std_logic;

  signal dip_switch   : std_logic_vector(7 downto 0);-- := (others => '0');
  signal status       : std_logic_vector(31 downto 0);
  signal buttons      : std_logic_vector(1 downto 0);
  signal scandoubler_disable : std_logic;
  signal ypbpr        : std_logic;
  signal ce_pix       : std_logic;
  
  signal scanlines    : std_logic_vector(1 downto 0);
  signal hq2x         : std_logic;

  signal coin         : std_logic;
  signal player_start : std_logic_vector(1 downto 0);
  signal button_left, button_right, button_protect, button_fire: std_logic;
  signal joy0         : std_logic_vector(7 downto 0);
  signal joy1         : std_logic_vector(7 downto 0);
  signal ps2Clk       : std_logic;
  signal ps2Data      : std_logic;
  signal kbd_joy     : std_logic_vector(7 downto 0);
  signal upjoyL      : std_logic;
  signal upjoyR      : std_logic;
  signal upjoyB      : std_logic;
-- config string used by the io controller to fill the OSD
  constant CONF_STR : string := "PHOENIX;;O4,Screen Direction,Upright,Normal;O67,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;T5,Reset;V,v1.1;";

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

   component mist_io
		generic ( STRLEN : integer := 0 );
		port (
			clk_sys :in std_logic;
			SPI_SCK, CONF_DATA0, SPI_DI :in std_logic;
			SPI_DO : out std_logic;
			conf_str : in std_logic_vector(8*STRLEN-1 downto 0);
			buttons : out std_logic_vector(1 downto 0);
			joystick_0 : out std_logic_vector(7 downto 0);
			joystick_1 : out std_logic_vector(7 downto 0);
			status : out std_logic_vector(31 downto 0);
			scandoubler_disable, ypbpr : out std_logic;
			ps2_kbd_clk : out std_logic;
			ps2_kbd_data : out std_logic
		);
	end component mist_io;

	component video_mixer
		generic ( LINE_LENGTH : integer := 352; HALF_DEPTH : integer := 1 );
		port (
			clk_sys, ce_pix, ce_pix_actual : in std_logic;
			SPI_SCK, SPI_SS3, SPI_DI : in std_logic;
			scanlines : in std_logic_vector(1 downto 0);
			scandoubler_disable, hq2x, ypbpr, ypbpr_full : in std_logic;
			rotate : in std_logic_vector(1 downto 0);
			R, G, B : in std_logic_vector(2 downto 0);
			HSync, VSync, line_start, mono : in std_logic;

			VGA_R,VGA_G, VGA_B : out std_logic_vector(5 downto 0);
			VGA_VS, VGA_HS : out std_logic
		);
	end component video_mixer;

   component keyboard
		PORT(
			clk : in std_logic;
			reset : in std_logic;
			ps2_kbd_clk : in std_logic;
			ps2_kbd_data : in std_logic;
			joystick : out std_logic_vector (7 downto 0)
		);
	end component;


begin
 
--   SWITCH 1:     SWITCH 2:    NUMBER OF SPACESHIPS:
--   ---------     ---------    ---------------------
--     OFF           OFF                  6
--     ON            OFF                  5
--     OFF           ON                   4
--     ON            ON                   3
--                               FIRST FREE     SECOND FREE
--   SWITCH 3:     SWITCH 4:     SHIP SCORE:    SHIP SCORE:
--  ---------     ---------     -----------    -----------
--     OFF           OFF           6,000          60,000
--     ON            OFF           5,000          50,000
--     OFF           ON            4,000          40,000
--     ON            ON            3,000          30,000
 
	--Cocktail,Factory,Factory,Factory,Bonus2,Bonus1,Ships2,Ships1
	dip_switch <= "00001111";

	mist_io_inst : mist_io
	generic map (STRLEN => CONF_STR'length)
	port map (
		clk_sys => clk,
		SPI_SCK => SPI_SCK,
		CONF_DATA0 => CONF_DATA0,
		SPI_DI => SPI_DI,
		SPI_DO => SPI_DO,
		conf_str => to_slv(CONF_STR),
		buttons  => buttons,
		scandoubler_disable => scandoubler_disable,
		ypbpr => ypbpr,
		joystick_1 => joy1,
		joystick_0 => joy0,
		status => status,
		ps2_kbd_clk => ps2Clk,
		ps2_kbd_data => ps2Data
	);

  --
  -- Audio
  --
	u_dac1 : entity work.dac
	port  map(
		clk_i   => clk_88m,
		res_n_i => not reset,
		dac_i   => audio,
		dac_o   => AUDIO_L
	);
	 
	u_dac2 : entity work.dac
	port  map(
		clk_i   => clk_88m,
		res_n_i => not reset,
		dac_i   => audio,
		dac_o   => AUDIO_R
	);
    
 
	pll: entity work.pll27
	port map(
      inclk0 => CLOCK_27, 
		c0 => clk_88m,
		c1 => clk,
      locked => clock_stable
	);

	reset <= status(0) or status(5) or buttons(1) or not clock_stable; 

	u_keyboard : keyboard
	port  map(
		clk 				=> clk,
		reset 			=> reset,
		ps2_kbd_clk 	=> ps2Clk,
		ps2_kbd_data 	=> ps2Data,
		joystick 		=> kbd_joy
	);

	process(clk_88m)
		variable cnt: integer range 0 to 6000000 := 0;
	begin
		if rising_edge(clk_88m) then
			if status(3 downto 1) /= "000" then
				cnt  :=  0;
				coin <= status(1);
				player_start <= status(3 downto 2);
			else
				if cnt < 6000000 then
					cnt := cnt + 1;
				else
					coin <= '0';
					player_start <= "00";
				end if;
			end if;
		end if;
	end process;

		upjoyB <= joy0(2) or joy1(2) when status(4) = '0' else joy0(0) or joy1(0);
		upjoyL <= joy0(1) or joy1(1) or kbd_joy(6) when status(4) = '0' else joy0(2) or joy1(2) or kbd_joy(5);
		upjoyR <= joy0(0) or joy1(0) or kbd_joy(7) when status(4) = '0' else joy0(3) or joy1(3) or kbd_joy(4);
		
	phoenix : entity work.phoenix
	port map
	(
		clk          => clk,
		reset        => reset,
		ce_pix       => ce_pix,
		dip_switch   => dip_switch,
		btn_coin     => kbd_joy(3) or coin,--ESC
		btn_player_start(0) => kbd_joy(1) or player_start(0),--1
		btn_player_start(1) => kbd_joy(2) or player_start(1),--2 
		btn_left     => upjoyL,
		btn_right    => upjoyR,
		btn_barrier  => upjoyB or kbd_joy(2),--TAB
		btn_fire     => joy0(4) or joy1(4) or kbd_joy(0),--space
		video_r      => video_r,
		video_g      => video_g,
		video_b      => video_b,
		video_hs     => hsync,
		video_vs     => vsync,
		audio_select => "000",
		audio        => audio
	);

	scanlines(0) <= '1' when status(7 downto 6) = "10" else '0';
	scanlines(1) <= '1' when status(7 downto 6) = "11" else '0';
	hq2x         <= '1' when status(7 downto 6) = "01" else '0';

	vmixer : video_mixer
	port map (
		clk_sys => clk_88m,
		ce_pix  => ce_pix,
		ce_pix_actual => ce_pix,

		SPI_SCK => SPI_SCK,
		SPI_SS3 => SPI_SS3,
		SPI_DI => SPI_DI,
		rotate => '1' & not status(4),
		scanlines => scanlines,
		scandoubler_disable => scandoubler_disable,
		hq2x => hq2x,
		ypbpr => ypbpr,
		ypbpr_full => '1',

		R => video_r & video_r(1),
		G => video_g & video_g(1),
		B => video_b & video_b(1),
		HSync => hsync,
		VSync => vsync,
		line_start => '0',
		mono => '0',

		VGA_R => VGA_R,
		VGA_G => VGA_G,
		VGA_B => VGA_B,
		VGA_VS => VGA_VS,
		VGA_HS => VGA_HS
	);

	LED <= '1';

end struct;
