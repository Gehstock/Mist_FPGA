--
-- A simulation model of YM2149 (AY-3-8910 with bells on)

-- Copyright (c) MikeJ - Jan 2005
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
-- Email support@fpgaarcade.com
--
-- Revision list
--
-- version 001 initial release
-- version 002 Bomb Jack customizations
--             commented out ports IOA and IOB
--             added support for IOA register to internally control master volume of all 3 audio channels
--
-- Clues from MAME sound driver and Kazuhiro TSUJIKAWA
--
-- These are the measured outputs from a real chip for a single Isolated channel into a 1K load (V)
-- vol 15 .. 0
-- 3.27 2.995 2.741 2.588 2.452 2.372 2.301 2.258 2.220 2.198 2.178 2.166 2.155 2.148 2.141 2.132
-- As the envelope volume is 5 bit, I have fitted a curve to the not quite log shape in order
-- to produced all the required values.
-- (The first part of the curve is a bit steeper and the last bit is more linear than expected)
--
-- NOTE, this component uses LINEAR mixing of the three analogue channels, and is only
-- accurate for designs where the outputs are buffered and not simply wired together.
-- The ouput level is more complex in that case and requires a larger table.

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;

entity YM2149 is
	port (
		-- data bus
		I_DA			: in  std_logic_vector(7 downto 0);
		O_DA			: out std_logic_vector(7 downto 0);
--		O_DA_OE_L	: out std_logic;
		-- control
		I_A9_L		: in  std_logic;
		I_A8			: in  std_logic;
		I_BDIR		: in  std_logic;
		I_BC2			: in  std_logic;
		I_BC1			: in  std_logic;
		I_SEL_L		: in  std_logic;

		O_AUDIO		: out std_logic_vector(7 downto 0) := (others => '0');
		I_CHEN		: in  std_logic_vector(2 downto 0) := (others => '0');
		-- port a
--		I_IOA			: in  std_logic_vector(7 downto 0);
--		O_IOA			: out std_logic_vector(7 downto 0);
--		O_IOA_OE_L	: out std_logic;
		-- port b
--		I_IOB			: in  std_logic_vector(7 downto 0);
--		O_IOB			: out std_logic_vector(7 downto 0);
--		O_IOB_OE_L	: out std_logic;

		ENA			: in  std_logic; -- clock enable for higher speed operation
		RESET_L		: in  std_logic;
		CLK			: in  std_logic  -- note 6 Mhz
	);
end;

architecture RTL of YM2149 is
	type  array_16x8   is array (0 to 15) of std_logic_vector(7 downto 0);
	type  array_3x12   is array (1 to 3) of std_logic_vector(11 downto 0);

	signal cnt_div				: std_logic_vector(3 downto 0) := (others => '0');
	signal noise_div			: std_logic := '0';
	signal ena_div				: std_logic;
	signal ena_div_noise		: std_logic;
	signal poly17				: std_logic_vector(16 downto 0) := (others => '0');

	-- registers
	signal addr					: std_logic_vector(7 downto 0);
	signal busctrl_addr		: std_logic;
	signal busctrl_we			: std_logic;
	signal busctrl_re			: std_logic;

	signal reg					: array_16x8 := (others => (others => '0'));
	signal env_reset			: std_logic := '1';
--	signal ioa_inreg			: std_logic_vector(7 downto 0);
--	signal iob_inreg			: std_logic_vector(7 downto 0);

	signal noise_gen_cnt		: std_logic_vector(4 downto 0);
	signal noise_gen_op		: std_logic;
	signal tone_gen_cnt		: array_3x12 := (others => (others => '0'));
	signal tone_gen_op		: std_logic_vector(3 downto 1) := (others => '0');

	signal env_gen_cnt		: std_logic_vector(15 downto 0);
	signal env_ena				: std_logic;
	signal env_hold			: std_logic;
	signal env_inc				: std_logic;
	signal env_vol				: std_logic_vector(4 downto 0);

	signal tone_ena_l			: std_logic;
	signal tone_src			: std_logic;
	signal noise_ena_l		: std_logic;
	signal chan_vol			: std_logic_vector(6 downto 0);

	signal dac_amp				: std_logic_vector(7 downto 0);
	signal audio_mix			: std_logic_vector(9 downto 0);
	signal audio_final		: std_logic_vector(9 downto 0);

	-- psg, bdir, bc2, bc1
	type	BUS_STATE_TYPE is ( nop0,AD0,nop1,RD,AD1,nop2,WR,AD2);
