restart -f -nowave
config wave -signalnamewidth 1

add wave reg_adc_clk
add wave reg_adc_rst
add wave reg_adc_start
add wave -divider "SPI SIGNALS"
add wave STIMULI
add wave spi_sequence
add wave reg_adc_mcp3001_miso
add wave reg_adc_mcp3001_cs_n
add wave reg_adc_mcp3001_clk
add wave adc_mcp3001_spi_interface_inst/reg_adc_wr_en
add wave adc_mcp3001_spi_interface_inst/adc_mcp3001_spi_inst/state
add wave adc_mcp3001_spi_interface_inst/adc_mcp3001_spi_inst/next_state
add wave -divider "OUTPUT SIGNAL"
add wave -radix binary reg_adc_dout
add wave reg_adc_fifo_rd_en
add wave reg_adc_fifo_rd_clk
add wave reg_adc_fifo_empty
add wave reg_adc_fifo_valid
add wave reg_adc_fifo_prog_full
run 1400000 ns

view signals wave
wave zoom full