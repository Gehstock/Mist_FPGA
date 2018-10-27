--
-- A simulation model of PSG hardware
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: passionoric.free.fr
--
-- Email seilebost@free.fr
--
--
-- Revision list
--
-- v0.42 2002/01/03 : It seems ok
-- v0.43 2009/01/21 : bus bidirectionnel => bus unidirectionnel
-- v0.44 2009/10/11 : Reset asynchrone pour le process U_TRAIT
-- v0.45 2010/01/03 : Ajout d'une horloge pour le DAC
-- v0.46 2010/01/06 : Modification du générateur de fréquence
--                    pour ajouter la division par 16 et par 256
-- v0.50 2010/01/19 : Reorganisation du code
--
--  AY3819X.vhd
--
--  Top entity of AY3819X.
--
--        Copyright (C)2001-2010 SEILEBOST
--                   All rights reserved.
--
-- $Id: AY3819.vhd, v0.50 2010/01/19 00:00:00 SEILEBOST $
--
-- TODO :
--   Many verification !!
-- Remark :

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
--use UNISIM.Vcomponents.ALL; -- for IOBUF and OBUF

entity AY3819X is
    Port ( DATA_IN     : in     std_logic_vector(7 downto 0);
	        DATA_OUT    : out    std_logic_vector(7 downto 0);
			  O_DATA_OE_L : out    std_logic; 
           RESET       : in     std_logic;
           CLOCK       : in     std_logic;
			  CLOCK_DAC   : in     std_logic; -- 24 MHz pour le DAC
           BDIR        : in     std_logic;
           BC1         : in     std_logic;
           BC2         : in     std_logic;
           IOA         : inout  std_logic_vector(7 downto 0);
           IOB         : inout  std_logic_vector(7 downto 0);
           AnalogA     : out    std_logic;
           AnalogB     : out    std_logic;
           AnalogC     : out    std_logic );
end AY3819X;


architecture Behavioral of AY3819X is

 SIGNAL BUS_CS : std_logic_vector(15 downto 0); -- Select the different module when Read / Write Register

 -- Create register 
 SIGNAL R0    : std_logic_vector(7  downto 0);  -- Tone generator frequency Fine Tune channel A
 SIGNAL R1    : std_logic_vector(7  downto 0);  -- Tone generator frequency Coarse Tune channel A
 SIGNAL R2    : std_logic_vector(7  downto 0);  -- Tone generator frequency Fine Tune  channel B
 SIGNAL R3    : std_logic_vector(7  downto 0);  -- Tone generator frequency Coarse Tune channel B
 SIGNAL R4    : std_logic_vector(7  downto 0);  -- Tone generator frequency Fine Tune channel C
 SIGNAL R5    : std_logic_vector(7  downto 0);  -- Tone generator frequency Coarse Tune channel B
 SIGNAL R6    : std_logic_vector(7  downto 0);  -- Noise generator frequency
 SIGNAL R7    : std_logic_vector(7  downto 0);  -- Mixer Control I/O Enable
 SIGNAL R8    : std_logic_vector(7  downto 0);  -- Amplitude control channel A
 SIGNAL R9    : std_logic_vector(7  downto 0);  -- Amplitude control channel B
 SIGNAL R10   : std_logic_vector(7  downto 0);  -- Amplitude control channel C
 SIGNAL R11   : std_logic_vector(7  downto 0);  -- Envelope period control fine tune 
 SIGNAL R12   : std_logic_vector(7  downto 0);  -- Envelope period control coarse tune
 SIGNAL R13   : std_logic_vector(7  downto 0);  -- Envelope shape/cycle control

 SIGNAL REG_ADDR     : std_logic_vector(3 downto 0); -- Keep the number of register addressed

 SIGNAL WR           : std_logic; -- WRITE (FLAG)

 SIGNAL CLK_A        : std_logic; -- CLOCK TONE VOICE A
 SIGNAL CLK_B        : std_logic; -- CLOCK TONE VOICE B
 SIGNAL CLK_C        : std_logic; -- CLOCK TONE VOICE C 
 SIGNAL CLK_TONE_A   : std_logic; -- CLOCK TONE VOICE A +/- CLOCK NOISE
 SIGNAL CLK_TONE_B   : std_logic; -- CLOCK TONE VOICE B +/- CLOCK NOISE
 SIGNAL CLK_TONE_C   : std_logic; -- CLOCK TONE VOICE C +/- CLOCK NOISE
 SIGNAL CLK_E        : std_logic; -- CLOCK Envelope Generator
 SIGNAL CLK_N        : std_logic; -- CLOCK FROM NOISE GENERATOR
 SIGNAL CLK_16       : std_logic; -- CLOCK (=1 MHz) / 16  pour le "tone"
 SIGNAL CLK_256      : std_logic; -- CLOCK (=1 MHz) / 256 pour l'enveloppe

 SIGNAL OUT_AMPL_E   : std_logic_vector(3 downto 0); -- Amplitude of signal from Envelope generator

 SIGNAL IAnalogA     : std_logic; -- FOR IOPAD, exit from DAC VOICE A
 SIGNAL IAnalogB     : std_logic; -- FOR IOPAD, exit from DAC VOICE B
 SIGNAL IAnalogC     : std_logic; -- FOR IOPAD, exit from DAC VOICE C
 
 SIGNAL RST_ENV      : std_logic; -- FOR RESET THE VALUE OF ENVELOPPE

 COMPONENT TONE_GENERATOR  PORT ( CLK         : in     std_logic;
                                  --CLK_TONE    : in     std_logic;
                                  RST         : in     std_logic; 
                                  WR          : in     std_logic;
                                  --CS_COARSE   : in     std_logic;
                                  --CS_FINE     : in     std_logic;
                                  DATA_COARSE : in     std_logic_vector(7 downto 0);
                                  DATA_FINE   : in     std_logic_vector(7 downto 0);
                                  OUT_TONE    : inout  std_logic );
 END COMPONENT;

 COMPONENT NOISE_GENERATOR  PORT ( CLK          : in     std_logic;
                                   RST          : in     std_logic;
                                   --WR           : in     std_logic;
                                   --CS           : in     std_logic;
                                   DATA         : in     std_logic_vector(4 downto 0);
                                   CLK_N        : out    std_logic );
 END COMPONENT;

 COMPONENT GEN_CLK  PORT ( CLK      : in  std_logic;
                           RST      : in  std_logic;
                           CLK_16   : out std_logic;
                           CLK_256  : out std_logic);
 END COMPONENT;

