----------------------------------------------------------------------------------
-- Crazy climber - Dar - June 2018
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity crazy_climber is
port(
  clock_12  : in std_logic;
  reset        : in std_logic;
  video_r      : out std_logic_vector(2 downto 0);
  video_g      : out std_logic_vector(2 downto 0);
  video_b      : out std_logic_vector(1 downto 0);
  video_hblank : out std_logic;
  video_vblank : out std_logic;
  video_hs     : out std_logic;
  video_vs     : out std_logic;
  audio_out    : out std_logic_vector(15 downto 0);

  
  start2       : in std_logic;
  start1       : in std_logic;
  coin1        : in std_logic;

  r_right1     : in std_logic;
  r_left1      : in std_logic;
  r_down1      : in std_logic;
  r_up1        : in std_logic;
  l_right1     : in std_logic;
  l_left1      : in std_logic;
  l_down1      : in std_logic;
  l_up1        : in std_logic;
  
  r_right2     : in std_logic;
  r_left2      : in std_logic;
  r_down2      : in std_logic;
  r_up2        : in std_logic;
  l_right2     : in std_logic;
  l_left2      : in std_logic;
  l_down2      : in std_logic;
  l_up2        : in std_logic
 
);
end crazy_climber;

architecture struct of crazy_climber is

-- clocks 
signal clock_12n : std_logic;
signal reset_n   : std_logic;

-- video syncs
signal hsync       : std_logic;
signal vsync       : std_logic;
signal hblank       : std_logic;
signal vblank       : std_logic;

-- global synchronisation
signal ena_pixel  : std_logic := '0';
signal is_sprite  : std_logic;
signal sprite     : std_logic_vector(2 downto 0);
signal x_tile     : std_logic_vector(4 downto 0);
signal y_tile     : std_logic_vector(4 downto 0);
signal x_pixel    : std_logic_vector(2 downto 0);
signal y_pixel    : std_logic_vector(2 downto 0);
signal y_line     : std_logic_vector(7 downto 0);

signal y_sp_bg    : std_logic_vector(7 downto 0);
signal y_line_shift : std_logic_vector(7 downto 0);
signal attr_sp : std_logic_vector(7 downto 0);
signal attr_sp_bg : std_logic_vector(7 downto 0);
signal bg_tile_code : std_logic_vector(7 downto 0);

signal tile_graph_rom_addr    : std_logic_vector(12 downto 0);
signal tile_graph_rom_addr_mod: std_logic_vector(11 downto 0);
signal tile_graph_rom_bit0_do : std_logic_vector(7 downto 0);
signal tile_graph_rom_bit1_do : std_logic_vector(7 downto 0);

signal big_sprite_tile_rom_addr : std_logic_vector(10 downto 0);
signal big_sprite_tile_rom_bit0_do : std_logic_vector(7 downto 0);
signal big_sprite_tile_rom_bit1_do : std_logic_vector(7 downto 0);

-- background and sprite tiles and graphics
signal tile_code   : std_logic_vector(12 downto 0);
signal tile_color  : std_logic_vector(3 downto 0);
signal tile_graph1 : std_logic_vector(7 downto 0);
signal tile_graph2 : std_logic_vector(7 downto 0);
signal x_sprite    : std_logic_vector(7 downto 0);
signal y_sprite    : std_logic_vector(7 downto 0);
signal keep_sprite : std_logic;

signal tile_color_r  : std_logic_vector(3 downto 0);
signal tile_graph1_r : std_logic_vector(7 downto 0);
signal tile_graph2_r : std_logic_vector(7 downto 0);

signal pixel_color    : std_logic_vector(5 downto 0);
signal pixel_color_r  : std_logic_vector(5 downto 0);

signal sprite_pixel_color  : std_logic_vector(5 downto 0);
signal do_palette          : std_logic_vector(7 downto 0);

signal addr_ram_sprite : std_logic_vector(8 downto 0);
signal is_sprite_r     : std_logic;

