library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity kb_synth is
	port (
		reset_n  : in  std_logic;
		clk : in  std_logic;
		in0 : in  std_logic;
		in1 : in  std_logic;
		in2 : in  std_logic;
		in3 : in  std_logic;
		speech_out   : out std_logic_vector(7 downto 0)
	);
end kb_synth;

architecture RTL of kb_synth is

signal cpu_addr : std_logic_vector(15 downto 0);
signal cpu_di : std_logic_vector(7 downto 0);
signal cpu_do : std_logic_vector(7 downto 0);
signal ram_do : std_logic_vector(7 downto 0);
signal rom4_do : std_logic_vector(7 downto 0);
signal rom5_do : std_logic_vector(7 downto 0);
signal rom6_do : std_logic_vector(7 downto 0);
signal mreq_n : std_logic;
signal iorq_n : std_logic;
signal rd_n : std_logic;
signal wr_n : std_logic;

signal ram_ce : std_logic;
signal rom4_ce : std_logic;
signal rom5_ce : std_logic;
signal rom6_ce : std_logic;
signal ic3_out : std_logic_vector(7 downto 0);
signal buf_do : std_logic_vector(7 downto 0);
signal buf_ce : std_logic;
signal A13n : std_logic;
begin

cpu_di <= ram_do when ram_ce = '1' else
			 rom4_do when rom4_ce = '1' else
			 rom5_do when rom5_ce = '1' else
			 rom6_do when rom6_ce = '1' else
			 buf_do when buf_ce = '0' else
			 "00000000";


	cpu : entity work.T80as
	port map (
		RESET_n      => reset_n,
		CLK_n        => clk,		
		WAIT_n       => '1',
		INT_n        => '1',
		NMI_n        => '1',
		BUSRQ_n      => '1',		
		MREQ_n       => mreq_n,
		IORQ_n       => iorq_n,
		RD_n         => rd_n,
		WR_n         => wr_n,		
		A            => cpu_addr,
		DI           => cpu_di,
		DO           => cpu_do
	);
	
A13n <= not cpu_addr(13);
ram_ce <= not (A13n or mreq_n);
	ram_inst : entity work.spram generic map(10,8)
	port map (
		address  	 => cpu_addr(9 downto 0),
		clock    	 => clk,
		data     	 => cpu_do,
		wren			 => not wr_n,
		q				 => ram_do
	);

rom4_ce <= ic3_out(0);
	rom4_inst : entity work.kbe1_IC4
	port map (
	clk    	 	 => clk,
	addr  	 	 => cpu_addr(10 downto 0),
	data			 => rom4_do
	);

rom5_ce <= ic3_out(1);
	rom5_inst : entity work.kbe2_IC5
	port map (
	clk    	 	 => clk,
	addr  	 	 => cpu_addr(10 downto 0),
	data			 => rom5_do
	);
	
rom6_ce <= ic3_out(2);	
	rom6_inst : entity work.kbe3_IC6
	port map (
	clk    	 	 => clk,
	addr  	 	 => cpu_addr(10 downto 0),
	data			 => rom6_do
	);
	
	ls138 : entity work.ttl_74138
	port map (
		a    	 		 => cpu_addr(11),
		b    	 		 => cpu_addr(12),
		c    	 		 => '0',
		g1    	 	 => A13n,
		g2a_n    	 => rd_n,
		g2b_n    	 => mreq_n,
		y_n    	 	 => ic3_out
	);

	ls273 : entity work.ttl_74273
	port map (
		CLRN    	 	 => reset_n,
		CLK    	 	 => not (wr_n or iorq_n),
		D8    	 	 => cpu_do(0),
		D7    	 	 => cpu_do(1),
		D6    	 	 => cpu_do(2),
		D5    	 	 => cpu_do(3),
		D4    	 	 => cpu_do(4),
		D3    	 	 => cpu_do(5),
		D2    	 	 => cpu_do(6),
		D1    	 	 => cpu_do(7),
		Q1    	 	 => speech_out(0),
		Q2    	 	 => speech_out(1),
		Q3    	 	 => speech_out(2),
		Q4    	 	 => speech_out(3),
		Q5    	 	 => speech_out(4),
		Q6    	 	 => speech_out(5),
		Q7    	 	 => speech_out(6),
		Q8    	 	 => speech_out(7)
	);

buf_ce <= rd_n or iorq_n;
--buf_do(6) <= '0';
--buf_do(7) <= '0';
	ls367 : entity work.ttl_74367 
	port map (
		p2GN    	 	 => buf_ce,--15
		
		p2A1    	 	 => '1',--12
		p2A2    	 	 => '1',--14
		
		p1A4    	 	 => '0',--in3,--10
		p1A3    	 	 => '0',--in2,--6
		p1A2    	 	 => in1,--4
		p1A1    	 	 => in0,--2
		
		p1GN    	 	 => buf_ce,--1
		
		p2Y1    	 	 => buf_do(4),--11
		p2Y2    	 	 => buf_do(5),--13
		
		p1Y4    	 	 => buf_do(3),--9
		p1Y3    	 	 => buf_do(2),--7
		p1Y2    	 	 => buf_do(1),--5
		p1Y1    	 	 => buf_do(0)--3
	);

end RTL;