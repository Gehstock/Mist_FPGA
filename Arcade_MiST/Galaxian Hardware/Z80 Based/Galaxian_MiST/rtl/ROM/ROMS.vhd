library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_PGM_0 is
generic (
	name : string := "GALAXIAN"
);
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(13 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_PGM_0 is
begin

rom_pgm: if name="GALAXIAN" generate
		mc_roms : entity work.GALAXIAN_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="MOONCR" generate
		mc_roms : entity work.MOONCR_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="AZURIAN" generate
		mc_roms : entity work.AZURIAN_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="BLACKHOLE" generate
		mc_roms : entity work.BLACKHOLE_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="CATACOMB" generate
		mc_roms : entity work.CATACOMB_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="CHEWINGG" generate
		mc_roms : entity work.CHEWINGGUM_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="DEVILFSH" generate
		mc_roms : entity work.DEVILFISH_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="KINGBAL" generate
		mc_roms : entity work.kb_prog
		port map (clk => clk, addr => addr, data => data );
	elsif name="MRDONIGH" generate
		mc_roms : entity work.MRDONIGHTMARE_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="OMEGA" generate
		mc_roms : entity work.OMEGA_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="ORBITRON" generate
		mc_roms : entity work.ORBITRON_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="PISCES" generate
		mc_roms : entity work.PISCES_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="UNIWARS" generate
		mc_roms : entity work.UNIWARS_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="VICTORY" generate
		mc_roms : entity work.VICTORY_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="WAROFBUG" generate
		mc_roms : entity work.WAROFBUGS_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="ZIGZAG" generate
		mc_roms : entity work.ZIGZAG_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
	elsif name="TRIPLEDR" generate
		mc_roms : entity work.TRIPLEDRAWPOKER_ROM_PGM_0
		port map (clk => clk, addr => addr, data => data );
end generate;

end architecture;

-------------------------
library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_1K is
generic (
	name : string := "GALAXIAN"
);
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(11 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_1K is
begin

rom_pgm: if name="GALAXIAN" generate
		mc_roms : entity work.GALAXIAN_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="MOONCR" generate
		mc_roms : entity work.MOONCR_1K
		port map (clk => clk, addr => addr, data => data );
	elsif name="AZURIAN" generate
		mc_roms : entity work.AZURIAN_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="BLACKHOLE" generate
		mc_roms : entity work.BLACKHOLE_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="CATACOMB" generate
		mc_roms : entity work.CATACOMB_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="CHEWINGG" generate
		mc_roms : entity work.CHEWINGGUM_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="DEVILFSH" generate
		mc_roms : entity work.DEVILFISH_1K
		port map (clk => clk, addr => addr, data => data );
	elsif name="KINGBAL" generate
		mc_roms : entity work.KB_1K
		port map (clk => clk, addr => addr, data => data );
	elsif name="MRDONIGH" generate
		mc_roms : entity work.MRDONIGHTMARE_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="OMEGA" generate
		mc_roms : entity work.OMEGA_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="ORBITRON" generate
		mc_roms : entity work.ORBITRON_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="PISCES" generate
		mc_roms : entity work.PISCES_1K
		port map (clk => clk, addr => addr, data => data );
	elsif name="UNIWARS" generate
		mc_roms : entity work.UNIWARS_1K
		port map (clk => clk, addr => addr, data => data );
	elsif name="VICTORY" generate
		mc_roms : entity work.VICTORY_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="WAROFBUG" generate
		mc_roms : entity work.WAROFBUGS_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="ZIGZAG" generate
		mc_roms : entity work.ZIGZAG_1K
		port map (clk => clk, addr => addr, data => data );
	elsif name="TRIPLEDR" generate
		mc_roms : entity work.TRIPLEDRAWPOKER_1K
		port map (clk => clk, addr => addr(10 downto 0), data => data );
end generate;

end architecture;

-------------------------

library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_1H is
generic (
	name : string := "GALAXIAN"
);
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(11 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_1H is
begin

rom_pgm: if name="GALAXIAN" generate
		mc_roms : entity work.GALAXIAN_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="MOONCR" generate
		mc_roms : entity work.MOONCR_1H
		port map (clk => clk, addr => addr, data => data );
	elsif name="AZURIAN" generate
		mc_roms : entity work.AZURIAN_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="BLACKHOLE" generate
		mc_roms : entity work.BLACKHOLE_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="CATACOMB" generate
		mc_roms : entity work.CATACOMB_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="CHEWINGG" generate
		mc_roms : entity work.CHEWINGGUM_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="DEVILFSH" generate
		mc_roms : entity work.DEVILFISH_1H
		port map (clk => clk, addr => addr, data => data );
	elsif name="KINGBAL" generate
		mc_roms : entity work.KB_1H
		port map (clk => clk, addr => addr, data => data );
	elsif name="MRDONIGH" generate
		mc_roms : entity work.MRDONIGHTMARE_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="OMEGA" generate
		mc_roms : entity work.OMEGA_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="ORBITRON" generate
		mc_roms : entity work.ORBITRON_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="PISCES" generate
		mc_roms : entity work.PISCES_1H
		port map (clk => clk, addr => addr, data => data );
	elsif name="UNIWARS" generate
		mc_roms : entity work.UNIWARS_1H
		port map (clk => clk, addr => addr, data => data );
	elsif name="VICTORY" generate
		mc_roms : entity work.VICTORY_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="WAROFBUG" generate
		mc_roms : entity work.WAROFBUGS_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
	elsif name="ZIGZAG" generate
		mc_roms : entity work.ZIGZAG_1H
		port map (clk => clk, addr => addr, data => data );
	elsif name="TRIPLEDR" generate
		mc_roms : entity work.TRIPLEDRAWPOKER_1H
		port map (clk => clk, addr => addr(10 downto 0), data => data );
end generate;

end architecture;

-------------------------

library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity ROM_6L is
generic (
	name : string := "GALAXIAN"
);
port (
	clk  : in  std_logic;
	addr : in  std_logic_vector(4 downto 0);
	data : out std_logic_vector(7 downto 0)
);
end entity;

architecture prom of ROM_6L is
begin

rom_pgm: if name="GALAXIAN" generate
		mc_roms : entity work.GALAXIAN_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="MOONCR" generate
		mc_roms : entity work.MOONCR_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="AZURIAN" generate
		mc_roms : entity work.AZURIAN_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="BLACKHOLE" generate
		mc_roms : entity work.BLACKHOLE_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="CATACOMB" generate
		mc_roms : entity work.CATACOMB_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="CHEWINGG" generate
		mc_roms : entity work.CHEWINGGUM_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="DEVILFSH" generate
		mc_roms : entity work.DEVILFISH_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="KINGBAL" generate
		mc_roms : entity work.KB_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="MRDONIGH" generate
		mc_roms : entity work.MRDONIGHTMARE_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="OMEGA" generate
		mc_roms : entity work.OMEGA_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="ORBITRON" generate
		mc_roms : entity work.ORBITRON_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="PISCES" generate
		mc_roms : entity work.PISCES_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="UNIWARS" generate
		mc_roms : entity work.UNIWARS_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="VICTORY" generate
		mc_roms : entity work.VICTORY_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="WAROFBUG" generate
		mc_roms : entity work.WAROFBUGS_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="ZIGZAG" generate
		mc_roms : entity work.ZIGZAG_6L
		port map (clk => clk, addr => addr, data => data );
	elsif name="TRIPLEDR" generate
		mc_roms : entity work.TRIPLEDRAWPOKER_6L
		port map (clk => clk, addr => addr, data => data );
end generate;

end architecture;
