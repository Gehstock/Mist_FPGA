---------------------------------------------------------------------------------
-- bagman speech - Dar - Feb 2014
---------------------------------------------------------------------------------
-- Main job here is to provide a bit stream from the PROM to the 
-- lpc10_speech_synthetizer which return speech samples. 
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all,ieee.numeric_std.all;

entity bagman_speech is
port(
  hclkn        : in std_logic;
  adrCpu       : in std_logic_vector (2 downto 0);
  doCpu        : in std_logic;
  weSelSpeech  : in std_logic;
  Clk1MHz      : in std_logic;
  SpeechSample : out integer range -512 to 511
);

end bagman_speech;

architecture struct of bagman_speech is

signal StartSpeak        : std_logic := '1';
signal SelSpeech3Reg     : std_logic;
signal SpeechHasPriority : boolean;
signal Speaking          : std_logic;
signal SelSpeech   : std_logic_vector( 5 downto 0);
signal SelSpeechReg: std_logic_vector( 5 downto 0);
signal SpeechCntr  : std_logic_vector(11 downto 0);
signal SpeechData1 : std_logic_vector( 7 downto 0);
signal SpeechData2 : std_logic_vector( 7 downto 0);
signal SpeechByte  : std_logic_vector( 7 downto 0);
signal SpeechBit   : std_logic;
signal Cnt512kHz   : std_logic_vector( 3 downto 0);
signal Clk512kHz   : std_logic;

begin

with SelSpeechReg(5 downto 4) select
  SpeechByte <= SpeechData1 when "10",
  SpeechData2 when "01",
  "00000000"  when others;

with SelSpeechReg(2 downto 0) select
  SpeechBit <= 
    SpeechByte(7) when "000",
    SpeechByte(3) when "001",
    SpeechByte(5) when "010",
    SpeechByte(1) when "011",
    SpeechByte(6) when "100",
    SpeechByte(2) when "101",
    SpeechByte(4) when "110",
    SpeechByte(0) when "111",
    '0' when others;

process(hclkn)
begin
  if rising_edge(hclkn) then

    if weSelSpeech = '0' then
      case adrCpu(2 downto 0) is
        when "000" => SelSpeech(0) <= doCpu;
        when "001" => SelSpeech(1) <= doCpu;
        when "010" => SelSpeech(2) <= doCpu;
        when "011" => SelSpeech(3) <= doCpu;
        when "100" => SelSpeech(4) <= doCpu;
        when "101" => SelSpeech(5) <= doCpu;
        when others => NULL;
      end case;
    end if;
    
  end if;
end process;

process(Clk1MHz)
begin
 if rising_edge(Clk1MHz) then

    Clk512kHz <= not Clk512kHz;

  end if;
end process;

-- Les paroles du bagman sont prioritaires sur les sons d'ambiance
-- (Aïe Aïe Aïe, Ho hiss, Hop la, A moi le magot)
SpeechHasPriority <= 
 SelSpeech(5 downto 4) = "01"  and 
 ( SelSpeech(2 downto 0) = "010" or 
   SelSpeech(2 downto 0) = "100" or 
   SelSpeech(2 downto 0) = "110" or 
   SelSpeech(2 downto 0) = "111"
 );

process(Clk512kHz)
begin

  if falling_edge( Clk512kHz) then
    
    SelSpeech3Reg <=  SelSpeech(3);
    
    -- On déclenche un nouveau son si le precedent est terminé ou si le nouveau est prioritaire
    if (SelSpeech3Reg = '0') and (SelSpeech(3) = '1') and ((Speaking = '0') or SpeechHasPriority) then
      StartSpeak <= '0';
      SelSpeechReg <= SelSpeech;
    else
      StartSpeak <= '1';
    end if;
    
  end if;
end process;

LPC10_SpeechSynth : entity work.LPC10_Speech_Synthetizer
port map(
  Clk512kHz   => Clk512kHz,
  StartSpeak  => StartSpeak,
  RomData     => SpeechBit,
  RomAdr      => SpeechCntr,
  SampleData  => SpeechSample,
  Speaking    => Speaking
);

SpeechRom1 : entity work.bagman_speech1
port map(
  addr => SpeechCntr,
  clk   => not hclkn,
  data  => SpeechData1
);

SpeechRom2 : entity work.bagman_speech2
port map(
  addr => SpeechCntr,
  clk  => not hclkn,
  data => SpeechData2
);

end architecture;
