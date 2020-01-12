---------------------------------------------------------------------------------
-- Moon patrol sound board by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
-- gen_ram.vhd  
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
---------------------------------------------------------------------------------
-- cpu68 - Version 9th Jan 2004 0.8
-- 6800/01 compatible CPU core 
-- GNU public license - December 2002 : John E. Kent
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Version 0.0 -- 24/11/2017 -- 
--		    initial version
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity moon_patrol_sound_board is
port(
 clock_E      : in std_logic; -- 3.58 Mhz/4
 areset       : in std_logic;

 select_sound : in std_logic_vector(7 downto 0);
 audio_out    : out std_logic_vector(11 downto 0);
 snd_rom_addr: out std_logic_vector(12 downto 0);
 snd_rom_do  : in  std_logic_vector(7 downto 0);
 dbg_cpu_addr : out std_logic_vector(15 downto 0)
);
end moon_patrol_sound_board;

architecture struct of moon_patrol_sound_board is
  component YM2149
  port (
    CLK         : in  std_logic;
    CE          : in  std_logic;
    RESET       : in  std_logic;
    A8          : in  std_logic := '1';
    A9_L        : in  std_logic := '0';
    BDIR        : in  std_logic; -- Bus Direction (0 - read , 1 - write)
    BC          : in  std_logic; -- Bus control
    DI          : in  std_logic_vector(7 downto 0);
    DO          : out std_logic_vector(7 downto 0);
    CHANNEL_A   : out std_logic_vector(7 downto 0);
    CHANNEL_B   : out std_logic_vector(7 downto 0);
    CHANNEL_C   : out std_logic_vector(7 downto 0);

    SEL         : in  std_logic;
    MODE        : in  std_logic;

    ACTIVE      : out std_logic_vector(5 downto 0);

    IOA_in      : in  std_logic_vector(7 downto 0);
    IOA_out     : out std_logic_vector(7 downto 0);

    IOB_in      : in  std_logic_vector(7 downto 0);
    IOB_out     : out std_logic_vector(7 downto 0)
    );
  end component;

 signal reset      : std_logic := '1';
 signal reset_cnt  : integer range 0 to 1000000 := 1000000;

 signal cpu_addr   : std_logic_vector(15 downto 0);
 signal cpu_di     : std_logic_vector( 7 downto 0);
 signal cpu_do     : std_logic_vector( 7 downto 0);
 signal cpu_rw     : std_logic;
 signal cpu_irq    : std_logic;
 signal cpu_nmi    : std_logic;
 
 signal irqraz_cs : std_logic;
 signal irqraz_we : std_logic;
 
 signal wram_cs   : std_logic;
 signal wram_we   : std_logic;
 signal wram_do   : std_logic_vector( 7 downto 0);
 
 signal rom_cs    : std_logic;
 signal rom_do    : std_logic_vector( 7 downto 0);

 signal ay1_chan_a    : std_logic_vector(7 downto 0);
 signal ay1_chan_b    : std_logic_vector(7 downto 0);
 signal ay1_chan_c    : std_logic_vector(7 downto 0);
 signal ay1_do        : std_logic_vector(7 downto 0);
 signal ay1_audio     : std_logic_vector(9 downto 0);
 signal ay1_port_b_do : std_logic_vector(7 downto 0);
 
 signal ay2_chan_a    : std_logic_vector(7 downto 0);
 signal ay2_chan_b    : std_logic_vector(7 downto 0);
 signal ay2_chan_c    : std_logic_vector(7 downto 0);
 signal ay2_do        : std_logic_vector(7 downto 0);
 signal ay2_audio     : std_logic_vector(9 downto 0);

 signal ports_cs    : std_logic;
 signal ports_we    : std_logic;
  
 signal port1_bus   : std_logic_vector(7 downto 0);  
 signal port1_data  : std_logic_vector(7 downto 0);
 signal port1_ddr   : std_logic_vector(7 downto 0);
 signal port1_in    : std_logic_vector(7 downto 0);
 
 signal port2_bus   : std_logic_vector(7 downto 0);  
 signal port2_data  : std_logic_vector(7 downto 0);
 signal port2_ddr   : std_logic_vector(7 downto 0);
 signal port2_in    : std_logic_vector(7 downto 0);
 
 signal adpcm_cs    : std_logic;
 signal adpcm_we    : std_logic;
 signal adpcm_0_di  : std_logic_vector(3 downto 0);

 signal select_sound_r  : std_logic_vector(7 downto 0);

 signal audio : std_logic_vector(12 downto 0);
 
 type t_step_size is array(0 to 48) of integer range 0 to 1552;
 constant step_size : t_step_size := (
    16,   17,   19,   21,   23,   25,   28,   31,
    34,   37,   41,   45,   50,   55,   60,   66,
    73,   80,   88,   97,  107,  118,  130,  143,
	157,  173,  190,  209,  230,  253,  279,  307,
	337,  371,  408,  449,  494,  544,  598,  658,
	724,  796,  876,  963, 1060, 1166, 1282, 1411, 1552);
	
 type t_delta_step is array(0 to 7) of integer range -1 to 8;	
 constant delta_step : t_delta_step := (-1,-1,-1,-1,2,4,6,8);

 signal adpcm_vclk  : std_logic := '0';
 signal adpcm_signal : integer range -16384 to 16383 := 0; 

