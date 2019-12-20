// Copyright (c) 2019 MiSTer-X

`ifndef __HID_DEFINITION
`define __HID_DEFINITION
/*
  wire [5:0] INP0 = { m_trig12, m_trig11, {m_left1, m_down1, m_right1, m_up1} };
  wire [5:0] INP1 = { m_trig22, m_trig22, {m_left2, m_down2, m_right2, m_up2} };
  wire [2:0] INP2 = { (m_coin1|m_coin2), m_start2, m_start1 };
*/
`define	none	1'b0

`define	COIN	INP2[2]
`define	P1ST	INP2[0]
`define	P2ST	INP2[1]

`define	P1UP	INP0[0]
`define	P1DW	INP0[2]
`define	P1LF	INP0[3]
`define	P1RG	INP0[1]
`define	P1TA	INP0[4]
`define	P1TB	INP0[5]

`define	P2UP	INP1[0]
`define	P2DW	INP1[2]
`define	P2LF	INP1[3]
`define	P2RG	INP1[1]
`define	P2TA	INP1[4]
`define	P2TB	INP1[5]

`endif

