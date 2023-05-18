  
//-- pattern access
//                    -- read Pattern Name Table
parameter AC_PNT =0;
//                   -- read Pattern Generator Table
parameter AC_PGT =1;
                    //-- read Pattern Color Table
parameter AC_PCT=2;
                    //-- sprite access
                    //-- sprite test read (y coordinate)
parameter AC_STST=3;
                    //-- read Sprite Attribute Table/Y
parameter AC_SATY=4;
                    //-- read Sprite Attribute Table/X
parameter AC_SATX=5;
                    //-- read Sprite Attribute Table/N
parameter AC_SATN=6;
                    //-- read Sprite Attribute Table/C
parameter AC_SATC=7;
                    //-- read Sprite Pattern Table/high quadrant
parameter AC_SPTH=8;
                    //-- read Sprite Pattern Table/low quadrant
parameter AC_SPTL=9;
                    //--
                    //-- CPU access
parameter AC_CPU=10;
                    //--
                    //-- no access at all
parameter AC_NONE=11;
parameter OPMODE_GRAPH1  = 0;
parameter OPMODE_GRAPH2= 1;
parameter OPMODE_MULTIC= 2;
parameter OPMODE_TEXTM= 3;

parameter hv_first_line_ntsc_c = -40; 
parameter hv_last_line_ntsc_c  = 221; 
parameter hv_first_line_pal_c  = -65;
parameter hv_last_line_pal_c   = 247;
parameter hv_first_pix_text_c  = -102;
parameter hv_last_pix_text_c   = 239;
parameter hv_first_pix_graph_c = -86;
parameter hv_last_pix_graph_c  = 255;
parameter hv_vertical_inc_c    = -32;
parameter hv_sprite_start_c    = 247;