type ram_256x6 is array(0 to 255) of std_logic_vector(5 downto 0);
signal ram_sprite : ram_256x6;

-- big sprite tiles and graphics
signal x_big_sprite           : std_logic_vector(7 downto 0);
signal y_big_sprite           : std_logic_vector(7 downto 0);
signal y_line_big_sprite_shift: std_logic_vector(7 downto 0);
signal attr_big_sprite      : std_logic_vector(5 downto 0);

signal big_sprite_graph1    : std_logic_vector(7 downto 0);
signal big_sprite_graph2    : std_logic_vector(7 downto 0);
signal xy_big_sprite        : std_logic_vector(7 downto 0);
signal big_sprite_tile_code : std_logic_vector(7 downto 0);
signal big_sprite_tile_code_r : std_logic_vector(7 downto 0);
signal is_big_sprite_on     : std_logic;
signal x_big_sprite_counter : std_logic_vector(7 downto 0);
signal big_sprite_graph1_delay : std_logic_vector(7 downto 0);
signal big_sprite_graph2_delay : std_logic_vector(7 downto 0);

signal do_big_sprite_palette   : std_logic_vector(7 downto 0);
signal big_sprite_pixel_color  : std_logic_vector(4 downto 0);
signal big_sprite_pixel_color_r: std_logic_vector(4 downto 0);

signal video_mux              : std_logic_vector(7 downto 0);

-- Z80 interface 
signal cpu_clock  : std_logic;
signal cpu_wr_n   : std_logic;
signal cpu_addr   : std_logic_vector(15 downto 0);
signal cpu_do     : std_logic_vector(7 downto 0);
signal cpu_di     : std_logic_vector(7 downto 0);
signal cpu_mreq_n : std_logic;
signal cpu_m1_n   : std_logic;
signal cpu_int_n  : std_logic;
signal cpu_iorq_n : std_logic;
signal cpu_di_mem   : std_logic_vector(7 downto 0);
signal cpu_addr_mod : std_logic_vector(9 downto 0);

-- misc
signal reg4_we_n  : std_logic;
signal reg5_we_n  : std_logic;
signal reg6_we_n  : std_logic;
signal raz_int_n  : std_logic;

signal prog_do    : std_logic_vector(7 downto 0);
signal wram1_do   : std_logic_vector(7 downto 0);
signal wram1_we   : std_logic;
--signal wram2_do   : std_logic_vector(7 downto 0);
--signal wram2_we   : std_logic;

signal tile_ram_addr : std_logic_vector(9 downto 0);
signal tile_ram_do   : std_logic_vector(7 downto 0);
signal tile_ram_we   : std_logic;
signal tile_ram_cs   : std_logic;

signal color_ram_addr: std_logic_vector(9 downto 0);
signal color_ram_do  : std_logic_vector(7 downto 0);
signal color_ram_we  : std_logic;
signal color_ram_cs  : std_logic;

signal big_sprite_ram_addr : std_logic_vector(7 downto 0);
signal big_sprite_ram_do   : std_logic_vector(7 downto 0);
signal big_sprite_ram_we   : std_logic;
signal big_sprite_ram_cs   : std_logic;

-- data bus from AY-3-8910
signal ym_8910_data : std_logic_vector(7 downto 0);

-- player I/O 
signal player1  : std_logic_vector(7 downto 0);
signal player2  : std_logic_vector(7 downto 0);
signal coins    : std_logic_vector(7 downto 0);

signal video_i : std_logic_vector (7 downto 0);

