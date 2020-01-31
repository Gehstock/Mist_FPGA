library IEEE;
use IEEE.std_logic_1164.all;

package scramble_pack is

    constant I_HWSEL_SCRAMBLE : integer := 0; -- this MUST be set true for scramble, the_end, amidar
    constant I_HWSEL_FROGGER  : integer := 1; -- this MUST be set true for frogger
    constant I_HWSEL_SCOBRA   : integer := 2; -- SuperCobra, TazzMania
    constant I_HWSEL_CALIPSO  : integer := 3; -- Calipso
	constant I_HWSEL_DARKPLNT : integer := 4; -- Dark Planet
	constant I_HWSEL_ANTEATER : integer := 5; -- Ant Eater (SCOBRA with obj_ram address line obfuscation)
	constant I_HWSEL_LOSTTOMB : integer := 6; -- Lost Tomb (SCOBRA with obj_ram address line obfuscation)

end;