-- adpcm algorithm (4bits) [no pcm here]
--
--   val    : input value 3bits (0 - 7 : b2b1b0)
--   sign   : input value sign  (4th bit : 0=>sign=1 ,1=>sign=-1)
--
--   step   : internal data, init = 0
--   signal : output value, init = 0;
--
--   for each new val (and sign) :
--   |
--   | step_size = 16*1.1^(step)
--   | delta     = sign * (step_size/8 + step_size/4*b0 + step_size/2*b1 + step_size*b2)
--   | signal    = signal + delta
--   | step      = step + delta_step(val)
--   |
--   | signal is then limited between -2048..2047
--   | step   is then limited between     0..48
 
begin

dbg_cpu_addr <= cpu_addr;

-- cs
wram_cs   <= '1' when cpu_addr(15 downto  7) = X"00"&'1' else '0'; -- 0080-00FF
ports_cs  <= '1' when cpu_addr(15 downto  4) = X"000"    else '0'; -- 0000-000F
adpcm_cs  <= '1' when cpu_addr(14 downto 11) = "0001"    else '0'; -- 0800-0FFF / 8800-8FFF
irqraz_cs <= '1' when cpu_addr(14 downto 12) = "001"     else '0'; -- 1000-1FFF / 9000-9FFF
rom_cs    <= '1' when cpu_addr(14 downto 12) = "111"     else '0'; -- 7000-7FFF / F000-FFFF
	
-- write enables
wram_we <=   '1' when cpu_rw = '0' and wram_cs =   '1' else '0';
ports_we <=  '1' when cpu_rw = '0' and ports_cs =  '1' else '0';
adpcm_we <=  '1' when cpu_rw = '0' and adpcm_cs =  '1' else '0';
irqraz_we <= '1' when cpu_rw = '0' and irqraz_cs = '1' else '0';

-- mux cpu in data between roms/io/wram
cpu_di <=
	wram_do when wram_cs = '1' else
	port1_ddr when ports_cs = '1' and cpu_addr(3 downto 0) = X"0" else
	port2_ddr when ports_cs = '1' and cpu_addr(3 downto 0) = X"1" else
	port1_in  when ports_cs = '1' and cpu_addr(3 downto 0) = X"2" else
	port2_in  when ports_cs = '1' and cpu_addr(3 downto 0) = X"3" else
	snd_rom_do when rom_cs = '1' else X"55";

process (clock_E)
begin
	if rising_edge(clock_E) then
		reset <= '0';
		if reset_cnt /= 0 then
			reset_cnt <= reset_cnt - 1;
			reset <= '1';
		end if;
		if areset = '1' then
		   reset_cnt <= 1000000;
		end if;
	end if;
