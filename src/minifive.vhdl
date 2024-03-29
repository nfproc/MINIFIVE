-- MINIFIVE: a simple (subset of) RISC-V processor
--   minifive.vhdl - top module of processor
-- Copyright (C) 2019-2023 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity MINIFIVE is
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
end MINIFIVE;

architecture RTL of MINIFIVE is
  -- DECODER -> decoder.vhdl
  component DECODER is
    port (INST     : in  std_logic_vector(31 downto 0);
          FORMAT   : out std_logic_vector( 2 downto 0);
          BR_COND  : out std_logic_vector( 1 downto 0);
          REG_WE3  : out std_logic;
          A_SRC    : out std_logic;
          B_SRC    : out std_logic;
          ALU_OP   : out std_logic_vector( 4 downto 0);
          DMEM_WE  : out std_logic;
          D3_SRC   : out std_logic_vector( 1 downto 0);
          UNDEF    : out std_logic);
  end component;

  -- REGFILE -> regfile.vhdl
  component REGFILE is
    port (CLK        : in  std_logic;
          A1, A2, A3 : in  std_logic_vector( 4 downto 0);
          D3         : in  std_logic_vector(31 downto 0);
          WE3        : in  std_logic; -- write enable
          Q1, Q2     : out std_logic_vector(31 downto 0));
  end component;

  -- IMM_EXTEND -> immextend.vhdl
  component IMM_EXTEND is
    port (INST     : in  std_logic_vector(31 downto 0);
          FORMAT   : in  std_logic_vector( 2 downto 0);
          IMM      : out std_logic_vector(31 downto 0));
  end component;

  -- ALU -> alu.vhdl
  component ALU is
    port (A, B   : in  std_logic_vector(31 downto 0);
          ALU_OP : in  std_logic_vector( 4 downto 0);
          Y      : out std_logic_vector(31 downto 0);
          Y_ZERO : out std_logic);
  end component;

  -- BRANCH -> branch.vhdl
  component BRANCH is
    port (BR_COND  : in  std_logic_vector( 1 downto 0);
          ALU_ZERO : in  std_logic;
          PC_SRC   : out std_logic_vector( 1 downto 0));
  end component;

  ---- internal signals
  -- state machine
  type STATE_TYPE is (STATE_IF, STATE_ID, STATE_EX,
                      STATE_MA, STATE_WB, STATE_HALT);
  signal STATE, NEXT_STATE : STATE_TYPE;

  -- IF Stage (instruction fetch)
  signal IF_PC          : std_logic_vector(31 downto 0);
  signal IF_PC_PLUS4    : std_logic_vector(31 downto 0);
  signal IF_NEXT_PC     : std_logic_vector(31 downto 0);
  --port IMEM_A

  -- IF <-> ID
  signal IFID_PC        : std_logic_vector(31 downto 0);
  signal IFID_PC_PLUS4  : std_logic_vector(31 downto 0);

  -- ID Stage (instruction decode)
  signal ID_INST        : std_logic_vector(31 downto 0);
  signal ID_A1, ID_A2, ID_A3 : std_logic_vector( 4 downto 0);
  signal ID_D3          : std_logic_vector(31 downto 0);
  signal ID_WE3         : std_logic;
  signal ID_RD          : std_logic_vector( 4 downto 0);
  signal ID_IMM         : std_logic_vector(31 downto 0);

  signal ID_FORMAT      : std_logic_vector( 2 downto 0);
  signal ID_BR_COND     : std_logic_vector( 1 downto 0);
  signal ID_REG_WE3     : std_logic;
  signal ID_A_SRC       : std_logic;
  signal ID_B_SRC       : std_logic;
  signal ID_ALU_OP      : std_logic_vector( 4 downto 0);
  signal ID_DMEM_WE     : std_logic;
  signal ID_D3_SRC      : std_logic_vector( 1 downto 0);
  signal ID_UNDEF       : std_logic;

  -- ID <-> EX
  signal IDEX_RS1, IDEX_RS2 : std_logic_vector(31 downto 0);
  signal IDEX_RD        : std_logic_vector( 4 downto 0);
  signal IDEX_IMM       : std_logic_vector(31 downto 0);
  signal IDEX_PC        : std_logic_vector(31 downto 0);
  signal IDEX_PC_PLUS4  : std_logic_vector(31 downto 0);

  signal IDEX_BR_COND   : std_logic_vector( 1 downto 0);
  signal IDEX_REG_WE3   : std_logic;
  signal IDEX_A_SRC     : std_logic;
  signal IDEX_B_SRC     : std_logic;
  signal IDEX_ALU_OP    : std_logic_vector( 4 downto 0);
  signal IDEX_DMEM_WE   : std_logic;
  signal IDEX_D3_SRC    : std_logic_vector( 1 downto 0);
  signal IDEX_UNDEF     : std_logic;

  -- EX Stage (execute)
  signal EX_ALU_A, EX_ALU_B : std_logic_vector(31 downto 0);
  signal EX_ALU_Y       : std_logic_vector(31 downto 0);
  signal EX_ALU_ZERO    : std_logic;
  signal EX_BRANCH_PC   : std_logic_vector(31 downto 0);
  signal EX_PC_SRC      : std_logic_vector( 1 downto 0);

  -- EX <-> MA
  signal EXMA_ALU_Y     : std_logic_vector(31 downto 0);
  signal EXMA_RS2       : std_logic_vector(31 downto 0);
  signal EXMA_RD        : std_logic_vector( 4 downto 0);
  signal EXMA_BRANCH_PC : std_logic_vector(31 downto 0);
  signal EXMA_PC_PLUS4  : std_logic_vector(31 downto 0);

  signal EXMA_PC_SRC    : std_logic_vector( 1 downto 0);
  signal EXMA_REG_WE3   : std_logic;
  signal EXMA_DMEM_WE   : std_logic;
  signal EXMA_D3_SRC    : std_logic_vector( 1 downto 0);
  signal EXMA_UNDEF     : std_logic;

  -- MA Stage (memory access)
  -- * no internal signals (data memory-related signals are given as ports)

  -- MA <-> WB
  signal MAWB_ALU_Y     : std_logic_vector(31 downto 0);
  signal MAWB_RD        : std_logic_vector( 4 downto 0);
  signal MAWB_BRANCH_PC : std_logic_vector(31 downto 0);
  signal MAWB_PC_PLUS4  : std_logic_vector(31 downto 0);

  signal MAWB_PC_SRC    : std_logic_vector( 1 downto 0);
  signal MAWB_REG_WE3   : std_logic;
  signal MAWB_D3_SRC    : std_logic_vector( 1 downto 0);
  signal MAWB_UNDEF     : std_logic;

  -- WB Stage (write back)
  signal WB_RESULT      : std_logic_vector(31 downto 0);

