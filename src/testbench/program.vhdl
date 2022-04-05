-- MINIFIVE: a simple (subset of) RISC-V processor
--   program.vhdl - Program Memory (for simulation only)
-- Copyright (C) 2019-2022 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity PROGRAM_ROM is
  port (CLK   : in  std_logic;
        ADDR  : in  std_logic_vector(31 downto 0);
        DATA  : out std_logic_vector(31 downto 0));
end PROGRAM_ROM;

architecture SIM of PROGRAM_ROM is
  type MEM_TYPE is array(0 to 255) of std_logic_vector(31 downto 0);
  signal initialized : boolean := false;
  signal MEM : MEM_TYPE;
  file   init_file : text open read_mode is "../program/fibonacci_program.txt";

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
      end if;
      DATA <= MEM(conv_integer(ADDR(9 downto 2)));
    end if;
  end process;
end SIM;