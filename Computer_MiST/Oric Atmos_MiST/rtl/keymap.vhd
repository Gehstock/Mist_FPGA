library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity keymap is
	port(
		A		: in std_logic_vector(7 downto 0);		
		clk_sys: in std_logic;
		ROW	: out std_logic_vector(2 downto 0);
		COL	: out std_logic_vector(2 downto 0);
		EN		: out std_logic
	);
end keymap;

architecture arch of keymap is
begin

ROM256X1_ROW2 : entity work.sprom
          generic map
          (
          init_file		=> "roms/key1.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> ROW(2)
          );

-- ROWS

--   ROM256X1_ROW2 : ROM256X1
 --  generic map (
--		INIT => X"00140800000000000000000000000000004000402E3400000000004E7C760000")
 --  port map (
 --     q => ROW(2),   -- ROM output
--      address => A
--   );

ROM256X1_ROW1 : entity work.sprom
          generic map
          (
          init_file		=> "roms/key2.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> ROW(1)
          );

--   ROM256X1_ROW1 : ROM256X1
--   generic map (
--		INIT => X"00340000000000000000000000000000000000002834763000146C7E68200000")
--   port map (
--      q => ROW(1),   -- ROM output
--      address => A
--   );

ROM256X1_ROW0 : entity work.sprom
          generic map
          (
          init_file		=> "roms/key3.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> ROW(0)
          );

--   ROM256X1_ROW0 : ROM256X1
--   generic map (
--		INIT => X"003008000000000000000000000000000040004004346C4A004A1C7A34400000")
--   port map (
--      q => ROW(0),   -- ROM output
--      address => A  -- ROM address
--   );

-- COLUMNS

ROM256X1_COL2 : entity work.sprom
          generic map
          (
          init_file		=> "roms/key4.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> COL(2)
          );

--   ROM256X1_COL2 : ROM256X1
--   generic map (
--		INIT => X"00340800000000000000000000000000000000400E302E3A5038021038060000")
--   port map (
--      q => COL(2),   -- ROM output
--      address => A  -- ROM address[7]
--   );

ROM256X1_COL1 : entity work.sprom
          generic map
          (
          init_file		=> "roms/key5.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> COL(1)
          );

--   ROM256X1_COL1 : ROM256X1
--   generic map (
--		INIT => X"000000000000000000000000000000000000000026245C64447C00327C100000")
--   port map (
--      q => COL(1),   -- ROM output
--      address => A  -- ROM address[7]
--   );

ROM256X1_COL0 : entity work.sprom
          generic map
          (
          init_file		=> "roms/key6.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> COL(0)
          );

--   ROM256X1_COL0 : ROM256X1
 --  generic map (
--		INIT => X"00000000000000000000000000000000004000402E347C7C5800380800220000")
--   port map (
--      q => COL(0),   -- ROM output
--      address => A  -- ROM address[7]
 --  );

-- ENABLE

ROM256X1_EN : entity work.sprom
          generic map
          (
          init_file		=> "roms/key7.hex",
            widthad_a		=> 8,
				width_a		=> 1
          )
          port map
          (
            clock		=> clk_sys,
            address => A,
            q(0)				=> EN
          );
			 
--   ROM256X1_EN : ROM256X1
--   generic map (
--		INIT => X"00340800000000000000000000000000004000402E347E7E7C7E7E7E7C760000")
--   port map (
--      q => EN,   -- ROM output
--      address => A  -- ROM address[7]
--   );

end arch;