begin
	-- cpu i/f
	p_busdecode            : process(I_BDIR, I_BC2, I_BC1, addr, I_A9_L, I_A8)
		variable cs : std_logic;
		variable sel : std_logic_vector(2 downto 0);
	begin
		-- BDIR BC2 BC1 MODE
		--   0   0   0  inactive
		--   0   0   1  address
		--   0   1   0  inactive
		--   0   1   1  read
		--   1   0   0  address
		--   1   0   1  inactive
		--   1   1   0  write
		--   1   1   1  read
		busctrl_addr <= '0';
		busctrl_we <= '0';
		busctrl_re <= '0';

		cs := '0';
		if (I_A9_L = '0') and (I_A8 = '1') and (addr(7 downto 4) = "0000") then
			cs := '1';
		end if;

		sel := (I_BDIR & I_BC2 & I_BC1);
		case sel is
			when "000" => null;
			when "001" => busctrl_addr <= '1';
			when "010" => null;
			when "011" => busctrl_re   <= cs;
			when "100" => busctrl_addr <= '1';
			when "101" => null;
			when "110" => busctrl_we   <= cs;
			when "111" => busctrl_addr <= '1';
			when others => null;
		end case;
	end process;

--	p_oe : process(busctrl_re)
--	begin
--		-- if we are emulating a real chip, maybe clock this to fake up the tristate typ delay of 100ns
--		O_DA_OE_L <= not (busctrl_re);
--	end process;

	--
	-- CLOCKED
	--
	p_waddr : process(RESET_L, CLK)
	begin
		-- looks like registers are latches in real chip, but the address is caught at the end of the address state.
		if (RESET_L = '0') then
			addr <= (others => '0');
		elsif rising_edge(CLK) then
			if (ENA = '1') then
				if (busctrl_addr = '1') then
					addr <= I_DA;
				end if;
			end if;
		end if;
	end process;

	p_wdata : process(RESET_L, CLK)
	begin
		if (RESET_L = '0') then
			reg <= (others => (others => '0'));
			env_reset <= '1';
		elsif rising_edge(CLK) then
			if (ENA = '1') then
				env_reset <= '0';
				if (busctrl_we = '1') then
					case addr(3 downto 0) is
						when x"0" => reg(0)  <= I_DA;
						when x"1" => reg(1)  <= I_DA;
						when x"2" => reg(2)  <= I_DA;
						when x"3" => reg(3)  <= I_DA;
						when x"4" => reg(4)  <= I_DA;
						when x"5" => reg(5)  <= I_DA;
						when x"6" => reg(6)  <= I_DA;
						when x"7" => reg(7)  <= I_DA;
						when x"8" => reg(8)  <= I_DA;
						when x"9" => reg(9)  <= I_DA;
						when x"A" => reg(10) <= I_DA;
						when x"B" => reg(11) <= I_DA;
						when x"C" => reg(12) <= I_DA;
						when x"D" => reg(13) <= I_DA; env_reset <= '1';
						when x"E" => reg(14) <= I_DA;
						when x"F" => reg(15) <= I_DA;
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;

	p_rdata : process(busctrl_re, addr, reg) --, ioa_inreg, iob_inreg)
	begin
		O_DA <= (others => '0'); -- 'X'
		if (busctrl_re = '1') then -- not necessary, but useful for putting 'X's in the simulator
			case addr(3 downto 0) is
				when x"0" => O_DA <= reg(0);
				when x"1" => O_DA <= reg(1);
				when x"2" => O_DA <= reg(2);
				when x"3" => O_DA <= reg(3);
				when x"4" => O_DA <= reg(4);
				when x"5" => O_DA <= reg(5);
				when x"6" => O_DA <= reg(6);
				when x"7" => O_DA <= reg(7);
				when x"8" => O_DA <= reg(8);
				when x"9" => O_DA <= reg(9);
				when x"A" => O_DA <= reg(10);
				when x"B" => O_DA <= reg(11);
				when x"C" => O_DA <= reg(12);
				when x"D" => O_DA <= reg(13);
				when x"E" =>
--					if (reg(7)(6) = '0') then -- input
--						O_DA <= ioa_inreg;
--					else
						O_DA <= reg(14); -- read output reg
