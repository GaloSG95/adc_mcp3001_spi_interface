library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc_mcp3001_spi_interface_tb is
end adc_mcp3001_spi_interface_tb;

architecture adc_mcp3001_spi_interface_tb_arch of adc_mcp3001_spi_interface_tb is

component adc_mcp3001_spi_interface
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
end component adc_mcp3001_spi_interface;

signal reg_adc_clk             : std_logic:='0';
signal reg_adc_rst             : std_logic:='0';
signal reg_adc_start           : std_logic:='0';
signal reg_adc_mcp3001_miso    : std_logic:='0';
signal reg_adc_mcp3001_cs_n    : std_logic;
signal reg_adc_mcp3001_clk     : std_logic;
signal reg_adc_fifo_rd_clk     : std_logic:='0';
signal reg_adc_fifo_rd_en      : std_logic:='0';
signal reg_adc_fifo_full       : std_logic;
signal reg_adc_fifo_empty      : std_logic;
signal reg_adc_fifo_valid      : std_logic;
signal reg_adc_fifo_prog_full  : std_logic;
signal reg_adc_dout            : std_logic_vector(9 downto 0);

constant period_100Mhz         : time := 10 ns;
constant period_spi            : time := 357.14 ns;

constant impedancenull         : std_logic_vector(2 downto 0):="ZZ0";
signal   spi_sequence          : std_logic_vector(12 downto 0);
signal   STIMULI               : unsigned(9 downto 0):=(others => '0');



begin
    
adc_mcp3001_spi_interface_inst: adc_mcp3001_spi_interface
  port map( adc_clk             =>	reg_adc_clk,
            adc_rst             =>	reg_adc_rst,
            adc_start           =>	reg_adc_start,
            adc_mcp3001_miso    =>	reg_adc_mcp3001_miso,
            adc_mcp3001_cs_n    =>	reg_adc_mcp3001_cs_n,
            adc_mcp3001_clk     =>	reg_adc_mcp3001_clk,
            adc_fifo_rd_clk     =>	reg_adc_fifo_rd_clk,
            adc_fifo_rd_en      =>	reg_adc_fifo_rd_en,
            adc_fifo_full       =>	reg_adc_fifo_full,
            adc_fifo_empty      =>	reg_adc_fifo_empty,
            adc_fifo_valid      =>	reg_adc_fifo_valid,
            adc_fifo_prog_full  =>	reg_adc_fifo_prog_full,
            adc_dout			=>	reg_adc_dout);

clk_process: process
begin
    reg_adc_clk <= not reg_adc_clk;
    reg_adc_fifo_rd_clk <= not reg_adc_fifo_rd_clk;
    wait for period_100Mhz/2;
end process clk_process;

rst_process: process
begin
    wait for 2*period_100Mhz;
    reg_adc_rst <= '1';
    wait for 2*period_100Mhz;
    reg_adc_rst <= '0';
    wait;
end process rst_process;

verification_process: process
begin
    wait for 700*period_100Mhz;

    reg_adc_start <= '1';
    wait until falling_edge(reg_adc_mcp3001_cs_n);
     
    while reg_adc_fifo_prog_full = '0' loop
        spi_sequence <= impedancenull & std_logic_vector(STIMULI);
        for idx in 12 downto 0 loop
            wait until falling_edge(reg_adc_mcp3001_clk);
            reg_adc_mcp3001_miso <= spi_sequence(idx);
        end loop;
        STIMULI <= STIMULI+1;
        wait until falling_edge(reg_adc_mcp3001_cs_n);
    end loop;
    
    STIMULI       <= (others => '0');
    reg_adc_start <= '0';
    wait until rising_edge(reg_adc_mcp3001_cs_n);
    wait for 3*period_spi;
    reg_adc_fifo_rd_en <= '1';

    while reg_adc_fifo_empty = '0' loop
        spi_sequence <= impedancenull & std_logic_vector(STIMULI);
        wait until rising_edge(reg_adc_fifo_rd_clk);
        assert(reg_adc_dout = spi_sequence(9 downto 0)) report "write not equal to read" severity error;
        STIMULI <= STIMULI+1;
    end loop;
    
    wait;
end process verification_process;

end adc_mcp3001_spi_interface_tb_arch;
