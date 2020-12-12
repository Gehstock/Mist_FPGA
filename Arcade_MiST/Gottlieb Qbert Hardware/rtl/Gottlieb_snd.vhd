-- Gottlieb MA-309 sound board used in System80 pinball machines Super Orbit, Royal Flush Deluxe, Amazon Hunt, Haunted House, Spirit,
-- Krull, Goin'Nuts and video game Mad Planets. This is the sound-only version and lacks the SC-01a speech synthesis chip, will run 
-- MA-216 pinball ROMs Mars, Volcano, Black Hole, Devil's Dare, Rocky, Striker, Q*Bert's Quest, Caveman (#PV810) and 
-- video games Reactor, Qbert, Krull, Three Stooges without speech. This is developed and tested on an Altera EP2C5T FPGA but should 
-- be easily ported to othernFPGA platforms. 
-- (c)2015 James Sweet
--
-- This top level file targeted at the EP2C5T144 Cyclone II mini board includes the PLL to generate the required 3.58 MHz clock signal for 
-- the sound board core as well as a PS/2 keyboard interface for testing purposes. If you intend to use the sound board for its original
-- purpose you will want to remove the PS/2 components and route the sound select signals directly to input pins on the FPGA.

-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.
--
-- Changelog:
-- V0.5 initial release
-- V1.0 
-- Minor cleanup, relocated PLL to top level file, added list of supported games

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Gottlieb_snd is
Port ( 	
			clk_358	:	in std_logic; -- 3.58 MHz clock
			reset_l	:	in std_logic; -- reset input, active low
			S1 		:	in std_logic; -- Sound control input lines (active low)
			S2			: 	in std_logic; 
			S4 		:  in std_logic;
			S8			:  in std_logic;
			S16		:	in std_logic;
			S32		:	in std_logic;	
			switches	: 	in	std_logic_vector(5 downto 0); -- DIP switches used for testing with some ROMs
			test		:	in	std_logic; -- Test button on the sound board, active low
			audio_dat: 	out std_logic_vector(7 downto 0)
			);
end Gottlieb_snd;


architecture rtl of Gottlieb_snd is

	signal clk 			: 	std_logic;
	signal clkCount	: 	std_logic_vector(1 downto 0);
	signal cpu_clk		: 	std_logic; -- 895 kHz CPU clock
	signal phi2			: 	std_logic; -- CPU clock phase 2

	signal cpu_addr	:	std_logic_vector(15 downto 0);
	signal cpu_din		: 	std_logic_vector(7 downto 0);
	signal cpu_dout	:  std_logic_vector(7 downto 0);
	signal n_cpu_nmi	: 	std_logic;
	signal n_cpu_irq	:  std_logic;
	signal n_cpu_wr	:  std_logic;
	
	signal riot_din	: 	std_logic_vector(7 downto 0);
	signal riot_dout	:  std_logic_vector(7 downto 0);
	signal riot_pa_i	:  std_logic_vector(7 downto 0);
	signal riot_pb_i	:  std_logic_vector(7 downto 0);
	signal riot_pb_o	:	std_logic_vector(7 downto 0);
	signal riot_cs		:  std_logic;
	signal riot_cs_n	: 	std_logic;
	
	signal ROM1_dout	:	std_logic_vector(7 downto 0);
	signal ROM2_dout	: 	std_logic_vector(7 downto 0);
	signal ROM_dout	: 	std_logic_vector(7 downto 0);
	signal ROM_cs		:  std_logic;

	signal dac_latch	: 	std_logic;		
Begin
phi2 <= not(cpu_clk); -- phase 2 is complement of CPU clock

-- Clock divider, takes 3.58 MHz input clock and divides it down to 895 kHz CPU clock
Clock_div : process(clk)
begin
	if rising_edge(clk_358) then
		ClkCount <= ClkCount + 1;
		cpu_clk <= ClkCount(1);
	end if;
end process;

-- 6502 CPU
CPU : entity work.T65
port map(
	Enable => '1',
	Mode => "00",
	Res_n => reset_l,
	Clk => cpu_clk,
	Rdy => '1',
	Abort_n => '1',
	IRQ_n => n_Cpu_irq,
	NMI_n => n_Cpu_nmi,
	SO_n => '1',
	R_W_n => n_cpu_WR,
	A(15 downto 0) => cpu_addr,
	DI => cpu_din,
	DO => cpu_dout
);	

-- ROMs
ROM1 : entity work.Qbert_snd1
port map(
	addr => cpu_addr(10 downto 0),
	clk	=> clk_358,
	data => ROM1_dout
);

ROM2 : entity work.Qbert_snd2
port map(
	addr => cpu_addr(10 downto 0),
	clk	=> clk_358,
	data => ROM2_dout
);

-- 6532 RAM-IO-Timer	
RIOT : entity work.RIOT
port map(
	PHI2 		=> phi2, 
	RES_N 	=> reset_l, 
	CS1 		=> riot_cs,
	CS2_N		=> riot_cs_n,
   RS_N 		=> cpu_addr(9),
	R_W		=> n_cpu_wr,
	A			=> cpu_addr(6 downto 0),
	D_I		=> cpu_dout,
	D_O		=> riot_dout,
   PA_I 		=> riot_pa_i,
	PA_O		=> open,
	DDRA_O	=> open,
   PB_I 		=> riot_pb_i,
	PB_O		=> riot_pb_o,
	DDRB_O	=> open,
	IRQ_N		=> n_cpu_irq
);

--Latch for pulling DAC data from the CPU data bus
Audio_DAC_Latch: Process(clk_358) is
Begin
	If rising_edge(clk_358) then
		if dac_latch = '1' then
			audio_dat <= cpu_dout;
		end if;		
	end if;
end process;



-- Address decoding here, cpu address bus 14-12 connect to 74LS138, only a few are used on non-speech board
--'000' riot cs
--'001' dac latch
--'111' rom enable
riot_cs 		<= '1' when cpu_addr(14 downto 12) ="000" else '0';
dac_latch 	<= '1' when cpu_addr(14 downto 12) ="001" else '0';
rom_cs 		<= '1' when cpu_addr(14 downto 12) ="111" else '0';

riot_cs_n <= not riot_cs;  -- RIOT has complementary chip select inputs

-- Bus control
cpu_din <= ROM_dout when rom_cs = '1' else 
riot_dout when n_cpu_wr = '1' else
x"FF";

-- ROM 1 or 2 select  depending on address bit 11
ROM_dout <= ROM1_dout when cpu_addr(11) = '0' else ROM2_dout; 

--Sound board inputs through RIOT port A
riot_pa_i(0) <= (NOT S1);
riot_pa_i(1) <= (NOT S2);
riot_pa_i(2) <= (NOT S4);
riot_pa_i(3) <= (NOT S8);
riot_pa_i(4) <= (NOT S16);
riot_pa_i(5) <= (NOT S32);
-- Strobe signal generates IRQ when inputs S1-S8 go low
riot_pa_i(7) <= (S1 AND S2 AND S4 AND S8);
riot_pb_i(5 downto 0) <= switches;
riot_pb_i(6) <= test;

n_cpu_nmi <= '1'; -- jumpered to Vcc in most games, can be strapped to riot PB7 out;
-- n_cpu_nmi <= riot_pb_o(7);
end;
			
			
