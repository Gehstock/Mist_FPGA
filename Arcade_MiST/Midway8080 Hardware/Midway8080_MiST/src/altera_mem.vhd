library IEEE;
use ieee.std_logic_1164.all;
library work;
use work.pace_pkg.all;
use work.platform_variant_pkg.all;

ENTITY invaders_rom_0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock			: IN STD_LOGIC ;
		q					: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END invaders_rom_0;

architecture SYN of invaders_rom_0 is
begin
	sprom_inst : entity work.sprom
		generic map
		(
			init_file		=> ROM_0_NAME,
			--numwords_a	=> 8192,
			widthad_a		=> 13
		)
    port map
    (
      clock		=> clock,
      address => address,
      q				=> q
    );
end SYN;

library IEEE;
use ieee.std_logic_1164.all;
library work;
use work.pace_pkg.all;
use work.platform_variant_pkg.all;

ENTITY invaders_rom_1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		clock			: IN STD_LOGIC ;
		q					: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END invaders_rom_1;

architecture SYN of invaders_rom_1 is
begin
	sprom_inst : entity work.sprom
		generic map
		(
			init_file		=> ROM_1_NAME,
			--numwords_a	=> 4096,
			widthad_a		=> 12
		)
    port map
    (
        clock		=> clock,
        address => address,
        q				=> q
    );
end SYN;
		
library IEEE;
use ieee.std_logic_1164.all;
library work;
use work.pace_pkg.all;
use work.platform_variant_pkg.all;

ENTITY vram IS
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock_a		: IN STD_LOGIC ;
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '1';
		wren_b		: IN STD_LOGIC  := '1';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END vram;

architecture SYN of vram is
begin
	dpam_inst : entity work.dpram
		generic map
		(
			init_file => VRAM_NAME,
			--numwords_a => 8192,
			widthad_a => 13
		)
    port map
    (
        clock_b   	=> clock_b,
        address_b   => address_b,
        data_b      => data_b,
        q_b					=> q_b,
        wren_b			=> wren_b,

        clock_a     => clock_a,
        address_a   => address_a,
     		data_a      => data_a,
        q_a					=> q_a,
     		wren_a			=> wren_a
    );
end SYN;

library IEEE;
use ieee.std_logic_1164.all;
library work;
use work.pace_pkg.all;

ENTITY wram IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock			: IN STD_LOGIC ;
		data			: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren			: IN STD_LOGIC ;
		q					: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END wram;

architecture SYN of wram is
begin
	spram_inst : entity work.spram
		generic map
		(
			--numwords_a => 1024,
			widthad_a => 10
		)
		port map
		(
			clock				=> clock,
			address			=> address,
			data				=> data,
			wren				=> wren,
			q						=> q
		);
end SYN;		
