library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity AS_2518_51 is
	port(
		cpu_clk		: in 	std_logic;
		reset_l		: in	std_logic;
		test_sw_l	: in 	std_logic;
		addr_i		: in 	std_logic_vector(5 downto 0);
		snd_int_i	: in 	std_logic;
		audio			: out std_logic_vector(10 downto 0)
		);
end;

architecture rtl of AS_2518_51 is 

signal E				: 	std_logic;

signal reset_h		: 	std_logic;

signal cpu_addr	: 	std_logic_vector(15 downto 0);
signal cpu_din		: 	std_logic_vector(7 downto 0) := x"FF";
signal cpu_dout	: 	std_logic_vector(7 downto 0);
signal cpu_rw		: 	std_logic;
signal cpu_vma		: 	std_logic;
signal cpu_irq		: 	std_logic;
signal cpu_nmi		:	std_logic;

signal pia_pa_i	:  std_logic_vector(7 downto 0) := x"FF";
signal pia_pa_o	: 	std_logic_vector(7 downto 0);
signal pia_pb_i	:	std_logic_vector(7 downto 0) := x"FF";
signal pia_pb_o	:  std_logic_vector(7 downto 0);
signal pia_dout	:	std_logic_vector(7 downto 0);
signal pia_irq_a	:	std_logic;
signal pia_irq_b	:	std_logic;
signal pia_cb1		:  std_logic;
signal pia_cs		:	std_logic;

signal ay_pa_i		:	std_logic_vector(7 downto 0);

signal rom_dout	:	std_logic_vector(7 downto 0);
signal rom_cs		: 	std_logic;

signal ram_dout	: 	std_logic_vector(7 downto 0);
signal ram_cs		:	std_logic;

signal snd_a		:	std_logic_vector(7 downto 0);
signal snd_b		:	std_logic_vector(7 downto 0);
signal snd_c		:	std_logic_vector(7 downto 0);

signal clk_div		: 	std_logic_vector(2 downto 0);

begin
reset_h <= (not reset_l);
E <= clk_div(2);
divider: process(cpu_clk)
begin
	if rising_edge(cpu_clk) then		
		clk_div <= clk_div + '1';
	end if;
end process;



cpu_irq <= pia_irq_a or pia_irq_b;
cpu_nmi <= not test_sw_l;

rom_cs <= cpu_addr(12) and cpu_vma;
pia_cs <= cpu_addr(7) and (not cpu_addr(12)) and cpu_vma;
ram_cs <= (not cpu_addr(7)) and (not cpu_addr(12)) and cpu_vma;

-- Bus control
cpu_din <= 
	pia_dout when pia_cs = '1' else
	rom_dout when rom_cs = '1' else
	ram_dout when ram_cs = '1' else
	x"FF";


U3: entity work.cpu68
port map(
	clk => cpu_clk,
	rst => reset_h,
	rw => cpu_rw,
	vma => cpu_vma,
	address => cpu_addr,
	data_in => cpu_din,
	data_out => cpu_dout,
	hold => '0',
	halt => '0',
	irq => cpu_irq,
	nmi => cpu_nmi
);

U4: entity work.U4_ROM
port map(
	address => cpu_addr(10 downto 0),
	clock => cpu_clk,
	q	=> rom_dout
	);
	
U2: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_dout, 
	irqa => pia_irq_a,   
	irqb => pia_irq_b,    
	pa_i => pia_pa_i,    
	pa_o => pia_pa_o,    
	ca1 => snd_int_i,    
	ca2_i => '1',    
	ca2_o => open,    
	pb_i => x"FF",    
	pb_o => pia_pb_o,    
	cb1 => pia_cb1,    
	cb2_i => '0',  
	cb2_o => open   
);

U10: entity work.m6810
port map(
	clk => cpu_clk, 
   rst => reset_h,     
   address => cpu_addr(6 downto 0), 
   cs => ram_cs,      
   rw => cpu_rw,       
   data_in => cpu_dout, 
   data_out => ram_dout
	);
	
U1: entity work.AY_3_8910
port map(
	clk => cpu_clk, 
   reset => reset_h,      
   clk_en => e,    
   cpu_d_in => pia_pa_o,   
   cpu_d_out => pia_pa_i,   
   cpu_bdir => pia_pb_o(1),  
   cpu_bc1 => pia_pb_o(0),   
   cpu_bc2 => '1',    
   io_a_in => ay_pa_i,   
   io_b_in => x"FF",    
   io_a_out => open,   
   io_b_out => open,  
	snd_A => snd_a,     
   snd_B => snd_b,      
   snd_C => snd_c
	);

ay_pa_i(5 downto 0) <= not addr_i;
ay_pa_i(7 downto 6) <= "00";

audio <= snd_a & '0' + snd_b & '0'+ snd_c & '0';

end rtl;


		