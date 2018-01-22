`ifndef RIVERRAID_DEFS
`define RIVERRAID_DEFS 

// Количество объектов в массиве берегов, островов и врагов
// Выставлять соответственно кол-ву элементов в RIVER_FLOW, ISLAND_FLOW и ENTITY_FLOW
`define RIVER_FLOW_SIZE			66
`define ISLAND_FLOW_SIZE		24
`define ENTITY_FLOW_SIZE		47

//		Format				PixelClock	ActiveVideo		FrontPorch	SyncPulse	BackPorch	ActiveVideo	FrontPorch	SyncPulse	BackPorch
//		1024x768,60Hz		65.000		1024				24				136			160			768			3				6				29
// Параметры для VGA генератора
//`define H_DISP					1024
//`define H_FPORCH				24
//`define H_SYNC					136
//`define H_BPORCH				160
//`define V_DISP					768
//`define V_FPORCH				3
//`define V_SYNC					6
//`define V_BPORCH				29
//`define SCREEN_WIDTH			11'd1024
//`define SCREEN_HEIGHT			11'd768

//1280x1024
`define H_DISP					1280
`define H_FPORCH				48
`define H_SYNC					112
`define H_BPORCH				248
`define V_DISP					1024
`define V_FPORCH				1
`define V_SYNC					3
`define V_BPORCH				38
`define SCREEN_WIDTH			11'd1280
`define SCREEN_HEIGHT		11'd1024	

`define SCREEN_MAX_X			(`SCREEN_WIDTH - 1)
`define SCREEN_MAX_Y			(`SCREEN_HEIGHT - 1)
`define SCREEN_CENTER_X			(`SCREEN_WIDTH/2 - 1)

// Скорость скролинга. За 1 прорисовку экрана будет скролинг на
// (FRAME_EVERY_SCROLLS / SCROLL_EVERY_FRAMES) пикселей
`define FRAME_EVERY_SCROLLS			4
`define SCROLL_EVERY_FRAMES			1
// Скорость скролинга когда игрок замедляет полет
`define SLOW_SCROLL_SPEED			(`FRAME_EVERY_SCROLLS/2)
// Скорость скролинга в начале раунда
`define START_SCROLL_SPEED			8

// Максимальное одновременное количество врагов и домов на экране
`define ENTITIES_ON_FRAME			10
// Ширина и высота спрайта "корабль"
`define SPRITE_SHIP_WIDTH			128
`define SPRITE_SHIP_HEIGHT			28
// Ширина и высота спрайта "самолет"
`define SPRITE_PLANE_WIDTH			128
`define SPRITE_PLANE_HEIGHT			31
// Ширина и высота спрайта "вертолет"
`define SPRITE_HELICOPTER_WIDTH		64
`define SPRITE_HELICOPTER_HEIGHT	26
// Ширина и высота спрайта "строение"
`define SPRITE_BUILDING_WIDTH		64
`define SPRITE_BUILDING_HEIGHT		107

`define SPRITE_FUEL_WIDTH			64
`define SPRITE_FUEL_HEIGHT			122

`define BRIDGE_HEIGHT				80

// Ширина и высота выпущенной ракеты
`define SPRITE_MISSILE_WIDTH		5
`define SPRITE_MISSILE_HEIGHT		22
`define MISSILE_SPEED				20
`define MISSILE_Y_START				(`PLAYER_Y - `SPRITE_MISSILE_HEIGHT)
// На какое расстояние должна отлететь ракета чтобы можно было выпустить новую
`define REMISSILE_DISTANCE			300
`define REMISSILE_Y_POS				(`PLAYER_Y - `SPRITE_MISSILE_HEIGHT - `REMISSILE_DISTANCE)

// Ширина берега в пикселях
`define SAND_WIDTH				11'd7
`define TRANSPARENT_COLOR		3'b000
`define LAND_START_POS			11'd200
`define LAND_COLOR				3'b010
`define SAND_COLOR				3'b110
`define RIVER_COLOR				3'b001

