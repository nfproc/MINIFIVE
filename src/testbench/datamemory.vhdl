-- MINIFIVE: a simple (subset of) RISC-V processor
--   datamemory.vhdl - data memory
-- Copyright (C) 2019-2021 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity DATA_MEMORY is
  port (CLK      : in  std_logic;
        ADDR     : in  std_logic_vector(31 downto 0);
        DATA_IN  : in  std_logic_vector(31 downto 0);
        WE       : in  std_logic; -- write enable
        DATA_OUT : out std_logic_vector(31 downto 0));
end DATA_MEMORY;

architecture RTL of DATA_MEMORY is
  type MEM_TYPE is array(0 to 255) of std_logic_vector(31 downto 0);
  signal MEM : MEM_TYPE;
begin
  process (CLK) begin
    if rising_edge(CLK) then
      if WE = '1' then
        MEM(conv_integer(ADDR(9 downto 2))) <= DATA_IN;
      end if;
      DATA_OUT <= MEM(conv_integer(ADDR(9 downto 2)));
    end if;
  end process;
end RTL;