//---------------------------------------------------------------------------------
// Mario Bros Arcade
//
// Author: gaz68 (https://github.com/gaz68) June 2020
//
// Controls and DIP Switches.
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------
// CONTROLS
//
// BIT           0       1       2       3       4        5          6        7
//---------------------------------------------------------------------------------
// SW1(MAIN)   RIGHT    LEFT     -       -      JUMP   1P START   2P START   TEST
// SW2(SUB)    RIGHT2   LEFT2    -       -      JUMP2    COIN        -        -
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------
//  DIP SWITCHES
//
//  Toggle (DIP1) Settings:
//  A   B   C   D   E   F   G   H    Option
//---------------------------------------------------------------------------------
//                                   Number of Players per Game
//                                   --------------------------
// Off Off                           3
// On  Off                           4
// Off On                            5
// On  On                            6
// 
//                                   Coin/Credit
//                                   ----------
//         Off Off                   1/1
//         On  Off                   2/1
//         Off On                    1/2
//         On  On                    1/3
//
//                                   Extra Life
//                                   ----------
//                 Off Off           20,000 points
//                 On  Off           30,000 points
//                 Off On            40,000 points
//                 On  On            No extra life
//
//                                   Difficulty
//                                   ----------
//                         Off Off   (1) Easy
//                         On  Off   (3) Hard
//                         Off On    (2) Medium
//                         On  On    (4) Hardest
//
//---------------------------------------------------------------------------------
// NOTE: Mario Bros does not have a cocktail mode.

module mario_inport
(
   input  [7:0]I_SW1,
   input  [7:0]I_SW2,
   input  [7:0]I_DIPSW,
   input       I_SW1_OEn,
   input       I_SW2_OEn,
   input       I_DIPSW_OEn,

   output [7:0]O_D
);

wire   [7:0]W_SW1   = I_SW1_OEn   ?  8'h00: ~I_SW1;
wire   [7:0]W_SW2   = I_SW2_OEn   ?  8'h00: ~I_SW2;

wire   [7:0]W_DIPSW = I_DIPSW_OEn ?  8'h00: {I_DIPSW[6],I_DIPSW[7],I_DIPSW[5:0]};

assign O_D = W_SW1 | W_SW2 | W_DIPSW;

endmodule
