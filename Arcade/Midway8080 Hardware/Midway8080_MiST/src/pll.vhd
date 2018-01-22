LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.all;

entity pll is
  generic
  (
    -- INCLK
    INCLK0_INPUT_FREQUENCY  : natural;

    -- CLK0
    CLK0_DIVIDE_BY          : natural := 1;
    CLK0_DUTY_CYCLE         : natural := 50;
    CLK0_MULTIPLY_BY        : natural := 1;
    CLK0_PHASE_SHIFT        : string := "0";

    -- CLK1
    CLK1_DIVIDE_BY          : natural := 1;
    CLK1_DUTY_CYCLE         : natural := 50;
    CLK1_MULTIPLY_BY        : natural := 1;
    CLK1_PHASE_SHIFT        : string := "0"
  );
	port
	(
		inclk0		: in std_logic  := '0';
		c0		    : out std_logic ;
		c1		    : out std_logic 
	);
END pll;

ARCHITECTURE SYN OF pll IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (5 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC ;
	SIGNAL sub_wire2	: STD_LOGIC ;
	SIGNAL sub_wire3	: STD_LOGIC ;
	SIGNAL sub_wire4	: STD_LOGIC_VECTOR (1 DOWNTO 0);
	SIGNAL sub_wire5_bv	: BIT_VECTOR (0 DOWNTO 0);
	SIGNAL sub_wire5	: STD_LOGIC_VECTOR (0 DOWNTO 0);

	COMPONENT altpll
	GENERIC (
		clk0_divide_by		: NATURAL;
		clk0_duty_cycle		: NATURAL;
		clk0_multiply_by		: NATURAL;
		clk0_phase_shift		: STRING;
		clk1_divide_by		: NATURAL;
		clk1_duty_cycle		: NATURAL;
		clk1_multiply_by		: NATURAL;
		clk1_phase_shift		: STRING;
		compensate_clock		: STRING;
		inclk0_input_frequency		: NATURAL;
		intended_device_family		: STRING;
		lpm_type		: STRING;
		operation_mode		: STRING;
		pll_type		: STRING;
		port_activeclock		: STRING;
		port_areset		: STRING;
		port_clkbad0		: STRING;
		port_clkbad1		: STRING;
		port_clkloss		: STRING;
		port_clkswitch		: STRING;
		port_fbin		: STRING;
		port_inclk0		: STRING;
		port_inclk1		: STRING;
		port_locked		: STRING;
		port_pfdena		: STRING;
		port_pllena		: STRING;
		port_scanaclr		: STRING;
		port_scanclk		: STRING;
		port_scandata		: STRING;
		port_scandataout		: STRING;
		port_scandone		: STRING;
		port_scanread		: STRING;
		port_scanwrite		: STRING;
		port_clk0		: STRING;
		port_clk1		: STRING;
		port_clk2		: STRING;
		port_clk3		: STRING;
		port_clk4		: STRING;
		port_clk5		: STRING;
		port_clkena0		: STRING;
		port_clkena1		: STRING;
		port_clkena2		: STRING;
		port_clkena3		: STRING;
		port_clkena4		: STRING;
		port_clkena5		: STRING;
		port_enable0		: STRING;
		port_enable1		: STRING;
		port_extclk0		: STRING;
		port_extclk1		: STRING;
		port_extclk2		: STRING;
		port_extclk3		: STRING;
		port_extclkena0		: STRING;
		port_extclkena1		: STRING;
		port_extclkena2		: STRING;
		port_extclkena3		: STRING;
		port_sclkout0		: STRING;
		port_sclkout1		: STRING
	);
	PORT (
			inclk	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
			clk	: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	sub_wire5_bv(0 DOWNTO 0) <= "0";
	sub_wire5    <= To_stdlogicvector(sub_wire5_bv);
	sub_wire2    <= sub_wire0(1);
	sub_wire1    <= sub_wire0(0);
	c0    <= sub_wire1;
	c1    <= sub_wire2;
	sub_wire3    <= inclk0;
	sub_wire4    <= sub_wire5(0 DOWNTO 0) & sub_wire3;

	altpll_component : altpll
	GENERIC MAP (
		clk0_divide_by => CLK0_DIVIDE_BY,
		clk0_duty_cycle => CLK0_DUTY_CYCLE,
		clk0_multiply_by => CLK0_MULTIPLY_BY,
		clk0_phase_shift => CLK0_PHASE_SHIFT,
		clk1_divide_by => CLK1_DIVIDE_BY,
		clk1_duty_cycle => CLK1_DUTY_CYCLE,
		clk1_multiply_by => CLK1_MULTIPLY_BY,
		clk1_phase_shift => CLK1_PHASE_SHIFT,
		compensate_clock => "CLK0",
		inclk0_input_frequency => INCLK0_INPUT_FREQUENCY,
		intended_device_family => "Cyclone II",
		lpm_type => "altpll",
		operation_mode => "NORMAL",
		pll_type => "FAST",
		port_activeclock => "PORT_UNUSED",
		port_areset => "PORT_UNUSED",
		port_clkbad0 => "PORT_UNUSED",
		port_clkbad1 => "PORT_UNUSED",
		port_clkloss => "PORT_UNUSED",
		port_clkswitch => "PORT_UNUSED",
		port_fbin => "PORT_UNUSED",
		port_inclk0 => "PORT_USED",
		port_inclk1 => "PORT_UNUSED",
		port_locked => "PORT_UNUSED",
		port_pfdena => "PORT_UNUSED",
		port_pllena => "PORT_UNUSED",
		port_scanaclr => "PORT_UNUSED",
		port_scanclk => "PORT_UNUSED",
		port_scandata => "PORT_UNUSED",
		port_scandataout => "PORT_UNUSED",
		port_scandone => "PORT_UNUSED",
		port_scanread => "PORT_UNUSED",
		port_scanwrite => "PORT_UNUSED",
		port_clk0 => "PORT_USED",
		port_clk1 => "PORT_USED",
		port_clk2 => "PORT_UNUSED",
		port_clk3 => "PORT_UNUSED",
		port_clk4 => "PORT_UNUSED",
		port_clk5 => "PORT_UNUSED",
		port_clkena0 => "PORT_UNUSED",
		port_clkena1 => "PORT_UNUSED",
		port_clkena2 => "PORT_UNUSED",
		port_clkena3 => "PORT_UNUSED",
		port_clkena4 => "PORT_UNUSED",
		port_clkena5 => "PORT_UNUSED",
		port_enable0 => "PORT_UNUSED",
		port_enable1 => "PORT_UNUSED",
		port_extclk0 => "PORT_UNUSED",
		port_extclk1 => "PORT_UNUSED",
		port_extclk2 => "PORT_UNUSED",
		port_extclk3 => "PORT_UNUSED",
		port_extclkena0 => "PORT_UNUSED",
		port_extclkena1 => "PORT_UNUSED",
		port_extclkena2 => "PORT_UNUSED",
		port_extclkena3 => "PORT_UNUSED",
		port_sclkout0 => "PORT_UNUSED",
		port_sclkout1 => "PORT_UNUSED"
	)
	PORT MAP (
		inclk => sub_wire4,
		clk => sub_wire0
	);



END SYN;
