--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:22:03 03/08/2011
-- Design Name:   
-- Module Name:   /home/will/Documents/VHDL/PROJET/OricinFPGA/simul_test.vhd
-- Project Name:  OricinFPGA
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ORIC
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library std;
use std.textio.all;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY simul_test IS
END simul_test;
 
ARCHITECTURE behavior OF simul_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ORIC
    PORT(
         AD : INOUT  std_logic_vector(17 downto 0);
         OE_SRAMn : OUT  std_logic;
         WE_SRAMn : OUT  std_logic;
         CE_SRAMn : OUT  std_logic;
         UB_SRAMn : OUT  std_logic;
         LB_SRAMn : OUT  std_logic;
         RW : OUT  std_logic;
         D : INOUT  std_logic_vector(7 downto 0);
         RESETn : IN  std_logic;
         PS2_CLK : IN  std_logic;
         PS2_DATA : IN  std_logic;
         VIDEO_R : OUT  std_logic;
         VIDEO_G : OUT  std_logic;
         VIDEO_B : OUT  std_logic;
         VIDEO_SYNC : OUT  std_logic;
         CLK_50 : IN  std_logic;
         btn : IN  std_logic_vector(3 downto 0);
         an : OUT  std_logic_vector(3 downto 0);
         sseg : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    
   --Inputs
   signal RESETn : std_logic := '0';
   signal PS2_CLK : std_logic := '0';
   signal PS2_DATA : std_logic := '0';
   signal CLK_50 : std_logic := '0';
   signal btn : std_logic_vector(3 downto 0) := (others => '0');

	--BiDirs
   signal AD : std_logic_vector(17 downto 0);
   signal D : std_logic_vector(7 downto 0);

 	--Outputs
   signal OE_SRAMn : std_logic;
   signal WE_SRAMn : std_logic;
   signal CE_SRAMn : std_logic;
   signal UB_SRAMn : std_logic;
   signal LB_SRAMn : std_logic;
   signal RW : std_logic;
   signal VIDEO_R : std_logic;
   signal VIDEO_G : std_logic;
   signal VIDEO_B : std_logic;
   signal VIDEO_SYNC : std_logic;
   signal an : std_logic_vector(3 downto 0);
   signal sseg : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant PS2_CLK_period : time := 10 ns;
   constant CLK_50_period : time := 40 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ORIC PORT MAP (
          AD => AD(17 downto 0),
          OE_SRAMn => OE_SRAMn,
          WE_SRAMn => WE_SRAMn,
          CE_SRAMn => CE_SRAMn,
          UB_SRAMn => UB_SRAMn,
          LB_SRAMn => LB_SRAMn,
          RW => RW,
          D => D,
          RESETn => RESETn,
          PS2_CLK => PS2_CLK,
          PS2_DATA => PS2_DATA,
          VIDEO_R => VIDEO_R,
          VIDEO_G => VIDEO_G,
          VIDEO_B => VIDEO_B,
          VIDEO_SYNC => VIDEO_SYNC,
          CLK_50 => CLK_50,
          btn => btn,
          an => an,
          sseg => sseg
        );
		  
  ------------------------------------------------------------
  -- GESTION SRAM
  ------------------------------------------------------------
  ramv : entity work.sram
  port map
  (
   A     => AD(15 downto 0),
	nOE	=> OE_SRAMn,
	nWE	=> WE_SRAMn,
	nCE1	=> CE_SRAMn,
	nUB1	=> '1',
	nLB1	=> '0',
	D     => D
   );
	
   tb_RESET : PROCESS
	BEGIN
	   RESETn <= '1';
		wait for 1000 ns;
		RESETn <= '0';		     
      wait; -- will wait forever
	END PROCESS;
	
	CLK_50_process :process
   begin
	   -- 10/03/2011 : En fait, pour 24 (2x12) Mhz et pas 50 MHz
		CLK_50 <= '0';
		wait for 20ns;
		CLK_50 <= '1';
		wait for 20ns;
   end process;
	
   tb_IN : PROCESS
	BEGIN
	   --MAPn      <= '1';
		--ROMDISn   <= '1';
		--IRQn      <= '1';
		--IOCONTROL <= '0';
		--K7_TAPEIN <= '0';
		--PRT_ACK   <= '0';
		-- 10/03/2011 : Au supprimer en reel :
		btn <= "0000";
		wait; -- will wait forever
	END PROCESS;
	
   -- Stimulus process
   tb_keyboard : process
	file file_in 		: text open read_mode is "./scenario.txt";
	variable line_in	: line;
	variable cmd		: character;
	variable delay		: time;
	variable sig		: std_logic;
	variable char		: std_logic_vector(7 downto 0);
begin

	loop                                   
		readline(file_in, line_in);           
      --exit when endfile(file_in);          
                                           
      read(line_in, cmd);
      exit when 	cmd = 'W'		-- Wait
					or cmd = 'E'		-- End
					or	cmd = 'K';		-- Keyboard
	end loop;

	--if not endfile(file_in) then                                        
		case cmd is

			when 'W' =>
				read(line_in, delay);
			   PS2_CLK <= '1';   -- Ajout du 23/11/2009
 				PS2_DATA <= '1';  -- Ajout du 23/11/2009
				wait for delay;

			when 'K' =>
				read(line_in, char);

PS2_DATA <= '0';	-- Start Bit
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(0);	-- LSB
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(1);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(2);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(3);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(4);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(5);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(6);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= char(7);
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= '0';	-- Parity (don't care)
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;
PS2_DATA <= '1';	-- Stop Bit
		PS2_CLK <= '0';
		wait for 40us;
		PS2_CLK <= '1';
		wait for 40us;

			when 'E' =>
				PS2_CLK <= '1';
				PS2_DATA <= 'Z';
				wait;

			when others =>

		end case;
	--else
	--	PS2_CLK <= '1';
	--	PS2_DATA <= 'Z';
	--	wait;
	--end if;
end process;

END;
