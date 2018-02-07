library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library altera;
use altera.altera_europa_support_lib.to_std_logic;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.sprite_pkg.all;
use work.target_pkg.all;
use work.project_pkg.all;
use work.platform_pkg.all;
use work.platform_variant_pkg.all;

entity platform is
  generic
  (
    NUM_INPUT_BYTES   : integer
  );
  port
  (
    -- clocking and reset
    clkrst_i        : in from_CLKRST_t;

    -- misc I/O
    buttons_i       : in from_BUTTONS_t;
    switches_i      : in from_SWITCHES_t;
    leds_o          : out to_LEDS_t;

    -- controller inputs
    inputs_i        : in from_MAPPED_INPUTS_t(0 to NUM_INPUT_BYTES-1);

    -- graphics
    
    bitmap_i        : in from_BITMAP_CTL_a(1 to PACE_VIDEO_NUM_BITMAPS);
    bitmap_o        : out to_BITMAP_CTL_a(1 to PACE_VIDEO_NUM_BITMAPS);
    
    tilemap_i       : in from_TILEMAP_CTL_a(1 to PACE_VIDEO_NUM_TILEMAPS);
    tilemap_o       : out to_TILEMAP_CTL_a(1 to PACE_VIDEO_NUM_TILEMAPS);

    sprite_reg_o    : out to_SPRITE_REG_t;
    sprite_i        : in from_SPRITE_CTL_t;
    sprite_o        : out to_SPRITE_CTL_t;
		spr0_hit				: in std_logic;

    -- various graphics information
    graphics_i      : in from_GRAPHICS_t;
    graphics_o      : out to_GRAPHICS_t;

    -- sound
    snd_i           : in from_SOUND_t;
    snd_o           : out to_SOUND_t;
    
    -- custom i/o
    project_i       : in from_PROJECT_IO_t;
    project_o       : out to_PROJECT_IO_t;
    platform_i      : in from_PLATFORM_IO_t;
    platform_o      : out to_PLATFORM_IO_t;
    target_i        : in from_TARGET_IO_t;
    target_o        : out to_TARGET_IO_t
  );
end entity platform;

architecture SYN of platform is

	alias clk_sys					: std_logic is clkrst_i.clk(0);
	alias clk_video       : std_logic is clkrst_i.clk(1);
	
  -- uP signals  
  signal clk_2M_en			: std_logic;
  signal cpu_a          : std_logic_vector(15 downto 0);
  signal cpu_d_i        : std_logic_vector(7 downto 0);
  signal cpu_d_o        : std_logic_vector(7 downto 0);
  signal cpu_mem_rd     : std_logic;
  signal cpu_mem_wr     : std_logic;
  signal cpu_io_rd      : std_logic;
  signal cpu_io_wr      : std_logic;
  signal cpu_irq        : std_logic;
  signal cpu_intvec     : std_logic_vector(7 downto 0);
  signal cpu_intack     : std_logic;
	alias io_addr					: std_logic_vector(7 downto 0) is cpu_a(7 downto 0);
	                        
  -- ROM signals        
	signal rom0_cs				: std_logic;
  signal rom0_datao     : std_logic_vector(7 downto 0);
	signal rom1_cs				: std_logic;                        
	signal rom1_datao			: std_logic_vector(7 downto 0);
	
  -- VRAM signals       
	signal vram_cs				: std_logic;
  signal vram_wr        : std_logic;
  signal vram_datao     : std_logic_vector(7 downto 0);
                        
  -- RAM signals        
  signal wram_cs        : std_logic;
  signal wram_wr        : std_logic;
  signal wram_datao     : std_logic_vector(7 downto 0);

	-- IO signals
	signal port_cs				: std_logic_vector(5 downto 0);
	signal port_wr				: std_logic_vector(5 downto 2);
	alias game_reset			: std_logic is inputs_i(2).d(0);
	signal shift_dout			: std_logic_vector(7 downto 0);

  -- other signals      
	signal cpu_reset			: std_logic;
  signal cpu_mem_d_i    : std_logic_vector(7 downto 0);
  signal cpu_io_d_i     : std_logic_vector(7 downto 0);
  
  signal spec_key_en    : std_logic_vector(7 downto 0);
  alias osd_key_en      : std_logic is spec_key_en(1);
  alias rot_key_en      : std_logic is spec_key_en(2);
  
