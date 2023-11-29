library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;


entity adc_mcp3001_spi_tb is

end adc_mcp3001_spi_tb;

architecture adc_mcp3001_spi_tb_arch of adc_mcp3001_spi_tb is

component adc_mcp3001_spi
  Port (    clk             : in    std_logic;
            rst             : in    std_logic;
            start           : in    std_logic;
            -- SPI SIGNALS
            mcp3001_miso    : in    std_logic;
            mcp3001_cs_n    : out   std_logic;
            mcp3001_clk     : out   std_logic;
            -- Interface signals
            dout            : out   std_logic_vector(9 downto 0);
            wr_en           : out   std_logic
            
  );
end component adc_mcp3001_spi;

signal reg_clk             : std_logic:='0';
signal reg_rst             : std_logic:='0';
signal reg_start           : std_logic:='0';
signal reg_mcp3001_miso    : std_logic:='0';
signal reg_mcp3001_cs_n    : std_logic;
signal reg_mcp3001_clk     : std_logic;
signal reg_dout            : std_logic_vector(9 downto 0);
signal reg_wr_en           : std_logic;

constant period            : time := 10 ns;
constant STIMULI           : std_logic_vector(12 downto 0):="ZZ00110110110";

begin

adc_mcp3001_spi_inst: adc_mcp3001_spi
port map(   clk          	=>	reg_clk,         
            rst          	=>	reg_rst,           
            start        	=>	reg_start,          
            mcp3001_miso 	=>	reg_mcp3001_miso,   
            mcp3001_cs_n 	=>	reg_mcp3001_cs_n,  
            mcp3001_clk  	=>	reg_mcp3001_clk,  
            dout         	=>	reg_dout,   
            wr_en   		=>	reg_wr_en);

clk_process: process
begin
    reg_clk <= not reg_clk;
    wait for period/2;
end process clk_process;

rst_process: process
begin
    wait for 2*period;
    reg_rst <= '1';
    wait for 2*period;
    reg_rst <= '0';
    wait;
end process rst_process;

verification_process: process
begin
    wait for 5*period;
    
    wait for 3*period;
    reg_start <= '1';
    wait until falling_edge(reg_mcp3001_cs_n);
    reg_start <= '0';
    for idx in 12 downto 0 loop
        wait until falling_edge(reg_mcp3001_clk);
        reg_mcp3001_miso <= STIMULI(idx);
    end loop;
    
    assert(reg_dout = STIMULI(9 downto 0)) report "SPI data failed" severity warning;
    wait for period;
end process verification_process;

end adc_mcp3001_spi_tb_arch;
