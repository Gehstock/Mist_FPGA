
-- VHDL Test Bench Created from source file ay3819x.vhd -- 15:33:03 12/26/2001
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY testbench IS
END testbench;

ARCHITECTURE behavior OF testbench IS 

constant CLK_PERIOD : time := 60 nS;        -- system clock period

	COMPONENT ay3819x
	PORT(
		RESET : IN std_logic;
		CLOCK : IN std_logic;
		BDIR : IN std_logic;
		BC1 : IN std_logic;
		BC2 : IN std_logic;    
		D : INOUT std_logic_vector(7 downto 0);
		IOA : INOUT std_logic_vector(7 downto 0);
		IOB : INOUT std_logic_vector(7 downto 0);      
		AnalogA : OUT std_logic;
		AnalogB : OUT std_logic;
		AnalogC : OUT std_logic );
	END COMPONENT;

   SIGNAL D :  std_logic_vector(7 downto 0);
   SIGNAL RESET :  std_logic;
   SIGNAL CLOCK :  std_logic;
   SIGNAL BDIR :  std_logic;
   SIGNAL BC1 :  std_logic;
   SIGNAL BC2 :  std_logic;
   SIGNAL IOA :  std_logic_vector(7 downto 0);
   SIGNAL IOB :  std_logic_vector(7 downto 0);
   SIGNAL AnalogA :  std_logic;
   SIGNAL AnalogB :  std_logic;
   SIGNAL AnalogC :  std_logic;

BEGIN

uut: ay3819x PORT MAP(
      D => D,
      RESET => RESET,
      CLOCK => CLOCK,
      BDIR => BDIR,
      BC1 => BC1,
      BC2 => BC2,
      IOA => IOA,
      IOB => IOB,
      AnalogA => AnalogA,
      AnalogB => AnalogB,
      AnalogC => AnalogC );


-- *** Test Bench - User Defined Section ***

CREATE_CLK: process
    begin
        CLOCK <= '0';
        wait for CLK_PERIOD/2;
        CLOCK <= '1';
        wait for CLK_PERIOD/2;
end process;

SIMUL_RESET: process
begin
        RESET    <= '1';
        wait until CLOCK'event and CLOCK = '1';
        wait until CLOCK'event and CLOCK = '1';
        wait for 15 ns;
        RESET <= '0';
        wait;
end process;

SIMUL_WR_TO_R0: process
begin 
      BDIR <= '0';
      BC1  <= '0';
      BC2  <= '0';
      wait for 150 ns; 
      BDIR <= '1';   -- Latch 
      BC1  <= '1';
      BC2  <= '1';
      wait for 15 ns;  
      BDIR <= '0';   -- HIGH IMPEDANCE
      BC1  <= '0';
      BC2  <= '0';
      wait for 45 ns;
      BDIR <= '1';   -- write to register
      BC1  <= '0';
      BC2  <= '1';      
      wait for 15 ns;
      BDIR <= '0';   -- HIGH IMPEDANCE
      BC1  <= '0';
      BC2  <= '0';
      wait for 45 ns; 
      BDIR <= '1';   -- latch
      BC1  <= '1';
      BC2  <= '1';
      wait for 15 ns; 
      BDIR <= '0';   -- High impedance
      BC1  <= '0';
      BC2  <= '0';
      wait for 45 ns;
      BDIR <= '1';   -- write to register
      BC1  <= '0';
      BC2  <= '1';      
      wait for 15 ns;
      BDIR <= '0';   -- High impedance
      BC1  <= '0';
      BC2  <= '0';
      wait for 45 ns;
      BDIR <= '1';   -- Latch 
      BC1  <= '1';
      BC2  <= '1';
      wait for 15 ns;  
      BDIR <= '0';   -- High impedance
      BC1  <= '0';
      BC2  <= '0';
      wait for 45 ns;
      BDIR <= '0';   -- Read
      BC1  <= '1';
      BC2  <= '1';
      wait for 15 ns;  
      BDIR <= '0';   -- High impedance
      BC1  <= '0';
      BC2  <= '0';
      wait;

end process;

BUS_D : process
begin
     D <= ( others => 'Z');
     wait for 150 ns;
     D <= "00001110";
     wait for 30 ns;
     D <= ( others => 'Z');
     wait for 30 ns;      -- 195 ns
     D <= "00010101";
     wait for 30 ns;      -- 225 ns
     D <= ( others => 'Z');
     wait for 30 ns;      -- 255 ns
     D <= "00000001";
     wait for 30 ns;      -- 285 ns
     D <= ( others => 'Z');
     wait for 30 ns;      -- 315 ns
     D <= "10010001";
     wait for 30 ns;      -- 345 ns
     D <= ( others => 'Z');
     wait for 30 ns;      -- 375 ns
     D <= "00001110";
     wait for 30 ns;      -- 405 ns
     D <= ( others => 'Z');
     wait;
end process;

tb : PROCESS
   BEGIN
      wait for 1000 ns; -- will wait forever
   END PROCESS;
-- *** End Test Bench - User Defined Section ***

END;
