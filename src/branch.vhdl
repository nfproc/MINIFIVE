-- MINIFIVE: a simple (subset of) RISC-V processor
--   branch.vhdl: determine whether branch is taken
-- Copyright (C) 2019-2023 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity BRANCH is
  port (BR_COND  : in  std_logic_vector( 1 downto 0);
        ALU_ZERO : in  std_logic;
        PC_SRC   : out std_logic_vector( 1 downto 0));
end BRANCH;

architecture RTL of BRANCH is
begin
  PC_SRC <= "00"                 when BR_COND = "00" else
            '0' & ALU_ZERO       when BR_COND = "01" else
            '0' & (not ALU_ZERO) when BR_COND = "10" else
            "10";
end RTL;
