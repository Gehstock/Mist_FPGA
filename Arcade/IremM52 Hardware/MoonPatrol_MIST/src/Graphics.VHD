library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.pace_pkg.all;
use work.video_controller_pkg.all;
use work.sprite_pkg.all;

entity Graphics is
  port
  (
    bitmap_ctl_i    	: in to_BITMAP_CTL_a(1 to 3);
    bitmap_ctl_o    	: out from_BITMAP_CTL_a(1 to 3);
    tilemap_ctl_i   	: in to_TILEMAP_CTL_a(1 to 1);
    tilemap_ctl_o   	: out from_TILEMAP_CTL_a(1 to 1);
    sprite_reg_i    	: in to_SPRITE_REG_t;
    sprite_ctl_i    	: in to_SPRITE_CTL_t;
	 sprite_ctl_o    	: out from_SPRITE_CTL_t;
	 spr0_hit			: out std_logic;   
    graphics_i      	: in to_GRAPHICS_t;
    graphics_o      	: out from_GRAPHICS_t;
	 video_i				: in from_VIDEO_t;
	 video_o				: out to_VIDEO_t
  );

end Graphics;

architecture SYN of Graphics is

	alias clk 					: std_logic is video_i.clk;
	signal from_video_ctl   : from_VIDEO_CTL_t;
	signal bitmap_ctl_o_s   : from_BITMAP_CTL_a(1 to 3);
	signal tilemap_ctl_o_s  : from_TILEMAP_CTL_a(1 to 1);
	signal sprite_ctl_o_s   : from_SPRITE_CTL_t;
	signal sprite_pri       : std_logic;
	signal rgb_data			: RGB_t;
	signal video_o_s        : to_VIDEO_t;
  
begin

	video_o.clk 		<= video_o_s.clk;
   video_o.rgb.r 		<= video_o_s.rgb.r;
   video_o.rgb.g 		<= video_o_s.rgb.g;
   video_o.rgb.b 		<= video_o_s.rgb.b;
	video_o.hsync 		<= video_o_s.hsync;
	video_o.vsync 		<= video_o_s.vsync;
	video_o.hblank 	<= video_o_s.hblank;
	video_o.vblank 	<= video_o_s.vblank;
	graphics_o.y 		<= from_video_ctl.y;
	graphics_o.hblank <= video_o_s.hblank;
	graphics_o.vblank <= video_o_s.vblank;
    
  pace_video_controller_inst : entity work.pace_video_controller
    generic map
    (
      CONFIG		=> PACE_VIDEO_VGA_800x600_60Hz,
      DELAY       => 7,
      H_SIZE      => 256,
      V_SIZE      => 256,
      L_CROP      => 0,--8
      R_CROP      => 0,--8
      H_SCALE     => 2,--2
      V_SCALE     => 2,--2
      H_SYNC_POL  => '1',--1
      V_SYNC_POL  => '1',--1
      BORDER_RGB  => RGB_BLACK
    )
    port map
    (
      video_i         	=> video_i,
		reg_i.h_scale		=> "000",
		reg_i.v_scale 		=> "000",
      rgb_i		    		=> rgb_data,
      video_ctl_o     	=> from_video_ctl,
      video_o     		=> video_o_s
    );


  pace_video_mixer_inst : entity work.pace_video_mixer
    port map
    (
        bitmap_ctl_o  => bitmap_ctl_o_s,
        tilemap_ctl_o => tilemap_ctl_o_s,
        sprite_rgb    => sprite_ctl_o_s.rgb,
        sprite_set    => sprite_ctl_o_s.set,
        sprite_pri    => sprite_pri,
        
        video_ctl_i   => from_video_ctl,
        graphics_i    => graphics_i,
        rgb_o         => rgb_data
    );

	
	  forground_bitmapctl_inst1 : entity work.BITMAP_1
      generic map
      (
        DELAY         => 7
      )
	    port map
	    (
			reset			=> video_i.reset,			
			video_ctl   => from_video_ctl,
	      ctl_i       => bitmap_ctl_i(1),
	      ctl_o       => bitmap_ctl_o_s(1),
         graphics_i  => graphics_i
	    );

	  forground_bitmapctl_inst2 : entity work.BITMAP_2
      generic map
      (
        DELAY         => 7
      )
	    port map
	    (
			reset			=> video_i.reset,				
			video_ctl   => from_video_ctl,
	      ctl_i       => bitmap_ctl_i(2),
	      ctl_o       => bitmap_ctl_o_s(2),
         graphics_i  => graphics_i
	    );


	  forground_bitmapctl_inst3 : entity work.BITMAP_3
      generic map
      (
        DELAY         => 7
      )
	    port map
	    (
			reset			=> video_i.reset,				
			video_ctl   => from_video_ctl,
	      ctl_i       => bitmap_ctl_i(3),
	      ctl_o       => bitmap_ctl_o_s(3),
         graphics_i  => graphics_i
	    );
      
  
  bitmap_ctl_o <= bitmap_ctl_o_s;

	
	  foreground_mapctl_inst : entity work.TILEMAP_1
      generic map
      (
        DELAY         => 7
      )
	    port map
	    (
			reset			=> video_i.reset,				
			video_ctl   => from_video_ctl,
			ctl_i       => tilemap_ctl_i(1),
			ctl_o       => tilemap_ctl_o_s(1),
         graphics_i  => graphics_i
	    );
    
  tilemap_ctl_o <= tilemap_ctl_o_s;

		sprites_inst : sprite_array
		      generic map
      (
		  N_SPRITES     => 64,
        DELAY         => 7
      )
			port map
			(
				reset				 => video_i.reset,  
				reg_i         	=> sprite_reg_i,
				video_ctl     	=> from_video_ctl,
				graphics_i    	=> graphics_i,
				row_a         	=> sprite_ctl_o_s.a,
				row_d         	=> sprite_ctl_i.d,				
				rgb				=> sprite_ctl_o_s.rgb,
				set           	=> sprite_ctl_o_s.set,
				pri           	=> sprite_pri,
				spr0_set	    	=> spr0_hit
			);


  sprite_ctl_o <= sprite_ctl_o_s;


end SYN;
