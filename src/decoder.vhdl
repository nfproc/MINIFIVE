-- MINIFIVE: a simple (subset of) RISC-V processor
--   decoder.vhdl - instruction decoder
-- Copyright (C) 2019-2023 Naoki FUJIEDA. New BSD License is applied.
------------------------------------------------------------------------

-- FORMAT output signal is encoded as follows:
--   000 - R-type
--   001 - I-type
--   010 - S-type
--   011 - B-type
--   100 - U-type
--   101 - J-type

-- BR_COND output signal is encoded as follows:
--   00 - never taken (i.e., neither branch nor jump)
--   01 - taken if ALU output is zero
--   10 - taken if ALU output is non-zero
--   11 - always taken (i.e., jump instruction)

-- ALU_OP output signal is encoded as follows:
--   00000 - addition
--   00001 - left shift
--   00010 - 1 if A < B else 0 (signed)
--   00011 - 1 if A < B else 0 (unsigned)
--   00100 - XOR
--   00101 - logical right shift
--   00110 - OR
--   00111 - AND
--   01000 - subtraction
--   01101 - arithmetic right shift
--   10000 - output B

library IEEE;
use IEEE.std_logic_1164.all;

entity DECODER is
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
    FORMAT   <= "000";
    BR_COND  <= "00";
    REG_WE3  <= '0';
    A_SRC    <= '0';
    B_SRC    <= '0';
    ALU_OP   <= "00000";
    DMEM_WE  <= '0';
    D3_SRC   <= "00";
    UNDEF    <= '0';
    if    OPCODE = "0110011" then -- R-type Arithmetic/Logic/etc.
      FORMAT   <= "000";                    -- R-type
      REG_WE3  <= '1';                      -- write to register file
      ALU_OP   <= '0' & FUNCT7(5) & FUNCT3; -- ALU control = depending on funct
    elsif OPCODE = "0010011" then -- I-type Arithmetic/Logic/etc.
      FORMAT   <= "001";                    -- I-type
      REG_WE3  <= '1';
      B_SRC    <= '1';                      -- ALU input B = immediate
      ALU_OP   <= "00" & FUNCT3;
    elsif OPCODE = "0110111" then -- lui instruction
      FORMAT   <= "100";                    -- U-type
      REG_WE3  <= '1';
      B_SRC    <= '1';
      ALU_OP   <= "10000";                  -- ALU control = output B
    elsif OPCODE = "0010111" then -- auipc instruction
      FORMAT   <= "100";                    -- U-type
      REG_WE3  <= '1';
      A_SRC    <= '1';                      -- ALU input A = current PC
      B_SRC    <= '1';
      ALU_OP   <= "00000";                  -- ALU control = addition
    elsif OPCODE = "0000011" then -- Load Instruction
      FORMAT   <= "001";                    -- I-type
      REG_WE3  <= '1';
      B_SRC    <= '1';
      ALU_OP   <= "00000";                  -- ALU control = addition
      D3_SRC   <= "01";                     -- write data = data memory output
    elsif OPCODE = "0100011" then -- Store Instruction
      FORMAT   <= "010";                    -- S-type
      B_SRC    <= '1';
      ALU_OP   <= "00000";
      DMEM_WE  <= '1';                      -- write to data memory
    elsif OPCODE = "1100011" then -- Branch Instruction
      FORMAT   <= "011";                    -- B-type
      if FUNCT3 = "000" or FUNCT3 = "101" or FUNCT3 = "111" then
        BR_COND  <= "01";                   -- branch if ALU outputs zero
      else
        BR_COND  <= "10";                   -- branch if ALU outputs non-zero
      end if;
      if FUNCT3(2 downto 1) = "00" then
        ALU_OP   <= "01000";                -- ALU control = subtraction
      elsif FUNCT3(2 downto 1) = "10" then
        ALU_OP   <= "00010";                -- ALU control = SLT signed
      else
        ALU_OP   <= "00011";                -- ALU control = SLT unsigned
      end if;
    elsif OPCODE = "1101111" then -- jal instruction
      FORMAT   <= "101";                    -- J-type
      BR_COND  <= "11";                     -- branch always taken
      REG_WE3  <= '1';
      A_SRC    <= '1';
      B_SRC    <= '1';
      ALU_OP   <= "00000";                  -- ALU control = addition
      D3_SRC   <= "10";                     -- write data = next PC (PC + 4)
    elsif OPCODE = "1100111" then -- jalr instruction
      FORMAT   <= "001";                    -- I-type
      BR_COND  <= "11";
      REG_WE3  <= '1';
      B_SRC    <= '1';
      ALU_OP   <= "00000";                  -- ALU control = addition
      D3_SRC   <= "10";
    else                          -- Others
      UNDEF    <= '1';                      -- stop processor
    end if;
  end process;
end RTL;
