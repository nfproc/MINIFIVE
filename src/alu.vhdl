-- MINIFIVE: a simple (subset of) RISC-V processor
--   alu.vhdl - ALU (Arithmetic Logic Unit)
-- Copyright (C) 2019-2026 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity ALU is
  port (A, B   : in  std_ulogic_vector(31 downto 0);
        ALU_OP : in  std_ulogic_vector( 4 downto 0);
        Y      : out std_ulogic_vector(31 downto 0);
        Y_ZERO : out std_ulogic);
end ALU;

architecture RTL of ALU is
  signal ALU_OUT : std_ulogic_vector(31 downto 0);
begin
  -- NOTE: some operations are intentionally omitted from implementation.
  process (all) begin
    case ALU_OP is
      when "00000" =>
        ALU_OUT <= A + B;
      when "00001" =>
        ALU_OUT <= A sll to_integer(B(4 downto 0));
      when "00011" =>
        ALU_OUT <= x"00000001" when A < B else x"00000000";
      when "00101" =>
        ALU_OUT <= A srl to_integer(B(4 downto 0));
      when "00111" =>
        ALU_OUT <= A and B;
      when "01000" =>
        ALU_OUT <= A - B;
      when "10000" =>
        ALU_OUT <= B;
      when others =>
        ALU_OUT <= A + B;
    end case;
  end process;
             
  Y      <= ALU_OUT;
  Y_ZERO <= ALU_OUT ?= x"00000000";
end RTL;
