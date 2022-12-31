
library ieee;
  use ieee.std_logic_1164.all;

package C07_SYNCGEN_PACK is

  type r_c07_syncgen_clken is record
    clk_rise : std_logic;
    clk_fall : std_logic;
  end record;

  constant z_c07_syncgen_clken : r_c07_syncgen_clken := (
    '0',
    '0'
    );

  type r_c07_syncgen_clken_out is record
    hcount : std_logic_vector(8 downto 0);
    vcount : std_logic_vector(8 downto 0);
    vblank : std_logic;
  end record;

end;
    
