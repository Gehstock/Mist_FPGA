---------------------------------------------------------------------------------
-- Naughty Boy by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy is
port(
 clock_12     : in std_logic;
 reset        : in std_logic;
 
 dn_addr      : in  std_logic_vector(15 downto 0);
 dn_data      : in  std_logic_vector(7 downto 0);
 dn_wr        : in  std_logic;
 
 dip_switch   : in std_logic_vector(7 downto 0);
 flip_screen  : in std_logic;
 game_mod	  : in std_logic_vector(1 downto 0);
 coin         : in std_logic;
 starts       : in std_logic_vector(1 downto 0);
 player1_btns : in std_logic_vector(4 downto 0);
 player2_btns : in std_logic_vector(4 downto 0);
 video_r      : out std_logic_vector(1 downto 0);
 video_g      : out std_logic_vector(1 downto 0);
 video_b      : out std_logic_vector(1 downto 0);
 video_csync  : out std_logic;
 video_hs     : out std_logic;
 video_vs     : out std_logic;
 video_hblank : out std_logic;
 video_vblank : out std_logic; 
 ce_pix       : inout std_logic;
 audio        : out std_logic_vector(11 downto 0)
);
end naughty_boy;

architecture struct of naughty_boy is

 signal reset_n: std_logic;

 signal clock_12n : std_logic;
 signal hcnt      : std_logic_vector(8 downto 0);
 signal hcnt_1r   : std_logic;
 signal ena_pix   : std_logic;
 signal vcnt      : std_logic_vector(7 downto 0);
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 
 signal rdy           : std_logic; 
 signal cpu_wait      : std_logic; 
 signal sel_cpu_addr  : std_logic; 
 signal sel_scrl_addr : std_logic;  
 signal hblank        : std_logic;
 signal vblank        : std_logic;
  
 signal cpu_ena  : std_logic;
 signal cpu_adr  : std_logic_vector(15 downto 0);
 signal cpu_di   : std_logic_vector( 7 downto 0);
 signal cpu_do   : std_logic_vector( 7 downto 0);
 signal cpu_wr_n : std_logic;
 signal prog_do  : std_logic_vector( 7 downto 0);
 
 signal wrk_ram_do  : std_logic_vector( 7 downto 0);
 signal wrk_ram_we  : std_logic; 
 
 signal horz_cnt : std_logic_vector(8 downto 0) := (others =>'0');
 signal vert_cnt : std_logic_vector(7 downto 0) := (others =>'0');
 signal hcnt_s   : std_logic_vector(2 downto 0) := (others =>'0');

 signal frgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal bkgnd_ram_adr: std_logic_vector(10 downto 0) := (others =>'0');
 signal frgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal bkgnd_ram_do : std_logic_vector( 7 downto 0) := (others =>'0');
 signal frgnd_ram_we : std_logic := '0';
 signal bkgnd_ram_we : std_logic := '0';
 
 signal frgnd_graph_adr : std_logic_vector(11 downto 0) := (others =>'0');
 signal bkgnd_graph_adr : std_logic_vector(11 downto 0) := (others =>'0');
 signal palette_adr     : std_logic_vector( 7 downto 0) := (others =>'0'); 
 
 signal frgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_tile_id : std_logic_vector(7 downto 0) := (others =>'0');

 signal frgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal frgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit0_graph : std_logic_vector(7 downto 0) := (others =>'0');
 signal bkgnd_bit1_graph : std_logic_vector(7 downto 0) := (others =>'0');
 
 signal fr_bit0  : std_logic;
 signal fr_bit1  : std_logic;
 signal bk_bit0  : std_logic;
 signal bk_bit1  : std_logic;
 signal fr_lin   : std_logic_vector(2 downto 0);
 signal bk_lin   : std_logic_vector(2 downto 0);
 
 signal color_set : std_logic_vector(1 downto 0);
 signal color_id  : std_logic_vector(5 downto 0);
 signal rgb_0     : std_logic_vector(7 downto 0);
 signal rgb_1     : std_logic_vector(7 downto 0);
  
 signal graphx_bank  : std_logic := '0';
 signal player2      : std_logic := '0';
 signal pl2_cocktail : std_logic := '0';
 signal bkgnd_offset : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_a      : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_b      : std_logic_vector(7 downto 0) := (others =>'0');
 signal sound_c      : std_logic_vector(1 downto 0) := (others =>'0');
 
 signal tms3615_notes : std_logic_vector(11 downto 0) := (others =>'0');
 signal tms3615_clk   : std_logic := '0';
 signal tms3615_octave: std_logic_vector(1 downto 0) := (others =>'0');

 signal melody  : std_logic_vector(11 downto 0) := (others =>'0');
 signal snd1    : std_logic_vector( 1 downto 0) := (others =>'0');
 signal snd2    : std_logic                     := '0';
 signal noise   : std_logic                     := '0';
 signal snd_C5  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal snd_A5  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal snd_A6  : std_logic_vector( 7 downto 0) := (others =>'0');
 signal snd_A7  : std_logic_vector( 7 downto 0) := (others =>'0');
 
 signal coin_n   : std_logic;
 signal buttons  : std_logic_vector(4 downto 0);
 
 signal romp_cs, rom10_cs, rom11_cs, rom20_cs, rom21_cs : std_logic;

 
