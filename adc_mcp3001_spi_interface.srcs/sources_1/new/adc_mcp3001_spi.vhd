library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity adc_mcp3001_spi is
  port (    clk             : in    std_logic;
            rst             : in    std_logic;
            start           : in    std_logic;
            -- SPI SIGNALS
            mcp3001_miso    : in    std_logic;
            mcp3001_cs_n    : out   std_logic;
            mcp3001_clk     : out   std_logic;
            -- Interface signals
            -- wr_ack          : in    std_logic;
            dout            : out   std_logic_vector(9 downto 0);
            wr_en           : out   std_logic
  );
end adc_mcp3001_spi;

architecture adc_mcp3001_spi_arch of adc_mcp3001_spi is

-- state declaration
type state_type is (idle,rx,store);
signal state, next_state : state_type;
-- output registers
signal reg_cs_n : std_logic:='1';
signal reg_clk  : std_logic:='0';
signal reg_dout : std_logic_vector(12 downto 0):=(others => '0');
signal reg_wr_en: std_logic:='0';
-- Internal Counter
signal      dcount  : unsigned(3 downto 0):=(others => '0');
signal      cdiv    : unsigned(1 downto 0):=(others => '0');
constant    wbit    : unsigned(3 downto 0):= "1101"; --(Z,Z,NULL,D9,D8,D7,D6,D5,D4,D3,D2,D1,D0)
constant    crel    : unsigned(1 downto 0):= "10";
begin

MCP3001_CLK_GENERATOR: process(clk)
begin
  if (clk'event and clk = '1') then
    if (rst = '1') then
        reg_clk     <= '0';
    else
        if(cdiv < crel - 1) then
            cdiv        <= cdiv + 1;
            reg_clk     <= reg_clk;
        else
            cdiv        <= "00";
            reg_clk     <= not reg_clk;
        end if;
    end if;
  end if;
end process MCP3001_CLK_GENERATOR;

SYNC_PROC: process (reg_clk)
begin
  if (reg_clk'event and reg_clk = '1') then
     if (rst = '1') then
        state       <= idle;
     else
        state       <= next_state;

     end if;
  end if;
end process;



--MOORE State-Machine - Outputs based on state only
OUTPUT_DECODE: process (reg_clk)
begin
if (reg_clk'event and reg_clk = '1') then
  case state is
    when idle =>
        reg_cs_n    <= '1';
        reg_wr_en   <= '0';
        reg_dout    <= reg_dout;
        dcount      <= (others => '0');
     when rx =>
        reg_cs_n    <= '0';
        reg_wr_en   <= '0';
        reg_dout    <= reg_dout(11 downto 0) & mcp3001_miso;
        if(dcount < wbit -1) then
            dcount <= dcount + 1;
        end if;
     when store =>
        reg_cs_n    <= '1';
        reg_wr_en   <= '1';
        reg_dout    <= reg_dout(11 downto 0) & mcp3001_miso;
        dcount      <= (others => '0');
   end case;
end if;    
end process;

--NEXT_STATE_DECODE: process (state, start, dcount, wr_ack)
NEXT_STATE_DECODE: process (state, start, dcount)
begin
  next_state <= state;
  case (state) is
     when idle =>
        if start = '1' then
           next_state <= rx;
        end if;
     when rx =>
        if (dcount = wbit -1) then
           next_state <= store;
        end if;
     when store =>
        --if(wr_ack = '1') then
            next_state <= idle;
        --end if;
  end case;
end process;

-- output
mcp3001_cs_n    <= reg_cs_n;
wr_en           <= reg_wr_en;
dout            <= reg_dout(9 downto 0);
mcp3001_clk     <= reg_clk;
end adc_mcp3001_spi_arch;
