--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:36:12 10/10/2009
-- Design Name:   
-- Module Name:   D:/Documents and Settings/JO/Mes documents/Projet/ORICATMOS/VERSION_2009_ISE_10.1/OA200906/tb_oa.vhd
-- Project Name:  OA2009
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
-- Revision 0.02 - 18/11/2009 : Test keyboard by PS2
-- Revision 0.03 - 23/11/2009 : Correction protocol PS2
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
 
ENTITY tb_oa IS
END tb_oa;
 
ARCHITECTURE behavior OF tb_oa IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ORIC
    PORT(
         AD : INOUT  std_logic_vector(17 downto 0);
			OE_SRAMn           : out std_logic;
	      WE_SRAMn           : out std_logic;
	      CE_SRAMn           : out std_logic;
	      UB_SRAMn           : out std_logic;
	      LB_SRAMn           : out std_logic;
         --MAPn : IN  std_logic;
         --ROMDISn : IN  std_logic;
         --IRQn : IN  std_logic;
         --CLK_EXT : OUT  std_logic;
         RW : OUT  std_logic;
         --IO : OUT  std_logic;
         --IOCONTROL : IN  std_logic;
         D : INOUT  std_logic_vector(7 downto 0);
         RESETn : IN  std_logic;
         PS2_CLK : IN  std_logic;
         PS2_DATA : IN  std_logic;
         --K7_TAPEIN : IN  std_logic;
         --K7_TAPEOUT : OUT  std_logic;
         --K7_REMOTE : OUT  std_logic;
         --K7_AUDIOOUT : OUT  std_logic;
         --AUDIO_OUT : OUT  std_logic_vector(2 downto 0);
         VIDEO_R : OUT  std_logic;
         VIDEO_G : OUT  std_logic;
         VIDEO_B : OUT  std_logic;
         --VIDEO_HSYNC : OUT  std_logic;
         --VIDEO_VSYNC : OUT  std_logic;
         VIDEO_SYNC : OUT  std_logic;
         --PRT_DATA : INOUT  std_logic_vector(7 downto 0);
         --PRT_STR : OUT  std_logic;
         --PRT_ACK : IN  std_logic;
         CLK_50 : IN  std_logic
         --DBG_ROM_DOUT : OUT  std_logic_vector(7 downto 0);
         --DBG_ULA_AD : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   --signal MAPn : std_logic := '0';
   --signal ROMDISn : std_logic := '0';
   --signal IRQn : std_logic := '0';
   --signal IOCONTROL : std_logic := '0';
   signal RESETn : std_logic := '0';
   signal PS2_CLK : std_logic := '0';
   signal PS2_DATA : std_logic := '0';
   --signal K7_TAPEIN : std_logic := '0';
   --signal PRT_ACK : std_logic := '0';
   signal CLK_50 : std_logic := '0';

	--BiDirs
   signal AD       : std_logic_vector(17 downto 0);
   signal D        : std_logic_vector(7 downto 0);
   --signal PRT_DATA : std_logic_vector(7 downto 0);

 	--Outputs
   --signal CLK_EXT      : std_logic;
   signal RW           : std_logic;
   --signal IO           : std_logic;
   --signal K7_TAPEOUT   : std_logic;
   --signal K7_REMOTE    : std_logic;
   --signal K7_AUDIOOUT  : std_logic;
   --signal AUDIO_OUT    : std_logic_vector(2 downto 0);
   signal VIDEO_R      : std_logic;
   signal VIDEO_G      : std_logic;
   signal VIDEO_B      : std_logic;
   --signal VIDEO_HSYNC  : std_logic;
   --signal VIDEO_VSYNC  : std_logic;
   signal VIDEO_SYNC   : std_logic;
   --signal PRT_STR      : std_logic;
   --signal DBG_ROM_DOUT : std_logic_vector(7 downto 0);
   --signal DBG_ULA_AD   : std_logic_vector(15 downto 0);
	
	--signal AD_SRAM : std_logic_vector(15 downto 0);
	signal OE_SRAM : std_logic;
	signal CE_SRAM : std_logic;
   signal WE_SRAM : std_logic;
	signal UB_SRAM : std_logic;
	signal LB_SRAM : std_logic;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ORIC PORT MAP (
          --AD => AD,
			 AD      => AD,
			 OE_SRAMn => OE_SRAM,
	       WE_SRAMn => WE_SRAM,
	       CE_SRAMn => CE_SRAM,
	       UB_SRAMn => UB_SRAM,
	       LB_SRAMn => LB_SRAM,
          --MAPn => MAPn,
          --ROMDISn => ROMDISn,
          --IRQn => IRQn,
          --CLK_EXT => CLK_EXT,
          RW => RW,
          --IO => IO,
          --IOCONTROL => IOCONTROL,
          D => D,
          RESETn => RESETn,
          PS2_CLK => PS2_CLK,
          PS2_DATA => PS2_DATA,
          --K7_TAPEIN => K7_TAPEIN,
          --K7_TAPEOUT => K7_TAPEOUT,
          --K7_REMOTE => K7_REMOTE,
          --K7_AUDIOOUT => K7_AUDIOOUT,
          --AUDIO_OUT => AUDIO_OUT,
          VIDEO_R => VIDEO_R,
          VIDEO_G => VIDEO_G,
          VIDEO_B => VIDEO_B,
          --VIDEO_HSYNC => VIDEO_HSYNC,
          --VIDEO_VSYNC => VIDEO_VSYNC,
          VIDEO_SYNC => VIDEO_SYNC,
          --PRT_DATA => PRT_DATA,
          --PRT_STR => PRT_STR,
          --PRT_ACK => PRT_ACK,
          CLK_50 => CLK_50
          --DBG_ROM_DOUT => DBG_ROM_DOUT,
          --DBG_ULA_AD => DBG_ULA_AD
        );
 
  ------------------------------------------------------------
  -- GESTION SRAM
  ------------------------------------------------------------
  ramv : entity work.sram
  port map
  (
   A     => AD(15 downto 0),
	nOE	=> OE_SRAM,
	nWE	=> WE_SRAM,
	nCE1	=> CE_SRAM,
	nUB1	=> UB_SRAM,
	nLB1	=> LB_SRAM,
	D     => D
   );
	
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   --18/11/2009 ne fonctionne pas ... constant CLK_12_period : TIME := 2ns;
 
   CLK_50_process :process
   begin
		CLK_50 <= '0';
		wait for 10ns;
		CLK_50 <= '1';
		wait for 10ns;
   end process;
 
   tb_RESET : PROCESS
	BEGIN
	   RESETn <= '1';
		wait for 1000 ns;
		RESETn <= '0';
		wait; -- will wait forever
	END PROCESS;
	
   tb_IN : PROCESS
	BEGIN
	   --MAPn      <= '1';
		--ROMDISn   <= '1';
		--IRQn      <= '1';
		--IOCONTROL <= '0';
		--K7_TAPEIN <= '0';
		--PRT_ACK   <= '0';
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