-- COMPONENT MIXER    PORT ( CLK          : in     std_logic;
 --                          CS           : in     std_logic;
 --                          RST          : in     std_logic;
 --                          WR           : in     std_logic;
 --                          IN_A         : in     std_logic;
  --                         IN_B         : in     std_logic;
  --                         IN_C         : in     std_logic;
  --                         IN_NOISE     : in     std_logic;
  --                         DATA         : in     std_logic_vector(5 downto 0);
  --                         OUT_A        : out    std_logic;
  --                         OUT_B        : out    std_logic;
  --                         OUT_C        : out    std_logic );                           
 --END COMPONENT; 

 COMPONENT GEN_ENV  PORT ( CLK_ENV      : in     std_logic;
                           DATA         : in     std_logic_vector(3 downto 0);
                           RST_ENV      : in     std_logic;
                           WR           : in     std_logic;                                    
                           --CS           : in     std_logic;
                           OUT_DATA     : inout  std_logic_vector(3 downto 0));
 END COMPONENT;

 COMPONENT MANAGE_AMPLITUDE  PORT ( CLK           : in   std_logic;
                                    CLK_DAC       : in   std_logic;
                                    CLK_TONE      : in   std_logic;
												CLK_NOISE     : in   std_logic;
                                    RST           : in   std_logic;
                                    CLK_TONE_ENA  : in   std_logic;
			                           CLK_NOISE_ENA : in   std_logic;
                                    AMPLITUDE     : in   std_logic_vector(4 downto 0);
                                    AMPLITUDE_E   : in   std_logic_vector(3 downto 0);
                                    OUT_DAC       : out  std_logic );
 END COMPONENT;
 
 --COMPONENT IOBUF_F_12 port (   O : out   std_logic;
 --                             IO : inout std_logic;
 --                              I : in    std_logic;
 --                              T : in    std_logic  );
 --END COMPONENT;

 --COMPONENT OBUF_F_12 port (   O : out   std_logic;
 --                            IO : inout std_logic;
 --                             I : in    std_logic;
 --                             T : in    std_logic  );
 --END COMPONENT;

 --component OBUF_F_24
 --port (
 --  I : in std_logic;
 --  O : out std_logic );
 --end component;

BEGIN

