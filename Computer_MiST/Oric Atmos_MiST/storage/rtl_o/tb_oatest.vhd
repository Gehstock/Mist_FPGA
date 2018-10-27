--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:53:03 11/18/2009
-- Design Name:   
-- Module Name:   D:/Documents and Settings/JO/Mes documents/Projet/ORICATMOS/VERSION_2009_ISE_10.1/OA200906/tb_oatest.vhd
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
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
 
ENTITY tb_oatest IS
END tb_oatest;
 
ARCHITECTURE behavior OF tb_oatest IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ORIC
    PORT(
         AD : INOUT  std_logic_vector(15 downto 0);
         MAPn : IN  std_logic;
         ROMDISn : IN  std_logic;
         IRQn : IN  std_logic;
         CLK_EXT : OUT  std_logic;
         RW : OUT  std_logic;
         IO : OUT  std_logic;
         IOCONTROL : IN  std_logic;
         D : INOUT  std_logic_vector(7 downto 0);
         RESETn : IN  std_logic;
         PS2_CLK : IN  std_logic;
         PS2_DATA : IN  std_logic;
         K7_TAPEIN : IN  std_logic;
         K7_TAPEOUT : OUT  std_logic;
         K7_REMOTE : OUT  std_logic;
         K7_AUDIOOUT : OUT  std_logic;
         AUDIO_OUT : OUT  std_logic_vector(3 downto 0);
         VIDEO_R : OUT  std_logic;
         VIDEO_G : OUT  std_logic;
         VIDEO_B : OUT  std_logic;
         VIDEO_HSYNC : OUT  std_logic;
         VIDEO_VSYNC : OUT  std_logic;
         VIDEO_SYNC : OUT  std_logic;
         PRT_DATA : INOUT  std_logic_vector(7 downto 0);
         PRT_STR : OUT  std_logic;
         PRT_ACK : IN  std_logic;
         CLK_12 : IN  std_logic;
         DBG_ROM_DOUT : OUT  std_logic_vector(7 downto 0);
         DBG_ULA_AD : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal MAPn : std_logic := '0';
   signal ROMDISn : std_logic := '0';
   signal IRQn : std_logic := '0';
   signal IOCONTROL : std_logic := '0';
   signal RESETn : std_logic := '0';
   signal PS2_CLK : std_logic := '0';
   signal PS2_DATA : std_logic := '0';
   signal K7_TAPEIN : std_logic := '0';
   signal PRT_ACK : std_logic := '0';
   signal CLK_12 : std_logic := '0';

	--BiDirs
   signal AD : std_logic_vector(15 downto 0);
   signal D : std_logic_vector(7 downto 0);
   signal PRT_DATA : std_logic_vector(7 downto 0);

 	--Outputs
   signal CLK_EXT : std_logic;
   signal RW : std_logic;
   signal IO : std_logic;
   signal K7_TAPEOUT : std_logic;
   signal K7_REMOTE : std_logic;
   signal K7_AUDIOOUT : std_logic;
   signal AUDIO_OUT : std_logic_vector(3 downto 0);
   signal VIDEO_R : std_logic;
   signal VIDEO_G : std_logic;
   signal VIDEO_B : std_logic;
   signal VIDEO_HSYNC : std_logic;
   signal VIDEO_VSYNC : std_logic;
   signal VIDEO_SYNC : std_logic;
   signal PRT_STR : std_logic;
   signal DBG_ROM_DOUT : std_logic_vector(7 downto 0);
   signal DBG_ULA_AD : std_logic_vector(15 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ORIC PORT MAP (
          AD => AD,
          MAPn => MAPn,
          ROMDISn => ROMDISn,
          IRQn => IRQn,
          CLK_EXT => CLK_EXT,
          RW => RW,
          IO => IO,
          IOCONTROL => IOCONTROL,
          D => D,
          RESETn => RESETn,
          PS2_CLK => PS2_CLK,
          PS2_DATA => PS2_DATA,
          K7_TAPEIN => K7_TAPEIN,
          K7_TAPEOUT => K7_TAPEOUT,
          K7_REMOTE => K7_REMOTE,
          K7_AUDIOOUT => K7_AUDIOOUT,
          AUDIO_OUT => AUDIO_OUT,
          VIDEO_R => VIDEO_R,
          VIDEO_G => VIDEO_G,
          VIDEO_B => VIDEO_B,
          VIDEO_HSYNC => VIDEO_HSYNC,
          VIDEO_VSYNC => VIDEO_VSYNC,
          VIDEO_SYNC => VIDEO_SYNC,
          PRT_DATA => PRT_DATA,
          PRT_STR => PRT_STR,
          PRT_ACK => PRT_ACK,
          CLK_12 => CLK_12,
          DBG_ROM_DOUT => DBG_ROM_DOUT,
          DBG_ULA_AD => DBG_ULA_AD
        );
 
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant <clock>_period := 1ns;
 
   <clock>_process :process
   begin
		<clock> <= '0';
		wait for <clock>_period/2;
		<clock> <= '1';
		wait for <clock>_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100ms.
      wait for 100ms;	

      wait for <clock>_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
