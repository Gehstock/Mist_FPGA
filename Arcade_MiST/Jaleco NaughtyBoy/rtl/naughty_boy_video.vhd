---------------------------------------------------------------------------------
-- Naughty Boy video generator by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

entity naughty_boy_video is
port(
 clk12    : in std_logic;
 hcnt     : out std_logic_vector(8 downto 0);
 vcnt     : out std_logic_vector(7 downto 0);
 ena_pix  : inout std_logic;
 hsync    : out std_logic;
 vsync    : out std_logic;
 csync    : out std_logic;
 cpu_wait : out std_logic;
-- clr_vid  : out std_logic;
 
 hblank   : out std_logic;
 vblank   : out std_logic;
 
 sel_cpu_addr  : out std_logic;
 sel_scrl_addr : out std_logic
); end naughty_boy_video;

architecture struct of naughty_boy_video is 
 signal hcnt_i : unsigned(8 downto 0) := (others=>'0');
 signal vcnt_i : unsigned(7 downto 0) := (others=>'0');
 
 constant start_l : integer := 170;
 
begin

-- horizontal counter clock (pixel clock) 
process (clk12)
begin
 if rising_edge(clk12) then
  ena_pix <= not ena_pix;
 end if;
end process;

-- horizontal counter from 0x080 to 0x1FF : 384 pixels 
process (clk12)
begin
	if rising_edge(clk12) then
		if ena_pix = '1' then
			if hcnt_i = "111111111" then
				hcnt_i <= "010000000";
			else
				hcnt_i  <= hcnt_i + 1;
			end if;
		end if;
	end if;
end process;

-- vertical counter from 0x00 to 0xFF : 256 lines 
process (clk12)
begin
	if rising_edge(clk12) then
		if ena_pix = '1' and hcnt_i = 159 then
			if vcnt_i = "11111111" then
				vcnt_i <= (others=>'0');
			else
				vcnt_i <= vcnt_i +1;
			end if;
		end if;  
	end if;
end process;

-- Misc
sel_scrl_addr <= hcnt_i(8);

hsync <= '0' when (hcnt_i > (192-16)) and (hcnt_i < (220-16)) else '1';
vsync <= '0' when (vcnt_i > 232) and (vcnt_i < 240) else '1';

hblank <= '1' when (hcnt_i > (128+15)) and (hcnt_i < (255-15)) else '0';
vblank <= '1' when (vcnt_i > 223) else '0'; 

process (clk12)
begin
	if rising_edge(clk12) then
		if ena_pix = '1' then
			
			if hcnt_i = 159                  then cpu_wait <= '0'; end if;
			if hcnt_i = 223 and vcnt_i < 224 then cpu_wait <= '1'; end if;

			if hcnt_i = 143                  then sel_cpu_addr <= '1'; end if;
			if hcnt_i = 239 and vcnt_i < 224 then sel_cpu_addr <= '0'; end if;
		
		end if;
	end if;
end process;

hcnt <= std_logic_vector(hcnt_i);
vcnt <= std_logic_vector(vcnt_i);
 
-- Composite Sync 
process (clk12)
begin
	if rising_edge(clk12) then
		if ena_pix = '1' then
			
			if vcnt_i >= 224 and vcnt_i <= 225 then
				if	hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
				if hcnt_i = start_l+192+14 then csync <= '1'; end if;
				
			elsif vcnt_i = 226 then
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
		
			elsif vcnt_i >= 227 and vcnt_i <= 228 then
				if hcnt_i = start_l    -14 then csync <= '1'; end if;
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l+192-14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;

			elsif vcnt_i = 229 then
				if hcnt_i = start_l    -14 then csync <= '1'; end if;
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
				if hcnt_i = start_l+192+14 then csync <= '1'; end if;
				
			elsif vcnt_i = 230 then
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +14 then csync <= '1'; end if;
				if hcnt_i = start_l+192    then csync <= '0'; end if;
				if hcnt_i = start_l+192+14 then csync <= '1'; end if;
				
			else
				if hcnt_i = start_l        then csync <= '0'; end if;
				if hcnt_i = start_l    +28 then csync <= '1'; end if;
			end if;
			
		end if;  
	end if;
end process;
	
end struct;