U_TRAIT : PROCESS(CLOCK, RESET, BC1, BC2, BDIR, REG_ADDR, DATA_IN)
BEGIN
 
  if (RESET = '1') then
     WR       <= '0';
     R0       <= "00000000"; 
     R1       <= "00000000"; 
     R2       <= "00000000"; 
     R3       <= "00000000"; 
     R4       <= "00000000"; 
     R5       <= "00000000"; 
     R6       <= "00000000"; 
     R7       <= "00000000"; 
     R8       <= "00000000"; 
     R9       <= "00000000"; 
     R10      <= "00000000";      
     R11      <= "00000000"; 
     R12      <= "00000000"; 
     R13      <= "00000000"; 
     IOA      <= "00000000";
     IOB      <= "00000000";
     DATA_OUT <= "00000000";
	  RST_ENV  <= '1';
  else
   if rising_edge(CLOCK) then -- edge clock
      -- READ FROM REGISTER
		RST_ENV <= '0';
      if ((BDIR = '0') and (BC2 = '1') and (BC1 = '1')) then 
        CASE REG_ADDR is
           WHEN "0000" => DATA_OUT        <= R0;
           WHEN "0001" => DATA_OUT        <= R1;
           WHEN "0010" => DATA_OUT        <= R2;
           WHEN "0011" => DATA_OUT        <= R3;
           WHEN "0100" => DATA_OUT        <= R4;
           WHEN "0101" => DATA_OUT        <= R5;
           WHEN "0110" => DATA_OUT        <= R6;
           WHEN "0111" => DATA_OUT        <= R7;
           WHEN "1000" => DATA_OUT        <= R8;
           WHEN "1001" => DATA_OUT        <= R9;
           WHEN "1010" => DATA_OUT        <= R10;
           WHEN "1011" => DATA_OUT        <= R11;
           WHEN "1100" => DATA_OUT        <= R12;
           WHEN "1101" => DATA_OUT        <= R13;
           WHEN "1110" => DATA_OUT        <= IOA;
           WHEN "1111" => DATA_OUT        <= IOB;
           WHEN OTHERS => NULL;             
        END CASE;
        WR <= '0';
      else
        DATA_OUT  <= "00000000";
        WR <= '0';
      end if;
   end if;
  end if;
  
  -- LATCH WHAT REGISTER
  if ((BDIR = '1') and (BC2 = '1') and (BC1 = '1')) then
    REG_ADDR <= DATA_IN(3 downto 0);
    WR       <= '0';
  end if;

  -- WRITE TO REGISTER OR IOA/IOB
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0')) then WR <= '1'; end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0000") ) then R0  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0001") ) then R1  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0010") ) then R2  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0011") ) then R3  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0100") ) then R4  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0101") ) then R5  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0110") ) then R6  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "0111") ) then R7  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1000") ) then R8  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1001") ) then R9  <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1010") ) then R10 <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1011") ) then R11 <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1100") ) then R12 <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1101") ) then R13 <= DATA_IN; RST_ENV <= '1'; end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1110") ) then IOA <= DATA_IN;end if;
  if ( (BDIR = '1') and (BC2 = '1') and (BC1 = '0') and (REG_ADDR = "1111") ) then IOB <= DATA_IN;end if;

end PROCESS;

URA: PROCESS(REG_ADDR, RESET)
BEGIN
  if (RESET = '1') then
     BUS_CS <= "0000000000000000";
  else
     case REG_ADDR is
           when "0000" => BUS_CS <= "0000000000000001";
           when "0001" => BUS_CS <= "0000000000000010";
           when "0010" => BUS_CS <= "0000000000000100";
           when "0011" => BUS_CS <= "0000000000001000";
           when "0100" => BUS_CS <= "0000000000010000";
           when "0101" => BUS_CS <= "0000000000100000";
           when "0110" => BUS_CS <= "0000000001000000";
           when "0111" => BUS_CS <= "0000000010000000";
           when "1000" => BUS_CS <= "0000000100000000";
           when "1001" => BUS_CS <= "0000001000000000";
           when "1010" => BUS_CS <= "0000010000000000";
           when "1011" => BUS_CS <= "0000100000000000";
           when "1100" => BUS_CS <= "0001000000000000";
           when "1101" => BUS_CS <= "0010000000000000";
           when "1110" => BUS_CS <= "0100000000000000";
           when "1111" => BUS_CS <= "1000000000000000";
           when others => NULL;
      end case;
  end if;
END PROCESS;


-- Instantiation of sub_level modules
UCLK : GEN_CLK PORT MAP( CLK      => CLOCK, 
                         RST      => RESET,
                         CLK_16   => CLK_16,
								 CLK_256  => CLK_256
                         );
								 
UTONE_A : TONE_GENERATOR PORT MAP( CLK         => CLOCK,
                                   --CLK_TONE    => CLK_16,
                                   RST         => RESET,
                                   WR          => WR,
                                   --CS_COARSE   => BUS_CS(1),
                                   --CS_FINE     => BUS_CS(0),
                                   DATA_COARSE => R1,
                                   DATA_FINE   => R0,
                                   OUT_TONE    => CLK_A);