-- decryption tool
signal prog_do_decrypted : std_logic_vector(7 downto 0);
signal index : integer range 0 to 127;
signal index_vector : std_logic_vector(6 downto 0);
type convtable_t is array(0 to 127) of std_logic_vector(7 downto 0);
signal convtable: convtable_t:= (
	X"44",X"14",X"54",X"10",X"11",X"41",X"05",X"50",X"51",X"00",X"40",X"55",X"45",X"04",X"01",X"15",
	X"44",X"10",X"15",X"55",X"00",X"41",X"40",X"51",X"14",X"45",X"11",X"50",X"01",X"54",X"04",X"05",
	X"45",X"10",X"11",X"44",X"05",X"50",X"51",X"04",X"41",X"14",X"15",X"40",X"01",X"54",X"55",X"00",
	X"04",X"51",X"45",X"00",X"44",X"10",X"ff",X"55",X"11",X"54",X"50",X"40",X"05",X"ff",X"14",X"01",
	X"54",X"51",X"15",X"45",X"44",X"01",X"11",X"41",X"04",X"55",X"50",X"ff",X"00",X"10",X"40",X"ff",
	X"ff",X"54",X"14",X"50",X"51",X"01",X"ff",X"40",X"41",X"10",X"00",X"55",X"05",X"44",X"11",X"45",
	X"51",X"04",X"10",X"ff",X"50",X"40",X"00",X"ff",X"41",X"01",X"05",X"15",X"11",X"14",X"44",X"54",
	X"ff",X"ff",X"54",X"01",X"15",X"40",X"45",X"41",X"51",X"04",X"50",X"05",X"11",X"44",X"10",X"14");

begin

clock_12n <= not clock_12;
reset_n   <= not reset;


-----------------------
-- Enable pixel counter
-----------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		ena_pixel <= not ena_pixel;
	end if;
end process;
	
------------------
-- video output
------------------
video_mux <= do_palette when is_big_sprite_on = '0' else do_big_sprite_palette;

process(clock_12)
begin
	if rising_edge(clock_12) then
		if ena_pixel = '1' then
			if hblank = '0' then
				video_i <= video_mux;			
			else
				video_i <= (others => '0');
			end if;
		end if;
	end if;
end process;

video_r     <= video_i(2 downto 0);
video_g     <= video_i(5 downto 3);
video_b     <= video_i(7 downto 6);

video_hblank <= hblank;
video_vblank <= vblank;

video_hs    <= hsync;
video_vs    <= vsync;

------------------
-- player controls
------------------
player1 <= r_right1 & r_left1 & r_down1 & r_up1 & l_right1 & l_left1 & l_down1 & l_up1;
player2 <= r_right2 & r_left2 & r_down2 & r_up2 & l_right2 & l_left2 & l_down2 & l_up2;
coins <=  ("0001" & start2 & start1 & '0' & coin1); -- upright cabinet

-----------------------
-- cpu write addressing
-----------------------
--wram2_we   <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 11) = "01100" else '0'; -- 6000-67ff (ckong)
--wram1_we   <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 11) = "01101" else '0'; -- 6800-6bff (ckong)
wram1_we   <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 11) = "10000" else '0'; -- 8000-87ff (cclimber)

tile_ram_cs       <= '1' when cpu_addr(15 downto 11) = "10010"    else '0'; -- 9000-93ff mirror 9400-97ff
color_ram_cs      <= '1' when cpu_addr(15 downto 11) = "10011"    else '0'; -- 9800-9bff 
big_sprite_ram_cs <= '1' when cpu_addr(15 downto  8) = "10001000" else '0'; -- 8800-88ff
 
reg4_we_n <= '0' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 11) = "10100" else '1';
reg5_we_n <= '0' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 11) = "10101" else '1';
reg6_we_n <= '0' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 11) = "10110" else '1';

---------------------------
-- enable/disable interrupt
---------------------------
process (cpu_clock)
begin
	if falling_edge(cpu_clock) then
		if cpu_addr(2 downto 0) = "000" and reg4_we_n = '0' then
			raz_int_n <= cpu_do(0);
		end if;
end if;
end process;

