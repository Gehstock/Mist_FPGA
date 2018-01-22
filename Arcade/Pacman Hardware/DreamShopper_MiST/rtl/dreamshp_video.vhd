--
-- A simulation model of Pacman hardware
-- Copyright (c) MikeJ - January 2006
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email pacman@fpgaarcade.com
--
-- Revision list
--
-- version 003 Jan 2006 release, general tidy up
-- version 001 initial release
--
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity DREAMSHP_VIDEO is
	generic(
		alt_transp : boolean := true
	);
	port (
		I_HCNT    : in  std_logic_vector(8 downto 0);
		I_VCNT    : in  std_logic_vector(8 downto 0);
		--
		vram_data : in  std_logic_vector(7 downto 0);
		sprite_xy : in  std_logic_vector(7 downto 0);
		--
		I_HBLANK  : in  std_logic;
		I_VBLANK  : in  std_logic;
		I_FLIP    : in  std_logic;
		O_HBLANK  : out std_logic;
		--
		O_RED     : out std_logic_vector(2 downto 0);
		O_GREEN   : out std_logic_vector(2 downto 0);
		O_BLUE    : out std_logic_vector(1 downto 0);
		ENA_6     : in  std_logic;
		CLK       : in  std_logic
	);
end;

architecture RTL of DREAMSHP_VIDEO is

	signal dr                 : std_logic_vector(7 downto 0);

	signal char_reg           : std_logic_vector(7 downto 0);
	signal char_sum_reg       : std_logic_vector(3 downto 0);
	signal char_match_reg     : std_logic;
	signal char_hblank_reg    : std_logic;
	signal char_hblank_reg_t1 : std_logic;
	signal sprite_data        : std_logic_vector(7 downto 0);

	signal xflip              : std_logic;
	signal yflip              : std_logic;
	signal obj_on             : std_logic;
	signal obj_on2            : std_logic;

	signal ca                 : std_logic_vector(12 downto 0);
	signal char_rom_5ef_buf   : std_logic_vector(7 downto 0);

	signal shift_regl         : std_logic_vector(3 downto 0);
	signal shift_regu         : std_logic_vector(3 downto 0);
	signal shift_op           : std_logic_vector(1 downto 0);
	signal shift_op_t1        : std_logic_vector(1 downto 0);
	signal shift_sel          : std_logic_vector(1 downto 0);

	signal vout_obj_on        : std_logic;
	signal vout_obj_on_t1     : std_logic;
	signal vout_yflip         : std_logic;
	signal vout_hblank        : std_logic;
	signal vout_hblank_t1     : std_logic;
	signal vout_db            : std_logic_vector(4 downto 0);

	signal sprite_ram_ip      : std_logic_vector(5 downto 0);
	signal sprite_ram_op      : std_logic_vector(5 downto 0);
	signal sprite_addr        : std_logic_vector(7 downto 0);
	signal sprite_addr_t1     : std_logic_vector(7 downto 0);

	signal lut_4a             : std_logic_vector(7 downto 0);
	signal lut_4a_t1          : std_logic_vector(7 downto 0);
	signal sprite_ram_reg     : std_logic_vector(5 downto 0);

	signal video_op_sel       : std_logic;
	signal final_col          : std_logic_vector(3 downto 0);

begin

dr <= not sprite_xy when I_HBLANK = '1' else "11111111"; -- pull ups on board

p_char_regs : process
	variable sum : std_logic_vector(8 downto 0);
	variable match : std_logic;
begin
	wait until rising_edge (CLK);
	if (I_HCNT(2 downto 0) = "011") and (ENA_6 = '1') then  -- rising 4h

		-- 1f, 2f
		sum := (I_VCNT(7 downto 0) & '1') + (dr & not I_HBLANK);

		-- 3e
		match := '0';

		if (sum(8 downto 5) = "1111") then
			match := '1';
		end if;

		-- 1h
		char_sum_reg     <= sum(4 downto 1);
		char_match_reg   <= match;
		char_hblank_reg  <= I_HBLANK;

		-- 4d
		sprite_data <= vram_data; -- character reg
	end if;
end process;

xflip <= I_FLIP when char_hblank_reg = '0' else sprite_data(1);
yflip <= I_FLIP when char_hblank_reg = '0' else sprite_data(0);

obj_on <= char_match_reg or I_HCNT(8); -- 256h not 256h_l

