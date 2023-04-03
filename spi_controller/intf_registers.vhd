library ieee;
use ieee.std_logic_1164.all;

entity intf_registers is
	port (
			i_clk : in std_ulogic;
			i_arstn : in std_ulogic;

			i_we : in std_ulogic;
			i_stb : in std_ulogic;
			i_addr : in std_ulogic;
			i_data : in std_ulogic_vector(15 downto 0);
			o_ack : out std_ulogic;
			o_data : out std_ulogic_vector(15 downto 0);
			w_stall : in std_ulogic;
			i_spi_rx_data : in std_ulogic_vector(15 downto 0);
			o_txreg : out std_ulogic_vector(15 downto 0);
			o_wr : out std_ulogic
		);
end intf_registers;

architecture rtl of intf_registers is
	signal w_txreg : std_ulogic_vector(15 downto 0);
	signal w_rxreg : std_ulogic_vector(15 downto 0);

begin
	manage_regs : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_txreg <= (others => '0');
			o_data <= (others => '0');
			o_wr <= '0';
		elsif (rising_edge(i_clk)) then
			o_ack <= i_stb;
			o_wr <= '0';
			if(w_stall = '0' and i_stb = '1' and i_we = '1' and i_addr = '0') then
				w_txreg <= i_data;
				o_wr <= '1';
			elsif (i_stb = '1' and i_we = '0' and i_addr = '1') then
				o_data <= w_rxreg;
			end if;
		end if;
	end process; -- manage_regs
	
	w_rxreg <= i_spi_rx_data;
	o_txreg <= w_txreg;
end rtl;