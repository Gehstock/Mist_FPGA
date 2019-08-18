-- Copyright (C) 1991-2014 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II 64-Bit"
-- VERSION		"Version 13.1.4 Build 182 03/12/2014 SJ Web Edition"
-- CREATED		"Fri Aug 16 22:43:02 2019"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY ttl_74367 IS 
	PORT
	(
		p2GN :  IN  STD_LOGIC;
		p2A1 :  IN  STD_LOGIC;
		p2A2 :  IN  STD_LOGIC;
		p1A4 :  IN  STD_LOGIC;
		p1A3 :  IN  STD_LOGIC;
		p1A2 :  IN  STD_LOGIC;
		p1A1 :  IN  STD_LOGIC;
		p1GN :  IN  STD_LOGIC;
		p2Y1 :  OUT  STD_LOGIC;
		p2Y2 :  OUT  STD_LOGIC;
		p1Y4 :  OUT  STD_LOGIC;
		p1Y3 :  OUT  STD_LOGIC;
		p1Y2 :  OUT  STD_LOGIC;
		p1Y1 :  OUT  STD_LOGIC
	);
END ttl_74367;

ARCHITECTURE bdf_type OF ttl_74367 IS 

SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC;


BEGIN 



PROCESS(p1A4,SYNTHESIZED_WIRE_6)
BEGIN
if (SYNTHESIZED_WIRE_6 = '1') THEN
	p1Y4 <= p1A4;
ELSE
	p1Y4 <= 'Z';
END IF;
END PROCESS;


PROCESS(p2A2,SYNTHESIZED_WIRE_7)
BEGIN
if (SYNTHESIZED_WIRE_7 = '1') THEN
	p2Y2 <= p2A2;
ELSE
	p2Y2 <= 'Z';
END IF;
END PROCESS;


SYNTHESIZED_WIRE_6 <= NOT(p1GN);



PROCESS(p2A1,SYNTHESIZED_WIRE_7)
BEGIN
if (SYNTHESIZED_WIRE_7 = '1') THEN
	p2Y1 <= p2A1;
ELSE
	p2Y1 <= 'Z';
END IF;
END PROCESS;


SYNTHESIZED_WIRE_7 <= NOT(p2GN);



PROCESS(p1A1,SYNTHESIZED_WIRE_6)
BEGIN
if (SYNTHESIZED_WIRE_6 = '1') THEN
	p1Y1 <= p1A1;
ELSE
	p1Y1 <= 'Z';
END IF;
END PROCESS;


PROCESS(p1A2,SYNTHESIZED_WIRE_6)
BEGIN
if (SYNTHESIZED_WIRE_6 = '1') THEN
	p1Y2 <= p1A2;
ELSE
	p1Y2 <= 'Z';
END IF;
END PROCESS;


PROCESS(p1A3,SYNTHESIZED_WIRE_6)
BEGIN
if (SYNTHESIZED_WIRE_6 = '1') THEN
	p1Y3 <= p1A3;
ELSE
	p1Y3 <= 'Z';
END IF;
END PROCESS;


END bdf_type;