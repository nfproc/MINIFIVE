-- MINIFIVE: a simple (subset of) RISC-V processor
--   immextend.vhdl - decode and sign extension of immediate value
-- Copyright (C) 2019-2023 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity IMM_EXTEND is
  port (INST     : in  std_logic_vector(31 downto 0);
        FORMAT   : in  std_logic_vector( 2 downto 0);
        IMM      : out std_logic_vector(31 downto 0));
end IMM_EXTEND;

architecture RTL of IMM_EXTEND is
begin
  process (INST, FORMAT)
    variable SIGN_EXT : std_logic_vector(31 downto 0);
  begin
    if INST(31) = '1' then -- sign bit of immediate value = MSB of instruction
      SIGN_EXT := x"ffffffff";
    else
      SIGN_EXT := x"00000000";
    end if;

    if FORMAT = "001" then    -- I-type
      IMM(31 downto 12) <= SIGN_EXT(31 downto 12);
      IMM(11 downto  0) <= INST(31 downto 20);
    elsif FORMAT = "010" then -- S-type
      IMM(31 downto 12) <= SIGN_EXT(31 downto 12);
      IMM(11 downto  5) <= INST(31 downto 25);
      IMM( 4 downto  0) <= INST(11 downto  7);
    elsif FORMAT = "011" then -- B-type
      IMM(31 downto 13) <= SIGN_EXT(31 downto 13);
      IMM(12)           <= INST(31);
      IMM(11)           <= INST( 7);
      IMM(10 downto  5) <= INST(30 downto 25);
      IMM( 4 downto  1) <= INST(11 downto  8);
      IMM( 0)           <= '0';
    elsif FORMAT = "100" then -- U-type
      IMM(31 downto 12) <= INST(31 downto 12);
      IMM(11 downto  0) <= x"000";
    elsif FORMAT = "101" then -- J-type
      IMM(31 downto 21) <= SIGN_EXT(31 downto 21);
      IMM(19 downto 12) <= INST(19 downto 12);
      IMM(11)           <= INST(20);
      IMM(10 downto  1) <= INST(30 downto 21);
      IMM( 0)           <= '0';
    else
      IMM <= (others => '-'); -- don't care
    end if;
  end process;
end RTL;