ca(12) <= char_hblank_reg;
ca(11 downto 6) <= sprite_data(7 downto 2);
ca(5) <= sprite_data(1) when char_hblank_reg = '0' else char_sum_reg(3) xor xflip;
ca(4) <= sprite_data(0) when char_hblank_reg = '0' else I_HCNT(3);
ca(3) <= I_HCNT(2)       xor yflip;
ca(2) <= char_sum_reg(2) xor xflip;
ca(1) <= char_sum_reg(1) xor xflip;
ca(0) <= char_sum_reg(0) xor xflip;

-- char roms
char_rom_5ef : entity work.GFX1
port map
(
	CLK         => CLK,
	ADDR        => ca,
	DATA        => char_rom_5ef_buf
);

p_char_shift : process
begin
	-- 4 bit shift req
	wait until rising_edge (CLK);
	if (ENA_6 = '1') then
		case shift_sel is
			when "00" =>	null;

			when "01" =>	shift_regu <= '0' & shift_regu(3 downto 1);
								shift_regl <= '0' & shift_regl(3 downto 1);

			when "10" =>	shift_regu <= shift_regu(2 downto 0) & '0';
								shift_regl <= shift_regl(2 downto 0) & '0';

			when "11" =>	shift_regu <= char_rom_5ef_buf(7 downto 4); -- load
								shift_regl <= char_rom_5ef_buf(3 downto 0);
			when others => null;
		end case;
	end if;
end process;

shift_sel(0) <= I_HCNT(0) and I_HCNT(1) when vout_yflip = '0' else '1';
shift_sel(1) <= '1'                     when vout_yflip = '0' else I_HCNT(0) and I_HCNT(1);
shift_op(0)  <= shift_regl(3)           when vout_yflip = '0' else shift_regl(0);
shift_op(1)  <= shift_regu(3)           when vout_yflip = '0' else shift_regu(0);           

p_video_out_reg : process
begin
	wait until rising_edge (CLK);
	if (ENA_6 = '1') then
		if (I_HCNT(2 downto 0) = "111") then
			vout_obj_on   <= obj_on;
			vout_yflip    <= yflip;
			vout_hblank   <= I_HBLANK;
			vout_db(4 downto 0) <= vram_data(4 downto 0); -- colour reg
		end if;

		if I_HCNT(3 downto 0) = "0111" and (vout_hblank='1' or I_HBLANK='1' or vout_obj_on='0') then
			sprite_addr <= dr;
		else
			sprite_addr <= sprite_addr + "1";
		end if;
	end if;
end process;

col_rom_4a : entity work.PROM4_DST
port map
(
	ADDR(7)          => '0',
	ADDR(6 downto 2) => vout_db(4 downto 0),
	ADDR(1 downto 0) => shift_op(1 downto 0),
	DATA             => lut_4a
);

u_sprite_ram : work.dpram generic map (8,6)
port map
(
	clock_a   => CLK,
	enable_a  => ENA_6,
	wren_a    => vout_obj_on_t1,
	address_a => sprite_addr_t1,
	data_a    => sprite_ram_ip,

	clock_b   => CLK,
	enable_b  => ENA_6,
	address_b => sprite_addr,
	q_b       => sprite_ram_op
);

sprite_ram_reg <= sprite_ram_op when vout_obj_on_t1 = '1' else "000000";
video_op_sel <= '0' when alt_transp and (sprite_ram_reg(1 downto 0) = "00") else
                '0' when not alt_transp and (sprite_ram_reg(5 downto 2) = "0000") else
					 '1';

p_sprite_ram_ip_reg : process
begin
	wait until rising_edge (CLK);
	if (ENA_6 = '1') then
		sprite_addr_t1 <= sprite_addr;
		vout_obj_on_t1 <= vout_obj_on;
		vout_hblank_t1 <= vout_hblank;
		lut_4a_t1      <= lut_4a;
		shift_op_t1    <= shift_op;
	end if;
end process;

sprite_ram_ip <= (others => '0') when vout_hblank_t1 = '0' else
					  sprite_ram_reg when video_op_sel = '1' else
					  lut_4a_t1(3 downto 0) & shift_op_t1;

final_col <= (others => '0') when (vout_hblank = '1') or (I_VBLANK = '1') else
				 sprite_ram_reg(5 downto 2) when video_op_sel = '1' else 
				 lut_4a(3 downto 0);

-- assign video outputs from color LUT PROM
col_rom_7f : entity work.PROM7_DST
port map
(
	CLK              => CLK,
	ADDR(3 downto 0) => final_col,
	DATA(2 downto 0) => O_RED,
	DATA(5 downto 3) => O_GREEN,
	DATA(7 downto 6) => O_BLUE
);

O_HBLANK <= vout_hblank and vout_hblank_t1;

end architecture;
