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
			i_dv : in std_ulogic;
			i_slave_address : in std_ulogic_vector(1 downto 0);
			i_sclk_cycles : in std_ulogic_vector(7 downto 0);
			i_setup_cycles : in std_ulogic_vector(7 downto 0);
			i_hold_cycles : in std_ulogic_vector(7 downto 0);
			i_tx2tx_cycles : in std_ulogic_vector(7 downto 0);
			i_data : in std_ulogic_vector(15 downto 0);
			o_data : out std_ulogic_vector(15 downto 0);
			o_tx_ready : out std_ulogic;
			o_rx_ready : out std_ulogic; 

			--SPI bus
			i_miso : in std_ulogic;
			o_mosi : out std_ulogic;
			o_sclk : out std_ulogic;
			o_ss_n : out std_ulogic_vector(3 downto 0));
end spi_top;

architecture rtl of spi_top is
	signal w_sclk : std_ulogic;
	signal w_ss_n : std_ulogic;
begin

	--prepare the ss_n for the slave device (4 here) to connect to this SPI bus

	gen_o_ss_n : process(i_clk,i_arstn) is
		variable v_ss_n : std_ulogic_vector(3 downto 0) := (others => '1');
	begin
		if(i_arstn = '0') then
			o_ss_n <= (others => '1');
			v_ss_n := (others => '1');
		elsif (rising_edge(i_clk)) then
			v_ss_n := (others => '1');
			case i_slave_address is 
				when "00" =>
					v_ss_n(0) := w_ss_n; 
					o_ss_n <= v_ss_n;
				when "01" =>
					v_ss_n(1) := w_ss_n;
					o_ss_n <= v_ss_n;
				when "10" => 
					v_ss_n(2) := w_ss_n;
					o_ss_n <= v_ss_n;
				when "11" =>
					v_ss_n(3) := w_ss_n;
					o_ss_n <= v_ss_n;
				when others =>
					o_ss_n <= (others => '1');
			end case;
		end if;
	end process; -- gen_o_ss_n

	o_sclk <= w_sclk;

	sclk_gen : entity work.sclk_gen(rtl)
	generic map(
		g_data_width => g_data_width)
	port map(
		i_clk =>i_clk,
		i_arstn =>i_arstn,
		i_dv => i_dv,
		i_sclk_cycles =>i_sclk_cycles,
		i_setup =>i_setup_cycles,
		i_hold =>i_hold_cycles,
		i_tx2tx =>i_tx2tx_cycles,
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
		i_dv =>i_dv,
		o_data =>o_data,
		o_tx_rdy => o_tx_ready,
		o_rx_rdy => o_rx_ready,

		i_ss_n =>w_ss_n,
		i_sclk =>w_sclk,
		i_miso =>i_miso,
		o_mosi =>o_mosi);

end rtl;