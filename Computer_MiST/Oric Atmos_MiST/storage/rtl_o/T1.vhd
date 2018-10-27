--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:44:36 03/10/2011
-- Design Name:   
-- Module Name:   /home/will/Documents/VHDL/PROJET/OricinFPGA/T1.vhd
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY T1 IS
END T1;
 
ARCHITECTURE behavior OF T1 IS 
 
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
   constant CLK_50_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ORIC PORT MAP (
          AD => AD,
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

   -- Clock process definitions
   PS2_CLK_process :process
   begin
		PS2_CLK <= '0';
		wait for PS2_CLK_period/2;
		PS2_CLK <= '1';
		wait for PS2_CLK_period/2;
   end process;
 
   CLK_50_process :process
   begin
		CLK_50 <= '0';
		wait for CLK_50_period/2;
		CLK_50 <= '1';
		wait for CLK_50_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for PS2_CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
