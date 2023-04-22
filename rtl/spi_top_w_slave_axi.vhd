library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity spi_top_w_slave_axi is 	
	generic(
		C_S_AXI_ADDR_WIDTH : natural := 4;
		C_S_AXI_DATA_WIDTH : natural :=32;
		g_data_width : natural :=8);
	port (

		--AXI4-Lite interface
		S_AXI_ACLK : in std_ulogic;
		S_AXI_ARESETN : in std_ulogic;
		--
		S_AXI_AWVALID : in std_ulogic;
		S_AXI_AWREADY : out std_ulogic;
		S_AXI_AWADDR : in std_ulogic_vector(C_S_AXI_ADDR_WIDTH -1 downto 0);
		S_AXI_AWPROT : in std_ulogic_vector(2 downto 0);
		--
		S_AXI_WVALID : in std_ulogic;
		S_AXI_WREADY : out std_ulogic;
		S_AXI_WDATA : in std_ulogic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
		S_AXI_WSTRB : in std_ulogic_vector(C_S_AXI_DATA_WIDTH/8 -1 downto 0);
		--
		S_AXI_BVALID : out std_ulogic;
		S_AXI_BREADY : in std_ulogic;
		S_AXI_BRESP : out std_ulogic_vector(1 downto 0);
		--
		S_AXI_ARVALID : in std_ulogic;
		S_AXI_ARREADY : out std_ulogic;
		S_AXI_ARADDR : in std_ulogic_vector(C_S_AXI_ADDR_WIDTH -1 downto 0);
		S_AXI_ARPROT : in std_ulogic_vector(2 downto 0);
		--
		S_AXI_RVALID : out std_ulogic;
		S_AXI_RREADY : in std_ulogic;
		S_AXI_RDATA : out std_ulogic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
		S_AXI_RRESP : out std_ulogic_vector(1 downto 0);

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
end spi_top_w_slave_axi;

architecture rtl of spi_top_w_slave_axi is
	signal i_arstn, i_arst : std_ulogic;
	alias i_clk  : std_ulogic is S_AXI_ACLK;


	signal w_sclk : std_ulogic;
	signal w_ss_n : std_ulogic;
	signal w_wr : std_ulogic;
	
	signal w_miso : std_ulogic;
	signal w_txreg ,w_data,w_data_slave : std_ulogic_vector(15 downto 0);
	signal w_config_reg : std_ulogic_vector(31 downto 0);
	signal w_tx_ready_slave, w_rx_ready_slave : std_ulogic;
begin

	i_arstn <= S_AXI_ARESETN;
	i_arst <= not S_AXI_ARESETN;

	o_sclk <= w_sclk;
	o_ss_n <= w_ss_n;


	axil_regs : entity work.axil_regs(rtl)
	port map(
		i_clk =>i_clk,
		i_arst =>i_arst,

		S_AXI_AWVALID => S_AXI_AWVALID,
		S_AXI_AWREADY => S_AXI_AWREADY,
		S_AXI_AWADDR => S_AXI_AWADDR,
		S_AXI_AWPROT => S_AXI_AWPROT,
		--
		S_AXI_WVALID => S_AXI_WVALID,
		S_AXI_WREADY => S_AXI_WREADY,
		S_AXI_WDATA => S_AXI_WDATA,
		S_AXI_WSTRB => S_AXI_WSTRB,
		--
		S_AXI_BVALID => S_AXI_BVALID,
		S_AXI_BREADY => S_AXI_BREADY,
		S_AXI_BRESP => S_AXI_BRESP,
		--
		S_AXI_ARVALID => S_AXI_ARVALID,
		S_AXI_ARREADY => S_AXI_ARREADY,
		S_AXI_ARADDR => S_AXI_ARADDR,
		S_AXI_ARPROT => S_AXI_ARPROT,
		--
		S_AXI_RVALID => S_AXI_RVALID,
		S_AXI_RREADY => S_AXI_RREADY,
		S_AXI_RDATA => S_AXI_RDATA,
		S_AXI_RRESP => S_AXI_RRESP,

		i_spi_rd_data =>w_data,
		o_tx_reg => w_txreg,
		o_config_reg => w_config_reg,
		o_wr => w_wr
		);

	o_data <= S_AXI_RDATA(15 downto 0);

	sclk_gen : entity work.sclk_gen(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_dv => w_wr,
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