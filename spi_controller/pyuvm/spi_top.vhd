library ieee;
use ieee.std_logic_1164.all;


entity spi_top is 
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
			i_rd : in std_ulogic;
			--i_dv : in std_ulogic;
			--i_slave_address : in std_ulogic_vector(1 downto 0);
			i_sclk_cycles : in std_ulogic_vector(7 downto 0);
			i_leading_cycles : in std_ulogic_vector(7 downto 0);
			i_tailing_cycles : in std_ulogic_vector(7 downto 0);
			i_iddling_cycles : in std_ulogic_vector(7 downto 0);
			i_data : in std_ulogic_vector(15 downto 0);
			o_data : out std_ulogic_vector(15 downto 0);
			o_tx_ready : out std_ulogic;
			o_rx_ready : out std_ulogic; 

			--SPI bus
			i_miso : in std_ulogic;
			o_mosi : out std_ulogic;
			o_sclk : out std_ulogic;
			o_ss_n : out std_ulogic);
end spi_top;

architecture rtl of spi_top is
	signal w_dv : std_ulogic;
	signal w_sclk : std_ulogic;
	signal w_ss_n : std_ulogic;
begin

	o_ss_n <= w_ss_n;
	o_sclk <= w_sclk;
	w_dv <= i_wr or i_rd;

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
		i_rd =>i_rd,
		i_dv =>w_dv,
		o_data =>o_data,
		o_tx_rdy => o_tx_ready,
		o_rx_rdy => o_rx_ready,

		i_ss_n =>w_ss_n,
		i_sclk =>w_sclk,
		i_miso =>i_miso,
		o_mosi =>o_mosi);

end rtl;