-------------------------------
-- latch interrupt at last line 
-------------------------------
process(clock_12, raz_int_n)
begin
	if raz_int_n = '0' then
		cpu_int_n <= '1';
	else
		if rising_edge(clock_12) then
			if y_tile = "11100" and y_pixel = "000" then
				cpu_int_n <= '0';
			end if;
		end if;
	end if;
end process;

------------------------------------
-- mux cpu data mem read and io read
------------------------------------
index_vector <= prog_do(7) & prog_do(1) & cpu_addr(0) & prog_do(6) & prog_do(4) & prog_do(2) & prog_do(0);
index <= to_integer(unsigned(index_vector));

with cpu_m1_n select
	prog_do_decrypted <=
		prog_do                                  when '1',
		(prog_do and X"AA") or convtable(index)  when others;

with cpu_addr(15 downto 11) select 
	cpu_di_mem <=
		prog_do_decrypted when "00000", -- 0000-07ff
		prog_do_decrypted when "00001", -- 0800-0fff
		prog_do_decrypted when "00010", -- 1000-17ff
		prog_do_decrypted when "00011", -- 1800-1fff
		prog_do_decrypted when "00100", -- 2000-27ff
		prog_do_decrypted when "00101", -- 2800-2fff
		prog_do_decrypted when "00110", -- 3000-37ff
		prog_do_decrypted when "00111", -- 3800-3fff
		prog_do_decrypted when "01000", -- 4000-47ff
		prog_do_decrypted when "01001", -- 4800-4fff
		prog_do_decrypted when "01010", -- 5000-57ff
		prog_do_decrypted when "01011", -- 5800-5fff
--		wram2_do          when "01100", -- 6000-67ff                         ckong only 
--		wram1_do          when "01101", -- 6800-6fff (ram only at 6800-6bff) ckong only
		wram1_do          when "10000", -- 8000-87ff (ram only at 8000-83ff) cclimber only		
		big_sprite_ram_do when "10001", -- 8800-8fff (ram only at 8800-88ff)
 		tile_ram_do       when "10010", -- 9000-97ff (ram only at 9000-93ff)
		color_ram_do      when "10011", -- 9800-9fff (ram only at 9800-9bff)		
		player1           when "10100", -- a000
		player2           when "10101", -- a800
		"00000000"        when "10110", -- b000 - dip switch (upright cabinet)
		coins             when "10111", -- b800 
		"00000000"        when others;

cpu_di <= ym_8910_data when cpu_iorq_n = '0' else cpu_di_mem;

------------------------------------------------------
-- big_sprite_registers (ckong)
------------------------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		if cpu_wr_n = '0' and cpu_mreq_n ='0' then
			if cpu_addr = X"98DD" then attr_big_sprite <= cpu_do(5 downto 0); end if;
			if cpu_addr = X"98DE" then y_big_sprite    <= cpu_do; end if;		
			if cpu_addr = X"98DF" then x_big_sprite    <= cpu_do; end if;
		end if;
	end if;
end process;

------------------------------------------------------
-- cpu addressing mode for color ram 98XX (ckong)
------------------------------------------------------
cpu_addr_mod <= cpu_addr(10 downto 6) & cpu_addr(4 downto 0);

