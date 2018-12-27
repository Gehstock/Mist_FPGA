library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity invaders_memory is
	port(
		CLK             : in    std_logic;--10mhz	
		RWE_n           : in    std_logic;
		AD              : in    std_logic_vector(15 downto 0);
		RAB             : in    std_logic_vector(12 downto 0);
		RDB             : out    std_logic_vector(7 downto 0);
		RWD             : in    std_logic_vector(7 downto 0);
		IB              : out    std_logic_vector(7 downto 0)
		);
end invaders_memory;

architecture rtl of invaders_memory is
	signal rom_data_0      : std_logic_vector(7 downto 0);
	signal rom_data_1      : std_logic_vector(7 downto 0);
	signal rom_data_2      : std_logic_vector(7 downto 0);
	signal rom_data_3      : std_logic_vector(7 downto 0);
	signal rom_data_4      : std_logic_vector(7 downto 0);
	signal rom_data_5      : std_logic_vector(7 downto 0);
	signal rom_data_6      : std_logic_vector(7 downto 0);
	signal rom_data_7      : std_logic_vector(7 downto 0);	

begin	
		u_rom_j : entity work.sprom
	  generic map (
--		init_file         => "./roms/Gunfight/7609h.hex",--not working
		init_file         => "./roms/SuEarthInv/earthinv.h.hex",--working
--		init_file         => "./roms/Seawolf/sw0041.h.hex",--not working
--		init_file         => "./roms/Dogpatch/dogpatch.h.hex",--not working
--		init_file         => "./roms/jspecter/romh.hex",--not working
--		init_file         => "./roms/InvadersRevenge/invrvnge.h.hex",
	   widthad_a         => 11,--11
	   width_a         	=> 8)
	  port map (
		clock         		=> Clk,
		Address        	=> AD(10 downto 0),
		q        			=> rom_data_0
		);
		
		u_rom_i : entity work.sprom
	  generic map (
--		init_file         => "./roms/Gunfight/7609h.hex",--not working
		init_file         => "./roms/SuEarthInv/earthinv.h.hex",--working
--		init_file         => "./roms/Seawolf/sw0041.h.hex",--not working
--		init_file         => "./roms/Dogpatch/dogpatch.h.hex",--not working
--		init_file         => "./roms/jspecter/romh.hex",--not working
--		init_file         => "./roms/InvadersRevenge/invrvnge.h.hex",
	   widthad_a         => 11,--11
	   width_a         	=> 8)
	  port map (
		clock         		=> Clk,
		Address        	=> AD(10 downto 0),
		q        			=> rom_data_0
		);

		u_rom_h : entity work.sprom
	  generic map (
--		init_file         => "./roms/Gunfight/7609h.hex",--not working
		init_file         => "./roms/SuEarthInv/earthinv.h.hex",--working
--		init_file         => "./roms/Seawolf/sw0041.h.hex",--not working
--		init_file         => "./roms/Dogpatch/dogpatch.h.hex",--not working
--		init_file         => "./roms/jspecter/romh.hex",--not working
--		init_file         => "./roms/InvadersRevenge/invrvnge.h.hex",
	   widthad_a         => 11,--11
	   width_a         	=> 8)
	  port map (
		clock         		=> Clk,
		Address        	=> AD(10 downto 0),
		q        			=> rom_data_0
		);
	--
	u_rom_g : entity work.sprom
	  generic map (
--		init_file         => "./roms/Gunfight/7609g.hex",
		init_file         => "./roms/SuEarthInv/earthinv.g.hex",
--		init_file         => "./roms/Seawolf/sw0042.g.hex",
--		init_file         => "./roms/Dogpatch/dogpatch.g.hex",
--		init_file         => "./roms/jspecter/romg.hex",
--		init_file         => "./roms/InvadersRevenge/invrvnge.g.hex",
	   widthad_a         => 11,--11
	   width_a         	=> 8)
	  port map (
		clock         		=> Clk,
		Address        	=> AD(10 downto 0),
		q        			=> rom_data_1
		);
	--
	u_rom_f : entity work.sprom
	  generic map (
--		init_file         => "./roms/Gunfight/7609f.hex",
		init_file         => "./roms/SuEarthInv/earthinv.f.hex",
--		init_file         => "./roms/Seawolf/sw0043.f.hex",
--		init_file         => "./roms/Dogpatch/dogpatch.f.hex",
--		init_file         => "./roms/jspecter/romf.hex",
--		init_file         => "./roms/InvadersRevenge/invrvnge.f.hex",
	   widthad_a         => 11,--11
	   width_a         	=> 8)
	  port map (
		clock         		=> Clk,
		Address        	=> AD(10 downto 0),
		q        			=> rom_data_2
		);
	--
	u_rom_e : entity work.sprom
	  generic map (
--		init_file         => "./roms/Gunfight/7609e.hex",
		init_file         => "./roms/SuEarthInv/earthinv.e.hex",
--		init_file         => "./roms/Seawolf/sw0044.e.hex",
--		init_file         => "./roms/Dogpatch/dogpatch.e.hex",
--		init_file         => "./roms/jspecter/rome.hex",
--		init_file         => "./roms/InvadersRevenge/invrvnge.e.hex",
	   widthad_a         => 11,--11
	   width_a         	=> 8)
	  port map (
		clock         		=> Clk,
		Address        	=> AD(10 downto 0),
		q        			=> rom_data_3
		);
	--
	p_rom_data : process(AD, rom_data_0, rom_data_1, rom_data_2, rom_data_3)
	begin
	  IB <= (others => '0');
	  case AD(12 downto 11) is
		when "000" => IB <= rom_data_0;
		when "001" => IB <= rom_data_1;
		when "010" => IB <= rom_data_2;
		when "011" => IB <= rom_data_3;
		when "100" => IB <= rom_data_4;
		when "101" => IB <= rom_data_5;
		when "110" => IB <= rom_data_6;		
		when "111" => IB <= rom_data_7;
		when others => null;
	  end case;
	end process;
		
	u_ram0 : entity work.spram
	generic map (
		 addr_width_g => 13,
		 data_width_g => 8) 
	port map (
		address	=> RAB,
		clken		=> '1',
		clock		=> Clk,
		data		=> RWD,
		wren		=> not RWE_n,
		q			=> RDB
	);

end;