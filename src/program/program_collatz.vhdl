-- MINIFIVE: a simple (subset of) RISC-V processor
--   program.vhdl - program memory (Collatz Sequence)
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
        when "00000" => DATA <= x"04700093";
        when "00001" => DATA <= x"40000113";
        when "00010" => DATA <= x"00100193";
        when "00011" => DATA <= x"48000213";
        when "00100" => DATA <= x"00112023";
        when "00101" => DATA <= x"00410113";
        when "00110" => DATA <= x"04308663";
        when "00111" => DATA <= x"04410463";
        when "01000" => DATA <= x"0010f293";
        when "01001" => DATA <= x"00028863";
        when "01010" => DATA <= x"001082b3";
        when "01011" => DATA <= x"001280b3";
        when "01100" => DATA <= x"00108093";
        when "01101" => DATA <= x"02000663";
        when "01110" => DATA <= x"00008313";
        when "01111" => DATA <= x"00000093";
        when "10000" => DATA <= x"00f37393";
        when "10001" => DATA <= x"00038663";
        when "10010" => DATA <= x"ffe30313";
        when "10011" => DATA <= x"00108093";
        when "10100" => DATA <= x"fe0006e3";
        when "10101" => DATA <= x"00030663";
        when "10110" => DATA <= x"ff030313";
        when "10111" => DATA <= x"00808093";
        when "11000" => DATA <= x"fe0008e3";
        when "11001" => DATA <= x"fa0004e3";
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