-------------------------------------
-- color ram addressing scheme 
-------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		color_ram_we <= '0';
		case x_pixel is
				
			when "000" =>	
				if is_sprite = '1' then 			
					color_ram_addr <= "00010" & sprite & "10"; -- y sprite -- ckong   (color ram 040-05f)
				else
					color_ram_addr <= "00000" & x_tile;-- bg scroll column -- ckong   (color ram 000-01f)
				end if;
				if ena_pixel = '1' then y_sp_bg <= color_ram_do; end if;

			when "010" =>	
				if is_sprite = '1' then 
					color_ram_addr <= "00010" & sprite & "01"; -- color sprite -- ckong (color ram 040-05f)
				else
					color_ram_addr <= '1' & y_line_shift(7 downto 4) & x_tile; -- color background -- ckong (color ram 040-05f)
				end if;
				if ena_pixel = '1' then attr_sp_bg <= color_ram_do; end if;

			when "100" =>	
				if is_sprite = '1' then 
					color_ram_addr <= "00010" & sprite & "00"; -- tile sprite -- ckong (color ram 040-05f)
				else
					color_ram_addr <= (others => '0');
				end if;
				if ena_pixel = '1' then attr_sp <= color_ram_do; end if;
						
			when "110" =>
				if is_sprite = '1' then 
					color_ram_addr <= "00010" & sprite & "11"; -- x sprite -- ckong (color ram 040-05f)
				else
					color_ram_addr <= (others => '0');
				end if;
				if ena_pixel = '1' then x_sprite <= color_ram_do; end if;
				
			when others =>
				color_ram_addr <= cpu_addr_mod;
				color_ram_we <= not(cpu_wr_n) and not(cpu_mreq_n) and color_ram_cs;				
				
		end case;	
	end if;
end process;

-------------------------------------
-- tile ram addressing scheme 
-------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		tile_ram_we <= '0';
		case x_pixel is
		
			when "100" =>
				tile_ram_addr <= y_line_shift(7 downto 3) & x_tile;-- bg tile code
					
			when others =>
				tile_ram_addr <= cpu_addr(9 downto 0);
				tile_ram_we <= not(cpu_wr_n) and not(cpu_mreq_n) and tile_ram_cs;				
				
		end case;	
	end if;
end process;

-------------------------------------
-- tile graph rom addressing scheme 
-------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		case x_pixel is
		
			when "100" =>
				if ena_pixel = '1' then
					bg_tile_code <= tile_ram_do;
				end if;
		
			when "110" =>
				if is_sprite = '1' then
						case attr_sp(7 downto 6) is
						when "00"   => tile_graph_rom_addr <= attr_sp_bg(4) & attr_sp_bg(5) & attr_sp(5 downto 0) & ((y_line_shift(3) & x_tile(0) & y_line_shift(2 downto 0)) xor "00000");
						when "01"   => tile_graph_rom_addr <= attr_sp_bg(4) & attr_sp_bg(5) & attr_sp(5 downto 0) & ((y_line_shift(3) & x_tile(0) & y_line_shift(2 downto 0)) xor "01000");
						when "10"   => tile_graph_rom_addr <= attr_sp_bg(4) & attr_sp_bg(5) & attr_sp(5 downto 0) & ((y_line_shift(3) & x_tile(0) & y_line_shift(2 downto 0)) xor "10111");
						when others => tile_graph_rom_addr <= attr_sp_bg(4) & attr_sp_bg(5) & attr_sp(5 downto 0) & ((y_line_shift(3) & x_tile(0) & y_line_shift(2 downto 0)) xor "11111");
						end case;
				else
					if attr_sp_bg(7) = '0' then
						tile_graph_rom_addr <= attr_sp_bg(4) & attr_sp_bg(5) & bg_tile_code & y_line_shift(2 downto 0);
					else
						tile_graph_rom_addr <= attr_sp_bg(4) & attr_sp_bg(5) & bg_tile_code & not(y_line_shift(2 downto 0));
					end if;
				end if;

			when "111" =>
				if ena_pixel = '1' then
					tile_graph1_r <= tile_graph_rom_bit0_do;
					tile_graph2_r <= tile_graph_rom_bit1_do;
					tile_color_r  <= attr_sp_bg(3 downto 0);
					
					if (is_sprite = '1' and attr_sp(6) = '1') or (is_sprite = '0' and attr_sp_bg(6) = '1' ) then 
						for i in 0 to 7 loop
							tile_graph1_r(i) <= tile_graph_rom_bit0_do(7-i);
							tile_graph2_r(i) <= tile_graph_rom_bit1_do(7-i);
						end loop;
					end if;

					is_sprite_r <= is_sprite;
					
					keep_sprite <= '0';
					if (y_line_shift(7 downto 4) = "1111") and (x_sprite /= X"00") and (y_sp_bg /= X"00") then
						keep_sprite <= '1';
					end if;
				
				end if;
				
			when others => null;		
				
		end case;	
	end if;
