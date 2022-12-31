----------------------------------------------------------------------------------
--
-- 05xx: Namco starfield generator for CPLDs, implementation matches
--       real custom chips using the correct LFSR and output decoding.
--
-- (c) copyright 2013 by W. Scherr, www.pin4.at, ws_arcade@pin4.at
--
-- $Id$
--
-------------------------------------------------------------------------------
-- Redistribution and use in source and synthesized forms, with or without
-- modification, also in projects with different (but compatible) licenses,
-- are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions, a modification note and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation or other materials provided with the distribution.
--
-- * The code must not be used for commercial purposes or re-licensed without
--   specific prior written permission of the author and contributors. It is
--   strictly for private use in hobby projects, without commercial interests.
--
-- * A person redistributing this code or any work products in private or 
--   public is also responsible for any legal issues which may arise by that.
--
-- Please feel free to report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that you have the latest 
-- version of this file. 
-------------------------------------------------------------------------------
-- DISCLAIMER
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
-- ARISING IN ANY WAY OUT OF THE USE OF THIS CODE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity n05xx is
    Port (
                clk_i    : in    std_logic;
                clk_en_i : in    std_logic;       -- tie to '1' if not used
		resn_i   : in    std_logic;		-- "starclr"
		oen_i    : in    std_logic;
		en_i     : in    std_logic;		-- "256H"
		vsn_i    : in    std_logic;
		hsn_i    : in    std_logic;
		xctrl_i  : in    std_logic_vector(2 downto 0);
		yctrl_i  : in    std_logic_vector(2 downto 0);
		map_i    : in    std_logic_vector(1 downto 0);
		rgb_o    : out   std_logic_vector(5 downto 0);
		lsfr_o   : out   std_logic;		-- usually not used
		oe_o     : out   std_logic
	);
end n05xx;

architecture rtl of n05xx is

signal vsn_del_s : std_logic_vector(3 downto 0) := "1111";
signal vsn_win_s   : std_logic;

signal lfsr_win_del_s : std_logic_vector(2 downto 0) := "111";
signal lfsr_win_s   : std_logic := '1';
signal lsfr_en_s   : std_logic;

signal lsfr_s : std_logic_vector(15 downto 0) := "1110011110111111";

signal rgb_s  : std_logic_vector(5 downto 0);
signal oe_s   : std_logic;