begin

-- video address/sync generator
video_gen : entity work.naughty_boy_video
port map(
 clk12    => clock_12,
 hcnt     => hcnt,
 vcnt     => vcnt,
 ena_pix  => ena_pix,
 hsync    => video_hs,
 vsync    => video_vs,
 csync    => video_csync,
 cpu_wait => cpu_wait,
 hblank   => hblank,
 vblank   => vblank,
 sel_cpu_addr  => sel_cpu_addr,
 sel_scrl_addr => sel_scrl_addr
);

-- misc
clock_12n<= not clock_12;
reset_n  <= not reset;
rdy      <= not cpu_wait when (cpu_adr(15 downto 12) = "1000") else '1';
ce_pix   <= ena_pix;


coin_n   <= not coin;
buttons  <= player1_btns when player2 = '0' else player2_btns;

-- ena_cpu
cpu_ena <= '1' when hcnt_1r ='0' and hcnt(0) = '1' else '0';

process (clock_12)
begin
	if rising_edge(clock_12) then
		hcnt_1r <= hcnt(0);
	end if;   
end process;

-- microprocessor Z80 - 1
Z80 : entity work.T80se
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
  RESET_n => reset_n,
  CLK_n   => clock_12,
  CLKEN   => cpu_ena,
  WAIT_n  => rdy,
  INT_n   => '1',
  NMI_n   => coin_n,
  BUSRQ_n => '1',
  M1_n    => open,
  MREQ_n  => open,
  IORQ_n  => open,
  RD_n    => open,
  WR_n    => cpu_wr_n,
  RFSH_n  => open,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu_adr,
  DI      => cpu_di,
  DO      => cpu_do
);

-- mux prog, ram, vblank, switch... to processor data bus in
cpu_di <= prog_do      when cpu_adr(15 downto 14) = "00" else
			 wrk_ram_do   when cpu_adr(15 downto 14) = "01" else
          frgnd_ram_do when cpu_adr(15 downto 11) = "10000" else
          bkgnd_ram_do when cpu_adr(15 downto 11) = "10001" else
			 not(buttons) &'0'& not(starts) when cpu_adr(15 downto 11) = "10110" else
			 not(vblank) & dip_switch(6 downto 0) when cpu_adr(15 downto 11) = "10111" else
			 x"FF";

-- write enable to RAMs from cpu
wrk_ram_we   <= '1' when cpu_wr_n = '0' and cpu_adr(15 downto 14) = "01" else '0'; 
frgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(15) = '1' and cpu_adr(13 downto 11) = "000" and sel_cpu_addr = '1' else '0';
bkgnd_ram_we <= '1' when cpu_wr_n = '0' and cpu_adr(15) = '1' and cpu_adr(13 downto 11) = "001" and sel_cpu_addr = '1' else '0';

