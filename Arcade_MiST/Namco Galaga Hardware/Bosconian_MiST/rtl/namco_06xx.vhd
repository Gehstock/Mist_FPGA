-- Namco 06xx multi-chip interface
-- Standalone FPGA implementation by Nolan Nicholson, 2021
-- Based on FPGA Galaga by Dar (darfpga@aol.fr, http://darfpga.blogspot.fr)

-- From MAME documentation:
--
-- This chip is used as an interface to up to 4 other custom chips.
-- It signals IRQs to the custom MCUs when writes happen, and generates
-- NMIs to the controlling CPU to drive reads based on a clock.
--
-- It uses a clock divider that's used to pulse the NMI and custom chip select
-- lines.
--
-- The control register controls chip as such: the low 4 bits are chip selects
-- (active high), the 5th bit is read/!write, and the upper 3 bits are the
-- clock divide.
--
-- SD0-SD7 are data I/O lines connecting to the controlling CPU
-- SEL selects either control (1) or data (0), usually connected to
-- 	an address line of the controlling CPU
-- /NMI is an NMI signal line for the controlling CPU
--
-- ID0-ID7 are data I/O lines connecting to the other custom chips
-- /IO1-/IO4 are IRQ signal lines for each custom chip

--                   +------+
--        [1] R/W out|1   28|Vcc
--                ID7|2   27|SD7
--                ID6|3   26|SD6
--                ID5|4   25|SD5
--                ID4|5   24|SD4
--                ID3|6   23|SD3
--                ID2|7   22|SD2
--                ID1|8   21|SD1
--                ID0|9   20|SD0
--               /IO1|10  19|/NMI
--               /IO2|11  18|/CS    TODO
--               /IO3|12  17|CLOCK
--               /IO4|13  16|R/W in
--                GND|14  15|SEL
--                   +------+
--
--    [1] on polepos, galaga, xevious, and bosco: connected to K3 of the 51xx
--        on bosco and xevious, connected to R8 of the 50xx

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity namco_06xx is
port(
	------- INPUTS -------
	clock_18n : in std_logic;
	reset : in std_logic;
	read_write : in std_logic; -- 0 for reads, 1 for writes
	sel : in std_logic; -- 1 for control, 0 for data

	-- Data from CPU to 06xx
	di_cpu : in std_logic_vector(7 downto 0);

  -- Clock enable for FALLING EDGE of the 06xx clock.
  -- Original clock signals:
  --  - CPU boards on Galaga, Bosconian, etc: 64H
  --  - Video board on Bosconian: /HBLANK*
  clk_fall_ena : in std_logic;

	chip_select : in std_logic;

	-- Data from custom MCU chips to 06xx
	di_chip0 : in std_logic_vector(7 downto 0);
	di_chip1 : in std_logic_vector(7 downto 0);
	di_chip2 : in std_logic_vector(7 downto 0);
	di_chip3 : in std_logic_vector(7 downto 0);

	------- OUTPUTS -------
	-- Data from 06xx to CPU
	do_cpu : out std_logic_vector(7 downto 0);

	-- Data from 06xx to custom MCU chips
	do_chip0 : out std_logic_vector(7 downto 0);
	do_chip1 : out std_logic_vector(7 downto 0);
	do_chip2 : out std_logic_vector(7 downto 0);
	do_chip3 : out std_logic_vector(7 downto 0);

	-- IRQ signals out to custom MCU chips
	chip0_irq_n : out std_logic;
	chip1_irq_n : out std_logic;
	chip2_irq_n : out std_logic;
	chip3_irq_n : out std_logic;

	rw_out : out std_logic;

	cpu_nmi_n : out std_logic
);
end namco_06xx;

architecture behavior of namco_06xx is

	signal cs06xx_di             : std_logic_vector(7 downto 0);
	signal cs06xx_control        : std_logic_vector(7 downto 0);
	signal cs06xx_nmi_cnt        : std_logic_vector(2 downto 0);
	signal cs06xx_nmi_stretch    : std_logic;
	signal cs06xx_nmi_state_next : std_logic;
	signal change_next           : std_logic;

begin
	with cs06xx_control(3 downto 0) select
	cs06xx_di <= di_chip0 when "0001",
		     di_chip1 when "0010",
		     di_chip2 when "0100",
		     di_chip3 when "1000",
		     X"00" when others;

	do_cpu <= cs06xx_di when sel = '0' else cs06xx_control;

	process (reset, clock_18n, read_write)
	begin
		if reset = '1' then
			chip0_irq_n <= '1';
			chip1_irq_n <= '1';
			chip2_irq_n <= '1';
			chip3_irq_n <= '1';

			do_chip0 <= X"00";
			do_chip1 <= X"00";
			do_chip2 <= X"00";
			do_chip3 <= X"00";
		else
			if rising_edge(clock_18n) then
				-- write to cs06XX
				if read_write = '1' then
					-- write to data register (0x7000 on CPU board)
					if sel = '0' then
						-- NOTE: MAME checks for the individual bits, without caring
						-- whether or not the last four bits are one-hot. I do not
						-- know which is correct.

						-- write data and launch irq to device 0
						if cs06xx_control(3 downto 0) = "0001" then
							do_chip0 <= di_cpu;
							chip0_irq_n <= '0';
						end if;

						-- write data and launch irq to device 1
						if cs06xx_control(3 downto 0) = "0010" then
							do_chip1 <= di_cpu;
							chip1_irq_n <= '0';
						end if;

						-- write data and launch irq to device 2
						if cs06xx_control(3 downto 0) = "0100" then
							do_chip2 <= di_cpu;
							chip2_irq_n <= '0';
						end if;

						-- write data and launch irq to device 3
						if cs06xx_control(3 downto 0) = "1000" then
							do_chip3 <= di_cpu;
							chip3_irq_n <= '0';
						end if;

					end if;

					-- write to control register (0x7100 on CPU board)
					-- data(3..0) select custom chip 50xx/51xx/54xx
					-- data (4)   read/write mode for custom chip
					if sel = '1' then
						cs06xx_control <= di_cpu;

						-- start/stop nmi timer (stop if no chip selected)
						if di_cpu(7 downto 5) = "000" then
							cs06xx_nmi_cnt <= (others => '0');
							cpu_nmi_n <= '1';
							chip0_irq_n <= '1';
							chip1_irq_n <= '1';
							chip2_irq_n <= '1';
							chip3_irq_n <= '1';
						else
							cs06xx_nmi_cnt <= (others => '0');
							cpu_nmi_n <= '1';
							cs06xx_nmi_stretch <= di_cpu(4);
							cs06xx_nmi_state_next <= '1';
						end if;
					end if;
				end if;

				-- generate periodic nmi when timer is on
				if cs06xx_control(7 downto 5) /= "000" then
					if clk_fall_ena = '1' then

						if cs06xx_nmi_cnt = 0 then
							cs06xx_nmi_cnt <= cs06xx_control(7 downto 5);

							if cs06xx_nmi_state_next = '1' then
								rw_out <= cs06xx_control(4);
							end if;

							if cs06xx_nmi_state_next = '1' and cs06xx_nmi_stretch = '0' then
								cpu_nmi_n <= '0';
							else
								cpu_nmi_n <= '1';
							end if;

							if cs06xx_nmi_state_next = '0' or cs06xx_nmi_stretch = '1' then
								chip0_irq_n <= not (cs06xx_control(0) and cs06xx_nmi_state_next);
								chip1_irq_n <= not (cs06xx_control(1) and cs06xx_nmi_state_next);
								chip2_irq_n <= not (cs06xx_control(2) and cs06xx_nmi_state_next);
								chip3_irq_n <= not (cs06xx_control(3) and cs06xx_nmi_state_next);
							end if;

							cs06xx_nmi_state_next <= not cs06xx_nmi_state_next;
							cs06xx_nmi_stretch <= '0';
						else
							cs06xx_nmi_cnt <= cs06xx_nmi_cnt - 1;
						end if;
					end if;
				end if;

				-- manage cs06XX data read (0x7000)
				change_next <= '0';
				if chip_select = '1' and sel = '0' then
					change_next <= '1';
				end if ;

				-- NOTE: I'm not seeing yet how this is implemented in MAME. In Galaga,
				-- only the chip0 IRQ (51xx) was fired here, even though chip3 was
				-- hooked up to the 54xx.
				-- TODO: not all of the chips appear to send IRQs in this manner
				if change_next = '1' and cs06xx_control(4) = '1' then
					if cs06xx_control(3 downto 0) = "0001" then
						chip0_irq_n <= '0';
					end if;
					if cs06xx_control(3 downto 0) = "0010" then
						chip1_irq_n <= '0';
					end if;
					if cs06xx_control(3 downto 0) = "0100" then
						chip2_irq_n <= '0';
					end if;
					if cs06xx_control(3 downto 0) = "1000" then
						chip3_irq_n <= '0';
					end if;
				end if;
				
			end if;
		end if;
	end process;
end behavior;
