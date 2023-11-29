library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;


entity adc_mcp3001_spi_interface is
  port (    adc_clk             : in    std_logic;
            adc_rst             : in    std_logic;
            adc_start           : in    std_logic;
            -- SPI SIGNALS
            adc_mcp3001_miso    : in    std_logic;
            adc_mcp3001_cs_n    : out   std_logic;
            adc_mcp3001_clk     : out   std_logic;
            -- FIFO SIGNALS
            adc_fifo_rd_clk     : in    std_logic;
            adc_fifo_rd_en      : in    std_logic;
            adc_fifo_full       : out   std_logic;
            adc_fifo_empty      : out   std_logic;
            adc_fifo_valid      : out   std_logic;
            adc_fifo_prog_full  : out   std_logic;
            adc_dout            : out   std_logic_vector(9 downto 0)
  );
end adc_mcp3001_spi_interface;

architecture adc_mcp3001_spi_interface_arch of adc_mcp3001_spi_interface is

--  PPL from 100Mhz to 11.2Mhz Component declaration
component ppl_11_2
  port (    clk11_2mhz        : out    std_logic;
            reset             : in     std_logic;
            locked            : out    std_logic;   -- do not operate until locked
            clk100mhz         : in     std_logic
  );
end component ppl_11_2;

-- adc spi and fifo interface
-- while start is high it will sample at 2.8Mhz
component adc_mcp3001_spi
  Port (    clk             : in    std_logic;
            rst             : in    std_logic;
            start           : in    std_logic;
            mcp3001_miso    : in    std_logic;
            mcp3001_cs_n    : out   std_logic;
            mcp3001_clk     : out   std_logic;
            --wr_ack          : in    std_logic;
            dout            : out   std_logic_vector(9 downto 0);   -- only valid once every 14 clk11_2mhz cycles
            wr_en           : out   std_logic);                     -- wr to fifo when valid
            
end component adc_mcp3001_spi;
-- stores sequential data
component adc_fifo
  port (	rst 		: IN STD_LOGIC;
			wr_clk 		: IN STD_LOGIC;                             -- write f=0,2 Mhz
			rd_clk 		: IN STD_LOGIC;                             -- read  f leq 0,2 Mhz
			din 		: IN STD_LOGIC_VECTOR(9 DOWNTO 0);          -- data from spi adc
			wr_en 		: IN STD_LOGIC;                             -- wr enable from spi adc
			rd_en 		: IN STD_LOGIC;                             -- read from external modules
			dout		: OUT STD_LOGIC_VECTOR(9 DOWNTO 0);         -- dout every rd_clk clock cycle
			full		: OUT STD_LOGIC;                            -- full fifo
			wr_ack		: OUT STD_LOGIC;                            -- wr acknowledge
			empty		: OUT STD_LOGIC;                            -- empty fifo
			valid		: OUT STD_LOGIC;                            -- valid read data
			prog_full	: OUT STD_LOGIC);                           -- half way full
end component;

-- PLL SIGNALS
signal ppl_11_2_locked          : std_logic;
signal ppl_11_2_output          : std_logic;
-- SPI SIGNALS
signal adc_mcp3001_spi_rst      : std_logic;
signal reg_adc_mcp3001_cs_n     : std_logic;
signal reg_adc_mcp3001_clk      : std_logic;
signal reg_adc_dout             : std_logic_vector(9 downto 0);
signal reg_adc_wr_en            : std_logic;
-- FIFO SIGNALS
signal fifo_reg_dout            : STD_LOGIC_VECTOR(9 DOWNTO 0);
signal fifo_reg_full            : STD_LOGIC;
--signal fifo_reg_wr_ack          : STD_LOGIC;
signal fifo_reg_empty           : STD_LOGIC;
signal fifo_reg_valid           : STD_LOGIC;
signal fifo_reg_prog_full       : STD_LOGIC;

begin

ppl_11_2_inst : ppl_11_2
  port map (   clk11_2mhz  => ppl_11_2_output,
               reset       => adc_rst,
               locked      => ppl_11_2_locked,
               clk100mhz   => adc_clk);
               
adc_mcp3001_spi_inst : adc_mcp3001_spi
  port map(    clk             => ppl_11_2_output,
               rst             => adc_mcp3001_spi_rst,
               start           => adc_start,
               mcp3001_miso    => adc_mcp3001_miso,
               mcp3001_cs_n    => reg_adc_mcp3001_cs_n,
               mcp3001_clk     => reg_adc_mcp3001_clk,
               --wr_ack          => fifo_reg_wr_ack,
               dout            => reg_adc_dout,
               wr_en           => reg_adc_wr_en);
               
adc_fifo_isnt : adc_fifo
  port map (     rst        => adc_mcp3001_spi_rst,
			     wr_clk     => reg_adc_mcp3001_clk,
			     rd_clk     => adc_fifo_rd_clk,
			     din		=> reg_adc_dout,
			     wr_en		=> reg_adc_wr_en,
			     rd_en		=> adc_fifo_rd_en,
			     dout		=> fifo_reg_dout,
			     full		=> fifo_reg_full,
			     --wr_ack		=> fifo_reg_wr_ack,
			     wr_ack		=> open,
			     empty		=> fifo_reg_empty,
			     valid		=> fifo_reg_valid,
			     prog_full	=> fifo_reg_prog_full);
			     
			              
-- Internal condition
adc_mcp3001_spi_rst <= (adc_rst) and (not ppl_11_2_locked); -- both condition most be satisfy, reset low and pll locked
-- Register to output 
adc_mcp3001_cs_n		<=		reg_adc_mcp3001_cs_n; -- to ADC
adc_mcp3001_clk 		<=		reg_adc_mcp3001_clk;  -- to ADC
adc_dout        		<=		fifo_reg_dout;        -- to other ips
adc_fifo_full           <=      fifo_reg_full; 
adc_fifo_empty          <=      fifo_reg_empty;
adc_fifo_valid          <=      fifo_reg_valid;
adc_fifo_prog_full      <=      fifo_reg_prog_full;

end adc_mcp3001_spi_interface_arch;
