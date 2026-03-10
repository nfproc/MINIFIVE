-- MINIFIVE: a simple (subset of) RISC-V processor
--   regfile.vhdl - レジスタファイル
------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std_unsigned.all;

entity REGFILE is
  port (CLK        : in  std_ulogic;
        A1, A2, A3 : in  std_ulogic_vector( 4 downto 0);
        D3         : in  std_ulogic_vector(31 downto 0);
        WE3        : in  std_ulogic; -- write enable（書込み有効か）
        Q1, Q2     : out std_ulogic_vector(31 downto 0));
end REGFILE;

architecture RTL of REGFILE is
  type MEM_TYPE is array(0 to 31) of std_ulogic_vector(31 downto 0);
  signal MEM : MEM_TYPE;

  type OUT_SOURCE is (SRC_MEM, SRC_ZERO, SRC_WRITE);
  signal Q_MEM1, Q_MEM2, Q_WRITE : std_ulogic_vector(31 downto 0);
  signal Q_SRC1, Q_SRC2          : OUT_SOURCE;
begin

  -- RAMの制御
  process (CLK) begin
    if rising_edge(CLK) then
      if WE3 then
        MEM(to_integer(A3)) <= D3;
      end if;
      Q_MEM1 <= MEM(to_integer(A1));
      Q_MEM2 <= MEM(to_integer(A2));
    end if;
  end process;

  -- 出力の制御
  Q1 <= x"00000000" when Q_SRC1 = SRC_ZERO  else
        Q_WRITE     when Q_SRC1 = SRC_WRITE else
        Q_MEM1;
  Q2 <= x"00000000" when Q_SRC2 = SRC_ZERO  else
        Q_WRITE     when Q_SRC2 = SRC_WRITE else
        Q_MEM2;  

  -- 出力の決定ロジック
  process (CLK) begin
    if rising_edge(CLK) then
      Q_WRITE <= D3;
      Q_SRC1  <= SRC_ZERO  when A1 = "00000"          else -- x0 は必ずゼロ
                 SRC_WRITE when A1 = A3 and WE3 = '1' else -- 書き込みを優先する
                 SRC_MEM;
      Q_SRC2  <= SRC_ZERO  when A2 = "00000"          else
                 SRC_WRITE when A2 = A3 and WE3 = '1' else
                 SRC_MEM;
    end if;
  end process;
end RTL;