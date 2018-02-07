library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package platform_variant_pkg is

	--
	-- Platform-variant-specific constants (optional)
	--
	
--Test Area	
	--$0000
	constant ROM_0_NAME		: string := "../roms/jatrespecter.hex";
	--$4000
	constant ROM_1_NAME		: string := "";
	constant VRAM_NAME		: string := "../roms/sivram.hex";


--**************************WORKING********************************************************

-- Space Invaders
--	constant ROM_0_NAME		: string := "../roms/invaders0.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";
	
-- Space Invaders 2	
--	constant ROM_0_NAME		: string := "../roms/invadpt20.hex";
--	constant ROM_1_NAME		: string := "../roms/invadpt21.hex";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";

-- Super Earth Invasion
---constant ROM_0_NAME		: string := "../roms/searthin.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "";

-- Lunar Rescue	
--	constant ROM_0_NAME		: string := "../roms/lrescue0.hex";
--	constant ROM_1_NAME		: string := "../roms/lrescue1.hex";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";
	
-- Space Laser
--	constant ROM_0_NAME		: string := "../roms/laser1.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/laser2.hex";

-- Galaxy Wars
--	constant ROM_0_NAME		: string := "../roms/galxwars0.hex";
--	constant ROM_1_NAME		: string := "../roms/galxwars1.hex";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";

-- Space Attack II
--	constant ROM_0_NAME		: string := "../roms/spaceatt.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "";



--**************************NOT WORKING********************************************************
--Yosaku To Donbei (set1)
--	constant ROM_0_NAME		: string := "../roms/yosakdon.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "";

--Yosaku To Donbei (set2)	
-- constant ROM_0_NAME		: string := "../roms/yosakdona.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "";
	
	
-- Ball Bomb
--	constant ROM_0_NAME		: string := "../roms/bomb1.hex";
--	constant ROM_1_NAME		: string := "../roms/bomb2.hex";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";


--4 Player Bowling Alley 
--	constant ROM_0_NAME		: string := "../roms/bowler1.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/bowler2.hex";

-- Gunfight(todo Controls)
--	constant ROM_0_NAME		: string := "../roms/gunfight.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "";

-- Boot Hill(todo Controls)
--	constant ROM_0_NAME		: string := "../roms/boothill.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";

--Check Mate
--	constant ROM_0_NAME		: string := "../roms/checkmate.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";

--Datsun 280 zzz
--	constant ROM_0_NAME		: string := "../roms/280zzzap.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";

--PhantomII
--	constant ROM_0_NAME		: string := "../roms/phantomII.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/phantomIIprom.hex";

-- Space Encounter
--	constant ROM_0_NAME		: string := "../roms/spaceenc1.hex";
--	constant ROM_1_NAME		: string := "../roms/spaceenc1.hex";
--	constant VRAM_NAME		: string := "";

--Jatre Spectre
--	constant ROM_0_NAME		: string := "../roms/jatrespecter.hex";
--	constant ROM_1_NAME		: string := "";
--	constant VRAM_NAME		: string := "../roms/sivram.hex";
	
end;