end process;

-- irq to cpu
process (reset, clock_E)
begin
	if reset='1' then
		cpu_irq <= '0';
		select_sound_r(7) <= '1';
	elsif rising_edge(clock_E) then
		select_sound_r <= select_sound;
		if select_sound_r(7) = '0' then
			cpu_irq  <= '1';
		end if;
		if irqraz_we = '1' then
			cpu_irq  <= '0';
		end if;
	end if;
end process;

-- cpu nmi
cpu_nmi <= adpcm_vclk;

-- 6803 ports 1 and 2 (only)
process (reset, clock_E)
begin
	if reset='1' then
		port1_ddr  <= (others=>'0');  -- port1 set as input
		port1_data <= (others=>'0');  -- port1 data set to 0
		port2_ddr  <= ("11100000");   -- port2 bit 7 to 5 should always remain output to simulate mode data
		port2_data <= ("01000000");   -- port2 data bit 7 to 5 set to 2 (for mode 2 at start up)
	elsif rising_edge(clock_E) then
			if ports_cs = '1' and ports_we = '1' then
				if cpu_addr(3 downto 0) = X"0" then port1_ddr  <= cpu_do; end if;
				if cpu_addr(3 downto 0) = X"1" then port2_ddr  <= cpu_do and "11100000"; end if;
				if cpu_addr(3 downto 0) = X"2" then port1_data <= cpu_do; end if; 
				if cpu_addr(3 downto 0) = X"3" then port2_data <= cpu_do; end if;
			end if;
	end if;
end process;

port1_in <= (port1_bus and not(port1_ddr)) or (port1_data and port1_ddr);
port2_in <= (port2_bus and not(port2_ddr)) or (port2_data and port2_ddr);

-- port1 bus mux
port1_bus <= ay1_do when port2_data(4) = '0' else 
				 ay2_do when port2_data(3) = '0' else X"FF";

-- port2 bus
port2_bus <= X"FF";


-- latch adpcm (msm5205) data in
process (reset, clock_E)
begin
	if reset='1' then
		adpcm_0_di <= (others=>'0');
	elsif rising_edge(clock_E) then
			if adpcm_cs = '1' and adpcm_we = '1' then
				if cpu_addr(1) = '0' then adpcm_0_di  <= cpu_do(3 downto 0); end if;
			end if;
	end if;
end process;

-- adcpm clocks and computation -- make 24kHz and vclk 8/6/4kHz
adpcm_clocks : process(clock_E, ay1_port_b_do)
	variable clock_div_a : integer range 0 to 148 := 0;
	variable clock_div_b : integer range 0 to 5 := 0;
	variable step   : integer range  0 to 48;
	variable step_n : integer range -1 to 48+8;
   variable sz : integer range 0 to 1552;
	variable dn : integer range -32768 to 32767;
	variable adpcm_signal_n : integer range -32768 to 32767;
begin
	if rising_edge(clock_E) then
		if clock_div_a = 37 then   -- 24kHz
			clock_div_a := 0;
			
			case ay1_port_b_do(3 downto 2) is				
			when "00" => if clock_div_b = 5 then clock_div_b := 0; else clock_div_b := clock_div_b +1; end if;  -- 4kHz
			when "01" => if clock_div_b = 2 then clock_div_b := 0; else clock_div_b := clock_div_b +1; end if;  -- 8kHz
			when "10" => if clock_div_b = 3 then clock_div_b := 0; else clock_div_b := clock_div_b +1; end if;  -- 6kHz
			when others => null;
			end case;
							
			if clock_div_b = 0 then adpcm_vclk <= '1'; else adpcm_vclk <= '0'; end if;
		else
			clock_div_a := clock_div_a + 1;			
		end if;
			
		if ay1_port_b_do(0) = '1' then
			step := 0;
			adpcm_signal <= 0;
		else
		
			if clock_div_b = 0 then
			case clock_div_a is
			
			when 0 => -- it's time to get new nibble (adpcm_0_di)
							
				sz := step_size(step);
				dn := sz/8;
				if adpcm_0_di(0) = '1' then dn := dn + sz/4; end if;
				if adpcm_0_di(1) = '1' then dn := dn + sz/2; end if;
				if adpcm_0_di(2) = '1' then dn := dn + sz  ; end if;
				
				if adpcm_0_di(3) = '1' then
					dn := -dn;	
				end if;
								
				step_n := step + delta_step(to_integer(unsigned(adpcm_0_di(2 downto 0))));
			
			when 4 => 
			
				adpcm_signal_n := adpcm_signal + dn;
			
				if step_n > 48 then step := 48; else step := step_n; end if;
				if step_n < 0  then step := 0;  else step := step_n; end if;
				
			when 8 =>
			
				if adpcm_signal_n >  2040 then adpcm_signal <=  2040; else adpcm_signal <= adpcm_signal_n; end if;
				if adpcm_signal_n < -2040 then adpcm_signal <= -2040; else adpcm_signal <= adpcm_signal_n; end if;
			
			when others => null;
			
			end case;
			end if;
			
		end if;
	end if;
