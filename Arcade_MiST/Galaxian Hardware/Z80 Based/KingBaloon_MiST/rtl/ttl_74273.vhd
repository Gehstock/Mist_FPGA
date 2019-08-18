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
-- CREATED		"Sun Aug 18 11:45:39 2019"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY ttl_74273 IS 
	PORT
	(
		CLRN :  IN  STD_LOGIC;
		CLK :  IN  STD_LOGIC;
		D8 :  IN  STD_LOGIC;
		D7 :  IN  STD_LOGIC;
		D6 :  IN  STD_LOGIC;
		D5 :  IN  STD_LOGIC;
		D4 :  IN  STD_LOGIC;
		D3 :  IN  STD_LOGIC;
		D2 :  IN  STD_LOGIC;
		D1 :  IN  STD_LOGIC;
		Q1 :  OUT  STD_LOGIC;
		Q2 :  OUT  STD_LOGIC;
		Q3 :  OUT  STD_LOGIC;
		Q4 :  OUT  STD_LOGIC;
		Q5 :  OUT  STD_LOGIC;
		Q6 :  OUT  STD_LOGIC;
		Q7 :  OUT  STD_LOGIC;
		Q8 :  OUT  STD_LOGIC
	);
END ttl_74273;

ARCHITECTURE bdf_type OF ttl_74273 IS 



BEGIN 



PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q8 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q8 <= D8;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q7 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q7 <= D7;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q6 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q6 <= D6;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q5 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q5 <= D5;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q4 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q4 <= D4;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q3 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q3 <= D3;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q2 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q2 <= D2;
END IF;
END PROCESS;


PROCESS(CLK,CLRN)
BEGIN
IF (CLRN = '0') THEN
	Q1 <= '0';
ELSIF (RISING_EDGE(CLK)) THEN
	Q1 <= D1;
END IF;
END PROCESS;


END bdf_type;