end process;

--------------------------------
-- sprite/ big sprite y position
--------------------------------
y_line                  <= y_tile & y_pixel;
y_line_shift            <= std_logic_vector(unsigned(y_line) + unsigned(y_sp_bg) + 1);
y_line_big_sprite_shift <= std_logic_vector(unsigned(y_line) + unsigned(y_big_sprite) + 1);

------------------------------------------
-- read/write sprite line-memory addresing
------------------------------------------
process (clock_12)
begin 
	if rising_edge(clock_12) then

		if ena_pixel = '1' then
			addr_ram_sprite <= addr_ram_sprite + '1';
		end if;

		if is_sprite = '1' and x_pixel = "111" and ena_pixel = '1' and x_tile(0) = '0' then
			addr_ram_sprite <= '0' & x_sprite;
		end if;

		if is_sprite = '0' and x_pixel = "111" and ena_pixel = '1' and x_tile = "00000" then
			addr_ram_sprite <= "000000001";
		end if;

	end if;
end process;

-------------------------------------
-- read/write sprite line-memory data
-------------------------------------
process (clock_12)
begin
	if rising_edge(clock_12) then
		if ena_pixel = '0' then
			sprite_pixel_color <= ram_sprite(to_integer(unsigned(addr_ram_sprite)));
		else
			if sprite_pixel_color(1 downto 0) = "00" then
				pixel_color_r <= pixel_color;
			else
				pixel_color_r <= sprite_pixel_color;
			end if;
		
			if is_sprite_r = '1' then
				if (keep_sprite = '1') and (addr_ram_sprite(8) = '0') then
					if sprite_pixel_color(1 downto 0) = "00" then
						ram_sprite(to_integer(unsigned(addr_ram_sprite))) <= pixel_color;
					else
						ram_sprite(to_integer(unsigned(addr_ram_sprite))) <= sprite_pixel_color;
					end if;
						
				end if;
			else
				ram_sprite(to_integer(unsigned(addr_ram_sprite))) <= (others => '0');
			end if;
		end if;
	end if;
end process;

-----------------------------------------------------------------
-- serialize background/sprite graph to pixel + concatenate color
-----------------------------------------------------------------
pixel_color <=	tile_color_r & 
	tile_graph1_r(to_integer(unsigned(not x_pixel))) &
	tile_graph2_r(to_integer(unsigned(not x_pixel)));

-------------------------------------
-- select big sprite ram tile address
-------------------------------------
with attr_big_sprite(5 downto 4) select
xy_big_sprite <=    y_line_big_sprite_shift(6 downto 3)  & not(x_big_sprite_counter(6 downto 3)) when "01",
					not (y_line_big_sprite_shift(6 downto 3)) & not(x_big_sprite_counter(6 downto 3)) when "11",
						  y_line_big_sprite_shift(6 downto 3)  &    (x_big_sprite_counter(6 downto 3)) when "00",
					not (y_line_big_sprite_shift(6 downto 3)) &    (x_big_sprite_counter(6 downto 3)) when others;

----------------------------------------
-- select big sprite graphic rom address
----------------------------------------
with attr_big_sprite(5) select
big_sprite_tile_rom_addr <= big_sprite_tile_code_r &      y_line_big_sprite_shift(2 downto 0) when '0',
                            big_sprite_tile_code_r & not (y_line_big_sprite_shift(2 downto 0)) when others;
 
