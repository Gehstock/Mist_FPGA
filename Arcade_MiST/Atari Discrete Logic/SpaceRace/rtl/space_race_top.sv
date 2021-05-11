/*
 * Space Race top module
 */
module space_race_top(
	input   					CLK_DRV, CLK_SRC, CLK_AUDIO,
	input   					RESET,
	input   					COINAGE,  // 0: 1CREDIT/1COIN, 1: 2CREDITS/1COIN
	input   			[3:0] PLAYTIME, // 0: 0%,  1: 10%, 2: 20%, 3: 30%, 4: 40%, 5: 50%,
                                 // 6: 60%, 7: 70%, 8: 80%, 9: 90%, 10: 100%
	input   					COIN_SW,
	input   					START_GAME,
	input   					UP1_N, DOWN1_N,
	input   					UP2_N, DOWN2_N,
	output  					CLK_VIDEO,
	output  					VIDEO,
	output  					SCORE,
	output  					HSYNC, VSYNC,
	output  					HBLANK, VBLANK,
	output  		  [15:0] SOUND,
	output  			      CREDIT_LIGHT_N
);
  // Clocks
  logic CLOCK, CLOCK_N;

  // Reset video counters and counters for stars
  // Note: It is diffrent from RESET signal on input port.
  logic RESET_N;

  // Video sync
  logic _1H, _2H, _4H, _8H, _16H, _32H, _64H, _128H, _256H, _256H_N;
  logic _1V, _2V, _4V, _8V, _16V, _32V, _64V, _128V, _256V, _256V_N;
  logic HRESET, HRESET_N, VRESET, VRESET_N;
  logic HBLANK_N, VBLANK_N;
  logic HSYNC_N, VSYNC_N;

  logic [8:0] VCNT;
  assign VCNT = {_256V, _128V, _64V, _32V, _16V, _8V, _4V, _2V, _1V};

  // Video
  logic STARS_N, ROCKETS_N, FUEL_N;

  // Video misc
  logic STAR_BLANK, V_WINDOW, R_RESET, R_BBOUND;

  // Game control
  logic GAME_ON;

  // Crash
  logic CRASH_1_N, CRASH_2_N, CRASH_N;

  // Score
  logic SCORE_1, SCORE_2;
  logic RESET_SCORE_N;
  logic SCORE_N;

  // For rocket sound
  logic ROCKET_1, ROCKET_2;
  logic SR1, SR2;

  // Submodules
  clock     clock(.*);
  hcounter  hcounter(.*);
  vcounter  vcounter(.*);
  videosync videosync(.*);
  videomisc videomisc(.*);
  stars     stars(.*);
  rockets   rockets(.*);
  score     score(.*);
  crash     crash(.*);
  gamecntl  gamecntl(.*);
  sound     sound(.*);

  assign CLK_VIDEO = CLOCK;

endmodule
