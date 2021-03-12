-- MINIFIVE: a simple (subset of) RISC-V processor
--   signextend.vhdl - sign extension (12 bits to 32 bits)
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity SIGN_EXTEND_12_32 is
  port (DATA_IN  : in  std_logic_vector(11 downto 0);
        DATA_OUT : out std_logic_vector(31 downto 0));
end SIGN_EXTEND_12_32;

architecture RTL of SIGN_EXTEND_12_32 is
begin
  DATA_OUT <= x"00000" & DATA_IN when DATA_IN(11) = '0' else
              x"fffff" & DATA_IN;
end RTL;
