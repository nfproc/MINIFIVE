-- MINIFIVE: a simple (subset of) RISC-V processor
--   memory.vhdl - Instruction and Data Memory (1 KiB)
-- Copyright (C) 2019-2026 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity MEMORY1K is
  port (CLK      : in  std_ulogic;
        ADDR     : in  std_ulogic_vector(31 downto 0);
        DATA_IN  : in  std_ulogic_vector(31 downto 0);
        WE       : in  std_ulogic;
        DATA_OUT : out std_ulogic_vector(31 downto 0));
end MEMORY1K;

architecture SIM of MEMORY1K is
  type MEM_TYPE is array(0 to 255) of std_ulogic_vector(31 downto 0);
  signal MEM : MEM_TYPE;
begin
  process (CLK)  begin
    if rising_edge(CLK) then
      if WE then
        MEM(to_integer(ADDR(9 downto 2))) <= DATA_IN;
      end if;
      DATA_OUT <= MEM(to_integer(ADDR(9 downto 2)));
    end if;
  end process;
end SIM;