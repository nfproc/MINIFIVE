-- MINIFIVE: a simple (subset of) RISC-V processor
--   regfile.vhdl - register file
-- Copyright (C) 2019-2023 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity REGFILE is
  port (CLK        : in  std_logic;
        A1, A2, A3 : in  std_logic_vector( 4 downto 0);
        D3         : in  std_logic_vector(31 downto 0);
        WE3        : in  std_logic; -- write enable
        Q1, Q2     : out std_logic_vector(31 downto 0));
end REGFILE;

architecture RTL of REGFILE is
  type MEM_TYPE is array(0 to 31) of std_logic_vector(31 downto 0);
  signal MEM : MEM_TYPE;

  type OUT_SOURCE is (SRC_MEM, SRC_ZERO, SRC_WRITE);
  signal Q_MEM1, Q_MEM2, Q_WRITE : std_logic_vector(31 downto 0);
  signal Q_SRC1, Q_SRC2          : OUT_SOURCE;
begin

  -- RAM control
  process (CLK) begin
    if rising_edge(CLK) then
      if WE3 = '1' then
        MEM(conv_integer(A3)) <= D3;
      end if;
      Q_MEM1  <= MEM(conv_integer(A1));
      Q_MEM2  <= MEM(conv_integer(A2));
    end if;
  end process;

  -- output control
  Q1 <= x"00000000" when Q_SRC1 = SRC_ZERO  else
        Q_WRITE     when Q_SRC1 = SRC_WRITE else
        Q_MEM1;
  Q2 <= x"00000000" when Q_SRC2 = SRC_ZERO  else
        Q_WRITE     when Q_SRC2 = SRC_WRITE else
        Q_MEM2;  

  -- logic for output control
  process (CLK) begin
    if rising_edge(CLK) then
      Q_WRITE <= D3;
      if A1 = "00000" then
        Q_SRC1 <= SRC_ZERO;  -- x0 is always zero
      elsif A1 = A3 and WE3 = '1' then
        Q_SRC1 <= SRC_WRITE; -- write is prioritized
      else
        Q_SRC1 <= SRC_MEM;
      end if;
      if A2 = "00000" then
        Q_SRC2 <= SRC_ZERO;
      elsif A2 = A3 and WE3 = '1' then
        Q_SRC2 <= SRC_WRITE;
      else
        Q_SRC2 <= SRC_MEM;
      end if;
    end if;
  end process;
end RTL;