-- RAMs address mux cpu/video_generator
frgnd_ram_adr <= 	cpu_adr(10 downto 0) when sel_cpu_addr ='1' else 
						vert_cnt(7 downto 3) & horz_cnt(8 downto 3) when sel_scrl_addr = '1' else 
						"1110" & vert_cnt(7 downto 3) & hcnt(4 downto 3) when pl2_cocktail = '0' else
						"1110" & vert_cnt(7 downto 3) & not hcnt(4 downto 3);
						
bkgnd_ram_adr <= 	frgnd_ram_adr;

-- demux cpu data to registers : background scrolling, sound control,
-- player id (1/2), palette color set. 
process (clock_12)
begin
	if rising_edge(clock_12) then
		if cpu_wr_n = '0' then
			case cpu_adr(15 downto 11) is
				when "10010" => 	player2 <= cpu_do(0);
										color_set <= cpu_do(2 downto 1);
										sound_c   <= cpu_do(5 downto 4);
				when "10011" => 	bkgnd_offset <= cpu_do;
				when "10100" =>	sound_a      <= cpu_do;
				when "10101" =>	sound_b      <= cpu_do;
										
					case cpu_do(3 downto 0) is
						when x"0" => tms3615_notes <= x"001";
						when x"1" => tms3615_notes <= x"002";
						when x"2" => tms3615_notes <= x"004";
						when x"3" => tms3615_notes <= x"008";
						when x"4" => tms3615_notes <= x"010";
						when x"5" => tms3615_notes <= x"020";
						when x"6" => tms3615_notes <= x"040";
						when x"7" => tms3615_notes <= x"080";
						when x"8" => tms3615_notes <= x"100";
						when x"9" => tms3615_notes <= x"200";
						when x"A" => tms3615_notes <= x"400";
						when x"B" => tms3615_notes <= x"800";
						when x"F" => tms3615_notes <= x"000";
						when others => null;
					end case;
					
					case cpu_do(7 downto 6) is
						when "00" => tms3615_octave <= "00";
						when "01" => tms3615_octave <= "01";
						when "10" => tms3615_octave <= "10";
						when others => null; -- keep previous octave when "11"
					end case;
										
				when others => null;
			end case;
		end if; 
	end if;
end process;

---- player2 and cocktail mode (flip horizontal/vertical)
pl2_cocktail <= (player2 and dip_switch(7)) xor flip_screen;
--
---- horizontal scan video RAMs address background and foreground
---- with flip and scroll offset
horz_cnt <=
	('0'&hcnt(7 downto 0)) + ('0'&bkgnd_offset) when pl2_cocktail = '0'else
	('0'&not hcnt(7 downto 0)) + ('0'&bkgnd_offset);

---- vertical scan video RAMs address
vert_cnt <= vcnt when pl2_cocktail = '0' else not (vcnt + X"20");

-- get tile_ids from RAMs
frgnd_tile_id <= frgnd_ram_do;
bkgnd_tile_id <= bkgnd_ram_do; 

-- address graphix ROMs with tile_ids and line counter
graphx_bank <= color_set(1);
frgnd_graph_adr <= graphx_bank & frgnd_tile_id & vert_cnt(2 downto 0);
bkgnd_graph_adr <= graphx_bank & bkgnd_tile_id & vert_cnt(2 downto 0);

hcnt_s <= 
	horz_cnt(2 downto 0) when sel_scrl_addr = '1' else 
	hcnt(2 downto 0) when pl2_cocktail = '0' else
	not hcnt(2 downto 0);

---- latch foreground/background next graphix byte, high bit and low bit
---- and palette_ids (fr_lin, bklin)
---- demux background and foreground pixel bits (0/1) from graphix byte with horizontal counter
---- and apply blanking
process (clock_12)
begin
	if rising_edge(clock_12) then
		if ena_pix = '1' then
			if (hblank = '0' and vblank = '0') then
				fr_bit0 <= frgnd_bit0_graph(to_integer(unsigned(hcnt_s))); 
				fr_bit1 <= frgnd_bit1_graph(to_integer(unsigned(hcnt_s))); 
				bk_bit0 <= bkgnd_bit0_graph(to_integer(unsigned(hcnt_s))); 
				bk_bit1 <= bkgnd_bit1_graph(to_integer(unsigned(hcnt_s))); 
			else
				fr_bit0 <= '0'; 
				fr_bit1 <= '0'; 
				bk_bit0 <= '0'; 
				bk_bit1 <= '0'; 
			end if;
			fr_lin <= frgnd_tile_id(7 downto 5);
			bk_lin <= bkgnd_tile_id(7 downto 5);
	end if;	
