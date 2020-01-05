---------------------------------------------------------------------------------
-- DE2-35 Top level for Phoenix by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity phoenix is
generic (
	C_test_picture: boolean := false;
	C_tile_rom: boolean := true; -- false: disable tile ROM to try game logic on small FPGA
	-- reduce ROMs: 14 is normal game, 13 will draw initial screen, 12 will repeatedly blink 1 line of garbage
	C_autofire: boolean := true;
	-- C_audio: boolean := true;
	C_prog_rom_addr_bits: integer range 12 to 14 := 14 
);
port(
	clk          : in std_logic; -- 11 MHz for TV, 25 MHz for VGA
	clk_28          : in std_logic;
	clk_ay          : in std_logic;
	reset        : in std_logic;
	ce_pix       : out std_logic;
	dip_switch   : in std_logic_vector(7 downto 0);
	-- game controls, normal logic '1':pressed, '0':released
 
	btn_coin: in std_logic;
	btn_player_start1: in std_logic;
	btn_player_start2: in std_logic;
	btn_fire, btn_le, btn_ri, btn_up, btn_dw: in std_logic;

	video_r      : out std_logic_vector(1 downto 0);
	video_g      : out std_logic_vector(1 downto 0);
	video_b      : out std_logic_vector(1 downto 0);
	video_vblank, video_hblank_bg, video_hblank_fg: out std_logic;
	video_hs     : out std_logic;
	video_vs     : out std_logic;

	audio        : out std_logic_vector(7 downto 0)
);
end phoenix;

architecture struct of phoenix is

 signal reset_n: std_logic;

 signal hcnt   : std_logic_vector(9 downto 1);
 signal vcnt   : std_logic_vector(8 downto 1);
 signal sync   : std_logic;
 signal adrsel : std_logic; 
 signal rdy    : std_logic := '1'; 
 signal vblank       : std_logic;
 signal hblank_bkgrd : std_logic;
 signal hblank_frgrd : std_logic; 
 signal ce_pix1 : std_logic;

 signal cpu_adr  : std_logic_vector(15 downto 0);
 signal cpu_di   : std_logic_vector( 7 downto 0);
 signal cpu_do   : std_logic_vector( 7 downto 0);
 signal cpu_wr_n : std_logic;
 signal prog_do  : std_logic_vector( 7 downto 0);
 signal S_prog_rom_addr : std_logic_vector(13 downto 0);

 signal frgnd_horz_cnt : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_horz_cnt : std_logic_vector(7 downto 0) := (others =>'0');
 signal vert_cnt       : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal bkgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal frgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal bkgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal frgnd_ram_we : std_logic := '0';
 signal bkgnd_ram_we : std_logic := '0';

 signal frgnd_graph_adr : std_logic_vector(10 downto 0) := (others =>'0');
 signal bkgnd_graph_adr : std_logic_vector(10 downto 0) := (others =>'0');
 signal palette_adr     : std_logic_vector( 7 downto 0) := (others =>'0'); 

 signal frgnd_clk : std_logic;
 signal bkgnd_clk : std_logic;

 signal frgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal frgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_bit0_graph_r : std_logic_vector(7 downto 0) := (others =>'0');
 signal frgnd_bit1_graph_r : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit0_graph_r : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit1_graph_r : std_logic_vector(7 downto 0) := (others =>'0');

 signal fr_bit0  : std_logic;
 signal fr_bit1  : std_logic;
 signal bk_bit0  : std_logic;
 signal bk_bit1  : std_logic;
 signal fr_lin   : std_logic_vector(2 downto 0);
 signal bk_lin   : std_logic_vector(2 downto 0);

 signal color_set : std_logic;
 signal color_id  : std_logic_vector(5 downto 0);
 signal rgb_0     : std_logic_vector(3 downto 0);
 signal rgb_1     : std_logic_vector(3 downto 0);

 signal player2      : std_logic := '0';
 signal pl2_cocktail : std_logic := '0';
 signal bkgnd_offset : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_a      : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_b      : std_logic_vector(7 downto 0) := (others =>'0');

 signal clk10 : std_logic;
 signal snd1  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal snd2  : std_logic_vector( 1 downto 0) := (others =>'0');
 signal snd3  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal song  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal mixed : std_logic_vector(11 downto 0) := (others =>'0');
 signal sound_string : std_logic_vector(31 downto 0);

 signal coin         : std_logic;
 signal player_start : std_logic_vector(1 downto 0);
 signal buttons      : std_logic_vector(3 downto 0);
 signal R_autofire   : std_logic_vector(21 downto 0);

 signal psg_cs    : std_logic;
 signal ay_ena    : std_logic;
 signal ay_do  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal ay_iob_do : std_logic_vector(7 downto 0);
 signal ay_ioa_di : std_logic_vector(7 downto 0);
 signal ay_bdir    : std_logic;
 signal ay_bc1    : std_logic;

