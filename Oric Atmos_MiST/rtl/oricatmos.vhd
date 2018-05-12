library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.ALL;
	use ieee.numeric_std.all;

entity oricatmos is
port (
	CLOCK_27  	: in std_logic;
	LED 			: out std_logic;
	VGA_R     	: out std_logic_vector(5 downto 0);
	VGA_G     	: out std_logic_vector(5 downto 0);
	VGA_B     	: out std_logic_vector(5 downto 0);
	VGA_HS    	: out std_logic;
	VGA_VS    	: out std_logic;
	SPI_SCK 		: in std_logic;
	SPI_DI 		: in std_logic;
	SPI_DO 		: out std_logic;
	SPI_SS3 		: in std_logic;
	CONF_DATA0	: in std_logic;
	AUDIO_L 		: out std_logic;
	AUDIO_R 		: out std_logic
);
end;

architecture RTL of oricatmos is
	signal VGA_R_O             : std_logic_vector(3 downto 0);
	signal VGA_G_O             : std_logic_vector(3 downto 0);
	signal VGA_B_O             : std_logic_vector(3 downto 0);
	signal hsync        			: std_logic;
	signal vsync        			: std_logic;
	signal hq2x        			: std_logic;
	signal buttons    			: std_logic_vector(1 downto 0);
	signal switches    			: std_logic_vector(1 downto 0);
	signal status     			: std_logic_vector(31 downto 0);
	signal scandoubler_disable : std_logic; 
	signal scanlines				: std_logic_vector(1 downto 0);
	signal ypbpr         		: std_logic;  
	signal ps2Clk     			: std_logic;
	signal ps2Data    			: std_logic;
	signal loc_reset_n        	: std_logic; --active low
	signal reset        			: std_logic := '1'; 
	signal clk24              	: std_logic := '0';
	signal clk12              	: std_logic := '0';
	signal clk6               	: std_logic := '0';
	signal pll_locked         	: std_logic := '0';
	signal CPU_ADDR           	: std_logic_vector(23 downto 0);
	signal CPU_DI             	: std_logic_vector( 7 downto 0);
	signal CPU_DO             	: std_logic_vector( 7 downto 0);
	signal cpu_rw             	: std_logic;
	signal cpu_irq            	: std_logic;
	signal ad                 	: std_logic_vector(15 downto 0);
	signal via_pa_out_oe      	: std_logic_vector( 7 downto 0);
	signal via_pa_in          	: std_logic_vector( 7 downto 0);
	signal via_pa_out         	: std_logic_vector( 7 downto 0);
	signal via_cb1_out        	: std_logic;
	signal via_cb1_oe_l       	: std_logic;
	signal via_cb2_out        	: std_logic;
	signal via_cb2_oe_l       	: std_logic;
	signal via_in             	: std_logic_vector( 7 downto 0);
	signal via_out            	: std_logic_vector( 7 downto 0);
	signal via_oe_l           	: std_logic_vector( 7 downto 0);
	signal VIA_DO             	: std_logic_vector( 7 downto 0);
	signal KEY_ROW            	: std_logic_vector( 7 downto 0);
	signal psg_bdir           	: std_logic;
	signal PSG_OUT            	: std_logic_vector( 7 downto 0);
	signal ula_phi2           	: std_logic;
	signal ula_CSIOn          	: std_logic;
	signal ula_CSIO           	: std_logic;
	signal ula_CSROMn         	: std_logic;
	signal SRAM_DO            	: std_logic_vector( 7 downto 0);
	signal ula_AD_SRAM        	: std_logic_vector(15 downto 0);
	signal ula_CE_SRAM        	: std_logic;
	signal ula_OE_SRAM        	: std_logic;
	signal ula_WE_SRAM        	: std_logic;
	signal ula_LE_SRAM        	: std_logic;
	signal ula_CLK_4          	: std_logic;
	signal ula_IOCONTROL      	: std_logic;
	signal ula_VIDEO_R        	: std_logic;
	signal ula_VIDEO_G        	: std_logic;
	signal ula_VIDEO_B        	: std_logic;
	signal ula_SYNC           	: std_logic;
	signal ROM_DO             	: std_logic_vector( 7 downto 0);
	signal hs_int             	: std_logic;
	signal vs_int             	: std_logic;
	signal dummy              	: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_cmpblk_n_out     	: std_logic;

	
	constant CONF_STR : string := 
		"ORIC;;O89,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;T6,Reset;";

	function to_slv(s: string) return std_logic_vector is
		constant ss: string(1 to s'length) := s;
		variable rval: std_logic_vector(1 to 8 * s'length);
		variable p: integer;
		variable c: integer; 
	begin  
		for i in ss'range loop
			p := 8 * i;
			c := character'pos(ss(i));
			rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
		end loop;
		return rval;
	end function;
  
   component mist_io
		generic ( STRLEN : integer := 0 );
		port (
			clk_sys :in std_logic;
			SPI_SCK, CONF_DATA0, SPI_DI :in std_logic;
			SPI_DO : out std_logic;
			conf_str : in std_logic_vector(8*STRLEN-1 downto 0);
			buttons : out std_logic_vector(1 downto 0);
			switches : out std_logic_vector(1 downto 0);
			joystick_0 : out std_logic_vector(7 downto 0);
			joystick_1 : out std_logic_vector(7 downto 0);
			status : out std_logic_vector(31 downto 0);
			scandoubler_disable, ypbpr : out std_logic;
			ps2_kbd_clk : out std_logic;
			ps2_kbd_data : out std_logic
		);
	end component mist_io;

	component video_mixer
		generic ( LINE_LENGTH : integer := 384; HALF_DEPTH : integer := 1 );
		port (
			clk_sys, ce_pix, ce_pix_actual : in std_logic;
			SPI_SCK, SPI_SS3, SPI_DI : in std_logic;
			
			scandoubler_disable, hq2x, ypbpr, ypbpr_full : in std_logic;
			scanlines : in std_logic_vector(1 downto 0);
			R, G, B : in std_logic_vector(2 downto 0);
			HSync, VSync, line_start, mono : in std_logic;

			VGA_R,VGA_G, VGA_B : out std_logic_vector(5 downto 0);
			VGA_VS, VGA_HS : out std_logic
		);
	end component video_mixer;

begin
	inst_pll : entity work.pll
	port map (
		areset	=> open,
		inclk0	=> CLOCK_27,
		c0		=> clk24,
		c1		=> clk12,
		c2		=> clk6,
		locked	=> pll_locked
	);

loc_reset_n <= pll_locked;
--reset <= not status(0) or status(6) or buttons(1);
	inst_cpu : entity work.T65
	port map (
		Mode    => "00",
		Res_n   => loc_reset_n,
		Enable  => '1',
		Clk     => ula_phi2,
		Rdy     => '1',
		Abort_n => '1',
		IRQ_n   => cpu_irq,
		NMI_n   => '1',
		SO_n    => '1',
		R_W_n   => cpu_rw,
		Sync    => open,
		EF      => open,
		MF      => open,
		XF      => open,
		ML_n    => open,
		VP_n    => open,
		VDA     => open,
		VPA     => open,
		A       => CPU_ADDR,
		DI      => CPU_DI,
		DO      => CPU_DO
	);
-- place Rom in LE and we can use 48kb Memory	 
--	inst_rom : entity work.rom
--	port map (
--		clk  => clk24,
--		ADDR => CPU_ADDR(13 downto 0),
--		DATA => ROM_DO
--	);
-- place in BRAM and reduce Memory to 16kb see file ram48k
	inst_rom : entity work.rrom
	port map (
		clock  => clk24,
		address => CPU_ADDR(13 downto 0),
		q => ROM_DO
	);

ad(15 downto 0)  <= ula_AD_SRAM when ula_phi2 = '0' else CPU_ADDR(15 downto 0);

	inst_ram : entity work.ram48k
	port map(
		clk  => clk24,
		cs   => ula_CE_SRAM,
		oe   => ula_OE_SRAM,
		we   => ula_WE_SRAM,
		addr => ad,
		di   => CPU_DO,
		do   => SRAM_DO
	);
	
	inst_ula : entity work.ULA
	port map (
		RESETn     => loc_reset_n,
		CLK        => clk24,
		CLK_4      => ula_CLK_4,
		RW         => cpu_rw,
		ADDR       => CPU_ADDR(15 downto 0),
		MAPn       => '1',
		DB         => SRAM_DO,
		CSROMn     => ula_CSROMn,
		CSIOn      => ula_CSIOn,
		SRAM_AD    => ula_AD_SRAM,
		SRAM_OE    => ula_OE_SRAM,
		SRAM_CE    => ula_CE_SRAM,
		SRAM_WE    => ula_WE_SRAM,
		LATCH_SRAM => ula_LE_SRAM,
		PHI2       => ula_PHI2,
		R          => ULA_VIDEO_R,
		G          => ULA_VIDEO_G,
		B          => ULA_VIDEO_B,
		SYNC       => ULA_SYNC,
		HSYNC      => hs_int,
		VSYNC      => vs_int
	);

	vmixer : video_mixer
	generic map(
	HALF_DEPTH => 1,
	LINE_LENGTH => 480
	)
	
	port map (
		clk_sys => clk24,
		ce_pix  => clk6,
		ce_pix_actual => clk6,
		SPI_SCK => SPI_SCK, 
		SPI_SS3 => SPI_SS3,
		SPI_DI => SPI_DI,
		hq2x => hq2x,
		ypbpr => ypbpr,
		ypbpr_full => '1',
		scanlines => scanlines,
		scandoubler_disable => scandoubler_disable,
		R => ULA_VIDEO_R & ULA_VIDEO_R & ULA_VIDEO_R,
		G => ULA_VIDEO_G & ULA_VIDEO_G & ULA_VIDEO_G,
		B => ULA_VIDEO_B & ULA_VIDEO_B & ULA_VIDEO_B,
		HSync => hs_int,
		VSync => vs_int,
		line_start => '0',
		mono => '0',
		VGA_R => VGA_R,
		VGA_G => VGA_G,
		VGA_B => VGA_B,
		VGA_VS => VGA_VS,
		VGA_HS => VGA_HS
);

scanlines(1) <= '1' when status(9 downto 8) = "11" and scandoubler_disable = '0' else '0';
scanlines(0) <= '1' when status(9 downto 8) = "10" and scandoubler_disable = '0' else '0';
hq2x         <= '1' when status(9 downto 8) = "01" else '0';

mist_io_inst : mist_io
	generic map (STRLEN => CONF_STR'length)
	port map (
		clk_sys => clk24,
		SPI_SCK => SPI_SCK,
		CONF_DATA0 => CONF_DATA0,
		SPI_DI => SPI_DI,
		SPI_DO => SPI_DO,
		conf_str => to_slv(CONF_STR),
		buttons  => buttons,
		switches  => switches,
		scandoubler_disable => scandoubler_disable,
		ypbpr => ypbpr,
		status => status,
		ps2_kbd_clk => ps2Clk,
		ps2_kbd_data => ps2Data
);

ula_CSIO <= not ula_CSIOn;

	inst_via : entity work.M6522
	port map (
		I_RS          => CPU_ADDR(3 downto 0),
		I_DATA        => CPU_DO(7 downto 0),
		O_DATA        => VIA_DO,
		O_DATA_OE_L   => open,
		I_RW_L        => cpu_rw,
		I_CS1         => ula_CSIO,
		I_CS2_L       => ula_IOCONTROL,
		O_IRQ_L       => cpu_irq,   -- note, not open drain
		I_CA1         => '1',       -- PRT_ACK
		I_CA2         => '1',       -- psg_bdir
		O_CA2         => psg_bdir,  -- via_ca2_out
		O_CA2_OE_L    => open,
		I_PA          => via_pa_in,
		O_PA          => via_pa_out,
		O_PA_OE_L     => via_pa_out_oe,
--		I_CB1         => K7_TAPEIN,
		I_CB1         => '0',
		O_CB1         => via_cb1_out,
		O_CB1_OE_L    => via_cb1_oe_l,
		I_CB2         => '1',
		O_CB2         => via_cb2_out,
		O_CB2_OE_L    => via_cb2_oe_l,
		I_PB          => via_in,
		O_PB          => via_out,
		O_PB_OE_L     => via_oe_l,
		RESET_L       => loc_reset_n,
		I_P2_H        => ula_phi2,
		ENA_4         => '1',
		CLK           => ula_CLK_4
	);

	inst_key : entity work.keyboard
	port map(
		CLK		=> clk24,
		RESET		=> '0', -- active high reset
		PS2CLK	=> ps2Clk,
		PS2DATA	=> ps2Data,
		COL		=> via_out(2 downto 0),
		ROWbit	=> KEY_ROW
	);

via_in <= x"F7" when (KEY_ROW or VIA_PA_OUT) = x"FF" else x"FF";

	inst_psg : entity work.YM2149
	port map (
		I_DA       => via_pa_out,
		O_DA       => via_pa_in,
		O_DA_OE_L  => open,
		I_A9_L     => '0',
		I_A8       => '1',
		I_BDIR     => via_cb2_out,
		I_BC2      => '1',
		I_BC1      => psg_bdir,
		I_SEL_L    => '1',
		O_AUDIO    => PSG_OUT,
		RESET_L    => loc_reset_n,
		ENA        => '1',
		CLK        => ula_PHI2
	);

	inst_dacl : entity work.DAC
	port map (
		CLK_DAC  => clk24,
		RST => loc_reset_n,
		IN_DAC  => PSG_OUT,
		OUT_DAC  => AUDIO_L
	);

	inst_dacr : entity work.DAC
	port map (
		CLK_DAC  => clk24,
		RST => loc_reset_n,
		IN_DAC  => PSG_OUT,
		OUT_DAC  => AUDIO_R
	);

ula_IOCONTROL <= '0';

	process
	begin
		wait until rising_edge(clk24);
		-- expansion port
		if    cpu_rw = '1' and ula_IOCONTROL = '1' and ula_CSIOn  = '0'                       then
			CPU_DI <= SRAM_DO;
		-- Via
		elsif cpu_rw = '1' and ula_IOCONTROL = '0' and ula_CSIOn  = '0' and ula_LE_SRAM = '0' then
			CPU_DI <= VIA_DO;
		-- ROM
		elsif cpu_rw = '1' and ula_IOCONTROL = '0' and ula_CSROMn = '0'                       then
			CPU_DI <= ROM_DO;
		-- Read data
		elsif cpu_rw = '1' and ula_IOCONTROL = '0' and ula_phi2   = '1' and ula_LE_SRAM = '0' then
			cpu_di <= SRAM_DO;
		end if;
	end process;

	------------------------------------------------------------
	-- K7 PORT
	------------------------------------------------------------
--	K7_TAPEOUT  <= via_out(7);
--	K7_REMOTE   <= via_out(6);
--	K7_AUDIOOUT <= AUDIO_OUT;

	------------------------------------------------------------
	-- PRINTER PORT
	------------------------------------------------------------
--	PRT_DATA    <= via_pa_out;
--	PRT_STR     <= via_out(4);
	LED <= '1';
end RTL;
