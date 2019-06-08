library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;


entity spacelaser_overlay is
	port(
		Video             : in    std_logic;
		Overlay           : in    std_logic;
		CLK               : in    std_logic;
		Rst_n_s           : in    std_logic;
		HSync             : in    std_logic;
		VSync             : in    std_logic;
		AD                : in    std_logic_vector(15 downto 0);
		O_VIDEO_R         : out   std_logic;
		O_VIDEO_G         : out   std_logic;
		O_VIDEO_B         : out   std_logic;
		O_HSYNC           : out   std_logic;
		O_VSYNC           : out   std_logic
		);
end spacelaser_overlay;

architecture rtl of spacelaser_overlay is

	signal HCnt            : std_logic_vector(11 downto 0);
	signal VCnt            : std_logic_vector(11 downto 0);
	signal HSync_t1        : std_logic;
	signal Overlay_G1      : boolean;
	signal Overlay_G2      : boolean;
	signal Overlay_B1      : boolean;
	signal Overlay_B2      : boolean;
	signal Overlay_B2_VCnt : boolean;
	signal Overlay_A1      : boolean;
	signal Overlay_P1      : boolean;
	signal Overlay_Y1      : boolean;
	signal Overlay_Y2      : boolean;
	signal Overlay_Y2_VCnt : boolean;
	signal Overlay_R1      : boolean;
	signal Overlay_A2      : boolean;
	signal Overlay_R2      : boolean;
	signal Overlay_A3      : boolean;
	signal Overlay_A3_VCnt : boolean;

	signal VideoRGB        : std_logic_vector(2 downto 0);
	signal col_data        : std_logic_vector(3 downto 0);
	signal col_addr        : std_logic_vector(9 downto 0);
begin	
	process (Rst_n_s, Clk)
		variable cnt : unsigned(3 downto 0);
	begin
		if Rst_n_s = '0' then
			cnt := "0000";
		elsif Clk'event and Clk = '1' then
			if cnt = 9 then
				cnt := "0000";
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;
	
  p_overlay : process(Rst_n_s, Clk)
	variable HStart : boolean;
  begin
	if Rst_n_s = '0' then
	  HCnt <= (others => '0');
	  VCnt <= (others => '0');
	  HSync_t1 <= '0';
	  Overlay_G1 <= false;

	  Overlay_B1 <= false;
	  Overlay_A1 <= false;
	  Overlay_P1 <= false;
	  Overlay_Y1 <= false;
	  Overlay_R1 <= false;
	  Overlay_A2 <= false;
	  Overlay_R2 <= false;
	  Overlay_Y2 <= false;
	  Overlay_Y2_VCnt <= false;
	  Overlay_B2 <= false;
	  Overlay_B2_VCnt <= false;
	  Overlay_A3 <= false;
	  Overlay_A3_VCnt <= false;
	elsif Clk'event and Clk = '1' then
	  HSync_t1 <= HSync;
	  HStart := (HSync_t1 = '0') and (HSync = '1');

	  if HStart then
		HCnt <= (others => '0');
	  else
		HCnt <= HCnt + "1";
	  end if;

	  if (VSync = '0') then
		VCnt <= (others => '0');
	  elsif HStart then
		VCnt <= VCnt + "1";
	  end if;

	  
	  if HStart then
		if (Vcnt = 140) then
		  Overlay_Y2_VCnt <= true;
		elsif (Vcnt = 232) then
		  Overlay_Y2_VCnt <= false;
		end if;
		
		if (Vcnt = 98) then
		  Overlay_B2_VCnt <= true;
		elsif (Vcnt = 140) then
		  Overlay_B2_VCnt <= false;
		end if;
		
		if (Vcnt = 0) then
		  Overlay_A3_VCnt <= true;
		elsif (Vcnt = 100) then
		  Overlay_A3_VCnt <= false;
		end if;
	  end if;  
	  
	  if (HCnt = 500) and Overlay_A3_VCnt then
		Overlay_A3 <= true;
	  elsif (HCnt = 540) then
		Overlay_A3 <= false;
	  end if;
	  
	  if (HCnt = 486) and Overlay_B2_VCnt then
		Overlay_B2 <= true;
	  elsif (HCnt = 540) then
		Overlay_B2 <= false;
	  end if;

	  if (HCnt = 486) and Overlay_Y2_VCnt then
		Overlay_Y2 <= true;
	  elsif (HCnt = 540) then
		Overlay_Y2 <= false;
	  end if;

	  if (HCnt = 64) then
		Overlay_R2 <= true;
	  elsif (HCnt = 98) then
		Overlay_R2 <= false;
	  end if;

	  if (HCnt = 92) then
		Overlay_A2 <= true;
	  elsif (HCnt = 120) then
		Overlay_A2 <= false;
	  end if;

	  if (HCnt = 120) then
		Overlay_R1 <= true;
	  elsif (HCnt = 166) then
		Overlay_R1 <= false;
	  end if;

	  if (HCnt = 166) then
		Overlay_Y1 <= true;
	  elsif (HCnt = 228) then
		Overlay_Y1 <= false;
	  end if;

	  if (HCnt = 228) then
		Overlay_P1 <= true;
	  elsif (HCnt = 292) then
		Overlay_P1 <= false;
	  end if;
	  
	  if (HCnt = 292) then
		Overlay_A1 <= true;
	  elsif (HCnt = 358) then
		Overlay_A1 <= false;
	  end if;	 

	  if (HCnt = 358) then
		Overlay_G1 <= true;
	  elsif (HCnt = 430) then
		Overlay_G1 <= false;
	  end if;

	  if (HCnt = 430) then
		Overlay_B1 <= true;
	  elsif (HCnt = 486) then
		Overlay_B1 <= false;
	  end if; 

	end if;
  end process;

  p_video_out_comb : process(Video, Overlay_G1, Overlay_G2, Overlay_B1)
  begin
	if (Video = '0') then
	  VideoRGB  <= "000";
	else
	  if Overlay_G1 then--GREEN
		VideoRGB  <= "010";
	  elsif Overlay_B1 or Overlay_B2 then--BLUE
		VideoRGB  <= "001";
	  elsif Overlay_A1 or Overlay_A2 or Overlay_A3 then--AQUA
		VideoRGB  <= "011";
	  elsif Overlay_P1 then--PINK
		VideoRGB  <= "101";
	  elsif Overlay_Y1 or Overlay_Y2 then--YELLOW
		VideoRGB  <= "110";
	  elsif Overlay_R1 or Overlay_R2 then--RED
		VideoRGB  <= "100";		
	  else	  
		VideoRGB  <= "111";--WHITE
	  end if;
	end if;
  end process;
  
  O_VIDEO_R <= VideoRGB(2) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_VIDEO_G <= VideoRGB(1) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_VIDEO_B <= VideoRGB(0) when (Overlay = '1') else VideoRGB(0) or VideoRGB(1) or VideoRGB(2);
  O_HSYNC   <= not HSync;
  O_VSYNC   <= not VSync;


end;