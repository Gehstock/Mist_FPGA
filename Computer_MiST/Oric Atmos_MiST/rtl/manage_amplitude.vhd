--
--  MANAGE_AMPLITUDE.vhd
--
--  Manage the amplitude for each tone.
--
--        Copyright (C)2001-2010 SEILEBOST
--                   All rights reserved.
--
-- $Id: MANAGE_AMPLITUDE.vhd, v0.50 2010/01/19 00:00:00 SEILEBOST $
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MANAGE_AMPLITUDE is
    Port ( CLK           : in   std_logic; -- the system clock
           CLK_DAC       : in   std_logic; -- the clok of DAC
           CLK_TONE      : in   std_logic; -- the frequency of sound
			  CLK_NOISE     : in   std_logic; -- the noise
           RST           : in   std_logic; -- reset
			  CLK_TONE_ENA  : in   std_logic; -- enable tone
			  CLK_NOISE_ENA : in   std_logic; -- enable noise
           AMPLITUDE     : in   std_logic_vector(4 downto 0); -- value from register
           AMPLITUDE_E   : in   std_logic_vector(3 downto 0); -- value from envelope
           OUT_DAC       : out  std_logic );        
end MANAGE_AMPLITUDE;

architecture Behavioral of MANAGE_AMPLITUDE is

 signal AMPLITUDE_TMP : std_logic_vector(3 downto 0);
 signal IN_DATA       : std_logic_vector(7 downto 0);

 COMPONENT DAC is Port ( CLK_DAC : in std_logic;
                         RST     : in std_logic;
                         IN_DAC  : in std_logic_vector(7 downto 0);
                         OUT_DAC : out std_logic );
 END COMPONENT;


begin
 
-- Convertisseur numérique analogique : méthode sigma delta
U_DAC : DAC PORT MAP ( CLK_DAC => CLK_DAC,
                       RST     => RST,
                       IN_DAC  => IN_DATA,
                       OUT_DAC => OUT_DAC);

-- Calcule de l'amplitude à générer par le DAC
  PROCESS(CLK, RST, AMPLITUDE_TMP, AMPLITUDE_E)
  variable mix_tone_noise : std_logic;
  BEGIN
       if (RST = '1') then  -- reset
          AMPLITUDE_TMP <= "0000";
          IN_DATA       <= "00000000";
       elsif (CLK'event and CLK = '1') then -- edge clock
		       -- Note that this means that if both tone and noise are disabled, the output */
	          -- is 1, not 0, and can be modulated changing the volume. */
             mix_tone_noise := (CLK_TONE or CLK_TONE_ENA) AND (CLK_NOISE or CLK_NOISE_ENA);				 
             if (mix_tone_noise = '1') then
				    if (AMPLITUDE(4) = '0') then -- Utilisation de la valeur du registre
                   AMPLITUDE_TMP <= AMPLITUDE(3 downto 0);                
                else -- Utilisation de la valeur de l'enveloppe
					    AMPLITUDE_TMP <= AMPLITUDE_E;               
                end if;
             else
                 AMPLITUDE_TMP <= "0000";
             end if;
       
             -- Each amplitude has an 1.5 db step from previous amplitude
             CASE AMPLITUDE_TMP IS            
              when "0000" => IN_DATA <= "00000000"; -- 0        
              when "0001" => IN_DATA <= "00010110"; -- 22
              when "0010" => IN_DATA <= "00011010"; -- 26
              when "0011" => IN_DATA <= "00011111"; -- 31
              when "0100" => IN_DATA <= "00100101"; -- 37
              when "0101" => IN_DATA <= "00101100"; -- 44
              when "0110" => IN_DATA <= "00110100"; -- 52
              when "0111" => IN_DATA <= "00111110"; -- 62
              when "1000" => IN_DATA <= "01001010"; -- 74
              when "1001" => IN_DATA <= "01011000"; -- 88
              when "1010" => IN_DATA <= "01101001"; -- 105
              when "1011" => IN_DATA <= "01110101"; -- 125
              when "1100" => IN_DATA <= "10011001"; -- 149
              when "1101" => IN_DATA <= "10110001"; -- 177
              when "1110" => IN_DATA <= "11010010"; -- 210
              when "1111" => IN_DATA <= "11111111"; -- 255
              when OTHERS => NULL;
             END CASE;
       end if;		 

  END PROCESS;

end Behavioral;
