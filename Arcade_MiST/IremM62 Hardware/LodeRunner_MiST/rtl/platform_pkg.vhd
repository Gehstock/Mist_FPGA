library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;

use work.platform_variant_pkg.all;
use work.video_controller_pkg.all;
package platform_pkg is

--	constant PACE_VIDEO_CONTROLLER_TYPE       : PACEVideoController_t := PACE_VIDEO_VGA_640x480_60Hz;
--	constant PACE_CLK0_DIVIDE_BY              : natural := 3;
--	constant PACE_CLK0_MULTIPLY_BY            : natural := 5;   -- 24*5/3 = 40MHz
--	constant PACE_CLK1_DIVIDE_BY              : natural := 19;
--	constant PACE_CLK1_MULTIPLY_BY            : natural := 20; 	-- 24*20/19 = 25.263158MHz
--	constant PACE_VIDEO_H_SCALE       	      : integer := 1;
--	constant PACE_VIDEO_V_SCALE       	      : integer := 1;
--	constant PACE_VIDEO_H_SYNC_POLARITY       : std_logic := '0';
--	constant PACE_VIDEO_V_SYNC_POLARITY       : std_logic := '0';

--  constant PACE_VIDEO_CONTROLLER_TYPE       : PACEVideoController_t := PACE_VIDEO_ARCADE_STD_336x240_60Hz;
--  constant PACE_CLK0_DIVIDE_BY              : natural := 19;
--  constant PACE_CLK0_MULTIPLY_BY            : natural := 20;  -- 27*20/19 = 24MHz
--  constant PACE_CLK1_DIVIDE_BY              : natural := 19;
--  constant PACE_CLK1_MULTIPLY_BY            : natural := 5;   -- 27*5/19 = 7.157895MHz
--  constant PACE_VIDEO_H_SCALE       	      : integer := 1;
--  constant PACE_VIDEO_V_SCALE       	      : integer := 1;
--  constant PACE_VIDEO_H_SYNC_POLARITY       : std_logic := '0';
--  constant PACE_VIDEO_V_SYNC_POLARITY       : std_logic := '0';

	constant PACE_VIDEO_CONTROLLER_TYPE       : PACEVideoController_t := PACE_VIDEO_PAL_576x288_50Hz;
	constant PACE_CLK0_DIVIDE_BY              : natural := 27;
	constant PACE_CLK0_MULTIPLY_BY            : natural := 44;   -- 27*44/27 = 44MHz
	constant PACE_CLK1_DIVIDE_BY              : natural := 27;
	constant PACE_CLK1_MULTIPLY_BY            : natural := 11;   -- 27*11/27 = 11MHz
	constant PACE_VIDEO_H_SCALE               : integer := 1;
	constant PACE_VIDEO_V_SCALE               : integer := 1;
	constant PACE_ENABLE_ADV724					      : std_logic := '1';
	constant USE_VIDEO_VBLANK_INTERRUPT 		  : boolean := false;
	constant PACE_VIDEO_H_SYNC_POLARITY       : std_logic := '1';
	constant PACE_VIDEO_V_SYNC_POLARITY       : std_logic := '1';

	constant PACE_VIDEO_BORDER_RGB            : RGB_t := RGB_BLACK;

	constant M62_VIDEO_H_SIZE				      : integer := 384;
	constant M62_VIDEO_H_OFFSET           : integer := (512-M62_VIDEO_H_SIZE)/2;
	constant M62_VIDEO_V_SIZE				      : integer := 256;

	constant PACE_VIDEO_NUM_BITMAPS		    : natural := 0;
	constant PACE_VIDEO_NUM_TILEMAPS	    : natural := 1;
	constant PACE_VIDEO_NUM_SPRITES 	    : natural := 32;
	constant PACE_VIDEO_H_SIZE				    : integer := M62_VIDEO_H_SIZE;
	constant PACE_VIDEO_V_SIZE				    : integer := M62_VIDEO_V_SIZE;
	constant PACE_VIDEO_L_CROP            : integer := 0;
	constant PACE_VIDEO_R_CROP            : integer := PACE_VIDEO_L_CROP;
	constant PACE_VIDEO_PIPELINE_DELAY    : integer := 5;

	constant PACE_INPUTS_NUM_BYTES        : integer := 6;

	constant CLK0_FREQ_MHz		            : natural := 
    27 * PACE_CLK0_MULTIPLY_BY / PACE_CLK0_DIVIDE_BY;
	constant CPU_FREQ_MHz                 : natural := 3;

	constant M62_CPU_CLK_ENA_DIVIDE_BY    : natural := CLK0_FREQ_MHz / CPU_FREQ_MHz;

  type from_PLATFORM_IO_t is record
    not_used  : std_logic;
  end record;

  type to_PLATFORM_IO_t is record
    not_used  : std_logic;
  end record;

end;