-------------------------------------
-- big sprite ram addressing scheme 
-------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		big_sprite_ram_we <= '0';
		case x_pixel is
				
			when "000" =>	
				big_sprite_ram_addr <= xy_big_sprite;
				if ena_pixel = '1' then
					big_sprite_tile_code <= big_sprite_ram_do;
				end if;
		
			when others =>
				big_sprite_ram_addr <= cpu_addr(7 downto 0);
				big_sprite_ram_we <= not(cpu_wr_n) and not(cpu_mreq_n) and big_sprite_ram_cs;				
				
		end case;	
	end if;
end process;			

------------------------------------
-- big sprite tile graph rom reading 
-------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
	
		if ena_pixel = '1' then
			x_big_sprite_counter <= x_big_sprite_counter + '1';		
		end if;
		
		if is_sprite = '1' and sprite = "110" and ena_pixel = '1' then
			x_big_sprite_counter <= std_logic_vector(to_unsigned(120,8) + unsigned(x_big_sprite and X"F8"));
		end if;

		
		if x_big_sprite_counter(2 downto 0) = "111" and ena_pixel = '1' then
			big_sprite_tile_code_r <= big_sprite_tile_code;
			
			big_sprite_graph1 <= big_sprite_tile_rom_bit0_do;
			big_sprite_graph2 <= big_sprite_tile_rom_bit1_do;
			if attr_big_sprite(4) = '0' then
				for i in 0 to 7 loop
					big_sprite_graph1(i) <= big_sprite_tile_rom_bit0_do(7-i);
					big_sprite_graph2(i) <= big_sprite_tile_rom_bit1_do(7-i);
				end loop;
			end if;
			
		end if;

	end if;
end process;

-----------------------------------------------------------------
-- serialize big sprite graph to pixel + concatenate color
-- clip big sprite display
-----------------------------------------------------------------
process(clock_12)
begin
	if rising_edge(clock_12) then
		if ena_pixel = '1' then
			big_sprite_graph1_delay <= big_sprite_graph1_delay(6 downto 0) & big_sprite_graph1(to_integer(unsigned(x_big_sprite_counter(2 downto 0))));
			big_sprite_graph2_delay <= big_sprite_graph2_delay(6 downto 0) & big_sprite_graph2(to_integer(unsigned(x_big_sprite_counter(2 downto 0))));
		end if;
	end if;
end process;
	
big_sprite_pixel_color <=	attr_big_sprite(2 downto 0) & 
	big_sprite_graph1_delay(to_integer(unsigned(not x_big_sprite(2 downto 0)))) &	 
	big_sprite_graph2_delay(to_integer(unsigned(not x_big_sprite(2 downto 0)))) ;

process (clock_12)
begin
	if rising_edge(clock_12) then
		big_sprite_pixel_color_r <= big_sprite_pixel_color;
	
		if big_sprite_pixel_color_r(1 downto 0) /= "00" and y_line_big_sprite_shift(7) = '1' and 
				x_big_sprite_counter >= (X"1F") and 
				x_big_sprite_counter <  (X"9F") then
			is_big_sprite_on <= '1';
		else
			is_big_sprite_on <= '0';
		end if;
	end if;
end process;

-- Sync and video counters
video : entity work.video_gen
port map (
  clock_12   => clock_12,
  ena_pixel  => ena_pixel,
  hsync      => hsync,
  vsync      => vsync,
  csync      => open,
  hblank     => hblank,
  vblank     => vblank,

  is_sprite  => is_sprite,
  sprite     => sprite,
  x_tile     => x_tile,
  y_tile     => y_tile,
  x_pixel    => x_pixel,
  y_pixel    => y_pixel,
	
  cpu_clock  => cpu_clock
);

-- sprite palette rom
palette : entity work.cclimber_palette
port map (
	addr => pixel_color_r,
	clk  => clock_12,
	data => do_palette 
);

-- big sprite palette rom
big_sprite_palette : entity work.cclimber_big_sprite_palette
port map (
	addr  => big_sprite_pixel_color_r,
	clk   => clock_12,
	data  => do_big_sprite_palette 
);