`define PLAYER_WIDTH			64
`define PLAYER_HEIGHT			86
`define PLAYER_START_X			640
`define PLAYER_Y				895
`define PLAYER_SPEED			7

// Ширина датчика топлива
`define FUEL_WIDTH				250
`define FUEL_HEIGHT				24
`define FUEL_Y					1000
`define FUEL_EMPTY_X			(`SCREEN_WIDTH - `FUEL_WIDTH)/ 2
// Скорость траты топлива
`define FUEL_DOWN_SPEED			3
`define FUEL_UP_SPEED			9
// 1 пиксель индикатора топлива = 16 единицам топлива
`define FUEL_FULL				(`FUEL_WIDTH * 16)



typedef enum {
	NONE,
	SHIP,
	PLANE,
	HELICOPTER,
	BRIDGE,
	FUEL,
	BUILDING
} entity_type_t;


`define RIVER_FLOW '{\
	'{'d0,			'd0		},\
	'{'d600,		'd1		},\
	'{'d620,		'd4		},\
	'{'d650,		'd0		},\
	'{'d900,		'd1		},\
	'{'d910,		'd2		},\
	'{'d955,		'd0		},\
	'{'d1060,		-'d1	},\
	'{'d1120,		-'d2	},\
	'{'d1150,		-'d4	},\
	'{'d1170,		-'d3	},\
	'{'d1210,		'd0		},\
	'{'d1820,		'd2		},\
	'{'d1840,		'd0		},\
	'{'d1910,		'd1		},\
	'{'d1930,		'd0		},\
	'{'d2070,		'd1		},\
	'{'d2090,		'd5		},\
	'{'d2130,		'd2		},\
	'{'d2160,		'd0		},\
	'{'d2260,		-'d2	},\
	'{'d2310,		-'d1	},\
	'{'d2370,		'd0		},\
	'{'d2880,		'd1		},\
	'{'d2900,		'd2		},\
	'{'d2940,		'd1		},\
	'{'d2960,		'd2		},\
	'{'d2976,		'd0		},\
	'{'d3280,		-'d1	},\
	'{'d3290,		-'d14	},\
	'{'d3294,		'd0		},\
	'{'d3640,		'd12	},\
	'{'d3648,		'd0		},\
	'{'d4500,		-'d3	},\
	'{'d4580,		'd0		},\
	'{'d5300,		'd1		},\
	'{'d5320,		'd3		},\
	'{'d5340,		'd1		},\
	'{'d5370,		'd0		},\
	'{'d5700,		'd2		},\
	'{'d5720,		'd0		},\
	'{'d5820,		'd2		},\
	'{'d5840,		'd0		},\
	'{'d5900,		'd2		},\
	'{'d5920,		'd0		},\
	'{'d6500,		'd2		},\
	'{'d6546,		'd0		},\
	'{'d7100,		-'d4	},\
	'{'d7240,		'd0		},\
	'{'d9000,		'd4		},\
	'{'d9138,		'd0		},\
	'{'d10000,		-'d1	},\
	'{'d10030,		-'d6	},\
	'{'d10060,		'd0		},\
	'{'d10300,		-'d1	},\
	'{'d10310,		-'d2	},\
	'{'d10320,		'd0		},\
	'{'d11000,		'd1		},\
	'{'d11010,		'd2		},\
	'{'d11020,		'd3		},\
	'{'d11040,		'd0		},\
	'{'d11050,		-'d3	},\
	'{'d11060,		-'d2	},\
	'{'d11070,		-'d1	},\
	'{'d11080,		'd0		},\
	'{24'hffffff,	'd0		}\
}

`define ISLAND_FLOW '{\
	'{'d0,			'd0		},\
	'{'d1420,		'd4		},\
	'{'d1470,		'd2		},\
	'{'d1510,		'd1		},\
	'{'d1546,		'd0		},\
	'{'d1750,		-'d1	},\
	'{'d1770,		-'d2	},\
	'{'d1820,		-'d4	},\
	'{'d1860,		'd0		},\
	'{'d1866,		-'d4	},\
	'{'d1875,		'd0		},\
	'{'d2500,		'd3		},\
	'{'d2520,		'd0		},\
	'{'d2600,		-'d3	},\
	'{'d2620,		'd0		},\
	'{'d5400,		'd8		},\
	'{'d5420,		'd0		},\
	'{'d5500,		-'d2	},\
	'{'d5520,		'd0		},\
	'{'d5600,		-'d2	},\
	'{'d5620,		'd0		},\
	'{'d5700,		-'d4	},\
	'{'d5720,		'd0		},\
	'{'d9000000,	'd0		}\
}

`define ENTITY_FLOW '{\
	'{'d530,		SHIP,		'd460,	'd2		},\
	'{'d630,		SHIP,		'd880,	'd0		},\
	'{'d750,		BUILDING,	'd220,	'd0		},\
	'{'d840,		HELICOPTER,	'd790,	-'d2	},\
	'{'d1100,		SHIP,		'd630,	'd9		},\
	'{'d1450,		SHIP,		'd810,	'd1		},\
	'{'d1525,		BUILDING,	'd610,	'd0		},\
	'{'d1755,		PLANE,		'd50,	'd16	},\
	'{'d2050,		SHIP,		'd700,	'd3		},\
	'{'d2250,		BRIDGE,		'd0,	'd0		},\
	'{'d2590,		FUEL,		'd430,	'd0		},\
	'{'d3030,		SHIP,		'd610,	'd8		},\
	'{'d3240,		BUILDING,	'd1020,	'd0		},\
	'{'d3250,		SHIP,		'd700,	'd4		},\
	'{'d3450,		SHIP,		'd900,	-'d6	},\
	'{'d3580,		SHIP,		'd300,	-'d5	},\
	'{'d3600,		PLANE,		'd50,	-'d10	},\
	'{'d3710,		SHIP,		'd660,	'd6		},\
	'{'d3930,		FUEL,		'd600,	'd0		},\
	'{'d4450,		BRIDGE,		'd0,	'd0		},\
	'{'d4455,		BUILDING,	'd400,	'd0		},\
	'{'d4470,		PLANE,		'd615,	'd20	},\
	'{'d4630,		SHIP,		'd620,	'd16	},\
	'{'d4730,		HELICOPTER,	'd620,	'd18	},\
	'{'d4860,		SHIP,		'd620,	'd22	},\
	'{'d5050,		HELICOPTER,	'd620,	'd26	},\
	'{'d5580,		FUEL,		'd820,	'd0		},\
	'{'d5581,		FUEL,		'd400,	'd0		},\
	'{'d5815,		BRIDGE,		'd0,	'd0		},\
	'{'d6010,		PLANE,		'd510,	-'d20	},\
	'{'d6060,		SHIP,		'd580,	'd0		},\
	'{'d6870,		PLANE,		'd410,	-'d16	},\
	'{'d7010,		BUILDING,	'd720,	'd0		},\
	'{'d7030,		BUILDING,	'd780,	'd0		},\
	'{'d7300,		PLANE,		'd0,	'd10	},\
	'{'d7350,		PLANE,		'd0,	-'d10	},\
	'{'d7420,		SHIP,		'd60,	'd9		},\
	'{'d7600,		SHIP,		'd600,	'd0		},\
	'{'d7800,		SHIP,		'd950,	'd0		},\
	'{'d8090,		SHIP,		'd350,	'd0		},\
	'{'d8270,		HELICOPTER,	'd200,	-'d12	},\
	'{'d8460,		HELICOPTER,	'd900,	'd12	},\
	'{'d8650,		FUEL,		'd100,	'd0		},\
	'{'d9400,		FUEL,		'd610,	'd0		},\
	'{'d9500,		HELICOPTER,	'd580,	'd0		},\
	'{'d9560,		HELICOPTER,	'd630,	'd0		},\
	'{'d10500,		SHIP,		'd420,	-'d32	}\
}


`define MISSILE_SPRITE '{\
	20'h00700,\
	20'h07770,\
	20'h87770,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h07770,\
	20'h07770,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h77777,\
	20'h74447,\
	20'h74447,\
	20'h04440,\
	20'h04440\
}

`endif