end process;

-- audio mux
audio <= ("000"&ay1_audio) + ("000"&ay2_audio) + ('0'&std_logic_vector(to_unsigned((adpcm_signal)+2048,12)));
audio_out <= audio(12 downto 1);
				 
-- microprocessor 6800/01/03
main_cpu : entity work.cpu68
port map(	
	clk      => clock_E,   -- E clock input (falling edge)
	rst      => reset,    -- reset input (active high)
	rw       => cpu_rw,   -- read not write output
	vma      => open,     -- valid memory address (active high)
	address  => cpu_addr, -- address bus output
	data_in  => cpu_di,   -- data bus input
	data_out => cpu_do,   -- data bus output
	hold     => '0',      -- hold input (active high) extend bus cycle
	halt     => '0',      -- halt input (active high) grants DMA
	irq      => cpu_irq,  -- interrupt request input (active high)
	nmi      => cpu_nmi,  -- non maskable interrupt request input (active high)
	test_alu => open,
	test_cc  => open
);

snd_rom_addr <= cpu_addr(12 downto 0);

-- cpu wram
cpu_ram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 7)
port map(
 clk  => clock_E,
 we   => wram_we,
 addr => cpu_addr(6 downto 0),
 d    => cpu_do,
 q    => wram_do
);

  ay83910_inst1: YM2149
  port map (
    CLK         => clock_E,
    CE          => '1',
    RESET       => reset,
    A8          => '1',
    A9_L        => port2_data(4),
    BDIR        => port2_data(0),
    BC          => port2_data(2),
    DI          => port1_data,
    DO          => ay1_do,
    CHANNEL_A   => ay1_chan_a,
    CHANNEL_B   => ay1_chan_b,
    CHANNEL_C   => ay1_chan_c,

    SEL         => '0',
    MODE        => '1',

    ACTIVE      => open,

    IOA_in      => select_sound_r,
    IOA_out     => open,

    IOB_in      => (others => '0'),
    IOB_out     => ay1_port_b_do
    );

  ay1_audio <= "0000000000" + ay1_chan_a + ay1_chan_b + ay1_chan_c;

  ay83910_inst2: YM2149
  port map (
    CLK         => clock_E,
    CE          => '1',
    RESET       => reset,
    A8          => '1',
    A9_L        => port2_data(3),
    BDIR        => port2_data(0),
    BC          => port2_data(2),
    DI          => port1_data,
    DO          => ay2_do,
    CHANNEL_A   => ay2_chan_a,
    CHANNEL_B   => ay2_chan_b,
    CHANNEL_C   => ay2_chan_c,

    SEL         => '0',
    MODE        => '1',

    ACTIVE      => open,

    IOA_in      => (others => '0'),
    IOA_out     => open,

    IOB_in      => (others => '0'),
    IOB_out     => open
    );

  ay2_audio <= "0000000000" + ay2_chan_a + ay2_chan_b + ay2_chan_c;

end struct;