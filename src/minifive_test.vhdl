-- MINIFIVE: a simple (subset of) RISC-V processor
--   minifive_test.vhdl - test bench of MINIFIVE
-- Copyright (C) 2019-2026 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;
use std.textio.all;
use std.env.all;

entity MINIFIVE_TEST is
end MINIFIVE_TEST;

architecture SIM of MINIFIVE_TEST is
  -- MINIFIVE (PROC) -> minifive.vhdl
  component MINIFIVE is
    port (CLK, RST : in  std_ulogic;
          IMEM_A   : out std_ulogic_vector(31 downto 0);
          IMEM_Q   : in  std_ulogic_vector(31 downto 0);
          DMEM_A   : out std_ulogic_vector(31 downto 0);
          DMEM_D   : out std_ulogic_vector(31 downto 0);
          DMEM_WE  : out std_ulogic;
          DMEM_Q   : in  std_ulogic_vector(31 downto 0);
          HALT     : out std_ulogic);
  end component;

  -- MEMORY1K (IMEM, DMEM) -> memory.vhdl
  component MEMORY1K is
    port (CLK      : in  std_ulogic;
          ADDR     : in  std_ulogic_vector(31 downto 0);
          DATA_IN  : in  std_ulogic_vector(31 downto 0);
          WE       : in  std_ulogic;
          DATA_OUT : out std_ulogic_vector(31 downto 0));
  end component;

  signal CLK, RST       : std_ulogic;
  signal IMEM_A, IMEM_D : std_ulogic_vector(31 downto 0);
  signal IMEM_WE        : std_ulogic;
  signal IMEM_Q         : std_ulogic_vector(31 downto 0);
  signal DMEM_A, DMEM_D : std_ulogic_vector(31 downto 0);
  signal DMEM_WE        : std_ulogic;
  signal DMEM_Q         : std_ulogic_vector(31 downto 0);
  signal PROC_IMEM_A    : std_ulogic_vector(31 downto 0);
  signal PROC_IMEM_Q    : std_ulogic_vector(31 downto 0);
  signal PROC_DMEM_A    : std_ulogic_vector(31 downto 0);
  signal PROC_DMEM_D    : std_ulogic_vector(31 downto 0);
  signal PROC_DMEM_WE   : std_ulogic;
  signal PROC_DMEM_Q    : std_ulogic_vector(31 downto 0);
  signal TEST_IMEM_A    : std_ulogic_vector(31 downto 0);
  signal TEST_IMEM_D    : std_ulogic_vector(31 downto 0);
  signal TEST_IMEM_WE   : std_ulogic;
  signal TEST_IMEM_Q    : std_ulogic_vector(31 downto 0);
  signal TEST_DMEM_A    : std_ulogic_vector(31 downto 0);
  signal TEST_DMEM_D    : std_ulogic_vector(31 downto 0);
  signal TEST_DMEM_WE   : std_ulogic;
  signal TEST_DMEM_Q    : std_ulogic_vector(31 downto 0);
  signal INIT, HALT     : std_ulogic;
  signal inst_count     : std_ulogic_vector(31 downto 0);

  file PROC_LOG  : text open write_mode is "_proc_log.txt";
  file DMEM_DMP  : text open write_mode is "_dmem_dmp.txt";
  file IMEM_INIT : text open read_mode is "program/fibonacci_program.txt";
  file DMEM_INIT : text open read_mode is "program/fibonacci_data.txt";

