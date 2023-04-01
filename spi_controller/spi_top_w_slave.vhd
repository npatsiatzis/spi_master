library ieee;
use ieee.std_logic_1164.all;


entity spi_top_w_slave is 
	generic (
		g_data_width : natural :=8);
	port (
		i_clk : in std_ulogic;
		i_arstn : in std_ulogic;

		--processor (parallel) bus
		i_wr : in std_ulogic;
		i_pol : in std_ulogic;
		i_pha : in std_ulogic;
		i_lsb_first : in std_ulogic;
		i_stb : in std_ulogic;
		--i_dv : in std_ulogic;
		i_sclk_cycles : in std_ulogic_vector(7 downto 0);
		i_leading_cycles : in std_ulogic_vector(7 downto 0);
		i_tailing_cycles : in std_ulogic_vector(7 downto 0);
		i_iddling_cycles : in std_ulogic_vector(7 downto 0);
		i_data : in std_ulogic_vector(15 downto 0);
		o_ack : out std_ulogic;
		o_stall : out std_ulogic;
		o_data : out std_ulogic_vector(15 downto 0);
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
	
	signal w_miso : std_ulogic;
	signal w_data_slave : std_ulogic_vector(15 downto 0);
	signal w_tx_ready_slave, w_rx_ready_slave : std_ulogic;
begin


	o_sclk <= w_sclk;
	o_ss_n <= w_ss_n;
	w_dv <= '1' when (i_stb = '1' and i_wr = '1') else '0';

	sclk_gen : entity work.sclk_gen(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_dv => w_dv,
		i_sclk_cycles =>i_sclk_cycles,
		i_leading_cycles =>i_leading_cycles,
		i_tailing_cycles =>i_tailing_cycles,
		i_iddling_cycles =>i_iddling_cycles,
		i_pol =>i_pol,
		o_stall => o_stall,
		o_ss_n =>w_ss_n,
		o_sclk =>w_sclk);

	spi_logic : entity work.spi_logic(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_pol =>i_pol,
		i_pha =>i_pha,
		i_lsb_first =>i_lsb_first,
		i_data =>i_data,
		i_wr =>i_wr,
		i_stb =>i_stb,
		o_ack => o_ack,
		o_data =>o_data,

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
		i_pol =>i_pol,
		i_pha =>i_pha,
		i_lsb_first => i_lsb_first,
		i_data => i_data,
		i_wr => i_wr,
		o_data => w_data_slave,
		o_tx_rdy =>w_tx_ready_slave,
		o_rx_rdy =>w_rx_ready_slave,

		--spi interface
		i_ss_n =>w_ss_n,						
		i_sclk =>w_sclk,
		i_miso =>o_mosi,
		o_mosi =>w_miso);

end rtl;