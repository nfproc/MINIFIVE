-- MINIFIVE: a simple (subset of) RISC-V processor
--   datamemory.vhdl - Data Memory (for simulation only)
-- Copyright (C) 2019-2022 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity DATA_MEMORY is
  port (CLK      : in  std_logic;
        ADDR     : in  std_logic_vector(31 downto 0);
        DATA_IN  : in  std_logic_vector(31 downto 0);
        WE       : in  std_logic;
        DATA_OUT : out std_logic_vector(31 downto 0));
end DATA_MEMORY;

architecture SIM of DATA_MEMORY is
  type MEM_TYPE is array(0 to 255) of std_logic_vector(31 downto 0);
  signal initialized : boolean := false;
  signal MEM : MEM_TYPE;
  file   init_file : text open read_mode is "../program/squaresum_data.txt";

begin
  process (CLK) 
    variable l      : line;
    variable r_data : std_logic_vector(31 downto 0);
  begin
    if rising_edge(CLK) then
      if not initialized then
        for i in 0 to 255 loop
          if not endfile(init_file) then
            readline(init_file, l);
            hread(l, r_data);
            MEM(i) <= r_data;
          end if;
        end loop;
        initialized <= true;
      elsif WE = '1' then
        MEM(conv_integer(ADDR(9 downto 2))) <= DATA_IN;
      end if;
      DATA_OUT <= MEM(conv_integer(ADDR(9 downto 2)));
    end if;
  end process;
end SIM;