UTONE_B : TONE_GENERATOR PORT MAP( CLK         => CLOCK,
                                   --CLK_TONE    => CLK_16,
                                   RST         => RESET,
                                   WR          => WR,
                                   --CS_COARSE   => BUS_CS(3),
                                   --CS_FINE     => BUS_CS(2),
                                   DATA_COARSE => R3,
                                   DATA_FINE   => R2,
                                   OUT_TONE    => CLK_B);

UTONE_C : TONE_GENERATOR PORT MAP( CLK         => CLOCK,
                                   --CLK_TONE    => CLK_16,
                                   RST         => RESET,
                                   WR          => WR,
                                   --CS_COARSE   => BUS_CS(5),
                                   --CS_FINE     => BUS_CS(4),
                                   DATA_COARSE => R5,
                                   DATA_FINE   => R4,
                                   OUT_TONE    => CLK_C);

UTONE_NOISE : NOISE_GENERATOR PORT MAP( CLK           => CLK_16,
                                        RST           => RESET,
                                        --WR            => WR,
                                        --CS            => BUS_CS(6),
                                        DATA          => R6(4 downto 0),
                                        CLK_N         => CLK_N);

UTONE_ENV : TONE_GENERATOR PORT MAP( CLK           => CLK_16,
                                     --CLK           => CLOCK,
                                     --CLK_TONE      => CLK_256,
                                     RST           => RESET,
                                     WR            => WR,
                                     --CS_COARSE     => BUS_CS(12), 
                                     --CS_FINE       => BUS_CS(11),
                                     DATA_COARSE   => R12,
                                     DATA_FINE     => R11,
                                     OUT_TONE      => CLK_E);

--UMIXER : MIXER PORT MAP ( CLK          => CLOCK,
--                          CS           => BUS_CS(7),
--                          RST          => RESET,
--                          WR           => WR,
--                         IN_A         => CLK_A,
--                          IN_B         => CLK_B,
--                          IN_C         => CLK_C,
--                         IN_NOISE     => CLK_N,
--                          DATA         => R7(5 downto 0),
--                          OUT_A        => CLK_TONE_A,
--                          OUT_B        => CLK_TONE_B,
--                          OUT_C        => CLK_TONE_C);

UGenEnv : GEN_ENV PORT MAP( CLK_ENV      => CLK_E,
                            --CS           => BUS_CS(13),                             
                            DATA         => R13(3 downto 0),
                            RST_ENV      => RST_ENV,
                            WR           => WR,
                            OUT_DATA     => OUT_AMPL_E);

UManAmpA : MANAGE_AMPLITUDE PORT MAP ( CLK           => CLOCK,
                                       CLK_DAC       => CLOCK_DAC,
                                       CLK_TONE      => CLK_A, --CLK_TONE_A,
													CLK_NOISE     => CLK_N,
                                       RST           => RESET,
                                       CLK_TONE_ENA  => R7(0),
													CLK_NOISE_ENA => R7(3),
                                       AMPLITUDE     => R8(4 downto 0),
                                       AMPLITUDE_E   => OUT_AMPL_E(3 downto 0),
                                       OUT_DAC       => IAnalogA );                                       

UManAmpB : MANAGE_AMPLITUDE PORT MAP ( CLK           => CLOCK,
                                       CLK_DAC       => CLOCK_DAC,
                                       CLK_TONE      => CLK_B, --CLK_TONE_B,
													CLK_NOISE     => CLK_N,
                                       RST           => RESET,
                                       CLK_TONE_ENA  => R7(1),
													CLK_NOISE_ENA => R7(4),
                                       AMPLITUDE     => R9(4 downto 0),
                                       AMPLITUDE_E   => OUT_AMPL_E(3 downto 0),
                                       OUT_DAC       => IAnalogB );                                          

UManAmpC : MANAGE_AMPLITUDE PORT MAP ( CLK           => CLOCK,
                                       CLK_DAC       => CLOCK_DAC,
                                       CLK_TONE      => CLK_C, --CLK_TONE_C,
													CLK_NOISE     => CLK_N,
                                       RST           => RESET,
                                       CLK_TONE_ENA  => R7(2),
													CLK_NOISE_ENA => R7(5),
                                       AMPLITUDE     => R10(4 downto 0),
                                       AMPLITUDE_E   => OUT_AMPL_E(3 downto 0),
                                       OUT_DAC       => IAnalogC );      
                                  

--PAD_ANALOGA : OBUF_F_24 port map( I => IAnalogA, O => AnalogA);
--PAD_ANALOGB : OBUF_F_24 port map( I => IAnalogB, O => AnalogB);
--PAD_ANALOGC : OBUF_F_24 port map( I => IAnalogC, O => AnalogC);
AnalogA <= IAnalogA;
AnalogB <= IAnalogB;
AnalogC <= IAnalogC;

end Behavioral;