begin

  assert false
    report  "CLK0_FREQ_MHz=" & integer'image(CLK0_FREQ_MHz) &
            " CPU_FREQ_MHz=" &  integer'image(CPU_FREQ_MHz) &
            " CPU_CLK_ENA_DIV=" & integer'image(INVADERS_CPU_CLK_ENA_DIVIDE_BY)
      severity note;

	cpu_reset <= clkrst_i.arst or game_reset;
	
  -- read mux
  cpu_d_i <= cpu_mem_d_i when (cpu_mem_rd = '1') else cpu_io_d_i;

	-- memory chip selects
	-- ROM0 $0000-$1FFF
	rom0_cs <= '1' when cpu_a(14 downto 13) = "00" else '0';
	-- WRAM $2000-$23FF
	wram_cs <= '1' when cpu_a(14 downto 10) = "01000" else '0';
	-- VRAM $2400-$3FFF
	vram_cs <= '1' when cpu_a(14 downto 13) = "01" and cpu_a(12 downto 10) /= "000" else '0';
	-- ROM1 $4000-$5FFF
	rom1_cs <= '1' when cpu_a(14 downto 13) = "10" else '0';

	-- memory write enables
	vram_wr <= vram_cs and cpu_mem_wr;
	wram_wr <= wram_cs and cpu_mem_wr;

	-- I/O chip selects
	-- inputs port 0
	port_cs(0) <= '1' when cpu_a(2 downto 0) = "000" else '0';
	-- inputs port 1
	port_cs(1) <= '1' when cpu_a(2 downto 0) = "001" else '0';
	-- number of bits to shift ($2)
	port_cs(2) <= '1' when cpu_a(2 downto 0) = "010" else '0';
	-- sound reg #1 ($3)
	port_cs(3) <= '1' when cpu_a(2 downto 0) = "011" else '0';
	-- shifter data ($4)
	port_cs(4) <= '1' when cpu_a(2 downto 0) = "100" else '0';
	-- sound reg #2 ($5)
	port_cs(5) <= '1' when cpu_a(2 downto 0) = "101" else '0';

	-- io write enables
	port_wr(2) <= port_cs(2) and cpu_io_wr;
	port_wr(3) <= port_cs(3) and cpu_io_wr;
	port_wr(4) <= port_cs(4) and cpu_io_wr;
	port_wr(5) <= port_cs(5) and cpu_io_wr;

	-- sound interface
	snd_o.rd <= (port_cs(3) or port_cs(5)) and cpu_io_rd; -- not used
	snd_o.wr <= (port_cs(3) or port_cs(5)) and cpu_io_wr;
  snd_o.d <= cpu_d_o;
  snd_o.a <= cpu_a(snd_o.a'range);
  
	-- memory read mux
	cpu_mem_d_i <= 	rom0_datao when rom0_cs = '1' else
									wram_datao when wram_cs = '1' else
									vram_datao when vram_cs = '1' else
									rom1_datao when rom1_cs = '1' else
									(others => '1');
	
	-- io read mux
	cpu_io_d_i <= X"40" when port_cs(0) = '1' else
								inputs_i(0).d when port_cs(1) = '1' else
								inputs_i(1).d when port_cs(2) = '1' else
								shift_dout when port_cs(3) = '1' else
								X"00";

	-- shifter block
	process (clk_sys, clkrst_i.arst)
		variable shift_din	: std_logic_vector(15 downto 0);
		variable shift_amt 	: std_logic_vector(2 downto 0);
		variable wr2_r 			: std_logic := '0';
		variable wr4_r 			: std_logic := '0';
	begin
		if clkrst_i.arst = '1' then
			wr2_r := '0';
			wr4_r := '0';
		elsif rising_edge(clk_sys) then
			-- latch on rising edge of WR to port 2 (shift_amt)
			if port_wr(2) = '1' and wr2_r = '0' then
				shift_amt := cpu_d_o(2 downto 0);
			-- latch on rising edge of WR to port 4 (shift_din)
			elsif port_wr(4) = '1' and wr4_r = '0' then
				shift_din := cpu_d_o & shift_din(15 downto 8);
			end if;
			wr2_r := port_wr(2);
			wr4_r := port_wr(4);
		end if;

		-- combinatorial logic
    case shift_amt(2 downto 0) is
	    when "000" =>
		    shift_dout <= shift_din(15 downto 8);
		    when "001" =>
		    shift_dout <= shift_din(14 downto 7);
	    when "010" =>
		    shift_dout <= shift_din(13 downto 6);
	    when "011" =>
		    shift_dout <= shift_din(12 downto 5);
	    when "100" =>
		    shift_dout <= shift_din(11 downto 4);
	    when "101" =>
		    shift_dout <= shift_din(10 downto 3);
	    when "110" =>
		    shift_dout <= shift_din(9 downto 2);
	    when "111" =>
		    shift_dout <= shift_din(8 downto 1);
	    when others =>
    end case;

	end process;

	INT_BLOCK : block
	
		constant RST08 : std_logic_vector(7 downto 0) := X"CF";
		constant RST10 : std_logic_vector(7 downto 0) := X"D7";
	
	begin

		process (clk_sys, cpu_reset)
			subtype count_60Hz_t is integer range 0 to CLK0_FREQ_MHz * 1000000 / 60 - 1;
			variable count : count_60Hz_t;
		begin
			if cpu_reset = '1' then
				cpu_irq <= '0';
				count := 0;
			elsif rising_edge(clk_sys) then
				-- generate interrupt
				count := count + 1;
				if count = count_60Hz_t'high/2 then
					cpu_irq <= '1';
					cpu_intvec <= RST08;
				elsif count = count_60Hz_t'high then
					count := 0;
					cpu_irq <= '1';
					cpu_intvec <= RST10;
				-- clear interrupt
				elsif cpu_intack = '1' then
					cpu_irq <= '0';
				end if;
			end if;
		end process;

	end block INT_BLOCK;	

  -- special keys
  process (clk_sys, clkrst_i.arst)
    variable spec_key_r   : std_logic_vector(7 downto 0);
  begin
    if clkrst_i.arst = '1' then
      spec_key_r := (others => '0');
      osd_key_en <= '0';
      rot_key_en <= to_std_logic(INVADERS_ROTATE_VIDEO);
    elsif rising_edge(clk_sys) then
      for i in 0 to 7 loop
        if inputs_i(2).d(i) = '1' and spec_key_r(i) = '0' then
          spec_key_en <= not spec_key_en;
        end if;
      end loop;
      spec_key_r := inputs_i(2).d;
    end if;
  end process;

  -- video rotate key
  graphics_o.bit8(0)(0) <= rot_key_en;
  
	-- generate CPU clock (2MHz from 20MHz)
	clk_en_inst : entity work.clk_div
		generic map
		(
			DIVISOR		=> integer(INVADERS_CPU_CLK_ENA_DIVIDE_BY)
		)
		port map
		(
			clk				=> clk_sys,
			reset			=> clkrst_i.arst,
			clk_en		=> clk_2M_en
		);
		
  U_uP : entity work.Z80                                                
    port map
    (
      clk			=> clk_sys,                                   
      clk_en	=> clk_2M_en,
      reset  	=> cpu_reset,                                     

      addr   	=> cpu_a,
      datai  	=> cpu_d_i,
      datao  	=> cpu_d_o,

      mem_rd 	=> cpu_mem_rd,
      mem_wr 	=> cpu_mem_wr,
      io_rd  	=> cpu_io_rd,
      io_wr  	=> cpu_io_wr,

      intreq 	=> cpu_irq,
      intvec 	=> cpu_intvec,
      intack 	=> cpu_intack,
      nmi    	=> '0'
    );

 
  
    rom0_inst : entity work.invaders_rom_0
      port map
      (
        clock		=> clk_sys,
        address => cpu_a(12 downto 0),
        q				=> rom0_datao
      );


  -- this should be inside the above generate
  -- but this crashes Quartus v10.1SP1
  GEN_ROM1 : if ROM_1_NAME /= "" generate
    rom1_inst : entity work.invaders_rom_1
      port map
      (
        clock		=> clk_sys,
        address => cpu_a(11 downto 0),
        q				=> rom1_datao
      );
  else generate
    rom1_datao <= (others => '0');
  end generate GEN_ROM1;

  --
  --	*** WARNING - the contents of the VRAM are offset!!!
  --							- the video won't look right!!!!
  --
  
  -- wren_a *MUST* be GND for CYCLONEII_SAFE_WRITE=VERIFIED_SAFE
  vram_inst : entity work.vram
    port map
    (
        clock_b   	=> clk_sys,
        address_b   => cpu_a(12 downto 0),
        data_b      => cpu_d_o,
        q_b					=> vram_datao,
        wren_b			=> vram_wr,

        clock_a     => clk_video,
        address_a   => bitmap_i(1).a(12 downto 0),
        data_a      => (others => '0'),
        q_a			    => bitmap_o(1).d(7 downto 0),
        wren_a		  => '0'
    );

		
			wram_inst : entity work.wram
				port map
				(
					clock				=> clk_sys,
					address			=> cpu_a(9 downto 0),
					data				=> cpu_d_o,
					wren				=> wram_wr,
					q						=> wram_datao
				);

		
  -- unused outputs

  --graphics_o <= NULL_TO_GRAPHICS;
  --tilemap_o <= NULL_TO_TILEMAP_CTL;
  sprite_reg_o <= NULL_TO_SPRITE_REG;
  sprite_o <= NULL_TO_SPRITE_CTL;
	leds_o <= (others => '0');
  
end SYN;