begin
  -- state machine (state transition)
  HALT  <= '1' when STATE = STATE_HALT else '0';

  process (STATE, MAWB_UNDEF) begin
    if    STATE = STATE_IF then
      NEXT_STATE <= STATE_ID;
    elsif STATE = STATE_ID then
      NEXT_STATE <= STATE_EX;
    elsif STATE = STATE_EX then
      NEXT_STATE <= STATE_MA;
    elsif STATE = STATE_MA then
      NEXT_STATE <= STATE_WB;
    elsif STATE = STATE_WB then
      if MAWB_UNDEF = '1' then
        NEXT_STATE <= STATE_HALT; -- stop if unknown inst. has come
      else
        NEXT_STATE <= STATE_IF;   -- otherwise, proceed to next inst.
      end if;
    else
      NEXT_STATE <= STATE_HALT;
    end if;
  end process;

  process (CLK) begin
    if rising_edge(CLK) then
      if RST = '1' then
        STATE <= STATE_IF;
      else
        STATE <= NEXT_STATE;
      end if;
    end if;
  end process;

  -- IF Stage (instruction fetch)
  IMEM_A      <= IF_PC;
  IF_PC_PLUS4 <= IF_PC + 4;
  IF_NEXT_PC  <= IF_PC_PLUS4    when MAWB_PC_SRC = "00" else
                 MAWB_BRANCH_PC when MAWB_PC_SRC = "01" else
                 MAWB_ALU_Y;
  
  -- IF <-> ID
  process (CLK) begin
    if rising_edge(CLK) then
      if RST = '1' then
        IF_PC         <= x"00000000";
        IFID_PC       <= x"00000000";
        IFID_PC_PLUS4 <= x"00000000";
      elsif STATE = STATE_IF then
        IFID_PC       <= IF_PC;
        IFID_PC_PLUS4 <= IF_PC_PLUS4;
      elsif STATE = STATE_WB then
        IF_PC         <= IF_NEXT_PC;
      end if;
    end if;
  end process;

  -- ID Stage (instruction decode)
  DEC: DECODER port map
    (ID_INST, ID_FORMAT, ID_BR_COND, ID_REG_WE3, ID_A_SRC, ID_B_SRC,
     ID_ALU_OP, ID_DMEM_WE, ID_D3_SRC, ID_UNDEF);
  RF: REGFILE port map
    (CLK, ID_A1, ID_A2, ID_A3, ID_D3, ID_WE3, IDEX_RS1, IDEX_RS2);
  EXT: IMM_EXTEND port map
    (ID_INST, ID_FORMAT, ID_IMM);
  
  ID_INST  <= IMEM_Q;
  ID_A1    <= ID_INST(19 downto 15);
  ID_A2    <= ID_INST(24 downto 20);
  ID_A3    <= MAWB_RD;
  ID_D3    <= WB_RESULT;
  ID_WE3   <= MAWB_REG_WE3 when STATE = STATE_WB else '0';
  ID_RD    <= ID_INST(11 downto  7);
  
  -- ID <-> EX
  process (CLK) begin
    if rising_edge(CLK) then
      if RST = '1' then
        IDEX_RD       <= "00000";
        IDEX_IMM      <= x"00000000";
        IDEX_PC       <= x"00000000";
        IDEX_PC_PLUS4 <= x"00000000";
        IDEX_BR_COND  <= "00";
        IDEX_REG_WE3  <= '0';
        IDEX_A_SRC    <= '0';
        IDEX_B_SRC    <= '0';
        IDEX_ALU_OP   <= "00000";
        IDEX_DMEM_WE  <= '0';
        IDEX_D3_SRC   <= "00";
        IDEX_UNDEF    <= '0';
      elsif STATE = STATE_ID then
        IDEX_RD       <= ID_RD;
        IDEX_IMM      <= ID_IMM;
        IDEX_PC       <= IFID_PC;
        IDEX_PC_PLUS4 <= IFID_PC_PLUS4;
        IDEX_BR_COND  <= ID_BR_COND;
        IDEX_REG_WE3  <= ID_REG_WE3;
        IDEX_A_SRC    <= ID_A_SRC;
        IDEX_B_SRC    <= ID_B_SRC;
        IDEX_ALU_OP   <= ID_ALU_OP;
        IDEX_DMEM_WE  <= ID_DMEM_WE;
        IDEX_D3_SRC   <= ID_D3_SRC;
        IDEX_UNDEF    <= ID_UNDEF;
      end if;
    end if;
  end process;

  -- EX Stage (execute)
  AL: ALU port map
    (EX_ALU_A, EX_ALU_B, IDEX_ALU_OP, EX_ALU_Y, EX_ALU_ZERO);
  BR: BRANCH port map
    (IDEX_BR_COND, EX_ALU_ZERO, EX_PC_SRC);
  
  EX_ALU_A     <= IDEX_RS1   when IDEX_A_SRC = '0' else IDEX_PC;
  EX_ALU_B     <= IDEX_RS2   when IDEX_B_SRC = '0' else IDEX_IMM;
  EX_BRANCH_PC <= IDEX_PC + IDEX_IMM;

  -- EX <-> MA
  process (CLK) begin
    if rising_edge(CLK) then
      if RST = '1' then
        EXMA_ALU_Y     <= x"00000000";
        EXMA_RS2       <= x"00000000";
        EXMA_RD        <= "00000";
        EXMA_BRANCH_PC <= x"00000000";
        EXMA_PC_PLUS4  <= x"00000000";
        EXMA_PC_SRC    <= "00";
        EXMA_REG_WE3   <= '0';
        EXMA_DMEM_WE   <= '0';
        EXMA_D3_SRC    <= "00";
        EXMA_UNDEF     <= '0';
      elsif STATE = STATE_EX then
        EXMA_ALU_Y     <= EX_ALU_Y;
        EXMA_RS2       <= IDEX_RS2;
        EXMA_RD        <= IDEX_RD;
        EXMA_BRANCH_PC <= EX_BRANCH_PC;
        EXMA_PC_PLUS4  <= IDEX_PC_PLUS4;
        EXMA_PC_SRC    <= EX_PC_SRC;
        EXMA_REG_WE3   <= IDEX_REG_WE3;
        EXMA_DMEM_WE   <= IDEX_DMEM_WE;
        EXMA_D3_SRC    <= IDEX_D3_SRC;
        EXMA_UNDEF     <= IDEX_UNDEF;
      end if;
    end if;
  end process;

  -- MA Stage (memory access)
  DMEM_A  <= EXMA_ALU_Y;
  DMEM_D  <= EXMA_RS2;
  DMEM_WE <= EXMA_DMEM_WE when STATE = STATE_MA else '0';

  -- MA <-> WB
  process (CLK) begin
    if rising_edge(CLK) then
      if RST = '1' then
        MAWB_ALU_Y     <= x"00000000";
        MAWB_RD        <= "00000";
        MAWB_BRANCH_PC <= x"00000000";
        MAWB_PC_PLUS4  <= x"00000000";
        MAWB_PC_SRC    <= "00";
        MAWB_REG_WE3   <= '0';
        MAWB_D3_SRC    <= "00";
        MAWB_UNDEF     <= '0';
      elsif STATE = STATE_MA then
        MAWB_ALU_Y     <= EXMA_ALU_Y;
        MAWB_RD        <= EXMA_RD;
        MAWB_BRANCH_PC <= EXMA_BRANCH_PC;
        MAWB_PC_PLUS4  <= EXMA_PC_PLUS4;
        MAWB_PC_SRC    <= EXMA_PC_SRC;
        MAWB_REG_WE3   <= EXMA_REG_WE3;
        MAWB_D3_SRC    <= EXMA_D3_SRC;
        MAWB_UNDEF     <= EXMA_UNDEF;
      end if;
    end if;
  end process;
  
  -- WB State (write back)
  WB_RESULT <= MAWB_ALU_Y    when MAWB_D3_SRC = "00" else
               DMEM_Q        when MAWB_D3_SRC = "01" else
               MAWB_PC_PLUS4;

  -- debug signals (used by test bench)
  DEBUG_A3 <= ID_A3 when ID_WE3 = '1' else "00000";
  DEBUG_D3 <= ID_D3;
  DEBUG_EN <= '1' when STATE = STATE_WB else '0';

end RTL;