begin

	-- The idea of the scrolling is that the linear feedback shift register
	-- has a period of 65535 cycles and the screen display for the stars is
	-- 256x256=65536 pixel. So by proper enabling this register during the
	-- blanking phase it is possible to "shift" the LFSR in all 4 directions.
	-- (BUT: the X scroll makes some error, as all 256 x shifts a single y
	--  shift happens - the actual replacements DO NOT cover this fact!)

	-- LFSR enable signal Y
	-- -----------------------

	-- (controls y-scrolling by adding/removing line sync cycles per frame to the LFSR period)
	-- for that we logically and/or the shifted (delayed) horizontal sync accordingly
	lsfr_ydelay : process (clk_i, resn_i, clk_en_i) is
		variable hsn_v : std_logic;
	begin
		if resn_i='0' then
			hsn_v:='1';
			vsn_del_s<="1111";
		elsif rising_edge(clk_i) and clk_en_i = '1' then
			if hsn_i='1' and hsn_v='0' then
				vsn_del_s <= vsn_del_s(2 downto 0) & vsn_i;
			end if;
			hsn_v := hsn_i;
		end if;
	end process lsfr_ydelay;
	-- yspeed: 7 (period 2^16-1-256 = 65279, scroll -1 line)
	vsn_win_s  <= 	vsn_del_s(3) and vsn_del_s(2) when yctrl_i(2 downto 0)="111" else
	-- yspeed: 6 (period 2^16-1-512 = 65023, scroll -2 lines)
					vsn_del_s(3) and vsn_del_s(1) when yctrl_i(2 downto 0)="110" else
	-- yspeed: 5 (period 2^16-1-768 = 64767, scroll -3 lines)
					vsn_del_s(3) and vsn_del_s(0) when yctrl_i(2 downto 0)="101" else
	-- yspeed: 1 (period 2^16-1+256 = 65791, scroll +1 line)
					vsn_del_s(3) or  vsn_del_s(2) when yctrl_i(2 downto 0)="001" else
	-- yspeed: 2 (period 2^16-1+512 = 66047, scroll +2 lines)
					vsn_del_s(3) or  vsn_del_s(1) when yctrl_i(2 downto 0)="010" else
	-- yspeed: 3 (period 2^16-1+768 = 66303, scroll +3 lines)
					vsn_del_s(3) or  vsn_del_s(0) when yctrl_i(2 downto 0)="011" else
	-- yspeed: 0/4 (period 2^16-1 = 65535, scroll +/-0 lines)
					vsn_del_s(3);

	-- LFSR enable signal X
	-- -----------------------
	
	-- (controls x-scrolling by adding/removing single clock cycles per frame to the LFSR period)
	-- for that we logically and/or the shifted (delayed) vertical sync accordingly
	lsfr_xdelay : process (clk_i, resn_i, clk_en_i) is
	begin
		if resn_i='0' then
			lfsr_win_del_s<="111";
			lfsr_win_s<='1';
		elsif rising_edge(clk_i) and clk_en_i = '1' then
			lfsr_win_del_s <= lfsr_win_del_s(1 downto 0) & lfsr_win_s;
			if en_i='1' then
				lfsr_win_s <= vsn_win_s;
			end if;
		end if;
	end process lsfr_xdelay;
	-- xspeed: 6 (period 2^16-2 = 65534, scroll -1 pixel)
	lsfr_en_s  <=	lfsr_win_del_s(0) and vsn_win_s when xctrl_i(2 downto 0)="110" else
	-- xspeed: 5 (period 2^16-2 = 65533, scroll -2 pixel)
					lfsr_win_del_s(1) and vsn_win_s when xctrl_i(2 downto 0)="101" else
	-- xspeed: 4 (period 2^16-2 = 65532, scroll -3 pixel)
					lfsr_win_del_s(2) and vsn_win_s when xctrl_i(2 downto 0)="100" else
	-- xspeed: 0 (period 2^16 = 65536, scroll +1 pixel)
					lfsr_win_s when xctrl_i(2 downto 0)="000" else
	-- xspeed: 1 (period 2^16+1 = 65537, scroll +2 pixel)
					(lfsr_win_s or lfsr_win_del_s(0)) when xctrl_i(2 downto 0)="001" else
	-- xspeed: 2 (period 2^16+2 = 65538, scroll +3 pixel)
					(lfsr_win_s or lfsr_win_del_s(1)) when xctrl_i(2 downto 0)="010" else
	-- xspeed: 7/3 (period 2^16-1 = 65535, scroll +/-0 pixel)
					lfsr_win_s and vsn_win_s;

	-- LSFR the "hart" of the starfield generator...
	-- ------------------------------------------------

	lsfr : process (clk_i, resn_i, clk_en_i) is
	begin
		if resn_i='0' then
			-- reset value ensures exactly the same behavior as original
			-- (makes a difference e.g. in Bosconian on start screen, by this
			--  the "static" stars are perfectly the same as with the original game)
			lsfr_s <= "1110011110111111";
		elsif rising_edge(clk_i) and clk_en_i = '1' then
			-- all the fuzz is about this generator polynomial, this is the base for
			-- generating the correct RGB code and enable signal for the stars!
			-- This is the ONLY possible/correct polynomial out of 65536 possibilities.
			if en_i='1' and lsfr_en_s='1' then
				lsfr_s <= "0"&lsfr_s(15 downto 1) xor lsfr_s(0)&"00"&lsfr_s(0)&"0"&lsfr_s(0)&"0000"&lsfr_s(0)&"00000";
			end if;
		end if;
	end process lsfr;

	-- OUTPUT ENABLE LUT
	-- (out of enable inputs + map control input + LSFR code)
	-- RGB LUT
	-- (out of LSFR code)
	-- ------------------------------------------------------

	rgb_out_lut : process (lsfr_s, map_i, en_i) is
	variable oe1_v : std_logic;
	variable oe2_v : std_logic;
	variable oe3_v : std_logic;
	
	variable rgb0_v : std_logic;
	variable rgb1_v : std_logic;
	variable rgb2_v : std_logic;
	variable rgb3_v : std_logic;
	variable rgb4_v : std_logic;
	begin		
		-- RGB ENABLE
		oe1_v := (lsfr_s(13) xor lsfr_s(10));
		oe2_v := ((lsfr_s(15) and lsfr_s(12)) and oe1_v) or 
				   ((lsfr_s(15) nor lsfr_s(12)) and (not oe1_v));
		oe3_v := oe2_v and 
		         (not lsfr_s(1)) and lsfr_s(3) and lsfr_s(4) and lsfr_s(5) and (not lsfr_s(7));
		oe_s <= en_i and oe3_v and
		        ( (lsfr_s(0) and lsfr_s(2) and (not lsfr_s(6)) and map_i(1)) or
				    ((not lsfr_s(0)) and lsfr_s(2) and lsfr_s(6) and (not map_i(1))) or
					 (lsfr_s(0) and (lsfr_s(2) nor lsfr_s(6)) and map_i(0)) or
					 ((lsfr_s(0) nor lsfr_s(2)) and lsfr_s(6) and (not map_i(0))));
		-- RGB
		rgb0_v :=     lsfr_s(15)  and not(lsfr_s(13)) and     lsfr_s(12);
		rgb1_v := not(lsfr_s(15)) and     lsfr_s(13)  and not(lsfr_s(12));
		rgb2_v := not(lsfr_s(15)) and not(lsfr_s(13)) and not(lsfr_s(12));
		rgb3_v :=     lsfr_s(15)  and     lsfr_s(13)  and     lsfr_s(12);
		rgb4_v := (    lsfr_s(10)  and ( rgb1_v or rgb0_v) ) or
					 (not(lsfr_s(10)) and ( rgb2_v or rgb3_v) );
		rgb_s(0)  <= (rgb0_v and     lsfr_s(10) ) or
						 (rgb2_v and not(lsfr_s(10)));
		rgb_s(1)  <= not(lsfr_s(14)) and rgb4_v;
		rgb_s(2)  <= (rgb1_v and lsfr_s(10)) or
						 (rgb2_v and not(lsfr_s(10)));
		rgb_s(3)  <= ((( lsfr_s(11) and not(lsfr_s(8)) ) or
						  ( not(lsfr_s(11)) and lsfr_s(8) )) and (
									 (    lsfr_s(10)  and ( (rgb1_v and not(lsfr_s(14))) or (rgb0_v and lsfr_s(14))) ) or
									 (not(lsfr_s(10)) and ( (rgb2_v and lsfr_s(14)) or (rgb3_v and not(lsfr_s(14)))) )
						          )
						 ) or
		             (((not(lsfr_s(11)) and not(lsfr_s(8)) ) or
						  (     lsfr_s(11)  and lsfr_s(8) )) and (
									 (    lsfr_s(10)  and ( (rgb1_v and lsfr_s(14)) or (rgb0_v and not(lsfr_s(14)))) ) or
									 (not(lsfr_s(10)) and ( (rgb2_v and not(lsfr_s(14))) or (rgb3_v and lsfr_s(14))) )
						          )
						 );
		rgb_s(4)  <=  ((not(lsfr_s(14)) and not(lsfr_s(9)) ) or
						   (    lsfr_s(14)  and     lsfr_s(9)  )) and 
						  rgb4_v;
		rgb_s(5)  <=  ((not(lsfr_s(14)) and not(lsfr_s(11)) ) or
						   (    lsfr_s(14)  and     lsfr_s(11)  )) and 
						  rgb4_v;
	end process rgb_out_lut;

	-- final outputs
	-- -------------

	lsfr_o <= lsfr_s(0);
	oe_o <= oe_s and not(oen_i);
	rgb_o <= rgb_s;  -- when oe_s='1' and oen_i='0' else (others => 'Z');
	
end rtl;
