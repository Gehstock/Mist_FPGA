/*
---------------------------------------------------------------------------------
To select a resolution and refresh rate, remove the comments around the desired
block in this file. The pixel clock output by the DCM module should approximately
equal the rate specified above the timing block that is uncommented.
---------------------------------------------------------------------------------
*/

// DEFINE THE VARIOUS PIPELINE DELAYS

`define CHARACTER_DECODE_DELAY  4


//  640 X 480 @ 60Hz with a 25.175MHz pixel clock
`define H_ACTIVE			640		// pixels
`define H_FRONT_PORCH		16		// pixels
`define H_SYNCH				96		// pixels
`define H_BACK_PORCH		48		// pixels
`define H_TOTAL				800		// pixels

`define V_ACTIVE			480		// lines
`define V_FRONT_PORCH		11		// lines
`define V_SYNCH				2		// lines
`define V_BACK_PORCH		31		// lines
`define V_TOTAL				524		// lines

`define CLK_MULTIPLY		2		// 50 * 2/4 = 25.000 MHz
`define CLK_DIVIDE			4


/*
//  640 X 480 @ 72Hz with a 31.500MHz pixel clock
`define H_ACTIVE			640	// pixels
`define H_FRONT_PORCH	24		// pixels
`define H_SYNCH			40		// pixels
`define H_BACK_PORCH		128	// pixels
`define H_TOTAL			832	// pixels

`define V_ACTIVE			480	// lines
`define V_FRONT_PORCH	9		// lines
`define V_SYNCH			3		// lines
`define V_BACK_PORCH		28		// lines
`define V_TOTAL			520	// lines

`define CLK_MULTIPLY		5		// 50 * 5/8 = 31.250 MHz
`define CLK_DIVIDE		8
*/

/*
//  640 X 480 @ 75Hz with a 31.500MHz pixel clock
`define H_ACTIVE			640	// pixels
`define H_FRONT_PORCH	16		// pixels
`define H_SYNCH			96		// pixels
`define H_BACK_PORCH		48		// pixels
`define H_TOTAL			800	// pixels

`define V_ACTIVE			480	// lines
`define V_FRONT_PORCH	11		// lines
`define V_SYNCH			2		// lines
`define V_BACK_PORCH		32		// lines
`define V_TOTAL			525	// lines

`define CLK_MULTIPLY		5		// 50 * 5/8 = 31.250 MHz
`define CLK_DIVIDE		8
*/

/*
// 640 X 480 @ 85Hz with a 36.000MHz pixel clock
`define H_ACTIVE			640	// pixels
`define H_FRONT_PORCH	32		// pixels
`define H_SYNCH			48		// pixels
`define H_BACK_PORCH		112	// pixels
`define H_TOTAL			832	// pixels

`define V_ACTIVE			480	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			3		// lines
`define V_BACK_PORCH		25		// lines
`define V_TOTAL			509	// lines

`define CLK_MULTIPLY		18		// 50 * 18/25 = 36.000 MHz
`define CLK_DIVIDE		25
*/

/*
// 800 X 600 @ 56Hz with a 38.100MHz pixel clock
`define H_ACTIVE			800	// pixels
`define H_FRONT_PORCH	32		// pixels
`define H_SYNCH			128	// pixels
`define H_BACK_PORCH		128	// pixels
`define H_TOTAL			1088	// pixels

`define V_ACTIVE			600	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			4		// lines
`define V_BACK_PORCH		14		// lines
`define V_TOTAL			619	// lines

`define CLK_MULTIPLY		16		// 50 * 16/21 = 38.095 MHz
`define CLK_DIVIDE		21
*/

/*
// 800 X 600 @ 60Hz with a 40.000MHz pixel clock
`define H_ACTIVE			800	// pixels
`define H_FRONT_PORCH	40		// pixels
`define H_SYNCH			128	// pixels
`define H_BACK_PORCH		88		// pixels
`define H_TOTAL			1056	// pixels

`define V_ACTIVE			600	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			4		// lines
`define V_BACK_PORCH		23		// lines
`define V_TOTAL			628	// lines

`define CLK_MULTIPLY		4		// 50 * 4/5 = 40.000 MHz
`define CLK_DIVIDE		5
*/

/*
// 800 X 600 @ 72Hz with a 50.000MHz pixel clock
`define H_ACTIVE			800	// pixels
`define H_FRONT_PORCH	56		// pixels
`define H_SYNCH			120	// pixels
`define H_BACK_PORCH		64		// pixels
`define H_TOTAL			1040	// pixels

