-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity BALLY_CHECK is
  port (
    CLK         : in    std_logic;
    ENA         : in    std_logic;
    ADDR        : in    std_logic_vector(10 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of BALLY_CHECK is

  function romgen_str2bv (str : string) return bit_vector is
    variable result : bit_vector (str'length*4-1 downto 0);
  begin
    for i in 0 to str'length-1 loop
      case str(str'high-i) is
        when '0'       => result(i*4+3 downto i*4) := x"0";
        when '1'       => result(i*4+3 downto i*4) := x"1";
        when '2'       => result(i*4+3 downto i*4) := x"2";
        when '3'       => result(i*4+3 downto i*4) := x"3";
        when '4'       => result(i*4+3 downto i*4) := x"4";
        when '5'       => result(i*4+3 downto i*4) := x"5";
        when '6'       => result(i*4+3 downto i*4) := x"6";
        when '7'       => result(i*4+3 downto i*4) := x"7";
        when '8'       => result(i*4+3 downto i*4) := x"8";
        when '9'       => result(i*4+3 downto i*4) := x"9";
        when 'A'       => result(i*4+3 downto i*4) := x"A";
        when 'B'       => result(i*4+3 downto i*4) := x"B";
        when 'C'       => result(i*4+3 downto i*4) := x"C";
        when 'D'       => result(i*4+3 downto i*4) := x"D";
        when 'E'       => result(i*4+3 downto i*4) := x"E";
        when 'F'       => result(i*4+3 downto i*4) := x"F";
        when others    => null;
      end case;
    end loop;
    return result;
  end romgen_str2bv;

  attribute INITP_00 : string;
  attribute INITP_01 : string;
  attribute INITP_02 : string;
  attribute INITP_03 : string;
  attribute INITP_04 : string;
  attribute INITP_05 : string;
  attribute INITP_06 : string;
  attribute INITP_07 : string;

  attribute INIT_00 : string;
  attribute INIT_01 : string;
  attribute INIT_02 : string;
  attribute INIT_03 : string;
  attribute INIT_04 : string;
  attribute INIT_05 : string;
  attribute INIT_06 : string;
  attribute INIT_07 : string;
  attribute INIT_08 : string;
  attribute INIT_09 : string;
  attribute INIT_0A : string;
  attribute INIT_0B : string;
  attribute INIT_0C : string;
  attribute INIT_0D : string;
  attribute INIT_0E : string;
  attribute INIT_0F : string;
  attribute INIT_10 : string;
  attribute INIT_11 : string;
  attribute INIT_12 : string;
  attribute INIT_13 : string;
  attribute INIT_14 : string;
  attribute INIT_15 : string;
  attribute INIT_16 : string;
  attribute INIT_17 : string;
  attribute INIT_18 : string;
  attribute INIT_19 : string;
  attribute INIT_1A : string;
  attribute INIT_1B : string;
  attribute INIT_1C : string;
  attribute INIT_1D : string;
  attribute INIT_1E : string;
  attribute INIT_1F : string;
  attribute INIT_20 : string;
  attribute INIT_21 : string;
  attribute INIT_22 : string;
  attribute INIT_23 : string;
  attribute INIT_24 : string;
  attribute INIT_25 : string;
  attribute INIT_26 : string;
  attribute INIT_27 : string;
  attribute INIT_28 : string;
  attribute INIT_29 : string;
  attribute INIT_2A : string;
  attribute INIT_2B : string;
  attribute INIT_2C : string;
  attribute INIT_2D : string;
  attribute INIT_2E : string;
  attribute INIT_2F : string;
  attribute INIT_30 : string;
  attribute INIT_31 : string;
  attribute INIT_32 : string;
  attribute INIT_33 : string;
  attribute INIT_34 : string;
  attribute INIT_35 : string;
  attribute INIT_36 : string;
  attribute INIT_37 : string;
  attribute INIT_38 : string;
  attribute INIT_39 : string;
  attribute INIT_3A : string;
  attribute INIT_3B : string;
  attribute INIT_3C : string;
  attribute INIT_3D : string;
  attribute INIT_3E : string;
  attribute INIT_3F : string;

  component RAMB16_S9
    --pragma translate_off
    generic (
      INITP_00 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_01 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_02 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_03 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_04 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_05 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_06 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INITP_07 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";

      INIT_00 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_01 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_02 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_03 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_04 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_05 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_06 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_07 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_08 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_09 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_0F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_10 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_11 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_12 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_13 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_14 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_15 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_16 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_17 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_18 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_19 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_1F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_20 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_21 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_22 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_23 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_24 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_25 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_26 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_27 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_28 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_29 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_2F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_30 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_31 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_32 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_33 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_34 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_35 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_36 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_37 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_38 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_39 : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3A : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3B : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3C : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3D : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3E : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000";
      INIT_3F : bit_vector (255 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000000"
      );
    --pragma translate_on
    port (
      DO    : out std_logic_vector (7 downto 0);
      DOP   : out std_logic_vector (0 downto 0);
      ADDR  : in  std_logic_vector (10 downto 0);
      CLK   : in  std_logic;
      DI    : in  std_logic_vector (7 downto 0);
      DIP   : in  std_logic_vector (0 downto 0);
      EN    : in  std_logic;
      SSR   : in  std_logic;
      WE    : in  std_logic 
      );
  end component;

  signal rom_addr : std_logic_vector(10 downto 0);

begin

  p_addr : process(ADDR)
  begin
     rom_addr <= (others => '0');
     rom_addr(10 downto 0) <= ADDR;
  end process;

  rom0 : if true generate
    attribute INIT_00 of inst : label is "A716DB2920A715DB08F3201627772728FFAA55002F0F0F2FC98787878720ADC3";
    attribute INIT_01 of inst : label is "264FCA02FE25D9CA01FE27BACA02FE2627CA01FE3628A714DB0F20A717DB3020";
    attribute INIT_02 of inst : label is "0FE679D92673CA02FE25EACA01FE10182748CA02FE2611CA01FE1C18182810FE";
    attribute INIT_03 of inst : label is "0118A03E0520A7780918B13E042084FE79112043CB001640203CFE7A14D9D94F";
    attribute INIT_04 of inst : label is "4706C6780420A0FE2003CD7D2C002618203CFE7C24001E20203CFE7B1CFFD3AF";
    attribute INIT_05 of inst : label is "08D3003EFFD3AA3ED96F675F57810E47AFD9F3C9FB08D96F47AF032099FE7804";
    attribute INIT_06 of inst : label is "C320E221FD6C1823EF21011EF318092818FE790C0820A778ED140EAF0AD3C83E";
    attribute INIT_07 of inst : label is "0116FB5EED0FD3AF0DD37D47ED7C2014210ED3083E4FC8314F00504E04182164";
    attribute INIT_08 of inst : label is "0021200001FBD9800E301823EF21FF0E021ED90A20A77B0E20A77AD9F325CFCD";
    attribute INIT_09 of inst : label is "4F08D67C031EE718122828FE7C214AC30A20A4FE7AF72005FA200D235786AF00";
    attribute INIT_0A of inst : label is "68180618215E21FDFB4F00504E04181318215121FDF323E6C3214A21A00E0220";
    attribute INIT_0B of inst : label is "EE2003BEFD7C234B18217921DD0628A87E70046EFD0566FD0106000E40004F3F";
    attribute INIT_0C of inst : label is "FD7C232718218021DDE928AE772F783318219121DD0628A87E162802BEFD7C2B";
    attribute INIT_0D of inst : label is "21041EE9FD0220A779B13020CBEA1877AF151821AF21DD0628AE2F780F2803BE";
    attribute INIT_0E of inst : label is "FD68780077FD6F67AF0CD37901064FAF481021DD081021FDE9DD4FB14F1821C8";
    attribute INIT_0F of inst : label is "20BC017EDD1320BD007EDDF5203D1CCB1DCB1CCB1DCB0B28A7790177FDAF0077";
    attribute INIT_10 of inst : label is "0E224A214810110CD3403E3318221521051E0718C62004FE4F3C79CF3010CB0D";
    attribute INIT_11 of inst : label is "1A18F23039CB230720BE1A0077FD2F7919CBF33021CB231A20BE1A0077FD7901";
    attribute INIT_12 of inst : label is "4FAF0CD3083EBF7FEFDFFBF7FEFD02010804201080404718225A21071E4F2F79";
    attribute INIT_13 of inst : label is "C67AEA10231120BA017EDD1720BA007EDD0177FD0077FD7E040619D3200C2157";
    attribute INIT_14 of inst : label is "FE1C2801FE22E3CD22CECD103E3818229321121E0718DA2014FE4F05C6795755";
    attribute INIT_15 of inst : label is "22A321081E0218101E233AC3122802FE122801FE22E3CD2C22CECD203E142802";
    attribute INIT_16 of inst : label is "C9013EC904066F4F5F57AF01042108DB0CD323E6C3233A21111E0218091E0918";
    attribute INIT_17 of inst : label is "DB0728A779E22000BEDDA97A0218B17A0420BDAF2333CD2333CD2333CDC9023E";
    attribute INIT_18 of inst : label is "20A77B14CBC83024CB24CB3BCB040001D3104F8479D520B908DB0518DC20BB08";
    attribute INIT_19 of inst : label is "0FDB0EDBFF06C90071FD0072DDC9B130881E0400015755C67A3BCB0218881E04";
    attribute INIT_1A of inst : label is "790C7120FFFE78ED1C0E17DB16DB15DB14DBF42014FE790C23C8C2A778ED100E";
    attribute INIT_1B of inst : label is "D3143E07D303D306D302D305D301D304D300D37808D3003EFF06D610F42020FE";
    attribute INIT_1C of inst : label is "14D316D317D3FF3EB3ED180E080623D621B3ED0B0E080623DE21500AD3C83E09";
    attribute INIT_1D of inst : label is "A7FE18FBD9082084FE790C0A287FCB79D9F3BA104215D313D312D311D310D37A";
    attribute INIT_1E of inst : label is "92DBF5F5FDFF003444481018236821141E1718234E21131E211BC3FBD90C0120";
    attribute INIT_1F of inst : label is "3E311823FF21FFD379391823F721FFD37B5028A70FE6D979D9F3004992DB0049";
    attribute INIT_20 of inst : label is "1018FFD3A03E0220A7242021D978D91F18241121FFD3DE3E2818240821FFD3CB";
    attribute INIT_21 of inst : label is "FBE9F42015F9203DFE10FF06FF3E021623EF21FFD3AA3E0718242921FFD3AA3E";
    attribute INIT_22 of inst : label is "4554495257005244444120444145520058454820544749442D342052544E45E9";
    attribute INIT_23 of inst : label is "0054524F5020444145520058454820544749442D322052544E45005244444120";
    attribute INIT_24 of inst : label is "544749442D322052544E45005244444120545254530054524F50204554495257";
    attribute INIT_25 of inst : label is "002A2A2A2A002A2A004554495257204F54204554594200415441440058454820";
    attribute INIT_26 of inst : label is "36313D35313D34313D33313D32313D31313D30312020202020203D46303D4530";
    attribute INIT_27 of inst : label is "AF004E5552204F5420224F47223D46313D45313D44313D43312020203D37313D";
    attribute INIT_28 of inst : label is "35FFC924410C280435FFC9000FB040001BFF03D302D301D30F3E09D300D304D3";
    attribute INIT_29 of inst : label is "DD0C0EC924AA0C320435FF24950C280435FFC924660C280435FFC924510C3204";
    attribute INIT_2A of inst : label is "78F82013FE200843FF4FEC32FF3EE5D5C930C607C6254DFA0AFEC932FF020D21";
    attribute INIT_2B of inst : label is "35FF071824B80C464835FF0920A7F5C9D1E12546CD47256EF214FEAF012010FE";
    attribute INIT_2C of inst : label is "50CD672003CD78253DCD464811E22815FE3E2818FE2550CD00002124BB0C4648";
    attribute INIT_2D of inst : label is "6F2003CD78253DCDC62815FE2550CDF5C90120A7F167B07C253DCDD02815FE25";
    attribute INIT_2E of inst : label is "CD2516CD24FFCDC9F9203DFE10FF06FF3EC9F16FB07D253DCDB72815FE2550CD";
    attribute INIT_2F of inst : label is "16CD24FFCD25CFCDFFD37CE52571CDAF252ECD24FFCDFD187E2571CD013E251E";
    attribute INIT_30 of inst : label is "CDAF24760C320435FF2526CD24FFCDFD1870C12571CD013E245B0C320435FF25";
    attribute INIT_31 of inst : label is "CD25CFCDFFD37CE52571CDAF24800C320435FF2526CD24FFCDFC1878ED4C2571";
    attribute INIT_32 of inst : label is "25CFCDFFD37CE52571CDAF252ECD24FFCDFC1861ED48C12571CDAF252ECD24FF";
    attribute INIT_33 of inst : label is "2126FBCD0A041124C02124FFCDFC187E70C12571CD013E251ECD2516CD24FFCD";
    attribute INIT_34 of inst : label is "11CD321C1110DBFB0ED3033E0DD37D47ED7C20102108AF0826FBCD00501124D8";
    attribute INIT_35 of inst : label is "11CD00681114DB2711CD501C1113DB2711CD461C1112DB2711CD3C1C1111DB27";
    attribute INIT_36 of inst : label is "11CD3268111CDB2711CD1E681117DB2711CD14681116DB2711CD0A681115DB27";
    attribute INIT_37 of inst : label is "3DCD7E03069E182711CD5068111FDB2711CD4668111EDB2711CD3C68111DDB27";
    attribute INIT_38 of inst : label is "E67C253DCD2546CD0F0F0F0FF0E667C9EB205AFE570AC67A5F18D67BF9102325";
    attribute INIT_39 of inst : label is "CD141C1108D60FDB2711CD0A1C113FCB0EDB081728A708F3C9253DCD2546CD0F";
    attribute INIT_3A of inst : label is "ED7C201221B0ED0FDC01400021B0ED00140127A621400011FA18083CC9FB2711";
    attribute INIT_3B of inst : label is "02D33C01D33C00D3F376FB59ED043E500021200011F80F0109D3143E0DD37D47";
    attribute INIT_3C of inst : label is "043E20001127A0C2151C1C1C1C1C1C09C607D33C06D33C05D33C04D3A003D33C";
    attribute INIT_3D of inst : label is "2516CD24FFCDFFFFFFFFFFAAAAAAAAAA5555555555000000000076FBE1DD59ED";
    attribute INIT_3E of inst : label is "0C320435FF24950C280435FF24FFCD25CFCDE5E52571CD013E248B0C320435FF";
    attribute INIT_3F of inst : label is "37EA18D513127CD1E9E1E1032018FE782571CDAF25CFCD24F30C5A0435FF24A5";
  begin
  inst : RAMB16_S9
      --pragma translate_off
      generic map (
        INITP_00 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_01 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_02 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_03 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_04 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_05 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_06 => x"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_07 => x"0000000000000000000000000000000000000000000000000000000000000000",

        INIT_00 => romgen_str2bv(inst'INIT_00),
        INIT_01 => romgen_str2bv(inst'INIT_01),
        INIT_02 => romgen_str2bv(inst'INIT_02),
        INIT_03 => romgen_str2bv(inst'INIT_03),
        INIT_04 => romgen_str2bv(inst'INIT_04),
        INIT_05 => romgen_str2bv(inst'INIT_05),
        INIT_06 => romgen_str2bv(inst'INIT_06),
        INIT_07 => romgen_str2bv(inst'INIT_07),
        INIT_08 => romgen_str2bv(inst'INIT_08),
        INIT_09 => romgen_str2bv(inst'INIT_09),
        INIT_0A => romgen_str2bv(inst'INIT_0A),
        INIT_0B => romgen_str2bv(inst'INIT_0B),
        INIT_0C => romgen_str2bv(inst'INIT_0C),
        INIT_0D => romgen_str2bv(inst'INIT_0D),
        INIT_0E => romgen_str2bv(inst'INIT_0E),
        INIT_0F => romgen_str2bv(inst'INIT_0F),
        INIT_10 => romgen_str2bv(inst'INIT_10),
        INIT_11 => romgen_str2bv(inst'INIT_11),
        INIT_12 => romgen_str2bv(inst'INIT_12),
        INIT_13 => romgen_str2bv(inst'INIT_13),
        INIT_14 => romgen_str2bv(inst'INIT_14),
        INIT_15 => romgen_str2bv(inst'INIT_15),
        INIT_16 => romgen_str2bv(inst'INIT_16),
        INIT_17 => romgen_str2bv(inst'INIT_17),
        INIT_18 => romgen_str2bv(inst'INIT_18),
        INIT_19 => romgen_str2bv(inst'INIT_19),
        INIT_1A => romgen_str2bv(inst'INIT_1A),
        INIT_1B => romgen_str2bv(inst'INIT_1B),
        INIT_1C => romgen_str2bv(inst'INIT_1C),
        INIT_1D => romgen_str2bv(inst'INIT_1D),
        INIT_1E => romgen_str2bv(inst'INIT_1E),
        INIT_1F => romgen_str2bv(inst'INIT_1F),
        INIT_20 => romgen_str2bv(inst'INIT_20),
        INIT_21 => romgen_str2bv(inst'INIT_21),
        INIT_22 => romgen_str2bv(inst'INIT_22),
        INIT_23 => romgen_str2bv(inst'INIT_23),
        INIT_24 => romgen_str2bv(inst'INIT_24),
        INIT_25 => romgen_str2bv(inst'INIT_25),
        INIT_26 => romgen_str2bv(inst'INIT_26),
        INIT_27 => romgen_str2bv(inst'INIT_27),
        INIT_28 => romgen_str2bv(inst'INIT_28),
        INIT_29 => romgen_str2bv(inst'INIT_29),
        INIT_2A => romgen_str2bv(inst'INIT_2A),
        INIT_2B => romgen_str2bv(inst'INIT_2B),
        INIT_2C => romgen_str2bv(inst'INIT_2C),
        INIT_2D => romgen_str2bv(inst'INIT_2D),
        INIT_2E => romgen_str2bv(inst'INIT_2E),
        INIT_2F => romgen_str2bv(inst'INIT_2F),
        INIT_30 => romgen_str2bv(inst'INIT_30),
        INIT_31 => romgen_str2bv(inst'INIT_31),
        INIT_32 => romgen_str2bv(inst'INIT_32),
        INIT_33 => romgen_str2bv(inst'INIT_33),
        INIT_34 => romgen_str2bv(inst'INIT_34),
        INIT_35 => romgen_str2bv(inst'INIT_35),
        INIT_36 => romgen_str2bv(inst'INIT_36),
        INIT_37 => romgen_str2bv(inst'INIT_37),
        INIT_38 => romgen_str2bv(inst'INIT_38),
        INIT_39 => romgen_str2bv(inst'INIT_39),
        INIT_3A => romgen_str2bv(inst'INIT_3A),
        INIT_3B => romgen_str2bv(inst'INIT_3B),
        INIT_3C => romgen_str2bv(inst'INIT_3C),
        INIT_3D => romgen_str2bv(inst'INIT_3D),
        INIT_3E => romgen_str2bv(inst'INIT_3E),
        INIT_3F => romgen_str2bv(inst'INIT_3F)
        )
      --pragma translate_on
      port map (
        DO   => DATA(7 downto 0),
        DOP  => open,
        ADDR => rom_addr,
        CLK  => CLK,
        DI   => "00000000",
        DIP  => "0",
        EN   => ENA,
        SSR  => '0',
        WE   => '0'
        );
  end generate;
end RTL;