begin

  video: entity work.phoenix_video
  port map
  (
    clk11    => clk,
	 ce_pix   => ce_pix1,
    hcnt     => hcnt,
    vcnt     => vcnt,
    sync_hs  => video_hs,
    sync_vs  => video_vs,
    adrsel   => adrsel, -- RAM address selector ('0')cpu / ('1')video_generator
    rdy      => rdy,    -- Ready ('1')cpu can access RAMs read/write 
    vblank   => vblank,
    hblank_frgrd => hblank_frgrd,
    hblank_bkgrd => hblank_bkgrd,
    reset    => reset
  );
  reset_n <= not reset;
  ce_pix <= ce_pix1;
  
-- microprocessor 8085
cpu8085 : entity work.T8080se
generic map
(
	Mode => 2,
	T2Write => 0
)
port map(
	RESET_n => reset_n,
	CLK     => clk,
	CLKEN  => '1', -- fixme: use it to make 5.5 MHz clock average
	READY  => rdy,
	HOLD  => '1',
	INT   => '1',
	INTE  => open,
	DBIN  => open,
	SYNC  => open, 
	VAIT  => open,
	HLDA  => open,
	WR_n  => cpu_wr_n,
	A     => cpu_adr,
	DI   => cpu_di,
	DO   => cpu_do
);

-- mux prog, ram, vblank, switch... to processor data bus in
cpu_di <= prog_do when cpu_adr(14) = '0' else
          frgnd_ram_do when cpu_adr(13 downto 10) = 2#00_00# else
          bkgnd_ram_do when cpu_adr(13 downto 10) = 2#00_10# else
			 ay_do when cpu_adr(13 downto 10) = 2#01_00# else
          btn_dw & btn_le & btn_ri & btn_up & btn_fire & btn_player_start2 & btn_player_start1 & coin when cpu_adr(13 downto 10) = 2#11_00# else
          not vblank & dip_switch(6 downto 0) when cpu_adr(13 downto 10) = 2#11_10# else
          prog_do;

-- write enable to RAMs from cpu
frgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(14 downto 10) = "10000" and adrsel = '0' else '0';
bkgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(14 downto 10) = "10010" and adrsel = '0' else '0';

-- RAMs address mux cpu/video_generator, bank0 for player1, bank1 for player2
frgnd_ram_adr <= player2 & cpu_adr(9 downto 0) when adrsel ='0' else player2 & vert_cnt(7 downto 3) & frgnd_horz_cnt(7 downto 3); 
bkgnd_ram_adr <= player2 & cpu_adr(9 downto 0) when adrsel ='0' else player2 & vert_cnt(7 downto 3) & bkgnd_horz_cnt(7 downto 3); 

-- demux cpu data to registers : background scrolling, sound control,
-- player id (1/2), palette color set. 
process (clk)
begin
 if rising_edge(clk) then
  if cpu_wr_n = '0' then
   case cpu_adr(14 downto 10) is
    when "10110" => bkgnd_offset <= cpu_do;
    when "11000" => sound_a      <= cpu_do;--address_w
--    when "11010" => sound_a      <= cpu_do;--data_w
    when "10100" => player2      <= cpu_do(0);
                    color_set    <= cpu_do(1);
    when others => null;
   end case;
  end if; 
 end if;
end process;

-- player2 and cocktail mode (flip horizontal/vertical)
pl2_cocktail <= player2 and dip_switch(7);