`define V_ACTIVE			600	// lines
`define V_FRONT_PORCH	37		// lines
`define V_SYNCH			6		// lines
`define V_BACK_PORCH		23		// lines
`define V_TOTAL			666	// lines

`define CLK_MULTIPLY		2		// 50 * 2/2 = 50.000 MHz
`define CLK_DIVIDE		2
*/

/*
// 800 X 600 @ 75Hz with a 49.500MHz pixel clock
`define H_ACTIVE			800	// pixels
`define H_FRONT_PORCH	16		// pixels
`define H_SYNCH			80		// pixels
`define H_BACK_PORCH		160	// pixels
`define H_TOTAL			1056	// pixels

`define V_ACTIVE			600	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			2		// lines
`define V_BACK_PORCH		21		// lines
`define V_TOTAL			624	// lines

`define CLK_MULTIPLY		2		// 50 * 2/2 = 50.000 MHz
`define CLK_DIVIDE		2
*/

/*
// 800 X 600 @ 85Hz with a 56.250MHz pixel clock
`define H_ACTIVE			800	// pixels
`define H_FRONT_PORCH	32		// pixels
`define H_SYNCH			64		// pixels
`define H_BACK_PORCH		152	// pixels
`define H_TOTAL			1048	// pixels

`define V_ACTIVE			600	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			3		// lines
`define V_BACK_PORCH		27		// lines
`define V_TOTAL			631	// lines

`define CLK_MULTIPLY		9		// 50 * 9/8 = 56.250 MHz
`define CLK_DIVIDE		8
*/

/*
// 1024 X 768 @ 60Hz with a 65.000MHz pixel clock
`define H_ACTIVE			1024	// pixels
`define H_FRONT_PORCH	24		// pixels
`define H_SYNCH			136	// pixels
`define H_BACK_PORCH		160	// pixels
`define H_TOTAL			1344	// pixels

`define V_ACTIVE			768	// lines
`define V_FRONT_PORCH	3		// lines
`define V_SYNCH			6		// lines
`define V_BACK_PORCH		29		// lines
`define V_TOTAL			806	// lines

`define CLK_MULTIPLY		13		// 50 * 13/10 = 65.000 MHz
`define CLK_DIVIDE		10
/*

/*
// 1024 X 768 @ 70Hz with a 75.000MHz pixel clock
`define H_ACTIVE			1024	// pixels
`define H_FRONT_PORCH	24		// pixels
`define H_SYNCH			136	// pixels
`define H_BACK_PORCH		144	// pixels
`define H_TOTAL			1328	// pixels

`define V_ACTIVE			768	// lines
`define V_FRONT_PORCH	3		// lines
`define V_SYNCH			6		// lines
`define V_BACK_PORCH		29		// lines
`define V_TOTAL			806	// lines

`define CLK_MULTIPLY		3		// 50 * 3/2 = 75.000 MHz
`define CLK_DIVIDE		2
*/

/*
// 1024 X 768 @ 75Hz with a 78.750MHz pixel clock
`define H_ACTIVE			1024	// pixels
`define H_FRONT_PORCH	16		// pixels
`define H_SYNCH			96		// pixels
`define H_BACK_PORCH		176	// pixels
`define H_TOTAL			1312	// pixels

`define V_ACTIVE			768	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			3		// lines
`define V_BACK_PORCH		28		// lines
`define V_TOTAL			800	// lines

`define CLK_MULTIPLY		11		// 50 * 11/7 = 78.571 MHz
`define CLK_DIVIDE		7
*/

/*
// 1024 X 768 @ 85Hz with a 94.500MHz pixel clock
`define H_ACTIVE			1024	// pixels
`define H_FRONT_PORCH	48		// pixels
`define H_SYNCH			96		// pixels
`define H_BACK_PORCH		208	// pixels
`define H_TOTAL			1376	// pixels

`define V_ACTIVE			768	// lines
`define V_FRONT_PORCH	1		// lines
`define V_SYNCH			3		// lines
`define V_BACK_PORCH		36		// lines
`define V_TOTAL			808	// lines

`define CLK_MULTIPLY		17		// 50 * 17/9 = 94.444 MHz
`define CLK_DIVIDE		9
*/

