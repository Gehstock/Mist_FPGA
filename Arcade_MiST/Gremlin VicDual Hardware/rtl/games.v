
	/*============================================================================
	VIC arcade hardware by Gremlin Industries for MiSTer - Game metadata

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-02-20

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

// Game IDs
localparam GAME_ALPHAFIGHTER = 0;
localparam GAME_BORDERLINE = 1;
localparam GAME_CARHUNT_DUAL = 2;
localparam GAME_CARNIVAL = 3;
localparam GAME_DIGGER = 4;
localparam GAME_FROGS = 5;
localparam GAME_HEADON = 6;
localparam GAME_HEADON2 = 7;
localparam GAME_HEIANKYO = 8;
localparam GAME_INVINCO = 9;
localparam GAME_INVINCO_DEEPSCAN = 10;
localparam GAME_INVINCO_HEADON2 = 11;
localparam GAME_NSUB = 12;
localparam GAME_PULSAR = 13;
localparam GAME_SAFARI = 14;
localparam GAME_SAMURAI = 15;
localparam GAME_SPACEATTACK = 16;
localparam GAME_SPACEATTACK_HEADON = 17;
localparam GAME_SPACETREK = 18;
localparam GAME_STARRAKER = 19;
localparam GAME_SUBHUNT = 20;
localparam GAME_TRANQUILIZERGUN = 21;
localparam GAME_WANTED = 22;

localparam GAME_DEPTHCHARGE = 23;
localparam GAME_DEPTHCHARGEO = 24;

// Per game DIP setting constants for simulation
// - Alpha Fighter + Head On
localparam DIP_ALPHAFIGHTER_HEADON_LIVES_3 = 1'd0;
localparam DIP_ALPHAFIGHTER_HEADON_LIVES_4 = 1'd1;
localparam [1:0] DIP_ALPHAFIGHTER_LIVES_6 = 2'd0;
localparam [1:0] DIP_ALPHAFIGHTER_LIVES_5 = 2'd1;
localparam [1:0] DIP_ALPHAFIGHTER_LIVES_4 = 2'd2;
localparam [1:0] DIP_ALPHAFIGHTER_LIVES_3 = 2'd3;
localparam DIP_ALPHAFIGHTER_BONUSLIFE_1000 = 1'b0;
localparam DIP_ALPHAFIGHTER_BONUSLIFE_1500 = 1'b1;
localparam DIP_ALPHAFIGHTER_BONUSLIFEFORFINALUFO_ON = 1'b0;
localparam DIP_ALPHAFIGHTER_BONUSLIFEFORFINALUFO_OFF = 1'b1;
// - Borderline
localparam DIP_BORDERLINE_CABINET_OFF = 1'b0;
localparam DIP_BORDERLINE_CABINET_ON = 1'b1;
localparam DIP_BORDERLINE_BONUSLIFE_20000 = 1'b0;
localparam DIP_BORDERLINE_BONUSLIFE_15000 = 1'b1;
localparam [2:0] DIP_BORDERLINE_LIVES_3 = 3'b111;
localparam [2:0] DIP_BORDERLINE_LIVES_4 = 3'b101;
localparam [2:0] DIP_BORDERLINE_LIVES_5 = 3'b011;
localparam [2:0] DIP_BORDERLINE_LIVES_INFINITE = 3'b000;
// Car Hunt + Deep Scan (France) & Invinco + Car Hunt (Germany)
localparam [1:0] DIP_CARHUNT_DUAL_GAME1_LIVES_4 = 2'd3;
localparam [1:0] DIP_CARHUNT_DUAL_GAME1_LIVES_3 = 2'd2;
localparam [1:0] DIP_CARHUNT_DUAL_GAME1_LIVES_2 = 2'd1;
localparam [1:0] DIP_CARHUNT_DUAL_GAME1_LIVES_1 = 2'd0;
localparam [1:0] DIP_CARHUNT_DUAL_GAME2_LIVES_4 = 2'd0;
localparam [1:0] DIP_CARHUNT_DUAL_GAME2_LIVES_3 = 2'd3;
localparam [1:0] DIP_CARHUNT_DUAL_GAME2_LIVES_2 = 2'd2;
localparam [1:0] DIP_CARHUNT_DUAL_GAME2_LIVES_1 = 2'd1;
// - Carnival
localparam DIP_CARNIVAL_DEMOSOUNDS_ON = 1'b0;
localparam DIP_CARNIVAL_DEMOSOUNDS_OFF = 1'b1;
// - Digger
localparam [1:0] DIP_DIGGER_LIVES_6 = 2'd0;
localparam [1:0] DIP_DIGGER_LIVES_5 = 2'd1;
localparam [1:0] DIP_DIGGER_LIVES_4 = 2'd2;
localparam [1:0] DIP_DIGGER_LIVES_3 = 2'd3;
// - Frogs
localparam DIP_FROGS_DEMOSOUNDS_ON = 1'b0;
localparam DIP_FROGS_DEMOSOUNDS_OFF = 1'b1;
localparam DIP_FROGS_FREEGAME_NO = 1'b0;
localparam DIP_FROGS_FREEGAME_YES = 1'b1;
localparam DIP_FROGS_GAMETIME_60 = 1'b0;
localparam DIP_FROGS_GAMETIME_90 = 1'b1;
localparam DIP_FROGS_COINAGE_2C1C = 1'b0;
localparam DIP_FROGS_COINAGE_1C1C = 1'b1;
// - Head On
localparam [1:0] DIP_HEADON_LIVES_3 = 2'd0;
localparam [1:0] DIP_HEADON_LIVES_4 = 2'd1;
localparam [1:0] DIP_HEADON_LIVES_5 = 2'd2;
localparam [1:0] DIP_HEADON_LIVES_6 = 2'd3;
localparam DIP_HEADON_DEMOSOUNDS_ON = 1'b0;
localparam DIP_HEADON_DEMOSOUNDS_OFF = 1'b1;
// - Head On 2
localparam [1:0] DIP_HEADON2_LIVES_6 = 2'd0;
localparam [1:0] DIP_HEADON2_LIVES_5 = 2'd1;
localparam [1:0] DIP_HEADON2_LIVES_4 = 2'd3;
localparam DIP_HEADON2_DEMOSOUNDS_ON = 1'b0;
localparam DIP_HEADON2_DEMOSOUNDS_OFF = 1'b1;
// - Heiankyo Alien
localparam DIP_HEIANKYO_2PLAYERMODE_SIMULTANEOUS = 1'b0;
localparam DIP_HEIANKYO_2PLAYERMODE_ALTERNATING = 1'b1;
localparam DIP_HEIANKYO_LIVES_3 = 1'b0;
localparam DIP_HEIANKYO_LIVES_5 = 1'b1;
// - Invinco
localparam [1:0] DIP_INVINCO_LIVES_3 = 2'd0;
localparam [1:0] DIP_INVINCO_LIVES_4 = 2'd1;
localparam [1:0] DIP_INVINCO_LIVES_5 = 2'd2;
localparam [1:0] DIP_INVINCO_LIVES_6 = 2'd3;
// Invinco + Deep Scan
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME1_LIVES_4 = 2'd3;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME1_LIVES_3 = 2'd2;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME1_LIVES_2 = 2'd1;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME1_LIVES_1 = 2'd0;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME2_LIVES_4 = 2'd0;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME2_LIVES_3 = 2'd3;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME2_LIVES_2 = 2'd2;
localparam [1:0] DIP_INVINCO_DEEPSCAN_GAME2_LIVES_1 = 2'd1;
// Invinco + Head On 2
localparam [1:0] DIP_INVINCO_HEADON2_GAME1_LIVES_4 = 2'd0;
localparam [1:0] DIP_INVINCO_HEADON2_GAME1_LIVES_3 = 2'd1;
localparam [1:0] DIP_INVINCO_HEADON2_GAME1_LIVES_2 = 2'd3;
localparam [1:0] DIP_INVINCO_HEADON2_GAME2_LIVES_5 = 2'd0;
localparam [1:0] DIP_INVINCO_HEADON2_GAME2_LIVES_6 = 2'd3;
// - N-Sub

// - Pulsar
localparam [1:0] DIP_PULSAR_LIVES_2 = 2'b11;
localparam [1:0] DIP_PULSAR_LIVES_3 = 2'b01;
localparam [1:0] DIP_PULSAR_LIVES_4 = 2'b10;
localparam [1:0] DIP_PULSAR_LIVES_5 = 2'b00;
// - Safari

// - Samurai
localparam DIP_SAMURAI_LIVES_3 = 1'b1;
localparam DIP_SAMURAI_LIVES_4 = 1'b0;
localparam DIP_SAMURAI_INFINITELIVES_ON = 1'b0;
localparam DIP_SAMURAI_INFINITELIVES_OFF = 1'b1;
// - Space Attack
localparam DIP_SPACEATTACK_BONUSLIFEFORFINALUFO_ON = 1'b0;
localparam DIP_SPACEATTACK_BONUSLIFEFORFINALUFO_OFF = 1'b1;
localparam [2:0] DIP_SPACEATTACK_LIVES_3 = 3'b111;
localparam [2:0] DIP_SPACEATTACK_LIVES_4 = 3'b110;
localparam [2:0] DIP_SPACEATTACK_LIVES_5 = 3'b101;
localparam [2:0] DIP_SPACEATTACK_LIVES_6 = 3'b011;
localparam DIP_SPACEATTACK_BONUSLIFE_10000 = 1'b0;
localparam DIP_SPACEATTACK_BONUSLIFE_15000 = 1'b1;
localparam DIP_SPACEATTACK_CREDITSDISPLAY_OFF = 1'b1;
localparam DIP_SPACEATTACK_CREDITSDISPLAY_ON = 1'b0;
// - Space Attack + Head On
localparam DIP_SPACEATTACK_HEADON_BONUSLIFEFORFINALUFO_ON = 1'b0;
localparam DIP_SPACEATTACK_HEADON_BONUSLIFEFORFINALUFO_OFF = 1'b1;
localparam [1:0] DIP_SPACEATTACK_HEADON_GAME1_LIVES_3 = 2'd0;
localparam [1:0] DIP_SPACEATTACK_HEADON_GAME1_LIVES_4 = 2'd1;
localparam [1:0] DIP_SPACEATTACK_HEADON_GAME1_LIVES_5 = 2'd2;
localparam [1:0] DIP_SPACEATTACK_HEADON_GAME1_LIVES_6 = 2'd3;
localparam DIP_SPACEATTACK_HEADON_BONUSLIFE_10000 = 1'b0;
localparam DIP_SPACEATTACK_HEADON_BONUSLIFE_15000 = 1'b1;
localparam DIP_SPACEATTACK_HEADON_CREDITSDISPLAY_OFF = 1'b1;
localparam DIP_SPACEATTACK_HEADON_CREDITSDISPLAY_ON = 1'b0;
localparam DIP_SPACEATTACK_HEADON_GAME2_LIVES_3 = 1'd0;
localparam DIP_SPACEATTACK_HEADON_GAME2_LIVES_4 = 1'd1;
// - Space Trek
localparam DIP_SPACETREK_LIVES_3 = 1'b1;
localparam DIP_SPACETREK_LIVES_4 = 1'b0;
localparam DIP_SPACETREK_BONUSLIFE_ON = 1'b1;
localparam DIP_SPACETREK_BONUSLIFE_OFF = 1'b0;
// - Star Raker
localparam DIP_STARRAKER_CABINET_OFF = 1'b0;
localparam DIP_STARRAKER_CABINET_ON = 1'b1;
localparam DIP_STARRAKER_BONUSLIFE_20000 = 1'b0;
localparam DIP_STARRAKER_BONUSLIFE_15000 = 1'b1;
// - Sub Hunt

// - Tranquilizer Gun
// N/A
// - Wanted
localparam DIP_WANTED_CABINET_OFF = 1'b0;
localparam DIP_WANTED_CABINET_ON = 1'b1;
localparam DIP_WANTED_BONUSLIFE_30000 = 1'b0;
localparam DIP_WANTED_BONUSLIFE_20000 = 1'b1;
localparam [1:0] DIP_WANTED_LIVES_6 = 2'd0;
localparam [1:0] DIP_WANTED_LIVES_5 = 2'd1;
localparam [1:0] DIP_WANTED_LIVES_4 = 2'd2;
localparam [1:0] DIP_WANTED_LIVES_3 = 2'd3;
