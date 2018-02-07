LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.all;

ENTITY dpram_1r1w IS
	GENERIC
	(
		numwords_a		: natural;
		widthad_a			: natural;
		width_a				: natural := 8;
    outdata_reg_b : string := "UNREGISTERED"
	);
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		rdclocken		: IN STD_LOGIC  := '1';
		wraddress		: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		wrclock		: IN STD_LOGIC ;
		wrclocken		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
END dpram_1r1w;


ARCHITECTURE SYN OF dpram_1r1w IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);

	COMPONENT altsyncram
	GENERIC (
		address_reg_b		: STRING;
		clock_enable_input_a		: STRING;
		clock_enable_input_b		: STRING;
		clock_enable_output_b		: STRING;
		intended_device_family		: STRING;
		lpm_type		: STRING;
		numwords_a		: NATURAL;
		numwords_b		: NATURAL;
		operation_mode		: STRING;
		outdata_aclr_b		: STRING;
		outdata_reg_b		: STRING;
		power_up_uninitialized		: STRING;
		widthad_a		: NATURAL;
		widthad_b		: NATURAL;
		width_a		: NATURAL;
		width_b		: NATURAL;
		width_byteena_a		: NATURAL
	);
	PORT (
			clocken0	: IN STD_LOGIC ;
			clocken1	: IN STD_LOGIC ;
			wren_a	: IN STD_LOGIC ;
			clock0	: IN STD_LOGIC ;
			clock1	: IN STD_LOGIC ;
			address_a	: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
			address_b	: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
			q_b	: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
			data_a	: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	q    <= sub_wire0(width_a-1 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_reg_b => "CLOCK1",
		clock_enable_input_a => "BYPASS",
		clock_enable_input_b => "BYPASS",
		clock_enable_output_b => "BYPASS",
		intended_device_family => "Cyclone II",
		lpm_type => "altsyncram",
		numwords_a => numwords_a,
		numwords_b => numwords_a,
		operation_mode => "DUAL_PORT",
		outdata_aclr_b => "NONE",
		outdata_reg_b => outdata_reg_b,
		power_up_uninitialized => "FALSE",
		widthad_a => widthad_a,
		widthad_b => widthad_a,
		width_a => width_a,
		width_b => width_a,
		width_byteena_a => 1
	)
	PORT MAP (
		clocken0 => wrclocken,
		clocken1 => rdclocken,
		wren_a => wren,
		clock0 => wrclock,
		clock1 => rdclock,
		address_a => wraddress,
		address_b => rdaddress,
		data_a => data,
		q_b => sub_wire0
	);

END SYN;