end if;
end process;

---- select pixel bits and palette_id with foreground priority
color_id  <=  (fr_bit0 or fr_bit1) &  fr_bit1 & fr_bit0 & fr_lin when (fr_bit0 or fr_bit1) = '1' else
              (fr_bit0 or fr_bit1) &  bk_bit1 & bk_bit0 & bk_lin;

-- address palette with pixel bits color and color set
palette_adr <= color_set & color_id;

-- output video to top level
video_r <= rgb_1(0) & rgb_0(0);
video_g <= rgb_1(2) & rgb_0(2);
video_b <= rgb_1(1) & rgb_0(1);

video_hblank <= hblank;
video_vblank <= vblank;

-- download ROM CS
romp_cs  <= '1' when dn_addr(15 downto 14) = "00"    else '0';
rom10_cs <= '1' when dn_addr(15 downto 12) = "0100" else '0';
rom11_cs <= '1' when dn_addr(15 downto 12) = "0101" else '0';
rom20_cs <= '1' when dn_addr(15 downto 12) = "0110" else '0';
rom21_cs <= '1' when dn_addr(15 downto 12) = "0111" else '0';

-- foreground graphix ROM graph2 bit0
frgnd_bit0 : entity work.dpram generic map (12,8)
port map
(
 clock_a   => clock_12,
 wren_a    => dn_wr and rom20_cs,
 address_a => dn_addr(11 downto 0),
 data_a    => dn_data,

 clock_b   => clock_12,
 address_b => frgnd_graph_adr,
 q_b       => frgnd_bit0_graph
);
--frgnd_bit0 : entity work.prom_graphx_2_bit0
--port map(
-- clk  => clock_12,
-- addr => frgnd_graph_adr,
-- data => frgnd_bit0_graph
--);

-- foreground graphix ROM graph2 bit1
frgnd_bit1 : entity work.dpram generic map (12,8)
port map
(
 clock_a   => clock_12,
 wren_a    => dn_wr and rom21_cs,
 address_a => dn_addr(11 downto 0),
 data_a    => dn_data,

 clock_b   => clock_12,
 address_b => frgnd_graph_adr,
 q_b       => frgnd_bit1_graph
);
--frgnd_bit1 : entity work.prom_graphx_2_bit1
--port map(
-- clk  => clock_12,
-- addr => frgnd_graph_adr,
-- data => frgnd_bit1_graph
--);

-- background graphix ROM graph1 bit0
bkgnd_bit0 : entity work.dpram generic map (12,8)
port map
(
 clock_a   => clock_12,
 wren_a    => dn_wr and rom10_cs,
 address_a => dn_addr(11 downto 0),
 data_a    => dn_data,

 clock_b   => clock_12,
 address_b => bkgnd_graph_adr,
 q_b       => bkgnd_bit0_graph
);
--bkgnd_bit0 : entity work.prom_graphx_1_bit0
--port map(
-- clk  => clock_12,
-- addr => bkgnd_graph_adr,
-- data => bkgnd_bit0_graph
--);

-- background graphix ROM graph1 bit1
bkgnd_bit1 : entity work.dpram generic map (12,8)
port map
(
 clock_a   => clock_12,
 wren_a    => dn_wr and rom11_cs,
 address_a => dn_addr(11 downto 0),
 data_a    => dn_data,

 clock_b   => clock_12,
 address_b => bkgnd_graph_adr,
 q_b       => bkgnd_bit1_graph
);
--bkgnd_bit1 : entity work.prom_graphx_1_bit1
--port map(
-- clk  => clock_12,
-- addr => bkgnd_graph_adr,
-- data => bkgnd_bit1_graph
--);

