-------------------------------------------------------------------------------
--
-- $Id: alu_pack-p.vhd,v 1.2 2004/04/04 14:18:53 arniml Exp $
--
-- Copyright (c) 2004, Arnim Laeuger (arniml@opencores.org)
--
-- All rights reserved
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.t48_pack.word_width_c;

package alu_pack is

  -----------------------------------------------------------------------------
  -- The ALU operations
  -----------------------------------------------------------------------------
  type alu_op_t is (ALU_AND, ALU_OR, ALU_XOR,
                    ALU_CPL, ALU_CLR,
                    ALU_RL, ALU_RR,
                    ALU_SWAP,
                    ALU_DEC, ALU_INC,
                    ALU_ADD,
                    ALU_CONCAT,
                    ALU_NOP);

  -----------------------------------------------------------------------------
  -- The dedicated ALU arithmetic types.
  -----------------------------------------------------------------------------
  subtype alu_operand_t is std_logic_vector(word_width_c downto 0);

end alu_pack;


-------------------------------------------------------------------------------
-- File History:
--
-- $Log: alu_pack-p.vhd,v $
-- Revision 1.2  2004/04/04 14:18:53  arniml
-- add measures to implement XCHD
--
-- Revision 1.1  2004/03/23 21:31:52  arniml
-- initial check-in
--
--
-------------------------------------------------------------------------------
