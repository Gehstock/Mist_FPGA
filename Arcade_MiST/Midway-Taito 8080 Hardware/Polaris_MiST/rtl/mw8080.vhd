-- Midway 8080 main board
-- 9.984MHz Clock
--
-- Version : 0242
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
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
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--      http://www.fpgaarcade.com
--
-- Limitations :
--
-- File history :
--
--      0241 : First release
--
--      0242 : Removed the ROM
--
--      0300 : MikeJ tidyup for audio release
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mw8080 is
	port(
		Rst_n           : in  std_logic;
		Clk             : in  std_logic;
		ENA             : out std_logic;
		RWE_n           : out std_logic;
		RDB             : in  std_logic_vector(7 downto 0);
		RAB             : out std_logic_vector(12 downto 0);
		Sounds          : out std_logic_vector(7 downto 0);
		Ready           : out std_logic;
		GDB             : in  std_logic_vector(7 downto 0);
		IB              : in  std_logic_vector(7 downto 0);
		DB              : out std_logic_vector(7 downto 0);
		AD              : out std_logic_vector(15 downto 0);
		Status          : out std_logic_vector(7 downto 0);
		Systb           : out std_logic;
		Int             : out std_logic;
		Hold_n          : in  std_logic;
		IntE            : out std_logic;
		DBin_n          : out std_logic;
		Vait            : out std_logic;
		HldA            : out std_logic;
		Sample          : out std_logic;
		Wr              : out std_logic;
		ScreenFlip      : in std_logic;
		Overlay         : in std_logic;
		Overlay_Align   : in std_logic;
		OverlayTest     : in std_logic;
		color_prom_out  : in  std_logic_vector(7 downto 0);
		color_prom_addr : out std_logic_vector(10 downto 0);
		VShift		    : in  std_logic_vector(3 downto 0);
		HShift		    : in  std_logic_vector(3 downto 0);
		O_VIDEO_R       : out std_logic;
		O_VIDEO_G       : out std_logic;
		O_VIDEO_B       : out std_logic;
		O_VIDEO_A       : out std_logic;
		Video           : out std_logic;
		HSync           : out std_logic;
		VSync           : out std_logic;
		HBlank           : out std_logic;
		VBlank           : out std_logic);
end mw8080;

architecture struct of mw8080 is

	component T8080se
	generic(
		Mode : integer := 2;
		T2Write : integer := 0);
	port(
		RESET_n         : in  std_logic;
		CLK             : in  std_logic;
		CLKEN           : in  std_logic;
		READY           : in  std_logic;
		HOLD            : in  std_logic;
		INT             : in  std_logic;
		INTE            : out std_logic;
		DBIN            : out std_logic;
		SYNC            : out std_logic;
		VAIT            : out std_logic;
		HLDA            : out std_logic;
		WR_n            : out std_logic;
		A               : out std_logic_vector(15 downto 0);
		DI              : in  std_logic_vector(7 downto 0);
		DO              : out std_logic_vector(7 downto 0));
	end component;

	signal Ready_i      : std_logic;
	signal Hold         : std_logic;
	signal IntTrig      : std_logic;
	signal IntTrigOld   : std_logic;
	signal Int_i        : std_logic;
	signal IntE_i       : std_logic;
	signal DBin         : std_logic;
	signal Sync         : std_logic;
	signal Wr_n, Rd_n   : std_logic;
	signal ClkEnCnt     : unsigned(2 downto 0);
	signal Status_i     : std_logic_vector(7 downto 0);
	signal A            : std_logic_vector(15 downto 0);
	signal ISel         : std_logic_vector(1 downto 0);
	signal DI           : std_logic_vector(7 downto 0);
	signal DO           : std_logic_vector(7 downto 0);
	signal RR           : std_logic_vector(9 downto 0);

	signal VidEn        : std_logic;
	signal CntD5        : unsigned(3 downto 0); -- Horizontal counter / 320
	signal CntE5        : unsigned(4 downto 0); -- Horizontal counter 2
	signal CntE6        : unsigned(3 downto 0); -- Vertical counter / 262
	signal CntE7        : unsigned(4 downto 0); -- Vertical counter 2
	signal Shift        : std_logic_vector(7 downto 0);
	
	signal HSync_Start  :  std_logic_vector(8 downto 0);
	signal HSync_End    :  std_logic_vector(8 downto 0);
	signal VSync_Start  :  std_logic_vector(8 downto 0);
	signal VSync_End    :  std_logic_vector(8 downto 0);
	signal HBlank_Start  :  std_logic_vector(8 downto 0);
	signal HBlank_End  :  std_logic_vector(8 downto 0);
	signal VBlank_Start  :  std_logic_vector(8 downto 0);
	signal VBlank_End  :  std_logic_vector(8 downto 0);
