-- MINIFIVE: a simple (subset of) RISC-V processor
--   program.vhdl - program memory (Bubble Sort)
-- Copyright (C) 2019-2021 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity PROGRAM_ROM is
  port (CLK  : in  std_logic;
        ADDR : in  std_logic_vector(31 downto 0);
        DATA : out std_logic_vector(31 downto 0));
end PROGRAM_ROM;

architecture RTL of PROGRAM_ROM is
begin
  process (CLK) begin
    if rising_edge(CLK) then
      case ADDR(6 downto 2) is
        when "00000" => DATA <= x"40000093";
        when "00001" => DATA <= x"42000113";
        when "00010" => DATA <= x"00300193";
        when "00011" => DATA <= x"800004b7";
        when "00100" => DATA <= x"0030a023";
        when "00101" => DATA <= x"0230a023";
        when "00110" => DATA <= x"003182b3";
        when "00111" => DATA <= x"003281b3";
        when "01000" => DATA <= x"01f1f193";
        when "01001" => DATA <= x"00408093";
        when "01010" => DATA <= x"00208263";
        when "01011" => DATA <= x"fe0000e3";
        when "01100" => DATA <= x"40000093";
        when "01101" => DATA <= x"ffc10113";
        when "01110" => DATA <= x"02208463";
        when "01111" => DATA <= x"0000a183";
        when "10000" => DATA <= x"0040a203";
        when "10001" => DATA <= x"403202b3";
        when "10010" => DATA <= x"0092f2b3";
        when "10011" => DATA <= x"00028463";
        when "10100" => DATA <= x"0040a023";
        when "10101" => DATA <= x"0030a223";
        when "10110" => DATA <= x"00408093";
        when "10111" => DATA <= x"fc2088e3";
        when "11000" => DATA <= x"fc000ce3";
        when "11001" => DATA <= x"00000000";
        when "11010" => DATA <= x"00000000";
        when "11011" => DATA <= x"00000000";
        when "11100" => DATA <= x"00000000";
        when "11101" => DATA <= x"00000000";
        when "11110" => DATA <= x"00000000";
        when "11111" => DATA <= x"00000000";
        when others  => DATA <= x"00000000";
      end case;
    end if;
  end process;
end RTL;
