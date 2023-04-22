library ieee;
use ieee.std_logic_1164.all;


entity spi_top_w_slave is 
	generic (
		g_data_width : natural :=8);
	port (
		--system clock and reset
		i_clk : in std_ulogic;
		i_arstn : in std_ulogic;

		--wishbone b4 (slave) interface
		i_we : in std_ulogic;
		i_stb : in std_ulogic;
		i_addr : in std_ulogic_vector(1 downto 0);
		i_data : in std_ulogic_vector(15 downto 0);
		o_ack : out std_ulogic;
		o_stall : out std_ulogic;
		o_data : out std_ulogic_vector(15 downto 0);

		--interrupts
		o_tx_ready : out std_ulogic;
		o_rx_ready : out std_ulogic; 

		--SPI bus
		i_miso : in std_ulogic;
		o_mosi : out std_ulogic;
		o_sclk : out std_ulogic;
		o_ss_n : out std_ulogic);
end spi_top_w_slave;

architecture rtl of spi_top_w_slave is
	signal w_sclk : std_ulogic;
	signal w_ss_n : std_ulogic;
	signal w_dv : std_ulogic;
	signal w_wr : std_ulogic;
	
	signal w_miso : std_ulogic;
	signal w_txreg ,w_data,w_data_slave : std_ulogic_vector(15 downto 0);
	signal w_config_reg : std_ulogic_vector(31 downto 0);
	signal w_tx_ready_slave, w_rx_ready_slave : std_ulogic;
begin


	o_sclk <= w_sclk;
	o_ss_n <= w_ss_n;
	w_dv <= '1' when((i_stb = '1' and i_we = '1' and i_addr = "00")) else '0';


	intf_registers : entity work.intf_registers(rtl)
	port map(
			i_clk =>i_clk,
			i_arstn =>i_arstn,
			i_we =>i_we,
			i_stb =>i_stb,
			i_addr =>i_addr,
			i_data =>i_data,
			o_ack =>o_ack,
			o_data => o_data,
			w_stall => o_stall,

			i_spi_rx_data =>w_data,
			o_txreg => w_txreg,
			o_config_reg => w_config_reg,
			o_wr => w_wr
			);


	sclk_gen : entity work.sclk_gen(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_dv => w_dv,
		i_sclk_cycles =>w_config_reg(15 downto 8),
		i_leading_cycles =>w_config_reg(19 downto 16),
		i_tailing_cycles =>w_config_reg(23 downto 20),
		i_iddling_cycles =>w_config_reg(27 downto 24),
		i_pol =>w_config_reg(0),
		o_stall => o_stall,
		o_ss_n =>w_ss_n,
		o_sclk =>w_sclk);

	spi_logic : entity work.spi_logic(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_pol =>w_config_reg(0),
		i_pha =>w_config_reg(1),
		i_lsb_first => w_config_reg(2),
		i_data =>w_txreg,
		i_wr =>w_wr,
		o_data =>w_data,

		o_tx_rdy => o_tx_ready,
		o_rx_rdy => o_rx_ready,

		i_ss_n =>w_ss_n,
		i_sclk =>w_sclk,
		i_miso =>w_miso,
		o_mosi =>o_mosi);

	spi_slave : entity work.spi_slave(rtl)
	generic map(
	 	g_data_width => g_data_width)
	port map(
		--system (host) interface
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_pol =>w_config_reg(0),
		i_pha =>w_config_reg(1),
		i_lsb_first => w_config_reg(2),
		i_data => w_txreg,
		i_wr => w_wr,
		o_data => w_data_slave,
		o_tx_rdy =>w_tx_ready_slave,
		o_rx_rdy =>w_rx_ready_slave,

		--spi interface
		i_ss_n =>w_ss_n,						
		i_sclk =>w_sclk,
		i_miso =>o_mosi,
		o_mosi =>w_miso);

end rtl;