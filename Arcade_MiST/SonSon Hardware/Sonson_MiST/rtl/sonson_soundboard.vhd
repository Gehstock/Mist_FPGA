library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;

--SOUND CPU:
--0000-07ff RAM
--e000-ffff ROM
--read:
--a000      command from the main CPU
--write:
--2000      8910 #1 control
--2001      8910 #1 write
--4000      8910 #2 control
--4001      8910 #2 write

--WRITE_HANDLER( sonson_sh_irqtrigger_w )
--{
--	static int last;
--	if (last == 0 && data == 1)
--	{
--		 setting bit 0 low then high triggers IRQ on the sound CPU 
--		cpu_cause_interrupt(1,M6809_INT_FIRQ);
--	}
---	last = data;
--}

--void sonson_state::sound_map(address_map &map)
--{
--	map(0x0000, 0x07ff).ram();
--	map(0x2000, 0x2001).w("ay1", FUNC(ay8910_device::address_data_w));
--	map(0x4000, 0x4001).w("ay2", FUNC(ay8910_device::address_data_w));
--	map(0xa000, 0xa000).r("soundlatch", FUNC(generic_latch_8_device::read));
--	map(0xe000, 0xffff).rom();
--}

/* basic machine hardware */
--	{
--		{
--			CPU_M6809,
--			2000000,	/* 2 Mhz (?) */
--			readmem,writemem,0,0,
--			interrupt,1
--		},
--		{
--			CPU_M6809 | CPU_AUDIO_CPU,
--			2000000,	/* 2 Mhz (?) */
--			sound_readmem,sound_writemem,0,0,
--			interrupt,4	/* FIRQs are triggered by the main CPU */
--		},
--	},
	
	
entity sonson_soundboard is
  port(
  clk_2      	: in std_logic;
  clk_1p5      : in std_logic;
  sound_rd     : in std_logic;--a000      command from the main CPU
  areset       : in std_logic;
  sound_data   : in std_logic_vector(7 downto 0);
  audio_out    : out std_logic_vector(11 downto 0)
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
  
   signal reset      : std_logic := '1';
	signal reset_cnt  : integer range 0 to 1000000 := 1000000;
	signal cpu_addr   : std_logic_vector(15 downto 0);
	signal cpu_di     : std_logic_vector( 7 downto 0);
	signal cpu_do     : std_logic_vector( 7 downto 0);
	signal cpu_rw     : std_logic;
	signal cpu_irq    : std_logic;
	signal cpu_nmi    : std_logic;



   signal clk_2M_en			   : std_logic;
	signal cpu_clk_en          : std_logic;
	signal cpu_reset			   : std_logic;
	
	
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
	
	signal ay1_control    : std_logic;
	signal ay1_write    : std_logic;
	signal ay2_control    : std_logic;
	signal ay2_write    : std_logic;
	
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

	
	begin

	-- cs
wram_cs   <= '1' when cpu_addr(15 downto 12) = "0000" else '0';		--0000-07ff RAM 			0000 1000 0000 0000
rom_cs    <= '1' when cpu_addr(15 downto 13) = "111" else '0';			--e000-ffff ROM 			1110 0000 00000000
ay1_control <= '1' when cpu_addr(13 downto 0) = X"2000" else '0';		--2000 8910 #1 control	0010 0000 0000 0000
ay1_write <= '1' when cpu_addr(13 downto 0) = X"2001" else '0';		--2001 8910 #1 write		0010 0000 0000 0001
ay2_control <= '1' when cpu_addr(14 downto 0) = X"4000" else '0';		--4000 8910 #2 control	0100 0000 0000 0000
ay2_write <= '1' when cpu_addr(14 downto 0) = X"4001" else '0';		--4001 8910 #2 write		0100 0000 0000 0001

--ports_cs  <= '1' when cpu_addr(15 downto  4) = X"000"    else '0'; -- 0000-000F
--adpcm_cs  <= '1' when cpu_addr(14 downto 11) = "0001"    else '0'; -- 0800-0FFF / 8800-8FFF
--irqraz_cs <= '1' when cpu_addr(14 downto 12) = "001"     else '0'; -- 1000-1FFF / 9000-9FFF

	
-- write enables
wram_we <=   '1' when cpu_rw = '0' and wram_cs =   '1' else '0';



--ports_we <=  '1' when cpu_rw = '0' and ports_cs =  '1' else '0';
--adpcm_we <=  '1' when cpu_rw = '0' and adpcm_cs =  '1' else '0';
--irqraz_we <= '1' when cpu_rw = '0' and irqraz_cs = '1' else '0';

-- mux cpu in data between roms/io/wram
cpu_di <=	wram_do when wram_cs = '1' else
				sound_data when sound_rd = '1' else
--				port1_ddr when ports_cs = '1' and cpu_addr(3 downto 0) = X"0" else
--				port2_ddr when ports_cs = '1' and cpu_addr(3 downto 0) = X"1" else
--				port1_in  when ports_cs = '1' and cpu_addr(3 downto 0) = X"2" else
--				port2_in  when ports_cs = '1' and cpu_addr(3 downto 0) = X"3" else
				rom_do when rom_cs = '1' else X"FF";




	cpu_inst : mc6809i
	port map
    (
    D				=> cpu_di,
    DOut			=> cpu_do,
    ADDR	  		=> cpu_addr,
    RnW			=> cpu_rw,
    E   			=> '1',
    Q				=> clk_2,
    BS     		=> open,
    BA     		=> open,
    nIRQ			=> not cpu_irq,
    nFIRQ		=> '1',
    nNMI			=> '1',
    AVMA  		=> open,
    BUSY  		=> open,
	 LIC  		=> open,
    nHALT		=> '1',	 
    nRESET		=> not cpu_reset,
    nDMABREQ  	=> '1',
    RegData		=> open
    );
	 
	 
cpu_prog_rom : entity work.sound_rom
port map(
	clk  		=> clk_2,
	addr 		=> cpu_addr(12 downto 0),
	data 		=> rom_do
);

cpu_ram : entity work.spram
	generic map( widthad_a => 11)
port map(
	clock  	=> clk_2,
	wren   	=> wram_we,
	address 	=> cpu_addr(11 downto 0),
	data    	=> cpu_do,
	q    		=> wram_do
);

ay83910_inst1: YM2149
  port map (
    CLK         => clk_1p5,
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

    IOA_in      => (others => '0'),--select_sound_r,
    IOA_out     => open,

    IOB_in      => (others => '0'),
    IOB_out     => ay1_port_b_do
    );

  ay1_audio <= "0000000000" + ay1_chan_a + ay1_chan_b + ay1_chan_c;

  ay83910_inst2: YM2149
  port map (
    CLK         => clk_1p5,
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




end SYN;