library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pace_pkg.all;
use work.sdram_pkg.all;
use work.video_controller_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;
use work.target_pkg.all;

entity target_top is
  port
    (
		clock_30   : in std_logic;
		clock_v    : in std_logic;
		clock_3p58 : in std_logic;
		reset      : in std_logic;

		dn_addr    : in  std_logic_vector(15 downto 0);
		dn_data    : in  std_logic_vector(7 downto 0);
		dn_wr      : in  std_logic;

      AUDIO      : out signed(12 downto 0);
		JOY        : in std_logic_vector(7 downto 0);
		JOY2        : in std_logic_vector(7 downto 0);

      VGA_VBLANK : out std_logic;
      VGA_HBLANK : out std_logic;

      VGA_VS     : out std_logic;
      VGA_HS     : out std_logic;
      VGA_R      : out std_logic_vector(3 downto 0);
      VGA_G      : out std_logic_vector(3 downto 0);
      VGA_B      : out std_logic_vector(3 downto 0)
  );
end target_top;

architecture SYN of target_top is

  signal clkrst_i       : from_CLKRST_t;
  signal buttons_i      : from_BUTTONS_t;
  signal switches_i     : from_SWITCHES_t;
  signal leds_o         : to_LEDS_t;
  signal inputs_i       : from_INPUTS_t;
  signal flash_i        : from_FLASH_t;
  signal flash_o        : to_FLASH_t;
  signal sram_i			: from_SRAM_t;
  signal sram_o			: to_SRAM_t;	
  signal sdram_i        : from_SDRAM_t;
  signal sdram_o        : to_SDRAM_t;
  signal video_i        : from_VIDEO_t;
  signal video_o        : to_VIDEO_t;
  signal audio_i        : from_AUDIO_t;
  signal audio_o        : to_AUDIO_t;
  signal ser_i          : from_SERIAL_t;
  signal ser_o          : to_SERIAL_t;
  signal project_i      : from_PROJECT_IO_t;
  signal project_o      : to_PROJECT_IO_t;
  signal platform_i     : from_PLATFORM_IO_t;
  signal platform_o     : to_PLATFORM_IO_t;
  signal target_i       : from_TARGET_IO_t;
  signal target_o       : to_TARGET_IO_t;

  signal sound_data     : std_logic_vector(7 downto 0);
begin

  clkrst_i.clk(0)<=clock_30;
  clkrst_i.clk(1)<=clock_v;

  clkrst_i.arst <= reset;
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

	inputs_i.jamma_n.coin(1) <= JOY(7);
	inputs_i.jamma_n.p(1).start <= JOY(6);

	inputs_i.jamma_n.coin(2) <= JOY2(7);
	inputs_i.jamma_n.p(2).start <= JOY2(6);
	
	inputs_i.jamma_n.p(1).up <= not JOY(3);
	inputs_i.jamma_n.p(1).down <= not JOY(2);
	inputs_i.jamma_n.p(1).left <= not JOY(1);
	inputs_i.jamma_n.p(1).right <= not JOY(0);
	
	inputs_i.jamma_n.p(1).button(1) <= not JOY(4);
	inputs_i.jamma_n.p(1).button(2) <= not JOY(5);
	inputs_i.jamma_n.p(1).button(3) <= '1';
	inputs_i.jamma_n.p(1).button(4) <= '1';
	inputs_i.jamma_n.p(1).button(5) <= '1';
	
	inputs_i.jamma_n.p(2).up <= not JOY2(3);
	inputs_i.jamma_n.p(2).down <= not JOY2(2);
	inputs_i.jamma_n.p(2).left <= not JOY2(1);
	inputs_i.jamma_n.p(2).right <= not JOY2(0);
	
	inputs_i.jamma_n.p(2).button(1) <= not JOY2(4);
	inputs_i.jamma_n.p(2).button(2) <= not JOY2(5);
	inputs_i.jamma_n.p(2).button(3) <= '1';
	inputs_i.jamma_n.p(2).button(4) <= '1';
	inputs_i.jamma_n.p(2).button(5) <= '1';

  
	-- not currently wired to any inputs
	inputs_i.jamma_n.coin_cnt <= (others => '1');
	--inputs_i.jamma_n.coin(2) <= '1';
	inputs_i.jamma_n.service <= '1';
	inputs_i.jamma_n.tilt <= '1';
	inputs_i.jamma_n.test <= '1';
		
    video_i.clk <= clkrst_i.clk(1);	-- by convention
    video_i.clk_ena <= '1';
    video_i.reset <= clkrst_i.rst(1);

    VGA_R <= video_o.rgb.r(9 downto 6);
    VGA_G <= video_o.rgb.g(9 downto 6);
    VGA_B <= video_o.rgb.b(9 downto 6);
    VGA_HS <= video_o.hsync;
    VGA_VS <= video_o.vsync;
	 VGA_HBLANK <= video_o.hblank;
	 VGA_VBLANK <= video_o.vblank;
 
 pace_inst : entity work.pace                                            
   port map
   (
     -- clocks and resets
     clkrst_i		 => clkrst_i,

     -- misc inputs and outputs
     buttons_i     => buttons_i,
     switches_i    => switches_i,
     leds_o        => open,
     
     -- controller inputs
     inputs_i      => inputs_i,

     	-- external ROM/RAM
     flash_i       => flash_i,
     flash_o       => flash_o,
     sram_i        => sram_i,
     sram_o        => sram_o,
     sdram_i       => sdram_i,
     sdram_o       => sdram_o,
  
      -- VGA video
      video_i      => video_i,
      video_o      => video_o,
      
      -- sound
      audio_i      => audio_i,
      audio_o      => audio_o,

      -- SPI (flash)
      spi_i.din    => '0',
      spi_o        => open,
  
      -- serial
      ser_i        => ser_i,
      ser_o        => ser_o,
      
		sound_data_o => sound_data,

		dn_addr      => dn_addr,
		dn_data      => dn_data,
		dn_wr        => dn_wr,

      -- custom i/o
      project_i    => project_i,
      project_o    => project_o,
      platform_i   => platform_i,
      platform_o   => platform_o,
      target_i     => target_i,
      target_o     => target_o
    );

	moon_patrol_sound_board : entity work.moon_patrol_sound_board
	port map(
		clock_3p58   => clock_3p58,
		reset        => reset,
	 
		clock_30     => clock_30,
		dn_addr      => dn_addr,
		dn_data      => dn_data,
		dn_wr        => dn_wr,

		select_sound => sound_data,
		audio_out    => AUDIO
	);

end SYN;