--					end if;
				when x"F" =>
--					if (Reg(7)(7) = '0') then
--						O_DA <= iob_inreg;
--					else
						O_DA <= reg(15);
--					end if;
				when others => null;
			end case;
		end if;
	end process;
  --
	p_divider : process
	begin
		wait until rising_edge(CLK);
		-- / 8 when SEL is high and /16 when SEL is low
		if (ENA = '1') then
			ena_div <= '0';
			ena_div_noise <= '0';
			if (cnt_div = "0000") then
				cnt_div <= (not I_SEL_L) & "111";
				ena_div <= '1';

				noise_div <= not noise_div;
				if (noise_div = '1') then
					ena_div_noise <= '1';
				end if;
			else
				cnt_div <= cnt_div - "1";
			end if;
		end if;
	end process;

	p_noise_gen : process
		variable noise_gen_comp : std_logic_vector(4 downto 0);
		variable poly17_zero : std_logic;
	begin
		wait until rising_edge(CLK);

		if (reg(6)(4 downto 0) = "00000") then
			noise_gen_comp := (others => '0');
		else
			noise_gen_comp := (reg(6)(4 downto 0) - "1");
		end if;

		poly17_zero := '0';
		if (poly17 = "00000000000000000") then poly17_zero := '1'; end if;

		if (ENA = '1') then

			if (ena_div_noise = '1') then -- divider ena
				if (noise_gen_cnt >= noise_gen_comp) then
					noise_gen_cnt <= (others => '0');
					poly17 <= (poly17(0) xor poly17(2) xor poly17_zero) & poly17(16 downto 1);
				else
					noise_gen_cnt <= (noise_gen_cnt + "1");
				end if;
			end if;
		end if;
	end process;
	noise_gen_op <= poly17(0);

	p_tone_gens : process
		variable tone_gen_freq : array_3x12;
		variable tone_gen_comp : array_3x12;
	begin
		wait until rising_edge(CLK);

		-- looks like real chips count up - we need to get the Exact behaviour ..
		tone_gen_freq(1) := reg(1)(3 downto 0) & reg(0);
		tone_gen_freq(2) := reg(3)(3 downto 0) & reg(2);
		tone_gen_freq(3) := reg(5)(3 downto 0) & reg(4);
		-- period 0 = period 1
		for i in 1 to 3 loop
			if (tone_gen_freq(i) = x"000") then
				tone_gen_comp(i) := (others => '0');
			else
				tone_gen_comp(i) := (tone_gen_freq(i) - "1");
			end if;
		end loop;

		if (ENA = '1') then
			for i in 1 to 3 loop
				if (ena_div = '1') then -- divider ena
					if (tone_gen_cnt(i) >= tone_gen_comp(i)) then
						tone_gen_cnt(i) <= (others => '0');
						tone_gen_op(i) <= not tone_gen_op(i);
					else
						tone_gen_cnt(i) <= (tone_gen_cnt(i) + "1");
					end if;
				end if;
			end loop;
		end if;
	end process;

	p_envelope_freq : process
		variable env_gen_freq : std_logic_vector(15 downto 0);
		variable env_gen_comp : std_logic_vector(15 downto 0);
	begin
		wait until rising_edge(CLK);
		env_gen_freq := reg(12) & reg(11);
		-- envelope freqs 1 and 0 are the same.
		if (env_gen_freq = x"0000") then
			env_gen_comp := (others => '0');
		else
			env_gen_comp := (env_gen_freq - "1");
		end if;

		if (ENA = '1') then
			env_ena <= '0';
			if (ena_div = '1') then -- divider ena
				if (env_gen_cnt >= env_gen_comp) then
					env_gen_cnt <= (others => '0');
					env_ena <= '1';
				else
					env_gen_cnt <= (env_gen_cnt + "1");
				end if;
			end if;
		end if;
	end process;

	p_envelope_shape : process(env_reset, reg, CLK)
		variable is_bot		: boolean;
		variable is_bot_p1	: boolean;
		variable is_top_m1	: boolean;
		variable is_top		: boolean;
	begin
		-- envelope shapes
		-- C AtAlH
		-- 0 0 x x  \___
		--
		-- 0 1 x x  /___
		--
		-- 1 0 0 0  \\\\
		--
		-- 1 0 0 1  \___
		--
		-- 1 0 1 0  \/\/
		--           ___
		-- 1 0 1 1  \
		--
		-- 1 1 0 0  ////
		--           ___
		-- 1 1 0 1  /
		--
		-- 1 1 1 0  /\/\
		--
		-- 1 1 1 1  /___
		if (env_reset = '1') then
			-- load initial state
			if (reg(13)(2) = '0') then -- attack
				env_vol <= (others => '1');
				env_inc <= '0'; -- -1
			else
				env_vol <= (others => '0');
				env_inc <= '1'; -- +1
			end if;
			env_hold <= '0';

		elsif rising_edge(CLK) then
			is_bot    := (env_vol = "00000");
			is_bot_p1 := (env_vol = "00001");
			is_top_m1 := (env_vol = "11110");
			is_top    := (env_vol = "11111");

			if (ENA = '1') then
				if (env_ena = '1') then
					if (env_hold = '0') then
						if (env_inc = '1') then
							env_vol <= (env_vol + "00001");
						else
							env_vol <= (env_vol + "11111");
						end if;
					end if;

					-- envelope shape control.
					if (reg(13)(3) = '0') then
						if (env_inc = '0') then -- down
							if is_bot_p1 then env_hold <= '1'; end if;
						else
							if is_top then env_hold <= '1'; end if;
						end if;
					else
						if (reg(13)(0) = '1') then -- hold = 1
							if (env_inc = '0') then -- down
								if (reg(13)(1) = '1') then -- alt
									if is_bot    then env_hold <= '1'; end if;
								else
									if is_bot_p1 then env_hold <= '1'; end if;
								end if;
							else
								if (reg(13)(1) = '1') then -- alt
									if is_top    then env_hold <= '1'; end if;
								else
									if is_top_m1 then env_hold <= '1'; end if;
								end if;
							end if;

						elsif (reg(13)(1) = '1') then -- alternate
							if (env_inc = '0') then -- down
								if is_bot_p1 then env_hold <= '1'; end if;
								if is_bot    then env_hold <= '0'; env_inc <= '1'; end if;
							else
								if is_top_m1 then env_hold <= '1'; end if;
								if is_top    then env_hold <= '0'; env_inc <= '0'; end if;
							end if;
						end if;

					end if;
				end if;
			end if;
		end if;
	end process;

	p_chan_mixer : process(cnt_div, reg, tone_gen_op)
	begin
		tone_ena_l	<= '1';
		noise_ena_l	<= '1';
		tone_src		<= '1';
		chan_vol		<= (others => '0');
		case cnt_div(1 downto 0) is
			when "00" =>								-- chan A
				tone_ena_l 	<= reg(7)(0);
				noise_ena_l	<= reg(7)(3);
				tone_src		<= tone_gen_op(1);
