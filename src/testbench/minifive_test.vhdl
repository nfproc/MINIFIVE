-- MINIFIVE: a simple (subset of) RISC-V processor
--   minifive_test.vhdl - test bench of MINIFIVE
-- Copyright (C) 2019-2021 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

entity MINIFIVE_TEST is
end MINIFIVE_TEST;

architecture SIM of MINIFIVE_TEST is
  -- MINIFIVE -> minifive.vhdl
  component MINIFIVE is
    port (CLK, RST : in  std_logic;
          IMEM_A   : out std_logic_vector(31 downto 0);
          IMEM_Q   : in  std_logic_vector(31 downto 0);
          DMEM_A   : out std_logic_vector(31 downto 0);
          DMEM_D   : out std_logic_vector(31 downto 0);
          DMEM_WE  : out std_logic;
          DMEM_Q   : in  std_logic_vector(31 downto 0);
          DEBUG_A3 : out std_logic_vector( 4 downto 0);
          DEBUG_D3 : out std_logic_vector(31 downto 0);
          DEBUG_EN : out std_logic;
          HALT     : out std_logic);
  end component;

  -- PROGRAM_ROM -> program.vhdl
  component PROGRAM_ROM is
    port (CLK  : in  std_logic;
          ADDR : in  std_logic_vector(31 downto 0);
          DATA : out std_logic_vector(31 downto 0));
  end component;

  -- DATA_MEMORY -> datamemory.vhdl
  component DATA_MEMORY is
    port (CLK      : in  std_logic;
          ADDR     : in  std_logic_vector(31 downto 0);
          DATA_IN  : in  std_logic_vector(31 downto 0);
          WE       : in  std_logic;
          DATA_OUT : out std_logic_vector(31 downto 0));
  end component;

  signal CLK, RST      : std_logic;
  signal IMEM_A        : std_logic_vector(31 downto 0);
  signal IMEM_Q        : std_logic_vector(31 downto 0);
  signal DMEM_A        : std_logic_vector(31 downto 0);
  signal DMEM_D        : std_logic_vector(31 downto 0);
  signal DMEM_WE       : std_logic;
  signal DMEM_Q        : std_logic_vector(31 downto 0);
  signal PROC_DMEM_A   : std_logic_vector(31 downto 0);
  signal PROC_DMEM_D   : std_logic_vector(31 downto 0);
  signal PROC_DMEM_WE  : std_logic;
  signal PROC_DMEM_Q   : std_logic_vector(31 downto 0);
  signal TEST_DMEM_A   : std_logic_vector(31 downto 0);
  signal TEST_DMEM_D   : std_logic_vector(31 downto 0);
  signal TEST_DMEM_WE  : std_logic;
  signal TEST_DMEM_Q   : std_logic_vector(31 downto 0);
  signal DEBUG_A3      : std_logic_vector( 4 downto 0);
  signal DEBUG_D3      : std_logic_vector(31 downto 0);
  signal DEBUG_EN      : std_logic;
  signal HALT          : std_logic;
  signal inst_count    : std_logic_vector(31 downto 0);

  file PROC_LOG : text open write_mode is "proc_log.txt";
  file DMEM_DMP : text open write_mode is "dmem_dmp.txt";

begin
  PROC: MINIFIVE port map
    (CLK, RST, IMEM_A, IMEM_Q, PROC_DMEM_A, PROC_DMEM_D, PROC_DMEM_WE,
     PROC_DMEM_Q, DEBUG_A3, DEBUG_D3, DEBUG_EN, HALT);
  IMEM: PROGRAM_ROM port map (CLK, IMEM_A, IMEM_Q);
  DMEM: DATA_MEMORY port map (CLK, DMEM_A, DMEM_D, DMEM_WE, DMEM_Q);

  -- clock (period = 10 ns)
  process begin
    CLK <= '1'; wait for 5 ns;
    CLK <= '0'; wait for 5 ns;
  end process;

  -- reset (assert only at the first cycle)
  process begin
    RST <= '0'; wait for 5 ns;
    RST <= '1'; wait for 10 ns;
    RST <= '0'; wait;
  end process;

  -- Mux/Demux for data memory
  -- (Processor side is selected when running)
  DMEM_A      <= PROC_DMEM_A  when HALT = '0' else TEST_DMEM_A;
  DMEM_D      <= PROC_DMEM_D  when HALT = '0' else TEST_DMEM_D;
  DMEM_WE     <= PROC_DMEM_WE when HALT = '0' else TEST_DMEM_WE;
  PROC_DMEM_Q <= DMEM_Q;
  TEST_DMEM_Q <= DMEM_Q;

  -- body of test bench (log files generation)
  process
    variable li, li_dmem : line;
    variable st_dmem : string(1 to 21);
    alias swrite is write [line, string, side, width];
  begin
    -- write header line to instruction trace
    swrite(li, "Address   Inst.       Written");
    writeline(PROC_LOG, li);
    st_dmem(1) := 'X';

    -- initialize input of data memory
    TEST_DMEM_A  <= x"00000400";
    TEST_DMEM_D  <= x"00000000";
    TEST_DMEM_WE <= '0';
    wait for 20 ns;

    -- first loop (while processor is running)
    inst_count <= x"00000000";
    while HALT = '0' loop
      wait until falling_edge(CLK);
      if DMEM_WE = '1' then -- save the write request of data memory
        swrite(li_dmem, " # *(");
        hwrite(li_dmem, DMEM_A(11 downto 0), left);
        swrite(li_dmem, ") <- ");
        hwrite(li_dmem, DMEM_D);
        read(li_dmem, st_dmem);
      end if;
      if DEBUG_EN = '1' then -- write instruction trace
        hwrite(li, IMEM_A, left);
        swrite(li, ": ");
        hwrite(li, IMEM_Q, left);
        if DEBUG_A3 /= "00000" then -- incl. write to register file
          swrite(li, " #    x");
          write(li, conv_integer(DEBUG_A3), left, 2);
          swrite(li, " <- ");
          hwrite(li, DEBUG_D3);
        end if;
        if st_dmem(1) /= 'X' then -- incl. write to data memory
          write(li, st_dmem);
          st_dmem(1) := 'X';
        end if;
        if IMEM_Q /= x"00000033" then -- increment inst. count unless nop
          inst_count <= inst_count + '1';
        end if;
        writeline(PROC_LOG, li);
      end if;
    end loop;

    -- write header line to memory dump
    swrite(li, "executed instruction (except nop): ");
    write(li, conv_integer(inst_count), left);
    writeline(DMEM_DMP, li);
    writeline(DMEM_DMP, li);
    swrite(li, "Address   Hex.       Dec.");
    writeline(DMEM_DMP, li);

    -- second loop (after processor stopped)
    while TEST_DMEM_A < x"000007fc" loop
      wait until falling_edge(CLK);
      if not is_x(TEST_DMEM_Q) then
        hwrite(li, TEST_DMEM_A, left);
        swrite(li, ": ");
        hwrite(li, TEST_DMEM_Q, left);
        swrite(li, " # ");
        write(li, conv_integer(TEST_DMEM_Q), left);
        writeline(DMEM_DMP, li);
      end if;
      TEST_DMEM_A <= TEST_DMEM_A + 4;
    end loop;
    
    -- finish
    wait until rising_edge(CLK);
    assert false severity failure;
  end process;
end SIM;