begin
  PROC: MINIFIVE port map
    (CLK, RST or INIT, PROC_IMEM_A, PROC_IMEM_Q, PROC_DMEM_A, PROC_DMEM_D,
     PROC_DMEM_WE, PROC_DMEM_Q, HALT);
  IMEM: MEMORY1K port map (CLK, IMEM_A, IMEM_D, IMEM_WE, IMEM_Q);
  DMEM: MEMORY1K port map (CLK, DMEM_A, DMEM_D, DMEM_WE, DMEM_Q);

  -- clock (period = 10 ns)
  process begin
    CLK <= '0'; wait for 5 ns;
    CLK <= '1'; wait for 5 ns;    -- reset

    for i in 0 to 255 loop
      CLK <= '0'; wait for 10 ps;
      CLK <= '1'; wait for 10 ps; -- write initial value to memories
    end loop;
    CLK <= '0'; wait for 4880 ps; -- wait to align rising edge per 10 ns

    while HALT = '0' loop
      CLK <= '1'; wait for 5 ns;  -- wait while processor is running
      CLK <= '0'; wait for 5 ns;
    end loop;

    for i in 0 to 255 loop
      CLK <= '1'; wait for 10 ps; -- dump final value of data memory
      CLK <= '0'; wait for 10 ps; 
    end loop;
    wait for 4880 ps;
    finish;
  end process;

  -- reset (assert only at the first cycle)
  process begin
    RST <= '1'; wait for 10 ns;
    RST <= '0'; wait;
  end process;

  -- Mux/Demux for data memory
  -- (Processor side is selected when running)
  IMEM_A      <= PROC_IMEM_A  when not INIT and not HALT else TEST_IMEM_A;
  IMEM_D      <= TEST_IMEM_D;
  IMEM_WE     <= TEST_IMEM_WE;
  DMEM_A      <= PROC_DMEM_A  when not INIT and not HALT else TEST_DMEM_A;
  DMEM_D      <= PROC_DMEM_D  when not INIT and not HALT else TEST_DMEM_D;
  DMEM_WE     <= PROC_DMEM_WE when not INIT and not HALT else TEST_DMEM_WE;
  PROC_IMEM_Q <= IMEM_Q;
  TEST_IMEM_Q <= IMEM_Q;
  PROC_DMEM_Q <= DMEM_Q;
  TEST_DMEM_Q <= DMEM_Q;

  -- body of test bench (incl. memory initialization / log files generation)
  process
    variable li_init, li_log, li_dmem : line;
    variable r_data  : std_ulogic_vector(31 downto 0);
    variable st_dmem : string(1 to 21);
    variable last_x  : boolean;
    alias swrite is write [line, string, side, width];
    
    alias DEBUG_A3 is <<signal PROC.DEBUG_A3 : std_ulogic_vector( 4 downto 0)>>;
    alias DEBUG_D3 is <<signal PROC.DEBUG_D3 : std_ulogic_vector(31 downto 0)>>;
    alias DEBUG_EN is <<signal PROC.DEBUG_EN : std_ulogic>>;
  begin
    -- write header line to instruction trace
    swrite(li_log, "Address   Inst.       Written");
    writeline(PROC_LOG, li_log);
    st_dmem(1) := 'X';

    -- initialize input of memories
    TEST_IMEM_A  <= x"fffffffc";
    TEST_IMEM_D  <= x"00000000";
    TEST_IMEM_WE <= '0';
    TEST_DMEM_A  <= x"000003fc";
    TEST_DMEM_D  <= x"00000000";
    TEST_DMEM_WE <= '0';

    -- first loop (before processor starts)
    INIT <= '1';
    wait for 5 ns;

    while TEST_DMEM_A < x"000007fc" loop
      wait until falling_edge(CLK);
      if not endfile(IMEM_INIT) then -- instruction memory
        readline(IMEM_INIT, li_init);
        hread(li_init, r_data);
        TEST_IMEM_D  <= r_data;
        TEST_IMEM_WE <= '1';
      else
        TEST_IMEM_WE <= '0';
      end if;
      TEST_IMEM_A <= TEST_IMEM_A + 4;

      if not endfile(DMEM_INIT) then -- data memory
        readline(DMEM_INIT, li_init);
        hread(li_init, r_data);
        TEST_DMEM_D  <= r_data;
        TEST_DMEM_WE <= '1';
      else
        TEST_DMEM_WE <= '0';
      end if;
      TEST_DMEM_A <= TEST_DMEM_A + 4;
    end loop;
    
    INIT         <= '0';
    TEST_IMEM_WE <= '0';
    TEST_DMEM_A  <= x"00000400";
    TEST_DMEM_WE <= '0';

    -- second loop (while processor is running)
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
        hwrite(li_log, IMEM_A, left);
        swrite(li_log, ": ");
        hwrite(li_log, IMEM_Q, left);
        if DEBUG_A3 /= "00000" then -- incl. write to register file
          swrite(li_log, " #    x");
          write(li_log, to_integer(DEBUG_A3), left, 2);
          swrite(li_log, " <- ");
          hwrite(li_log, DEBUG_D3);
        end if;
        if st_dmem(1) /= 'X' then -- incl. write to data memory
          write(li_log, st_dmem);
          st_dmem(1) := 'X';
        end if;
        if IMEM_Q /= x"00000033" then -- increment inst. count unless nop
          inst_count <= inst_count + '1';
        end if;
        writeline(PROC_LOG, li_log);
      end if;
    end loop;

    -- write header line to memory dump
    swrite(li_log, "executed instruction (except nop): ");
    write(li_log, to_integer(inst_count), left);
    writeline(DMEM_DMP, li_log);
    writeline(DMEM_DMP, li_log);
    swrite(li_log, "Address   Hex.       Dec.");
    writeline(DMEM_DMP, li_log);

    -- third loop (after processor stopped)
    last_x := false;
    while TEST_DMEM_A < x"000007fc" loop
      wait until falling_edge(CLK);
      if not is_x(TEST_DMEM_Q) then
        if last_x then
          swrite(li_log, "...");
          writeline(DMEM_DMP, li_log);
        end if;
        hwrite(li_log, TEST_DMEM_A, left);
        swrite(li_log, ": ");
        hwrite(li_log, TEST_DMEM_Q, left);
        swrite(li_log, " # ");
        write(li_log, to_integer(TEST_DMEM_Q), left);
        writeline(DMEM_DMP, li_log);
      end if;
      last_x := is_x(TEST_DMEM_Q);
      TEST_DMEM_A <= TEST_DMEM_A + 4;
    end loop;
    
    -- finish (called in the CLK process)
    wait;
  end process;
end SIM;