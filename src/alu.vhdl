-- MINIFIVE: a simple (subset of) RISC-V processor
--   alu.vhdl - ALU (Arithmetic Logic Unit)
-- Copyright (C) 2019-2021 Naoki FUJIEDA. New BSD License is applied.
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
  ALU_OUT <= B       when ALU_OP = "10000" else 
             A - B   when ALU_OP = "01000" else
             A and B when ALU_OP = "00111" else
             shr(A, B(4 downto 0)) when ALU_OP = "00101" else
             A + B;
             
  Y      <= ALU_OUT;
  Y_ZERO <= '1' when ALU_OUT = x"00000000" else '0';
end RTL;
