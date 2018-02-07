---------------------------------------------------------------------------------
-- Galaga video horizontal/vertical and sync generator by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.ALL;

entity gen_video is
port(
	clk     : in std_logic;
	enable  : in std_logic;
	hcnt    : out std_logic_vector(8 downto 0);
	vcnt    : out std_logic_vector(8 downto 0);
	hsync   : out std_logic;
	vsync   : out std_logic;
	blankn  : out std_logic
);
end gen_video;

architecture struct of gen_video is
	signal hblank  : std_logic; 
	signal vblank  : std_logic; 
	signal hcntReg : unsigned (8 DOWNTO 0) := to_unsigned(000,9);
	signal vcntReg : unsigned (8 DOWNTO 0) := to_unsigned(015,9);
begin

hcnt  <= std_logic_vector(hcntReg);
vcnt  <= std_logic_vector(vcntReg);

-- Compteur horizontal : 511-128+1=384 pixels (48 tiles)
-- 192 à 255 :  64 pixels debut de ligne  (8 dont 2 dernières tiles affichées)
-- 256 à 511 : 256 pixels centre de ligne (32 tiles affichées)
-- 128 à 191 :  64 pixels fin de ligne    (8 dont 2 premières tiles affichées)

-- Compteur vertical   : 263-000+1=264 lignes (33 tiles)
-- 000 à 015 :  16 lignes debut de trame  (2 tiles)
-- 016 à 239 : 224 lignes centrales       (28 tiles affichées)
-- 240 à 263 :  24 lignes fin de trame    (3 tiles

-- Synchro horizontale : hcnt=[176 à 204] (29 pixels)
-- Synchro verticale   : vcnt=[260 à 003] ( 8 lignes)

process(clk) begin
	if rising_edge(clk) then    -- clk & ena at 6MHz
		if enable = '1' then

			if hcntReg = 511 then 
				hcntReg <= to_unsigned (128,9);
			else
				hcntReg <= hcntReg + 1;
			end if;

			if hcntReg = 191 then
				if vcntReg = 261 then
					vcntReg <= to_unsigned(0,9);
				else
					vcntReg <= vcntReg + 1;
				end if;
			end if;

			if    hcntReg = (175+ 0-8+8) then hsync <= '1'; -- 1
			elsif hcntReg = (175+29-8+8) then hsync <= '0';
			end if;

			if    vcntReg = 252 then vsync <= '1';
			elsif vcntReg = 260 then vsync <= '0';
			end if;

			if    hcntReg = (127+16+8) then hblank <= '1'; 
			elsif hcntReg = (255-17+8+1) then hblank <= '0';
			end if;

			if    vcntReg = (240+1-1) then vblank <= '1';
			elsif vcntReg = (015+1) then vblank <= '0';
			end if;

			blankn <= not (hblank or vblank); 
		end if;
	end if;
end process;

end architecture;