begin
	ENA <= ClkEnCnt(2);
	Status <= Status_i;
	Ready <= Ready_i;
	DB <= DO;
	Systb <= Sync;
	Int <= Int_i;
	Hold <= not Hold_n;
	IntE <= IntE_i;
	DBin_n <= not DBin;
	Sample <= not Wr_n and Status_i(4);
	Wr <= not Wr_n;
	AD <= A;
	Sounds(0) <= CntE7(3);
	Sounds(1) <= CntE7(2);
	Sounds(2) <= CntE7(1);
	Sounds(3) <= CntE7(0);
	Sounds(4) <= CntE6(3);
	Sounds(5) <= CntE6(2);
	Sounds(6) <= CntE6(1);
	Sounds(7) <= CntE6(0);

	IntTrig <= (not CntE7(2) nand CntE7(3)) nand not CntE7(4);

	ISel(0) <= Status_i(0) nor (Status_i(6) nor A(13));
	ISel(1) <= Status_i(0) nor Status_i(6);

	with ISel select
		DI <= "110" & CntE7(2) & not CntE7(2) & "111" when "00",
			GDB when "01",
			IB when "10",
			RR(7 downto 0) when others;

	RWE_n <= Wr_n or not (RR(8) xor RR(9)) or not CntD5(2);
	RAB <= A(12 downto 0) when CntD5(2) = '1' else
		std_logic_vector(CntE7(3 downto 0) & CntE6(3 downto 0) & CntE5(3 downto 0) & CntD5(3));

	u_8080: T8080se
		generic map (
			Mode => 2,
			T2Write => 1)
		port map (
			RESET_n => Rst_n,
			CLK => Clk,
			CLKEN => ClkEnCnt(2),
			READY => Ready_i,
			HOLD => Hold,
			INT => Int_i,
			INTE => IntE_i,
			DBIN => DBin,
			SYNC => Sync,
			VAIT => Vait,
			HLDA => HLDA,
			WR_n => Wr_n,
			A => A,
			DI => DI,
			DO => DO);

	-- Clock enables
	process (Rst_n, Clk)
	begin
		if Rst_n = '0' then
			ClkEnCnt <= "000";
			VidEn <= '0';
		elsif Clk'event and Clk = '1' then
			VidEn <= not VidEn;
			if ClkEnCnt = 4 then
				ClkEnCnt <= "000";
			else
				ClkEnCnt <= ClkEnCnt + 1;
			end if;
		end if;
	end process;

	-- Glue
	process (Rst_n, Clk)
		variable OldASEL : std_logic;
	begin
		if Rst_n = '0' then
			Status_i <= (others => '0');
			IntTrigOld <= '0';
			Int_i <= '0';
			OldASEL := '0';
			Ready_i <= '0';
			RR <= (others => '0');
		elsif Clk'event and Clk = '1' then
			-- E3
			-- Interrupt
			IntTrigOld <= IntTrig;
			if Status_i(0) = '1' then
				Int_i <= '0';
			elsif IntTrigOld = '0' and IntTrig = '1' then
				Int_i <= IntE_i;
			end if;

			-- D7
			-- Status register
			if Sync = '1' then
				Status_i <= DO;
			end if;

			-- A3, C3, E3
			-- RAM register/ready logic
			if Sync = '1' and A(13) = '1' then
				Ready_i <= '0';
			elsif Ready_i = '1' then
				Ready_i <= '1';
			else
				Ready_i <= RR(9);
			end if;
			if Sync = '1' and A(13) = '1' then
				RR <= (others => '0');
			elsif (CntD5(2) = '1' and OldASEL = '0') or                                 -- ASEL pos edge
				(CntD5(2) = '0' and OldASEL = '1' and RR(8) = '1') then -- ASEL neg edge
				RR(7 downto 0) <= RDB;
				RR(8) <= '1';
				RR(9) <= RR(8);
			end if;
			OldASEL := CntD5(2);
		end if;
	end process;

	-- Video counters
	process (Rst_n, Clk)
	begin
		if Rst_n = '0' then
			CntD5 <= (others => '0');
			CntE5 <= (others => '0');
			CntE6 <= (others => '0');
			CntE7 <= (others => '0');
		elsif Clk'event and Clk = '1' then
			if VidEn = '1' then
				CntD5 <= CntD5 + 1;
				if CntD5 = 15 then

					CntE5 <= CntE5 + 1;
					if CntE5(3 downto 0) = 15 then
						if CntE5(4) = '0' then
							CntE5 <= "11100";

							CntE6 <= CntE6 + 1;
							if CntE6 = 15 then

								CntE7 <= CntE7 + 1;
								if CntE7(3 downto 0) = 15 then
									if CntE7(4) = '0' then
										CntE6 <= "1010";
										CntE7 <= "11101";
									else
										CntE7 <= "00010";
									end if;
								end if;
							end if;
						end if;
					else
					end if;
				end if;
			end if;
		end if;
	end process;