-- horizontal scan video RAMs address background and foreground
-- with flip and scroll offset
frgnd_horz_cnt <= hcnt(8 downto 1) when pl2_cocktail = '0' else not hcnt(8 downto 1);
bkgnd_horz_cnt <= frgnd_horz_cnt + bkgnd_offset;

-- vertical scan video RAMs address
vert_cnt <= vcnt(8 downto 1) when pl2_cocktail = '0' else not (vcnt(8 downto 1) + X"30");

-- get tile_ids from RAMs
frgnd_tile_id <= frgnd_ram_do;
bkgnd_tile_id <= bkgnd_ram_do; 

-- address graphix ROMs with tile_ids and line counter
frgnd_graph_adr <= frgnd_tile_id & vert_cnt(2 downto 0);
bkgnd_graph_adr <= bkgnd_tile_id & vert_cnt(2 downto 0);

-- latch foreground/background next graphix byte, high bit and low bit
-- and palette_ids (fr_lin, bklin)
process (clk)
begin
 if rising_edge(clk) then
  if (pl2_cocktail = '0' and (frgnd_horz_cnt(2 downto 0) = "111")) or
     (pl2_cocktail = '1' and (frgnd_horz_cnt(2 downto 0) = "000")) then
     frgnd_bit0_graph_r <= frgnd_bit0_graph;
     frgnd_bit1_graph_r <= frgnd_bit1_graph;
     fr_lin <= frgnd_tile_id(7 downto 5);
  end if;
  if (pl2_cocktail = '0' and (bkgnd_horz_cnt(2 downto 0) = "111")) or
     (pl2_cocktail = '1' and (bkgnd_horz_cnt(2 downto 0) = "000")) then  
     bkgnd_bit0_graph_r <= bkgnd_bit0_graph;
     bkgnd_bit1_graph_r <= bkgnd_bit1_graph;
     bk_lin <= bkgnd_tile_id(7 downto 5);
  end if;
 end if;
end process;

