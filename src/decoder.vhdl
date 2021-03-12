-- MINIFIVE: a simple (subset of) RISC-V processor
--   decoder.vhdl - instruction decoder
-- Copyright (C) 2019-2021 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity DECODER is
  port (INST     : in  std_logic_vector(31 downto 0);
        BRANCH   : out std_logic;
        IFEQUAL  : out std_logic;
        REG_WE3  : out std_logic;
        B_SRC    : out std_logic_vector( 1 downto 0);
        ALU_OP   : out std_logic_vector( 4 downto 0);
        DMEM_WE  : out std_logic;
        D3_SRC   : out std_logic;
        UNDEF    : out std_logic);
end DECODER;

architecture RTL of DECODER is
  signal OPCODE : std_logic_vector(6 downto 0);
  signal FUNCT3 : std_logic_vector(2 downto 0);
  signal FUNCT7 : std_logic_vector(6 downto 0);
begin
  OPCODE <= INST( 6 downto  0);
  FUNCT3 <= INST(14 downto 12);
  FUNCT7 <= INST(31 downto 25);

  process (INST, OPCODE, FUNCT3, FUNCT7) begin
    BRANCH   <= '0';
    IFEQUAL  <= '0';
    REG_WE3  <= '0';
    B_SRC    <= "00";
    ALU_OP   <= "00000";
    DMEM_WE  <= '0';
    D3_SRC   <= '0';
    UNDEF    <= '0';
    if    OPCODE = "0110011" then -- R-type Arithmetic/Logic/etc.
      REG_WE3  <= '1';                      -- write to register file
      B_SRC    <= "00";                     -- B input of ALU = rs2
      ALU_OP   <= '0' & FUNCT7(5) & FUNCT3; -- ALU control signal
    elsif OPCODE = "0010011" then -- I-type Arithmetic/Logic/etc.
      REG_WE3  <= '1';
      B_SRC    <= "01";                     -- B input of ALU = I-type imm.
      ALU_OP   <= "00" & FUNCT3;
    elsif OPCODE = "0000011" then -- Load Instruction
      REG_WE3  <= '1';
      B_SRC    <= "01";
      ALU_OP   <= "00000";                  -- ALU control = addition
      D3_SRC   <= '1';                      -- write data = data memory output
    elsif OPCODE = "0100011" then -- Store Instruction
      B_SRC    <= "10";                     -- B input of ALU = S-type imm.
      ALU_OP   <= "00000";
      DMEM_WE  <= '1';                      -- write to data memory
    elsif OPCODE = "0110111" then -- lui Instruction
      REG_WE3  <= '1';
      B_SRC    <= "11";                     -- B input of ALU = U-type imm.
      ALU_OP   <= "10000";                  -- ALU control = B input
    elsif OPCODE = "1100011" then -- Branch Instruction
      BRANCH   <= '1';                      -- Branch is taken if ...
      if FUNCT3 = "000" then
        IFEQUAL  <= '1';                    --   rs1 = rs2 (rs1 - rs2 = 0)
      end if;
      ALU_OP   <= "01000";                  -- ALU control = subtraction
    else                          -- Others
      UNDEF    <= '1';                      -- stop processor
    end if;
  end process;
end RTL;