-- Z80
Z80 : entity work.T80s
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
  RESET_n => reset_n,
  CLK_n   => cpu_clock,
  WAIT_n  => '1',
  INT_n   => '1',
  NMI_n   => cpu_int_n,
  BUSRQ_n => '1',
  M1_n    => cpu_m1_n,
  MREQ_n  => cpu_mreq_n,
  IORQ_n  => cpu_iorq_n,
  RD_n    => open,
  WR_n    => cpu_wr_n,
  RFSH_n  => open,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu_addr,
  DI      => cpu_di,
  DO      => cpu_do
);


-- program rom 
program : entity work.cclimber_program
port map (
	addr  => cpu_addr(14 downto 0),
	clk   => clock_12n,
	data  => prog_do
);

-- working ram1 - 6800-6bff (ckong)
-- working ram1 - 8000-83ff (cclimber)
wram1 : entity work.gen_ram
generic map( dWidth => 8, aWidth => 10)
port map(
 clk  => clock_12n,
 we   => wram1_we,
 addr => cpu_addr( 9 downto 0),
 d    => cpu_do,
 q    => wram1_do
);

---- working ram2 - 6000-67ff (ckong only)
--wram2 : entity work.gen_ram
--generic map( dWidth => 8, aWidth => 11)
--port map(
-- clk  => clock_12n,
-- we   => wram2_we,
-- addr => cpu_addr( 10 downto 0),
-- d    => cpu_do,
-- q    => wram2_do
--);

-- tile_ram - 9000-93ff 
tile_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 10)
port map(
 clk  => clock_12n,
 we   => tile_ram_we,
 addr => tile_ram_addr,
 d    => cpu_do,
 q    => tile_ram_do
);

-- color_ram - 9800-9bff (9800-981F = 9820-983f ...)
color_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 10)
port map(
 clk  => clock_12n,
 we   => color_ram_we,
 addr => color_ram_addr,
 d    => cpu_do,
 q    => color_ram_do
);

-- big_sprite_tile_ram - 8800-88ff
big_sprite_tile_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk  => clock_12n,
 we   => big_sprite_ram_we,
 addr => big_sprite_ram_addr,
 d    => cpu_do,
 q    => big_sprite_ram_do
);

-- sprite and background graphics rom
tile_graph_rom_addr_mod <=  tile_graph_rom_addr(12) & tile_graph_rom_addr(10 downto 0); 

tile_bit0 : entity work.cclimber_tile_bit0
port map (
	addr  => tile_graph_rom_addr_mod,
	clk   => clock_12n,
	data  => tile_graph_rom_bit0_do
);

-- sprite and background graphics rom 
tile_bit1 : entity work.cclimber_tile_bit1
port map (
	addr  => tile_graph_rom_addr_mod,
	clk   => clock_12n,
	data  => tile_graph_rom_bit1_do
);

-- big sprite graphics rom 
big_sprite_tile_bit0 : entity work.cclimber_big_sprite_tile_bit0
port map (
	addr  => big_sprite_tile_rom_addr,
	clk   => clock_12n,
	data  => big_sprite_tile_rom_bit0_do
);

-- big sprite graphics rom 
big_sprite_tile_bit1 : entity work.cclimber_big_sprite_tile_bit1
port map (
	addr  => big_sprite_tile_rom_addr,
	clk   => clock_12n,
	data  => big_sprite_tile_rom_bit1_do
);

-- sound
cclimber_sound : entity work.crazy_climber_sound
port map(
  cpu_clock    => cpu_clock,
  cpu_addr     => cpu_addr,
  cpu_data     => cpu_do,
  cpu_iorq_n   => cpu_iorq_n,
  reg4_we_n    => reg4_we_n,
  reg5_we_n    => reg5_we_n,
  reg6_we_n    => reg6_we_n,
  ym_2149_data => ym_8910_data,
  sound_sample => audio_out
);
------------------------------------------
end architecture;