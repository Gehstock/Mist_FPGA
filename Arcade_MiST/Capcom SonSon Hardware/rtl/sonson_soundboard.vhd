library ieee;

use work.pace_pkg.all;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;

entity sonson_soundboard is
port(
  clkrst_i     : in from_CLKRST_t;
  sound_irq    : in std_logic;
  sound_data   : in std_logic_vector(7 downto 0);
  vblank       : in std_logic;
  audio_out_l  : out std_logic_vector(9 downto 0);
  audio_out_r  : out std_logic_vector(9 downto 0);
  snd_rom_addr : out std_logic_vector(12 downto 0);
  snd_rom_do   : in std_logic_vector(7 downto 0)
  );
  
end sonson_soundboard;

architecture SYN of sonson_soundboard is

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
  
  COMPONENT mc6809i
  GENERIC ( ILLEGAL_INSTRUCTIONS : STRING := "GHOST" );
  PORT
  (
    D		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    DOut		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ADDR		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    RnW		:	 OUT STD_LOGIC;
    E		:	 IN STD_LOGIC;
    Q		:	 IN STD_LOGIC;
    BS		:	 OUT STD_LOGIC;
    BA		:	 OUT STD_LOGIC;
    nIRQ		:	 IN STD_LOGIC;
    nFIRQ		:	 IN STD_LOGIC;
    nNMI		:	 IN STD_LOGIC;
    AVMA		:	 OUT STD_LOGIC;
    BUSY		:	 OUT STD_LOGIC;
    LIC		:	 OUT STD_LOGIC;
    nHALT		:	 IN STD_LOGIC;
    nRESET		:	 IN STD_LOGIC;
    nDMABREQ		:	 IN STD_LOGIC;
    RegData		:	 OUT STD_LOGIC_VECTOR(111 DOWNTO 0)
  );
END COMPONENT;

  alias clk         : std_logic is clkrst_i.clk(0);
  alias reset       : std_logic is clkrst_i.rst(0);  

  signal clk_E      : std_logic;
  signal clk_Q      : std_logic;
  signal cpu_addr   : std_logic_vector(15 downto 0);
  signal cpu_di     : std_logic_vector( 7 downto 0);
  signal cpu_do     : std_logic_vector( 7 downto 0);
  signal cpu_rw     : std_logic;
  signal cpu_irq    : std_logic;
  signal cpu_ba     : std_logic;
  signal cpu_bs     : std_logic;

  signal wram_cs    : std_logic;
  signal wram_we    : std_logic;
  signal wram_do    : std_logic_vector( 7 downto 0);
 
  signal rom_cs     : std_logic;
  signal snd_rd     : std_logic;

  signal clk_en_snd    : std_logic; -- 1.5 MHz
  signal ay1_cs        : std_logic;
  signal ay1_chan_a    : std_logic_vector(7 downto 0);
  signal ay1_chan_b    : std_logic_vector(7 downto 0);
  signal ay1_chan_c    : std_logic_vector(7 downto 0);
  signal ay1_do        : std_logic_vector(7 downto 0);
  signal ay1_port_b_do : std_logic_vector(7 downto 0);
 
  signal ay2_cs        : std_logic;
  signal ay2_chan_a    : std_logic_vector(7 downto 0);
  signal ay2_chan_b    : std_logic_vector(7 downto 0);
  signal ay2_chan_c    : std_logic_vector(7 downto 0);
  signal ay2_do        : std_logic_vector(7 downto 0);

  signal vblank_r      : std_logic;

begin

  -- cs
  snd_rd    <= '1' when cpu_addr(15 downto 13) = "101" else '0';  -- a000
  wram_cs   <= '1' when cpu_addr(15 downto 13) = "000" else '0';  -- 0000-07ff RAM
  rom_cs    <= '1' when cpu_addr(15 downto 13) = "111" else '0';  -- e000-ffff ROM
  ay1_cs    <= '1' when cpu_addr(15 downto 13) = "001" else '0';  -- 2000
  ay2_cs    <= '1' when cpu_addr(15 downto 13) = "010" else '0';  -- 4000

  -- write enables
  wram_we <=   '1' when cpu_rw = '0' and wram_cs =   '1' else '0';

  -- mux cpu in data between roms/io/wram
  cpu_di <=	wram_do when wram_cs = '1' else
            sound_data when snd_rd = '1' else
            ay1_do when ay1_cs = '1' else
            ay2_do when ay2_cs = '1' else
            snd_rom_do when rom_cs = '1' else X"FF";

  process (clk)
    variable count : unsigned(3 downto 0);
  begin
    if rising_edge(clk) then
      count := count + 1;
      if count(1 downto 0) = "11" then
        case count(3 downto 2) is
        when "00" => clk_E <= '0';
        when "01" => clk_Q <= '1';
        when "10" => clk_E <= '1';
        when "11" => clk_Q <= '0';
        end case;
      end if;

      clk_en_snd <= '0';
      if count = "0000" then
        clk_en_snd <= '1';
      end if;
    end if;
  end process;

  process (clk, reset)
  begin
    if reset = '1' then
      cpu_irq <= '0';
    elsif rising_edge(clk) then
      vblank_r <= vblank;
      if vblank_r = '0' and vblank = '1' then
        cpu_irq <= '1';
      elsif cpu_ba = '0' and cpu_bs = '1' then
        cpu_irq <= '0';
      end if;
    end if;
  end process;

	cpu_inst : mc6809i
	port map
    (
    D         => cpu_di,
    DOut      => cpu_do,
    ADDR      => cpu_addr,
    RnW       => cpu_rw,
    E         => clk_E,
    Q         => clk_Q,
    BS     		=> cpu_bs,
    BA     		=> cpu_ba,
    nIRQ			=> not cpu_irq,
    nFIRQ     => sound_irq,
    nNMI			=> '1',
    AVMA  		=> open,
    BUSY  		=> open,
    LIC       => open,
    nHALT     => '1',	 
    nRESET    => not reset,
    nDMABREQ  => '1',
    RegData   => open
    );

  snd_rom_addr <= cpu_addr(12 downto 0);	 

  cpu_ram : entity work.spram
	generic map( widthad_a => 11)
  port map(
    clock  	=> clk,
    wren   	=> wram_we,
    address 	=> cpu_addr(10 downto 0),
    data    	=> cpu_do,
    q    		=> wram_do
  );

  ay83910_inst1: YM2149
  port map (
    CLK         => clk,
    CE          => clk_en_snd,
    RESET       => reset,
    A8          => '1',
    A9_L        => not ay1_cs,
    BDIR        => not cpu_rw,
    BC          => not cpu_addr(0) or cpu_rw,
    DI          => cpu_do,
    DO          => ay1_do,
    CHANNEL_A   => ay1_chan_a,
    CHANNEL_B   => ay1_chan_b,
    CHANNEL_C   => ay1_chan_c,

    SEL         => '0',
    MODE        => '1',

    ACTIVE      => open,

    IOA_in      => (others => '0'),
    IOA_out     => open,

    IOB_in      => (others => '0'),
    IOB_out     => open
    );

  audio_out_l <= "0000000000" + ay1_chan_a + ay1_chan_b + ay1_chan_c;

  ay83910_inst2: YM2149
  port map (
    CLK         => clk,
    CE          => clk_en_snd,
    RESET       => reset,
    A8          => '1',
    A9_L        => not ay2_cs,
    BDIR        => not cpu_rw,
    BC          => not cpu_addr(0) or cpu_rw,
    DI          => cpu_do,
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

  audio_out_r <= "0000000000" + ay2_chan_a + ay2_chan_b + ay2_chan_c;

end SYN;