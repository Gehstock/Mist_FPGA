library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity minibd_top is
port(
		CLOCK_27		: in std_logic;
		SPI_SCK    	: in std_logic;
		SPI_DO     	: out std_logic;
		SPI_DI     	: in std_logic;
		SPI_SS2   	: in std_logic;
		SPI_SS3    	: in std_logic;
		CONF_DATA0 	: in std_logic;
		LED         : out std_logic;
		AUDIO_L		: out	std_logic;
		AUDIO_R		: out	std_logic
		);
end minibd_top;

architecture rtl of minibd_top is
-- Sound board signals
signal reset_l		: std_logic;
signal ps2_clk		: std_logic;
signal ps2_dat		: std_logic;
signal cpu_clk		: std_logic;
signal snd_ctl		: std_logic_vector(7 downto 0);
signal audio		: std_logic_vector(10 downto 0);

-- PS/2 interface signals
signal scanCode	: std_logic_vector(9 downto 0);
signal send 		: std_logic;
signal Command 	: std_logic_vector(7 downto 0);
signal PS2Busy		: std_logic;
signal PS2Error	: std_logic;
signal dataByte	: std_logic_vector(7 downto 0);
signal dataReady	: std_logic;
signal buttons		: std_logic_vector(1 downto 0);

component mist_io generic(STRLEN : integer := 0 ); port
(
	clk_sys           : in  std_logic;
	SPI_SCK           : in  std_logic;
	CONF_DATA0        : in  std_logic;
	SPI_SS2           : in  std_logic;
	SPI_DI            : in  std_logic;
	SPI_DO            : out std_logic;
	buttons           : out std_logic_vector(1 downto 0);
	ps2_kbd_clk       : out std_logic;
	ps2_kbd_data      : out std_logic
	);
end component mist_io;

begin

reset_l <= not buttons(1);
LED <= '1';

io: mist_io
port map(
	clk_sys => CLOCK_27,
	SPI_SCK => SPI_SCK,
	CONF_DATA0 => CONF_DATA0,
	SPI_SS2 => SPI_SS2,
	SPI_DO => SPI_DO,
	SPI_DI => SPI_DI,
	buttons => buttons,
	ps2_kbd_clk => ps2_clk,
	ps2_kbd_data => ps2_dat
	);
	
Core: entity work.AS_2518_51
port map(
	cpu_clk => cpu_clk,
	reset_l => reset_l,
	addr_i => snd_ctl(5 downto 0),
	snd_int_i => not scancode(8),
	test_sw_l => '1',
	audio => audio
	);

PLL: entity work.williams_snd_pll
port map(
	areset => not reset_l,
	inclk0 => CLOCK_27,
	c0 => cpu_clk
	);

keyboard: entity work.PS2Controller
port map(
		Reset     => not reset_l,
		Clock     => CLOCK_27,
		PS2Clock  => ps2_clk,
		PS2Data   => ps2_dat,
		Send      => send,
		Command   => command,
		PS2Busy   => ps2Busy,
		PS2Error  => ps2Error,
		DataReady => dataReady,
		DataByte  => dataByte
		);

decoder: entity work.KeyboardMapper
port map(
		Clock     => CLOCK_27,
		Reset     => not reset_l,
		PS2Busy   => ps2Busy,
		PS2Error  => ps2Error,
		DataReady => dataReady,
		DataByte  => dataByte,
		Send      => send,
		Command   => command,
		CodeReady => open,
		ScanCode  => scanCode
		);

inputreg: process
begin
	wait until rising_edge(CLOCK_27);
		if scanCode(8) = '0' then
			snd_ctl(5 downto 0) <= not scanCode(5 downto 0);
		else
			snd_ctl(5 downto 0) <= "111111";
		end if;
end process;

snd_ctl(7 downto 6) <= "11";

Audio_DACl: entity work.dac
port map(
   clk_i   	=> CLOCK_27,
   res_n_i 	=> reset_l,
   dac_i   	=> audio(10 downto 3),
   dac_o   	=> AUDIO_L
	);

Audio_DACr: entity work.dac
port map(
   clk_i   	=> CLOCK_27,
   res_n_i 	=> reset_l,
   dac_i   	=> audio(10 downto 3),
   dac_o   	=> AUDIO_R
	);
	
end rtl;
