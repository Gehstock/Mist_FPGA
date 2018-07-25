-- generated with romgen v3.0 by MikeJ
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

library UNISIM;
  use UNISIM.Vcomponents.all;

entity BALLY_BIOS_0 is
  port (
    CLK         : in    std_logic;
    ENA         : in    std_logic;
    ADDR        : in    std_logic_vector(11 downto 0);
    DATA        : out   std_logic_vector(7 downto 0)
    );
end;

architecture RTL of BALLY_BIOS_0 is

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
    attribute INIT_00 of inst : label is "5D5D5553F11B0063F9001033F92330039D06B0D3F27A60A3F0CCC073C1383F30";
    attribute INIT_01 of inst : label is "B3E1194ED56D9ED1D52ED36DAEDB6D563E9FDA30706F70B15568F2A13E9D001D";
    attribute INIT_02 of inst : label is "B0B333315D37D3A27D3AA80B5311A86ED76D9108D69FBA387B1B106B20F50C1F";
    attribute INIT_03 of inst : label is "4712A7D397E7D7C79757B6E62AE1B3F5C584E1B04A4B30D62290B9B60373A308";
    attribute INIT_04 of inst : label is "C36393E3134242E3F31DABBBDBCB0B6C5BC0BD1CBC71A6B6C1CA96366ABA6BB7";
    attribute INIT_05 of inst : label is "BBBB8F0000078FC3000300400F77F3FB3FF330FF0A0040800000020033CC13F3";
    attribute INIT_06 of inst : label is "63533FB07FCA09AAEFAA9B11114EDFE40DD34EF38E7D0EED55553730008BBBB8";
    attribute INIT_07 of inst : label is "00DDD49FC2FE0CE83E70D97D3CD9F3D8B1F82F8AB096D70C15DC4D241C09D8B1";
    attribute INIT_08 of inst : label is "035D1706F03032591C006F03052F33081D7EDADEFFFFAF5164084718804B3403";
    attribute INIT_09 of inst : label is "11D1D119301110D59B755F0B388B98B37FCFFDA08BB83B26D7F18368781BB26D";
    attribute INIT_0A of inst : label is "581130D37B3EF4FA81F61807CA8EF4FFBBBD190653B110DBF99B9065320D9311";
    attribute INIT_0B of inst : label is "99B06855111C0D33B907D7EFB98733E20D9D8AEDB6D55597D058F7B2FB2FFF1D";
    attribute INIT_0C of inst : label is "706EB80377E0EB80EE906D8EFBCFBCFAF9D01AF281B112FE387C036F8B510D1B";
    attribute INIT_0D of inst : label is "5987DF79E803327EAF970EE9D068964D068EB9D068980377E0EFB068EB906D89";
    attribute INIT_0E of inst : label is "BF3031B9A9B057976FD4A1390DC109F88AF71BAF1293CDFF1AFF2A90713CDFFA";
    attribute INIT_0F of inst : label is "34C139D38639D06FD15891287B980303FF9811E9E31DC1D9E940198E10D7554B";
    attribute INIT_10 of inst : label is "AC0F4B82E8603CDA068DF01471B04D591E7FB68FBEF31C0C99773C6886583E8D";
    attribute INIT_11 of inst : label is "860059B6797F67E9C6797067E06C87B9870C50E8D34019B7F67E78F6E13EC377";
    attribute INIT_12 of inst : label is "BBE811D54D5D5B05C87EFA1BEB0EBF919FD22FDAD0AB377107D687EA09B06F51";
    attribute INIT_13 of inst : label is "286BF819877DE877DE396907EB3863E35187EBEBF31B3B652253536340DD80BE";
    attribute INIT_14 of inst : label is "3D90FB463D20FB563D20FB881F4AFA25BA73EF0ADFEA385CDF02DF429EBF91EB";
    attribute INIT_15 of inst : label is "00EE8F423E70783DF0676083D881888FB500E54353F3A63F2AC07583548B78FB";
    attribute INIT_16 of inst : label is "284EB363EB83D06D3D0EDC09EF6700E18333DA005DB0780D0DF21900EE8CFF66";
    attribute INIT_17 of inst : label is "FA2F9F02DFE25363F3FA2E280EC8F920EF9AA0689D4F06F6A00E6803DBD02DBD";
    attribute INIT_18 of inst : label is "6D2EDE1BD68BD9B511401B0D29BB63E1E83348AF6391280EFE7589C09D881F92";
    attribute INIT_19 of inst : label is "48870FE363C1864BD68BD48CD091C2ED36D0ED16D59D05166D9D031879861D02";
    attribute INIT_1A of inst : label is "F99EDC34BBBEDF9E4BD134D25D33912D03D3FFB7FA8E4BD1E4BD026D30D30886";
    attribute INIT_1B of inst : label is "ED93111070ECF86D7E1EBFFFAFF255F62D7806FF68DFFC3696862DFE7857CF6F";
    attribute INIT_1C of inst : label is "037373A155B9101B98EB120D755F10FBC07BA6D363E1723EF33E561BD6EDB6D0";
    attribute INIT_1D of inst : label is "1BD9B0198E10B080B7B73A155B9C01B98EB1274ABB0D755F60FB9B0198E10308";
    attribute INIT_1E of inst : label is "B98E1B0D755F2B363EB97059C03738F38E064B9F6FC4DB8860BDDEDE6D61BD86";
    attribute INIT_1F of inst : label is "6DB850D1C4D8ED5D00E261D7DA75D553808D08DB377608371D604E7EA87E9201";
    attribute INIT_20 of inst : label is "ED9111DC4D1C057D15ED193ED18CD5546D58ED95ED66D70DD0946D3ED00106F0";
    attribute INIT_21 of inst : label is "93CE15D9D001D5D063ED9FF7B026D1A980EB016D4ED56D88ED97D0F7F7C36776";
    attribute INIT_22 of inst : label is "5BB8D8606936ED04D8ED10DD4900111B8037373A154B92D2D7B7718066EDC38E";
    attribute INIT_23 of inst : label is "88C8C8800000000000000000000091D9D00C311198E1018364ED8037373A1555";
    attribute INIT_24 of inst : label is "0000000000080000808080000000000000000000000808000088000800080080";
    attribute INIT_25 of inst : label is "0008880080080000088088080008800000000088888000000800000000000800";
    attribute INIT_26 of inst : label is "8800008000008080000000000000000000000000888800880880000008808800";
    attribute INIT_27 of inst : label is "8888888008000000088000008088888008000800880880888888080888800000";
    attribute INIT_28 of inst : label is "8888000008808888888888888888888888000000800000808888880000000888";
    attribute INIT_29 of inst : label is "0000880000088880008888888880000888088888800000080880080800088080";
    attribute INIT_2A of inst : label is "0008000080008000080000080000000800000008000000000080000000000008";
    attribute INIT_2B of inst : label is "2BBED58B8D9AFA1D7BDE06B321D654A987FB325CE30997DE9A510689D31D0000";
    attribute INIT_2C of inst : label is "000000000000000000000000000000000000000000000000009C3BED9852D43D";
    attribute INIT_2D of inst : label is "B0655B8BBD911B906FFBFB999D499906A06F38B065536BFC6590D00000000000";
    attribute INIT_2E of inst : label is "06F88C4DB63E92B3B06F917EF6E3806E7777981B199B065591F6FFFF481B1E99";
    attribute INIT_2F of inst : label is "68B401388B70BBDF8DF68FD12671DAE89B1BBDE6BD5FE1262D1D9A5DB4D97DE9";
    attribute INIT_30 of inst : label is "810BB9EBF81078EA36F618FBF8A331603307716E536080ED8971D06280BA6F66";
    attribute INIT_31 of inst : label is "9F750FFC2DFF2002FEBFFE100A3E00A0256F65D177403E484E243FEFC7C805F4";
    attribute INIT_32 of inst : label is "D16D40E728E4F2ED36D2FDE2F0681D191C01D9D55AF281385E3E001D312F0398";
    attribute INIT_33 of inst : label is "9D555952D43D551163E363E3A063EB711982FFE688387E1EFD0111159B05C50E";
    attribute INIT_34 of inst : label is "D618F697EDFD9D994F4E08115D818BF01800BF59F1FEF0011B7114F1D79085FD";
    attribute INIT_35 of inst : label is "C4879A070E97FF7CB4628A61E9890C9FE09BA8C980BD1CD54DF39DC5F0B3F6F5";
    attribute INIT_36 of inst : label is "1A00254E59B03FD17E6C8591AF17FF9FE6C85959916F50F9F688DE0F9BCD9D40";
    attribute INIT_37 of inst : label is "875D170435C5307E9C22923302F41C53C130541DB3583048796E57E9D80038D3";
    attribute INIT_38 of inst : label is "DE890C08E8F8887008E0B0E000B0FE81F3128DFFFFF08791076D09CC120938D8";
    attribute INIT_39 of inst : label is "DF49718BF9DF1FFF84E83E5FFFF9E15FE53F5E812F54BF403DF606DF843DFA46";
    attribute INIT_3A of inst : label is "19D0E195EA155F7F3AE01DE93EC2F319F32F9F624EE89F733337E76E488B6AE8";
    attribute INIT_3B of inst : label is "B806F4DF0992FEFCEDD6D87A15D9B7D05E4BEDA7D308E2AED01DF6F4DF099001";
    attribute INIT_3C of inst : label is "2DAFAEDB6D5006F3DF8F188421FA509CF8F2DF367797AEDB6DF6DF36F77EBBBB";
    attribute INIT_3D of inst : label is "E51F32533787F247FF72533787F2C36288E07FF925E31E01F81CF83115DBC3DD";
    attribute INIT_3E of inst : label is "0ECFC720CE57FADE36E317240EE4A3F2D00E2AFA101DAE2287F2187E583ECA7F";
    attribute INIT_3F of inst : label is "F524E401FDD59DF211EADE61EADE51EADE41F024EDF3AA81EFC2FECF41CFCF31";
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
    attribute INIT_00 of inst : label is "EFEDDCFEF008021CFC00221CFC72721CCF17F20CF60F020CF213120C06C0DAF0";
    attribute INIT_01 of inst : label is "C27EDC05F05F07FEDD05F05F06F06FD52514F203101500C2DE331071273F002F";
    attribute INIT_02 of inst : label is "CAC2222EEF07F1107F11026CE2DEA104F04F7D0AC404F2027C04200E134D0713";
    attribute INIT_03 of inst : label is "C0E060A0B0907010101000F0B0E0D0C0F0007080A0C0707030707CEF22711033";
    attribute INIT_04 of inst : label is "40502060406080D01020A040B0A0907010C01030F090B00000A0C03050F0F0E0";
    attribute INIT_05 of inst : label is "CCCCCCCCCCC00CEC0CC00DD22CC2CCCC1EEEED22C20F000C0CC0004020604070";
    attribute INIT_06 of inst : label is "1D1DFA22B4E321CAF4F3CFFCDE07C000AC0D330DC34E035EEDCFFCCE02C00C0C";
    attribute INIT_07 of inst : label is "120D0CC4E3F3D1FD1F07F07F0ECCABE0004E24E2F003FE230EC0FC011F17E000";
    attribute INIT_08 of inst : label is "05444424422055454452442204544525441D0C0B33330B0000A0E0000207C0AC";
    attribute INIT_09 of inst : label is "DEDEFEECF1CDEBEE1E4DCA02CD0CC0C2627627030C0BCE05C42020E7027CE05C";
    attribute INIT_0A of inst : label is "51CEE20E72E6F7F61CF3EF223036F7FA11E0C000CE2DCBEE403C700CE0CCCEFC";
    attribute INIT_0B of inst : label is "03C004CDCEEE20E2EF223A6FE02AE270CCED406F06FEEC34F1E766E7FE7F4AED";
    attribute INIT_0C of inst : label is "78F72F1272903ED5F7102266FE6FE6F6FCF1E6F024CEC1F302AF12BA3CCCBE2C";
    attribute INIT_0D of inst : label is "FC07F219FF1211281AC78E700004C03F03C7C12026CF1272903AE03C7C10226C";
    attribute INIT_0E of inst : label is "EA2727EC80F211201A440DCF203031A0274AFE54F210AC54F24E2800100AC4E2";
    attribute INIT_0F of inst : label is "20100DC2010DC014D222CE877ACF102A4070005C0D5E04E00CF1C020EBE4ECFC";
    attribute INIT_10 of inst : label is "7F30101117F121002A7EF01010E07CEC137BC027C74E2E10C74783030D03957E";
    attribute INIT_11 of inst : label is "007C3C0D0740E7AC0D0741E7A1E026CC7F1002A7E2010C747E7A027EAE113800";
    attribute INIT_12 of inst : label is "CE01EED01CEDE02312B74E2ECCC4C4F2C4D3B4D3E11C273022302B7033C014D2";
    attribute INIT_13 of inst : label is "024C4F20172301723725302B7212B272302B7EFC4E2E23300F321D1D023302E7";
    attribute INIT_14 of inst : label is "AE033C00AE033C00AE033C0104D34E305FB274D2D4C2010FC4D2D4D3C8C4F2FC";
    attribute INIT_15 of inst : label is "3BF914D32702A1AE41F0EB1BE0107025C139F0FC1D4D31D4D3E2BF120012033C";
    attribute INIT_16 of inst : label is "D30FE2525D12D06D2D06D020F0E23DFF1222D0203D0281AEAE4D103CF31150E0";
    attribute INIT_17 of inst : label is "4E3AC4D2D4C21D1DA24E3712FFA14F38E4F302E10554000E03EFC107D2D07D2D";
    attribute INIT_18 of inst : label is "3D04D70CDF0CFEEEFD027C07C7CE525DE12202B3E2CD03CF475D7CF17E0104F3";
    attribute INIT_19 of inst : label is "03B03CF24E73240CDB0CF02BF114706D06D05D05DE1D00105C1D001CA7C07F00";
    attribute INIT_1A of inst : label is "0705F0DFCE04CAC90CDE07D07DE2C07D07D1527527C40CDFD0CD003D07D223B4";
    attribute INIT_1B of inst : label is "7DC2ECF160C762C77AAA744F30F3CEA0ECF1CC00020A430E7F10ECF3021533E0";
    attribute INIT_1C of inst : label is "12727114ECECF1CE020ED1BE4DCA125C227C0FC2424F58275827FF0CD05D05D0";
    attribute INIT_1D of inst : label is "0CDCE1C020E727F12727114ECECE1CE020ED105E11AE4DCA125CCE1C020E727F";
    attribute INIT_1E of inst : label is "E020EEBE4DCAFC2424ECF210F12747492300FC0F0434E70270CD06D06DB0CDC7";
    attribute INIT_1F of inst : label is "9D31F23F0FC04CF032F002D0EFAEDECE106C0ACE241EF120EC036F0CFCA7CF1C";
    attribute INIT_20 of inst : label is "7FCCEED0FCDE107F807FC004DE06CEC04DD04C105D05DF20F1104D04D0020150";
    attribute INIT_21 of inst : label is "1D03DED3D002DED0004DC5A5F108D4703AFF108D07F05F403CC4F183A430E000";
    attribute INIT_22 of inst : label is "FE00C0F3E1D07F07C03CE23553002F2CF12727114FBCF4E4EAE0022CE07F0D03";
    attribute INIT_23 of inst : label is "44F4F44000055520222220000000CEDFDE10DFCD020E7020E07FF12727114EDC";
    attribute INIT_24 of inst : label is "04266000022F2200A7D7A042222241222221000066669A4A9619421CC2F07872";
    attribute INIT_25 of inst : label is "437800F8F11F95317803087F8870877222262788888708421006600000000F00";
    attribute INIT_26 of inst : label is "087421012400F0F0012484214266066066066061078877887887444210F788F8";
    attribute INIT_27 of inst : label is "F8887898887888E88FF88E88FF88888F7888887F88F88F888F88778BAB872021";
    attribute INIT_28 of inst : label is "A8887888F88FF88888F8889AC8888AAD8F88888889ACA9878000007222227888";
    attribute INIT_29 of inst : label is "84210F222258888525888DAA88822558887888888222222F780788789AF88F69";
    attribute INIT_2A of inst : label is "020F0200852580021F12027A2222024F4202222A72711111700124807444447F";
    attribute INIT_2B of inst : label is "FC04C0100CC0EEAE7E3232233323332333235525542C07F700D2004EDEED0000";
    attribute INIT_2C of inst : label is "2EAEEAEAE2222EEAE8EE2E8E22EAAE262EE8E2E44444EAAAE0C0D04CC107F07F";
    attribute INIT_2D of inst : label is "C00CE8107CCEFE10153C3C12255222026AC20274EFB0E76FEECBEEEEE404040E";
    attribute INIT_2E of inst : label is "015010FC252511C2C015CE7A0EA01FEA0000024CC03C00CECE0E0000024CC703";
    attribute INIT_2F of inst : label is "CBC12B027C0207C4F33E74E2400ECB3C7CC0ECB0CFC4E240002DC07F07F07F71";
    attribute INIT_30 of inst : label is "1F121CFC4F2D02B1004F1C4C4F322EF1202720C7E00F123D170EC8F027C2C0E0";
    attribute INIT_31 of inst : label is "2B110F4E330F30034C1F4C320CCF2030545404444CF21F021F014F0F054133FF";
    attribute INIT_32 of inst : label is "D06D01158033F06D06D3F233F3C7ED00001101CEE4F012025F272020F1000110";
    attribute INIT_33 of inst : label is "1CCEFC07F07FECFE42425252F1525E4DEE13F3303B02A7C4F411000C3D2B7E06";
    attribute INIT_34 of inst : label is "032C3EA07F409CDC3F00011E5044B1F00B401FDC05F4F331FC4FE3FE0B0203F0";
    attribute INIT_35 of inst : label is "0117DF120C165A51D6002000FD7DC37F0C7C3237C6C061051071C044F004F7FE";
    attribute INIT_36 of inst : label is "0F0254544CF126EF43E37FCC1FD4A4D13E37EDCCDD3FD6FD0E023F4FFC009C02";
    attribute INIT_37 of inst : label is "064444254444504444444545054544544440454444444054444454010E00120D";
    attribute INIT_38 of inst : label is "74E110004E502B10074F10064010F4E34F0024FFFFF033332444254444224205";
    attribute INIT_39 of inst : label is "5F976A7E025FA00A21F70000002C0A4F064FE05204D074635744347422574024";
    attribute INIT_3A of inst : label is "E1D011ED0B1EC444F34F2D0610900D0C4E3AC4D3134E1F722227A0EA025C814E";
    attribute INIT_3B of inst : label is "2C1E4E5F97C1A2F16D16DCA1DEDC17DD5F817D17D039F817D10C0E4E5F97CF1C";
    attribute INIT_3C of inst : label is "7D3F15D15DEC1E4E5F7F0F0000FA50C1F4025F0E007415D15D025F0E40072222";
    attribute INIT_3D of inst : label is "4F109F312777F107F07F312777F130E030F37F06F34F14F2A1E2F000DEDE17D1";
    attribute INIT_3E of inst : label is "A31F759953D601C7244F250D32F80050D35F8040010C14F327F1F20FF20F307F";
    attribute INIT_3F of inst : label is "4D303F1C02CC1DFE140AC0F20AC0E20AC0C205D0F34F321034E3F31F5E1F7599";
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
