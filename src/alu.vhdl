-- MINIFIVE: a simple (subset of) RISC-V processor
--   alu.vhdl - ALU (Arithmetic Logic Unit)
-- Copyright (C) 2019-2023 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ALU is
  port (A, B   : in  std_logic_vector(31 downto 0);
        ALU_OP : in  std_logic_vector( 4 downto 0);
        Y      : out std_logic_vector(31 downto 0);
        Y_ZERO : out std_logic);
end ALU;

architecture RTL of ALU is
  signal ALU_OUT : std_logic_vector(31 downto 0);
begin
  -- NOTE: some operations are intentionally omitted from implementation.
  process (A, B, ALU_OP) begin
    ALU_OUT <= A + B;
    case ALU_OP is
      when "00000" =>
        ALU_OUT <= A + B;
      when "00001" =>
        ALU_OUT <= shl(A, B(4 downto 0));
      when "00011" =>
        if A < B then
          ALU_OUT <= x"00000001";
        else
          ALU_OUT <= x"00000000";
        end if;
      when "00101" =>
        ALU_OUT <= shr(A, B(4 downto 0));
      when "00111" =>
        ALU_OUT <= A and B;
      when "01000" =>
        ALU_OUT <= A - B;
      when "10000" =>
        ALU_OUT <= B;
      when others =>
        null;
    end case;
  end process;
             
  Y      <= ALU_OUT;
  Y_ZERO <= '1' when ALU_OUT = x"00000000" else '0';
end RTL;