-- demux background and foreground pixel bits (0/1) from graphix byte with horizontal counter
-- and apply horizontal and vertical blanking
fr_bit0 <= frgnd_bit0_graph_r(to_integer(unsigned(frgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_frgrd)= '0' else '0'; 
fr_bit1 <= frgnd_bit1_graph_r(to_integer(unsigned(frgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_frgrd)= '0' else '0'; 
bk_bit0 <= bkgnd_bit0_graph_r(to_integer(unsigned(bkgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_bkgrd)= '0' else '0'; 
bk_bit1 <= bkgnd_bit1_graph_r(to_integer(unsigned(bkgnd_horz_cnt(2 downto 0)))) when (vblank or hblank_bkgrd)= '0' else '0'; 

-- select pixel bits and palette_id with foreground priority
color_id  <=  (fr_bit0 or fr_bit1) &  fr_bit1 & fr_bit0 & fr_lin when (fr_bit0 or fr_bit1) = '1' else
              (fr_bit0 or fr_bit1) &  bk_bit1 & bk_bit0 & bk_lin;

-- address palette with pixel bits color and color set
palette_adr <= '0' & color_set & color_id;

-- output video to top level
process(clk) begin
	if rising_edge(clk) then
		if ce_pix1='1' then
			video_vblank <= vblank;
			video_hblank_fg <= hblank_frgrd;
			video_hblank_bg <= hblank_bkgrd;
			if hcnt>=192 then
				video_r <= rgb_1(0) & rgb_0(0);
				video_g <= rgb_1(2) & rgb_0(2);
				video_b <= rgb_1(1) & rgb_0(1);
			else
				video_r <= "00";
				video_g <= "00";
				video_b <= "00";
			end if;
		end if;
	end if;
end process;

G_yes_tile_rom: if C_tile_rom generate
-- foreground graphix ROM bit0
frgnd_bit0 : entity work.prom_ic39
port map(
	clk  => clk,
	addr => frgnd_graph_adr,
	data => frgnd_bit0_graph
);

-- foreground graphix ROM bit1
frgnd_bit1 : entity work.prom_ic40
port map(
	clk  => clk,
	addr => frgnd_graph_adr,
	data => frgnd_bit1_graph
);

-- background graphix ROM bit0
bkgnd_bit0 : entity work.prom_ic23
port map(
	clk  => clk,
	addr => bkgnd_graph_adr,
	data => bkgnd_bit0_graph
);

-- background graphix ROM bit1
bkgnd_bit1 : entity work.prom_ic24
port map(
	clk  => clk,
	addr => bkgnd_graph_adr,
	data => bkgnd_bit1_graph
);

-- color palette ROM RBG low intensity
palette_0 : entity work.prom_palette_ic40
port map(
	clk  => clk,
	addr => palette_adr,
	data => rgb_0
);

-- color palette ROM RBG high intensity
palette_1 : entity work.prom_palette_ic41
port map(
	clk  => clk,
	addr => palette_adr,
	data => rgb_1
);
end generate;

G_no_tile_rom: if not C_tile_rom generate
	-- dummy replacement for missing tile ROMs
	frgnd_bit0_graph <= frgnd_graph_adr(10 downto 3);
	frgnd_bit1_graph <= "00000000";
	bkgnd_bit0_graph <= bkgnd_graph_adr(10 downto 3);
	bkgnd_bit1_graph <= "00000000";
	rgb_0 <= palette_adr(2 downto 0);
	rgb_1 <= palette_adr(2 downto 0);
end generate;

-- Program PROM
S_prog_rom_addr(C_prog_rom_addr_bits-1 downto 0) <= cpu_adr(C_prog_rom_addr_bits-1 downto 0);
prog : entity work.survival_prog
port map(
	clk  => clk,
	addr => S_prog_rom_addr,
	data => prog_do
);

-- foreground RAM   0x4000-0x433F
-- cpu working area 0x4340-0x43FF 
frgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
	clk  => clk,
	we   => frgnd_ram_we,
	addr => frgnd_ram_adr,
	d    => cpu_do,
	q    => frgnd_ram_do
);

-- background RAM   0x4800-0x4B3F
-- cpu working area 0x4B40-0x4BFF 
-- stack pointer downward from 0x4BFF
bkgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
	clk  => clk,
	we   => bkgnd_ram_we,
	addr => bkgnd_ram_adr,
	d    => cpu_do,
	q    => bkgnd_ram_do
);

-- bdir bc1 (bc2 = 1)
--  0    0 : Inactive
--  0    1 : Read
--  1    0 : Write
--  1    1 : Address
--ay_ioa_di <= not sw2(to_integer(unsigned(ay_iob_do(3 downto 1)))) & "000" & not sw1;

ay_bdir <= '1' when cpu_wr_n = '0' else '0';
ay_bc1  <= '1' when ((cpu_wr_n = '1' and cpu_adr(0) = '0')) else '0';
psg_cs <= '1' when cpu_adr(15 downto 10) = "110100" else '0';--110100000000000
ym2149 : entity work.ym2149											 --110100100000000
port map (
-- data bus
	I_DA            => cpu_do,       --: in  std_logic_vector(7 downto 0);
	O_DA            => ay_do,        --: out std_logic_vector(7 downto 0);
	O_DA_OE_L       => open,         --: out std_logic;
-- control
	I_A9_L          => '1',         --: in  std_logic;
	I_A8            => '1',          --: in  std_logic;
	I_BDIR          => ay_bdir,      --: in  std_logic;
	I_BC2           => '1',          --: in  std_logic;
	I_BC1           => ay_bc1,       --: in  std_logic;
	I_SEL_L         => '1',          --: in  std_logic;
-- audio
	O_AUDIO         => audio,     --: out std_logic_vector(7 downto 0);
-- port a
	I_IOA           => ay_ioa_di,    --: in  std_logic_vector(7 downto 0);
	O_IOA           => open,         --: out std_logic_vector(7 downto 0);
	O_IOA_OE_L      => open,         --: out std_logic;
-- port b
	I_IOB           => "11111111",   --: in  std_logic_vector(7 downto 0);
	O_IOB           => ay_iob_do,    --: out std_logic_vector(7 downto 0);
	O_IOB_OE_L      => open,         --: out std_logic;

	ENA             => '1',       --: in  std_logic; -- clock enable for higher speed operation
	RESET_L         => '1',          --: in  std_logic;
	CLK             => clk_ay
);

end struct;