-- color palette ROM RBG low intensity
palette_0 : entity work.prom_palette_1
port map(
 clk  => clock_12,
 addr => palette_adr,
 data => rgb_0
);

-- color palette ROM RBG high intensity
palette_1 : entity work.prom_palette_2
port map(
 clk  => clock_12,
 addr => palette_adr,
 data => rgb_1
);


-- Program PROM 0x0000-0x3FFF
prog : entity work.dpram generic map (14,8)
port map
(
 clock_a   => clock_12,
 wren_a    => dn_wr and romp_cs,
 address_a => dn_addr(13 downto 0),
 data_a    => dn_data,

 clock_b   => clock_12,
 address_b => cpu_adr(13 downto 0),
 q_b       => prog_do
);
--prog : entity work.prom_prog 
--port map(
-- clk  => clock_12,
-- addr => cpu_adr(13 downto 0),
-- data => prog_do
--);

-- working RAM   0x4000-0x47FF
working_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 10)
port map(
 clk  => clock_12,
 we   => wrk_ram_we,
 addr => cpu_adr(9 downto 0),
 d    => cpu_do,
 q    => wrk_ram_do
);

-- foreground RAM   0x8000-0x87FF
frgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => clock_12n,
 we   => frgnd_ram_we,
 addr => frgnd_ram_adr,
 d    => cpu_do,
 q    => frgnd_ram_do
);

-- background RAM   0x8800-0x8FFF
bkgnd_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 11)
port map(
 clk  => clock_12n,
 we   => bkgnd_ram_we,
 addr => bkgnd_ram_adr,
 d    => cpu_do,
 q    => bkgnd_ram_do
);
--
---- sound effect1
effect1 : entity work.naughty_boy_effect1
port map(
clk12       => clock_12,
trigger_B54 => sound_b(5 downto 4),
snd         => snd1
);

---- sound effect2
effect2 : entity work.naughty_boy_effect2
port map(
clk12   => clock_12,
clksnd  => vcnt(0),
divider => sound_a(3 downto 0),
snd     => snd2
);

noise_gen : entity work.naughty_boy_noise
port map(
 clk12    => clock_12,
 trigger  => sound_a(4),
 noise    => noise
);

effect3 : entity work.naughty_boy_effect3
port map(
 clk12      => clock_12,
 trigger_C4 => sound_c(0),
 trigger_C5 => sound_c(1),
 trigger_A5 => sound_a(5),
 noise      => noise,
 snd_C5     => snd_C5,
 snd_A5     => snd_A5
);

effect4 : entity work.naughty_boy_effect4
port map(
 clk12      => clock_12,
 trigger_A6 => sound_a(6),
 trigger_A7 => sound_a(7),
 noise      => noise,
 snd_A6     => snd_A6,
 snd_A7     => snd_A7
);


-- tms3615
tms3615_clk <= '0'     when tms3615_octave = "11" -- could not happen
			else  hcnt(1) when tms3615_octave = "10" 
			else  hcnt(2) when tms3615_octave = "01"
			else  hcnt(3) when tms3615_octave = "00";

tms3615ns : entity work.tms3615
port map(
	clk_sys => hcnt(0),
	clk_snd => tms3615_clk,
	trigger => '0'&tms3615_notes,
	audio   => melody
);

--audio <= melody;
--audio <= "000000" & snd1 & "0000";  -- alerte monsters
--audio <= "00000" & snd2 & "000000"; -- rock hit monsters, misc jingles, ...
--audio <= "00" & snd_A5 & "00";      -- rock hit monsters 
--audio <= "0000000" & snd_C5(7 downto 3) ;  -- rock is flying
--audio <= "0000" & snd_A6 ; -- rock hit floor, castle fire 
--audio <= "000000" & snd_A7(7 downto 2) ; -- trop fort -- boy step, castle fire 

---- mix effects and music
audio <= 
	melody
	+ ("000000"  & snd1 & "0000")
	+ ("00000"   & snd2 & "000000")
	+ ("00"      & snd_A5 & "00")
	+ ("0000000" & snd_C5(7 downto 3))
	+ ("0000"    & snd_A6)
	+ ("000000"  & snd_A7(7 downto 2));

end struct;
