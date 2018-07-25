-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity BALLY_BIOS_1 is
  port (
    CLK         : in    std_logic;
    ENA         : in    std_logic;
    ADDR        : in    std_logic_vector(11 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of BALLY_BIOS_1 is

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

  component RAMB16_S4
    --pragma translate_off
    generic (
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
      DO    : out std_logic_vector (3 downto 0);
      ADDR  : in  std_logic_vector (11 downto 0);
      CLK   : in  std_logic;
      DI    : in  std_logic_vector (3 downto 0);
      EN    : in  std_logic;
      SSR   : in  std_logic;
      WE    : in  std_logic 
      );
  end component;

  signal rom_addr : std_logic_vector(11 downto 0);

begin

  p_addr : process(ADDR)
  begin
     rom_addr <= (others => '0');
     rom_addr(11 downto 0) <= ADDR;
  end process;

  rom0 : if true generate
    attribute INIT_00 of inst : label is "3F004E0B3C98F87F9028D0E000B0FE01FFFFFFFFFFFF752875289110010FF759";
    attribute INIT_01 of inst : label is "AD2AD980D0AD78FEBF4138EE9707B287EE21FFFFFEFF60FDF803E243F503116D";
    attribute INIT_02 of inst : label is "1311081A0E00132126543987402111009EE11508BFB1E3127D5ED1EA20010DB0";
    attribute INIT_03 of inst : label is "E4FF26D16F08980EB816402E88EFBBF2AD281E219EF1BD098B6E61001F28080E";
    attribute INIT_04 of inst : label is "B1BEE26FEEAB6E41E82E009EFFF0904326DE025E16D260DF8E029F816D38EF0B";
    attribute INIT_05 of inst : label is "2C71E8F6EB9E40BEFFF8F16F14F12F1B1815129B6E41EF1518BFE0A26DA815D0";
    attribute INIT_06 of inst : label is "811EA1005EFBF52AD206BA8BBBF8FB5E3989F87E38AEEEF1EA12AD580E126DE1";
    attribute INIT_07 of inst : label is "F0606B06F6787E32F0616287EE2157E381B3FDED1943FD33333989637370EE9C";
    attribute INIT_08 of inst : label is "EE41F32F94582E987E3418CEEE4127DE8100C8081F97B7F02EEE112A33EE0A12";
    attribute INIT_09 of inst : label is "F81E016E51181AE50DC000F81F8E48BE6388981C50D08F0081F8E587E387A01B";
    attribute INIT_0A of inst : label is "0A7FC6256FA0914F2419B892F21DF16FB6F08E284E7B60FB6FCE150E6FDEC0D9";
    attribute INIT_0B of inst : label is "6833D50F6EBC83FDEE309E9DD03FD6F3EAFF061B8FD7E9A8FDEE0AEF1D32DB00";
    attribute INIT_0C of inst : label is "00CF6BFF3128DFFC225DFF61FFFF777770269B17B03FD5B569B07DB1790610EE";
    attribute INIT_0D of inst : label is "FC23812F09104D09D0BD09D07D09E0AD5B000D87E7002F2B004F4B57990FF613";
    attribute INIT_0E of inst : label is "2A7F4AF224E285E482EF424E285EF3AFC242C7F2D1D43DF12701FA2F01F32381";
    attribute INIT_0F of inst : label is "1A06A5D514F0E4ED56D41144F66B12F586D7ED2F6EDDD56D4ED16A556BDA06FF";
    attribute INIT_10 of inst : label is "4F81F2F4EFC1065140DF3251F53E001FD467D0E068567D0E980F111D52D999F6";
    attribute INIT_11 of inst : label is "E8E6BD6BDF3236CF3A69D04A343B4394374354B168485F243FFD2F69D43D20D1";
    attribute INIT_12 of inst : label is "6D0ED90D018BF9031E539E330ED9D068B028F363ED6BDF3A98F69D6D3FB564B3";
    attribute INIT_13 of inst : label is "D56D37D17DC069D16D8869D1E869D386BD1ED6ED0E507800D11078F7F3066BD2";
    attribute INIT_14 of inst : label is "5557115E7017C191AF41106B0BF54035FD57DF6A47DF5A4F0E4114ED56D54D4E";
    attribute INIT_15 of inst : label is "810ED4019D001D4ED56D183333378D1113D881171F4F4110E154D4ED56D543A5";
    attribute INIT_16 of inst : label is "594F152D7999F61950688E6BD6BD9D4EE6BD5F414866BD9053D783B3501DD011";
    attribute INIT_17 of inst : label is "D96F2D1D364F3CE86D7ED9B1B409ED8F302FC27DFCA942855F216079E1F152D7";
    attribute INIT_18 of inst : label is "066BD3E883ECEE8CE281ED27D2ED300F6BD94F0E411154D54ED56D7ED3ED8E6B";
    attribute INIT_19 of inst : label is "7FFDF6FFF872787E749111D566BF1D56EBF559F5268EF21682E7F4A6837D1ED3";
    attribute INIT_1A of inst : label is "5912B740568B6FD0FF8658E976BD8EF697206BD8E7D070E4747F86BD816D8870";
    attribute INIT_1B of inst : label is "8F4658BEBA8FB48F4638BEBA87B28746108EAA8FB08746F80EAA87B5ED46D555";
    attribute INIT_1C of inst : label is "0FB7D10FB71107B7919111AB061F62BF52A407E9081C07EB10BF81155382B716";
    attribute INIT_1D of inst : label is "00004101010501500440819875A07EC1DC715D6FC1DC7D82D881C87941ED9751";
    attribute INIT_1E of inst : label is "5DF0EEF55DF0FFF88887823A22A0FCCF33F0A884004451045540154010473737";
    attribute INIT_1F of inst : label is "F9BFF2C3FFC2B2C7F887FCA2D1D01F3983FFFFF0000000055DF044855DF088E5";
    attribute INIT_20 of inst : label is "6FA5D5FC22E280E7FCAD02DA9187E9021987E87A877EDFDFBF8CDF98F9FAF1CD";
    attribute INIT_21 of inst : label is "D31633393D3333163511B9DF199B2FED06B09F608156BAFB9F180E60BD281990";
    attribute INIT_22 of inst : label is "068F11D58F8F81D933D42D85D94DEF0010010EDF81D48F11D989F71F23F06193";
    attribute INIT_23 of inst : label is "E016D9EFDB1016D226DE08E6ED9176D016D8E7BD0F80E061ED9F7DCE20EEFFFF";
    attribute INIT_24 of inst : label is "F6FD8F1DDFC860BDA88EE060BD0EC00E98090630E06F71B0BF5B6DCE07F0AD08";
    attribute INIT_25 of inst : label is "F4F3F21CE2F0EF21D9070E5EEB4F706203E86BED816D026D616DF2FD4F8DDFA8";
    attribute INIT_26 of inst : label is "93CE5D51384E98D8F021E8383E98D305E82E398D304E81E1938E5E419FE21EA1";
    attribute INIT_27 of inst : label is "87F82B006F6B0FF61F442EDF937B6BA33063337A3337A9112F8E7A55385E98D1";
    attribute INIT_28 of inst : label is "1C5BC5F64B287F24B2872D0D00FF2B0C818BF1800BDB0CFAF0F32FF0F23D3986";
    attribute INIT_29 of inst : label is "AD0D006DF81DD0DF51006DF11DF72F42FE98DD910EF5A98DDE18EF1AF02F2DAB";
    attribute INIT_2A of inst : label is "1D0E2082E401F81D021E48AC3F938EB8D0DAB6D866D086D3C6D006DFF1DD87F0";
    attribute INIT_2B of inst : label is "F88BC1B37281DB37BB203D7B10503F82B0F2D1D341FD34E7DDEC09D3C6D176D0";
    attribute INIT_2C of inst : label is "81D89CB89B888F8FBF8AAC32B8F0F8DFEA9D118ED5546021F81D2B452430F208";
    attribute INIT_2D of inst : label is "DE68F4518061BDFF2FD5DD7DF21F38ED34E5D9882222207118A67F48D38578F5";
    attribute INIT_2E of inst : label is "8F819B981DD0DF51D3DE2DEFFC18F64188FC1EFB63E9FED06D7100E1BDEFCC2E";
    attribute INIT_2F of inst : label is "E1BD61BD06C3FEDDEDE6D1861BDF81D46FF2FDAD360613DAD46011F915D55557";
    attribute INIT_30 of inst : label is "D36E28D7DF21109D02161BDE1BDE1BD88706BE9001F7DD3DE2D8F0ED6EDB6DB8";
    attribute INIT_31 of inst : label is "DBD5DC8AD7DF5126A09DE1BD48E7BDEFC8E1BD021DB146F81DBF3AE200E2EBED";
    attribute INIT_32 of inst : label is "61BDE1BD88EFD318861BDE1BDB26D6061BD27D7096D86D46D3ED50E1BDD3261B";
    attribute INIT_33 of inst : label is "111D20DBC525D0DF5100E1BD07DE1BD780EDFED17DE1BDA327DAE62EDC6211ED";
    attribute INIT_34 of inst : label is "1C6D176D016D236D9B73077FED39609418063EE8D0DF21E1BDD5DF51EFD81911";
    attribute INIT_35 of inst : label is "5204574AB9B191D57BBB633E393B92BBEF6873E30F6D315DB26D6F6D8B6D466D";
    attribute INIT_36 of inst : label is "42E3C683D0F304E0F406F0F40800F40B10F40C20F40F30F30B9F071248AF0941";
    attribute INIT_37 of inst : label is "010052AAEC89BEC89EC88BEC811E2E2E4E8E0E6D8FF00000000667CD27BD2FD8";
    attribute INIT_38 of inst : label is "0404050100625A0000000500526A00040500427A050422AA01040032AA000104";
    attribute INIT_39 of inst : label is "050405050552F34B550000040552F24040501001505505153F04000041515A00";
    attribute INIT_3A of inst : label is "00051005100450005400550455058000A240AA102A008A005500450001341042";
    attribute INIT_3B of inst : label is "0CC6220800C155551556158A008A00550045000174D0C2400001000000010005";
    attribute INIT_3C of inst : label is "6400510550510510510550550800A00A20220A2055051040F30011005D04F700";
    attribute INIT_3D of inst : label is "4AA20AA00AA20450055005510545450541054105450545450555055105500050";
    attribute INIT_3E of inst : label is "F9D004D6D2D4D6D2F9D0648662DCE4F9D90901004000400048005AA248004A80";
    attribute INIT_3F of inst : label is "FFFFFFFFFFFFFFFFFFFFF0C5F551FF0005DF0FFF8012E612168286D218161218";
  begin
  inst : RAMB16_S4
      --pragma translate_off
      generic map (
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
        DO   => DATA(3 downto 0),
        ADDR => rom_addr,
        CLK  => CLK,
        DI   => "0000",
        EN   => ENA,
        SSR  => '0',
        WE   => '0'
        );
  end generate;
  rom1 : if true generate
    attribute INIT_00 of inst : label is "000094C111101B1F075010064010F4C3FFFFFFFFFFFF0A600A60CC000007F4CC";
    attribute INIT_01 of inst : label is "CC10C01BE1CC030725372C0F75CA732A74C250000A40E195F7C1F014FE14218C";
    attribute INIT_02 of inst : label is "12111E18200710001000100014553668C74C2D1B5F71DCE1CCE4D24D2002BEE1";
    attribute INIT_03 of inst : label is "4C5F11C03020700F1103020F314C06F10C4174C2C4C2EF114004E2121A131D1D";
    attribute INIT_04 of inst : label is "00E4C36F4C3004C24D34D004C5FCA18C11C4C30314C03C3014C374014C014C00";
    attribute INIT_05 of inst : label is "33703C0E7204C004C5F6F06F06F06F16161616C004C14C2D155F4C311CD117C0";
    attribute INIT_06 of inst : label is "2BC4D20014C1FC10C12B22122E45FE3427CB02A72C0F74C14D210C2100E11C4C";
    attribute INIT_07 of inst : label is "F2C032030C02A723F2C3C02A74C2E00501E10C4D17310C111110103272020F71";
    attribute INIT_08 of inst : label is "74E24E3AC3125F12A723025F74E21CC4524250023FC727AC0F74C218C004C3E3";
    attribute INIT_09 of inst : label is "FD048284E201103F234852FD3F033D0F92114113F234242023F033CA72CA124C";
    attribute INIT_0A of inst : label is "225444545422CF3F1B2DC4C3F1C5FF3F804B0302034C124C5F004F005F00F230";
    attribute INIT_0B of inst : label is "F110C020E7EE210C03F20F700210C5F101FA000E5F004D35F004C34C13662220";
    attribute INIT_0C of inst : label is "000491F4F0024F4D8034F493FFFF00000067CEE7F126EEE00CF16E24A0000C0F";
    attribute INIT_0D of inst : label is "4A23220000200100102100105100107150A00106B10024A10004E111A10F493F";
    attribute INIT_0E of inst : label is "A344A34A303030F030F4A303030F4F34D42043F002D1BC4C24524B21524B2372";
    attribute INIT_0F of inst : label is "24007EDDD2F1306F06F0001150C7D3FD05F05F3F04F1105D05D3C7DC15C70144";
    attribute INIT_10 of inst : label is "1F25F3F402413CFF19C4A305FF03A2BA0107D83001007DC302BACDED1EC00049";
    attribute INIT_11 of inst : label is "E270CD15C4A30E34A314CC185185185185185164F1154F014F4D3A14C1BCE23F";
    attribute INIT_12 of inst : label is "4D04DC0024B1FC1D131D031D07F0F004F10300007D15C4A3C4F14C11C3C1D1BC";
    attribute INIT_13 of inst : label is "D05D07D07D321AC04D021AC4021AC121AC07D17C0002B707D402B744A0270CD0";
    attribute INIT_14 of inst : label is "DCF1B203181160CD2F00100E03FD19C1FC07D4A307D4A32F1300006F06F12C05";
    attribute INIT_15 of inst : label is "B207F0011F002F05F05FD100001023FCDBE010E05F2F00013E12C05D05DC0D1E";
    attribute INIT_16 of inst : label is "C75FC1EC30004927C001270CD15C7000B0CD34A20270CDE212FF172002BE0204";
    attribute INIT_17 of inst : label is "DC3F002D401580305F05FECAC0304F7F14C4D3234D3C302334A2D2B715FC1ECB";
    attribute INIT_18 of inst : label is "270CD0E020E0E020E120AD07D07D02BA15CC2F13000E12CE05D05D12C07DC70C";
    attribute INIT_19 of inst : label is "7F4B4B4A4A16151414CDEEDD175FEFD165FEDC4D39034A20203B4A3B107D07D0";
    attribute INIT_1A of inst : label is "CCD1C3F210271BCA5001D03C41AC0300C4021AC034F10830407FC1AC704D02B2";
    attribute INIT_1B of inst : label is "150C025F7024C1150D120F7024C2150C239F7025C3150D220F7025C05D05DFED";
    attribute INIT_1C of inst : label is "C5C182C4C192C4C182CCDE3C01F4A374A37E2B70020E2B7EE03F55CDD211C3F0";
    attribute INIT_1D of inst : label is "0000404150400540011010511A677710211A8899107119ABBC100119DEEFC192";
    attribute INIT_1E of inst : label is "FFF03E8FFFF03FEFFFF8F6BA88A33F0FCCF22A01551154010010451800080000";
    attribute INIT_1F of inst : label is "FCF0F30DA4D40043F02B4D3002D81FF1ECFFFFF00000000FFFF0344FFFF0384F";
    attribute INIT_20 of inst : label is "260EDE4D3030213B4D302030C02B7101102B7CB0CB07F434D47D0F01414D46D0";
    attribute INIT_21 of inst : label is "C2032001DC0002032EECE1181126605D01F11F302100E3FE1A024370CD061220";
    attribute INIT_22 of inst : label is "EE7462D0127472DC07D07D07D07D7F08208104D472D01462D04C1D0411F83E1D";
    attribute INIT_23 of inst : label is "F003DC3F182803D003D034F07DC003D003DC50CDD022F6E07DC07D03020F0000";
    attribute INIT_24 of inst : label is "4A1A046D0F0270CDD151D270CD41036FCF217B27700FD1E03F105D41CB493135";
    attribute INIT_25 of inst : label is "F3FF102001FC3412D6670C0F725F52C031F0D07D603D813D013D4A1B647D0F01";
    attribute INIT_26 of inst : label is "1D03F1E20D0F1CC04938300D0F1CC030FD0F01CC030FD0FF1D03F1F2C4D303F5";
    attribute INIT_27 of inst : label is "B14F0700D4010F4034F8014FC17E8E020030127120171CFD2F0350DF0D0F1CCF";
    attribute INIT_28 of inst : label is "0231204AC00834AC0003001000841100F461F064011C004D50FF019C4111C10D";
    attribute INIT_29 of inst : label is "313C503D472D13C412103D462D4134134318C1B0414A318C1B0514A3493A0170";
    attribute INIT_2A of inst : label is "7D6002B03020412D0111F0242F1D030115C003D403D403D003D103D482D12B49";
    attribute INIT_2B of inst : label is "F002351503600150B002318004343F0120F002DF65F0D734E13E11D003D003D0";
    attribute INIT_2C of inst : label is "1B51B51201207FC7C4F310C0D1E1D234D31DCD1CCDC00011412D01340140F043";
    attribute INIT_2D of inst : label is "D122F1012240CD0F3A12C16C4120DC30D73EDD0033333C1E51051F5189195185";
    attribute INIT_2E of inst : label is "1102CFD0ED15C41207D07D1F1322F101011021FE525105D011D23260CD1F2216";
    attribute INIT_2F of inst : label is "70CDB0CDC30D07D06D06D1270CD412D000F3A11C00011211C00011412EDEDCFE";
    attribute INIT_30 of inst : label is "0D731216C412B11D011F0CDE0CDB0CD02BC3E7140207D07D07D3F07D05D05D22";
    attribute INIT_31 of inst : label is "DF12C1FC16C41200E11DB0CD0250CD3F0270CD01118200412DF0D6303033F07D";
    attribute INIT_32 of inst : label is "A0CDD0CD023F18221E0CDD0CD413D3260CD07D120BD0BD0BD07D2260CD10C40C";
    attribute INIT_33 of inst : label is "DEED00CF17C015C4122250CD17DD0CD021BD07D17DD0CD1117D11115D1DF917D";
    attribute INIT_34 of inst : label is "003D003D803D303DC272CA7F7DFCF11302AE27D115C41290CD12C4123F172CFC";
    attribute INIT_35 of inst : label is "45254440151CCEDDA7225225FC72C1127502A7720F3DFDED413D003D203D003D";
    attribute INIT_36 of inst : label is "41042140F00000F00000F0000000000000000000000000000509054544020544";
    attribute INIT_37 of inst : label is "05040000A108E730A73006310101413121111101F008003300000867A807A302";
    attribute INIT_38 of inst : label is "0501000040000004050104400000050540010000450500004001050000400000";
    attribute INIT_39 of inst : label is "4001010105000004155555555100000750140540144005000000644140000005";
    attribute INIT_3A of inst : label is "0145010505050505550551055040A050A018A000A000A004550454001010001D";
    attribute INIT_3B of inst : label is "333FFB333200555145A1018000A004550454001000003D500040004000500050";
    attribute INIT_3C of inst : label is "1000500540540545555550510A00A08A00A00A05511510400000000044254433";
    attribute INIT_3D of inst : label is "8AA10AA08AA00510055045505150505150415041505151515550455005500500";
    attribute INIT_3E of inst : label is "19CF7280B182B0B119CF92A091807219CC00B1800001000100218AA5002102A1";
    attribute INIT_3F of inst : label is "FFFFFFFFFFFFFFFFFFFFFF40800E3FBEFFFF03FE8FE1E0E1E0C1C0B1E1E0E1E1";
  begin
  inst : RAMB16_S4
      --pragma translate_off
      generic map (
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
        DO   => DATA(7 downto 4),
        ADDR => rom_addr,
        CLK  => CLK,
        DI   => "0000",
        EN   => ENA,
        SSR  => '0',
        WE   => '0'
        );
  end generate;
end RTL;