--	-- Video shift register
--	process (Rst_n, Clk)
--	begin
--		if Rst_n = '0' then
--			Shift <= (others => '0');
--			Video <= '0';
--		elsif Clk'event and Clk = '1' then
--			if VidEn = '1' then
--				if CntE7(4) = '0' and CntE5(4) = '0' and CntD5(2 downto 0) = "011" then
--					Shift(7 downto 0) <= RDB(7 downto 0);
--				else
--					Shift(6 downto 0) <= Shift(7 downto 1);
--					Shift(7) <= '0';
--				end if;
--				Video <= Shift(0);
--			end if;
--		end if;
--	end process;
--
--	-- Sync
--	process (Rst_n, Clk)
--	begin
--		if Rst_n = '0' then
--			HSync <= '1';
--			VSync <= '1';
--		elsif Clk'event and Clk = '1' then
--			if VidEn = '1' then
--				if CntE5(4) = '1' and CntE5(1 downto 0) = "10" then
--					HSync <= '0';
--				else
--					HSync <= '1';
--				end if;
--				if CntE7(4) = '1' and CntE7(0) = '0' and CntE6(3 downto 2) = "11" then
--					VSync <= '0';
--				else
--					VSync <= '1';
--				end if;
--			end if;
--		end if;
--	end process;

	-- Video shift register
	process (Rst_n, Clk)
	variable H_Pos  : unsigned(8 downto 0);
	variable V_Pos  : unsigned(8 downto 0);
	variable Bitmap : std_logic_vector(7 downto 0);
	begin
		if Rst_n = '0' then
			Shift <= (others => '0');
			Video <= '0';
		elsif Clk'event and Clk = '1' then
			if VidEn = '1' then
				if CntE7(4) = '0' and CntE5(4) = '0' and CntD5(2 downto 0) = "011" then

					-- Corrected horizontal position for Vortex
					H_Pos(8 downto 4) := CntE5;
					H_Pos(3 downto 0) := CntD5; 
					H_Pos := H_Pos - 3;

					-- Used to correct if overlay aligned to 4 pixels
					V_Pos := CntE7 & CntE6;
					
					if ScreenFlip='0' then
						-- Normal way up
						if Overlay_Align='0' then
							color_prom_addr <= std_logic_vector('0' & CntE7(3 downto 0) & CntE6(3) & CntE5(3 downto 0) & CntD5(3));
						else
							V_Pos := V_Pos + 4;
							color_prom_addr <= std_logic_vector('0' & V_Pos(7 downto 3) & CntE5(3 downto 0) & CntD5(3));
						end if;
						Bitmap          := RDB;
						--LastVortexCol   <= not Vortex_Col & H_Pos(5) & Vortex_Col;
					else
					   -- Flipped 
						if Overlay_Align='0' then
							v_Pos := V_Pos - 32;
							color_prom_addr <= not std_logic_vector('1' & V_Pos(7 downto 3) & CntE5(3 downto 0) & CntD5(3));
						else
							v_Pos := V_Pos - 28;
							color_prom_addr <= not std_logic_vector('1' & V_Pos(7 downto 3) & CntE5(3 downto 0) & CntD5(3));
						end if;
						Bitmap          := RDB(0) & RDB(1) & RDB(2) & RDB(3) & RDB(4) & RDB(5) & RDB(6) & RDB(7);
						--LastVortexCol   <= not Vortex_Col & not H_Pos(5) & Vortex_Col;
					end if;
					 
					if OverlayTest='1' then
						case CntE6(2 downto 0) is
							when "000" | "111" => Shift(7 downto 0) <= Bitmap(7 downto 0) or x"C3";
							when "001" | "110" => Shift(7 downto 0) <= Bitmap(7 downto 0) or x"81";
							when others        => Shift(7 downto 0) <= Bitmap(7 downto 0);
						end case;
					else
						Shift(7 downto 0) <= Bitmap(7 downto 0);
					end if;
				else
					Shift(6 downto 0) <= Shift(7 downto 1);
					Shift(7) <= '0';
				end if;
				Video <= Shift(0);
				O_VIDEO_A <= Shift(0); -- Background or Foreground (1 = background)
				if (Shift(0)='1') then
				   if (Overlay = '1') then
						  O_VIDEO_R <= color_prom_out(0);
						  O_VIDEO_G <= color_prom_out(2);
						  O_VIDEO_B <= color_prom_out(1);
			           else
				     O_VIDEO_R <= '1';
				     O_VIDEO_G <= '1';
				     O_VIDEO_B <= '1';
			           end if;
				else
				   O_VIDEO_R <= '0';
				   O_VIDEO_G <= '0';
				   O_VIDEO_B <= '0';
				end if;

			end if;
		end if;
	end process;

	-- Mister Sync / Blank and Counters
	
	process (HShift, VShift, Rst_n)
	begin
		-- Defaults are centred on my CRT
		HSync_Start <= std_logic_vector(469 + resize(signed(HShift),9));
		HSync_End   <= std_logic_vector(485 + resize(signed(HShift),9));
		VSync_Start <= std_logic_vector(484 + resize(signed(VShift),9));
		VSync_End   <= std_logic_vector(488 + resize(signed(VShift),9));	
		
		HBlank_Start <= 	"000000101";
		HBlank_End <= 		"111001001";
		VBlank_Start <= 	"011111111";
		VBlank_End <= 		"111111111";
		
	end process;
	
	process (Rst_n, Clk)
		variable TimeH, TimeV : std_logic_vector(8 downto 0);
	begin
		if Rst_n = '0' then

			HSync <= '1';
			VSync <= '1';
			HBlank <='1';
			VBlank <='1';

		elsif Clk'event and Clk = '1' then
		
			if VidEn = '1' then
			
				-- Convert SI counters into single fields to make comparisons easier
				
				TimeH := std_logic_vector(CntE5(4 downto 0)) & std_logic_vector(CntD5(3 downto 0));
				TimeV := std_logic_vector(CntE7(4 downto 0)) & std_logic_vector(CntE6(3 downto 0));
				
				-- Syncs
				
				if (TimeH = HSync_Start) then
					HSync <= '0';
				elsif (TimeH = HSync_End) then
					HSync <= '1';
				end if;

				if (TimeV = VSync_Start) then
					VSync <= '0';
				elsif (TimeV = VSync_End) then
					VSync <= '1';
				end if;

				-- Blanks
				
				if (TimeH = HBlank_Start) then
					HBlank <= '0';
				elsif (TimeH = HBlank_End) then
					HBlank <= '1';
				end if;

				if (TimeV = VBlank_Start) then
					VBlank <= '1';
				elsif (TimeV = VBlank_End) then
					VBlank <= '0';
				end if;
				
			end if;

		end if;
		
	end process;

end;