--				chan_vol		<= "11" & reg(8)(4 downto 0);
				chan_vol		<= reg(14)(1 downto 0) & reg(8)(4 downto 0);
			when "01" =>								-- chan B
				tone_ena_l	<= reg(7)(1);
				noise_ena_l	<= reg(7)(4);
				tone_src		<= tone_gen_op(2);
--				chan_vol		<= "11" & reg(9)(4 downto 0);
				chan_vol		<= reg(14)(3 downto 2) & reg(9)(4 downto 0);
			when "10" =>								-- chan C
				tone_ena_l	<= reg(7)(2);
				noise_ena_l	<= reg(7)(5);
				tone_src		<= tone_gen_op(3);
--				chan_vol		<= "11" & reg(10)(4 downto 0);
				chan_vol		<= reg(14)(5 downto 4) & reg(10)(4 downto 0);
			when "11" => null;						-- tone gen outputs become valid on this clock
			when others => null;
		end case;
	end process;

	p_op_mixer : process
		variable chan_mixed : std_logic;
		variable chan_amp : std_logic_vector(6 downto 0);
	begin
		wait until rising_edge(CLK);
		if (ENA = '1') then

--			chan_mixed := (tone_ena_l or tone_src) and (noise_ena_l or noise_gen_op);
			chan_mixed := ( (not tone_ena_l) and tone_src ) or ( (not noise_ena_l) and noise_gen_op );

			chan_amp := (others => '0');
			if (chan_mixed = '1') then
				if (chan_vol(4) = '0') then
					if (chan_vol(3 downto 0) = "0000") then -- nothing is easy ! make sure quiet is quiet
						chan_amp := (others => '0');
					else
						chan_amp := chan_vol(6 downto 5) & chan_vol(3 downto 0) & '1'; -- make sure level 31 (env) = level 15 (tone)
					end if;
				else
					chan_amp := chan_vol(6 downto 5) & env_vol(4 downto 0);
				end if;
			end if;

			-- volume tables that take into account the amplification factor set
			-- by the IOA register 14 high/low bits through the external op-amps
			dac_amp <= x"00";
			case chan_amp is
				-- x1.8 table
				when "1111111" => dac_amp <= x"FF";
				when "1111110" => dac_amp <= x"D9";
				when "1111101" => dac_amp <= x"BA";
				when "1111100" => dac_amp <= x"9F";
				when "1111011" => dac_amp <= x"88";
				when "1111010" => dac_amp <= x"74";
				when "1111001" => dac_amp <= x"63";
				when "1111000" => dac_amp <= x"54";
				when "1110111" => dac_amp <= x"48";
				when "1110110" => dac_amp <= x"3D";
				when "1110101" => dac_amp <= x"34";
				when "1110100" => dac_amp <= x"2C";
				when "1110011" => dac_amp <= x"25";
				when "1110010" => dac_amp <= x"1F";
				when "1110001" => dac_amp <= x"1A";
				when "1110000" => dac_amp <= x"16";
				when "1101111" => dac_amp <= x"13";
				when "1101110" => dac_amp <= x"10";
				when "1101101" => dac_amp <= x"0D";
				when "1101100" => dac_amp <= x"0B";
				when "1101011" => dac_amp <= x"09";
				when "1101010" => dac_amp <= x"08";
				when "1101001" => dac_amp <= x"07";
				when "1101000" => dac_amp <= x"06";
				when "1100111" => dac_amp <= x"05";
				when "1100110" => dac_amp <= x"04";
				when "1100101" => dac_amp <= x"03";
				when "1100100" => dac_amp <= x"03";
				when "1100011" => dac_amp <= x"02";
				when "1100010" => dac_amp <= x"02";
				when "1100001" => dac_amp <= x"01";
				when "1100000" => dac_amp <= x"00";
				-- x1.3 table
				when "1011111" => dac_amp <= x"B8";
				when "1011110" => dac_amp <= x"9C";
				when "1011101" => dac_amp <= x"86";
				when "1011100" => dac_amp <= x"72";
				when "1011011" => dac_amp <= x"62";
				when "1011010" => dac_amp <= x"53";
				when "1011001" => dac_amp <= x"47";
				when "1011000" => dac_amp <= x"3C";
				when "1010111" => dac_amp <= x"34";
				when "1010110" => dac_amp <= x"2C";
				when "1010101" => dac_amp <= x"25";
				when "1010100" => dac_amp <= x"1F";
				when "1010011" => dac_amp <= x"1A";
				when "1010010" => dac_amp <= x"16";
				when "1010001" => dac_amp <= x"12";
				when "1010000" => dac_amp <= x"0F";
				when "1001111" => dac_amp <= x"0D";
				when "1001110" => dac_amp <= x"0B";
				when "1001101" => dac_amp <= x"09";
				when "1001100" => dac_amp <= x"07";
				when "1001011" => dac_amp <= x"06";
				when "1001010" => dac_amp <= x"05";
				when "1001001" => dac_amp <= x"05";
				when "1001000" => dac_amp <= x"04";
				when "1000111" => dac_amp <= x"03";
				when "1000110" => dac_amp <= x"02";
				when "1000101" => dac_amp <= x"02";
				when "1000100" => dac_amp <= x"02";
				when "1000011" => dac_amp <= x"01";
				when "1000010" => dac_amp <= x"01";
				when "1000001" => dac_amp <= x"00";
				when "1000000" => dac_amp <= x"00";
				-- x0.8 table
				when "0111111" => dac_amp <= x"71";
				when "0111110" => dac_amp <= x"60";
				when "0111101" => dac_amp <= x"52";
				when "0111100" => dac_amp <= x"46";
				when "0111011" => dac_amp <= x"3C";
				when "0111010" => dac_amp <= x"33";
				when "0111001" => dac_amp <= x"2C";
				when "0111000" => dac_amp <= x"25";
				when "0110111" => dac_amp <= x"20";
				when "0110110" => dac_amp <= x"1B";
				when "0110101" => dac_amp <= x"17";
				when "0110100" => dac_amp <= x"13";
				when "0110011" => dac_amp <= x"10";
				when "0110010" => dac_amp <= x"0D";
				when "0110001" => dac_amp <= x"0B";
				when "0110000" => dac_amp <= x"09";
				when "0101111" => dac_amp <= x"08";
				when "0101110" => dac_amp <= x"07";
				when "0101101" => dac_amp <= x"05";
				when "0101100" => dac_amp <= x"04";
				when "0101011" => dac_amp <= x"04";
				when "0101010" => dac_amp <= x"03";
				when "0101001" => dac_amp <= x"03";
				when "0101000" => dac_amp <= x"02";
				when "0100111" => dac_amp <= x"02";
				when "0100110" => dac_amp <= x"01";
				when "0100101" => dac_amp <= x"01";
				when "0100100" => dac_amp <= x"01";
				when "0100011" => dac_amp <= x"00";
				when "0100010" => dac_amp <= x"00";
				when "0100001" => dac_amp <= x"00";
				when "0100000" => dac_amp <= x"00";
				-- x0.3 table
				when "0011111" => dac_amp <= x"2A";
				when "0011110" => dac_amp <= x"24";
				when "0011101" => dac_amp <= x"1E";
				when "0011100" => dac_amp <= x"1A";
				when "0011011" => dac_amp <= x"16";
				when "0011010" => dac_amp <= x"13";
				when "0011001" => dac_amp <= x"10";
				when "0011000" => dac_amp <= x"0D";
				when "0010111" => dac_amp <= x"0C";
				when "0010110" => dac_amp <= x"0A";
				when "0010101" => dac_amp <= x"08";
				when "0010100" => dac_amp <= x"07";
				when "0010011" => dac_amp <= x"06";
				when "0010010" => dac_amp <= x"05";
				when "0010001" => dac_amp <= x"04";
				when "0010000" => dac_amp <= x"03";
				when "0001111" => dac_amp <= x"03";
				when "0001110" => dac_amp <= x"02";
				when "0001101" => dac_amp <= x"02";
				when "0001100" => dac_amp <= x"01";
				when "0001011" => dac_amp <= x"01";
				when "0001010" => dac_amp <= x"01";
				when "0001001" => dac_amp <= x"01";
				when "0001000" => dac_amp <= x"00";
				when "0000111" => dac_amp <= x"00";
				when "0000110" => dac_amp <= x"00";
				when "0000101" => dac_amp <= x"00";
				when "0000100" => dac_amp <= x"00";
				when "0000011" => dac_amp <= x"00";
				when "0000010" => dac_amp <= x"00";
				when "0000001" => dac_amp <= x"00";
				when "0000000" => dac_amp <= x"00";

				when others => null;
			end case;

			if (cnt_div(1 downto 0) = "10") then
				audio_mix   <= (others => '0');
				audio_final <= audio_mix;
			else
				case cnt_div(1 downto 0) is
					when "01" =>
						if I_CHEN(0)='1' then
							audio_mix   <= audio_mix + ("00" & dac_amp);
						end if;
					when "00" =>
						if I_CHEN(1)='1' then
							audio_mix   <= audio_mix + ("00" & dac_amp);
						end if;
					when "11" =>
						if I_CHEN(2)='1' then
							audio_mix   <= audio_mix + ("00" & dac_amp);
						end if;
					when others => null;
				end case;
			end if;
		end if;
	end process;

	p_audio_output : process(RESET_L, CLK)
	begin
		if (RESET_L = '0') then
			O_AUDIO <= (others => '0');
		elsif rising_edge(CLK) then
			if (ENA = '1') then
				O_AUDIO <= audio_final(9 downto 2);
			end if;
		end if;
	end process;

--	p_io_ports : process(reg)
--	begin
--		O_IOA <= reg(14);
--		O_IOA_OE_L <= not reg(7)(6);
--		O_IOB <= reg(15);
--		O_IOB_OE_L <= not reg(7)(7);
--	end process;

--	p_io_ports_inreg : process
--	begin
--		wait until rising_edge(CLK);
--		if (ENA = '1') then -- resync
--			ioa_inreg <= I_IOA;
--			iob_inreg <= I_IOB;
--		end if;
--	end process;
end architecture RTL;
