library ieee;
use ieee.std_logic_1164.all;

entity intf_registers is
	port (
			i_clk : in std_ulogic;
			i_arstn : in std_ulogic;

			i_we : in std_ulogic;
			i_stb : in std_ulogic;
			i_addr : in std_ulogic_vector(1 downto 0);
			i_data : in std_ulogic_vector(15 downto 0);
			o_ack : out std_ulogic;
			o_data : out std_ulogic_vector(15 downto 0);
			w_stall : in std_ulogic;
			
			i_spi_rx_data : in std_ulogic_vector(15 downto 0);
			o_txreg : out std_ulogic_vector(15 downto 0);
			o_config_reg : out std_ulogic_vector(31 downto 0);
			o_wr : out std_ulogic
		);
end intf_registers;

architecture rtl of intf_registers is
	signal w_tx_reg : std_ulogic_vector(15 downto 0);
	signal w_rx_reg : std_ulogic_vector(15 downto 0);
	signal w_config_reg : std_ulogic_vector(31 downto 0);

	-- 					REGISTER MAP

	-- 			Address 		| 		Functionality
	--			   0 			|	tx_reg (data to tx)
	--			   1 			|	rx_reg (data read)
	--			   2 			|	(15 downto 8) -> scl_cycles, (7 downto 3) -> X, 2->lsb_first, 1->pha, 0->pol
	--			   3 			|	(31 downto 28) -> X, (27 downto 24) -> idling, (23 downto 20) -> tailing, (19 donwto 16) -> leading


begin
	manage_regs : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_tx_reg <= (others => '0');
			o_data <= (others => '0');
			w_config_reg <= (others => '0');
			o_wr <= '0';
		elsif (rising_edge(i_clk)) then
			o_ack <= i_stb;
			o_wr <= '0';
			if(w_stall = '0' and i_stb = '1' and i_we = '1' and i_addr = "00") then
				w_tx_reg <= i_data;
				o_wr <= '1';
			elsif (i_stb = '1' and i_we = '0' and i_addr = "01") then
				o_data <= w_rx_reg;
			elsif(w_stall = '0' and i_stb = '1' and i_we = '1' and i_addr = "10") then
				w_config_reg(15 downto 0) <= i_data;
			elsif(w_stall = '0' and i_stb = '1' and i_we = '1' and i_addr = "11") then
				w_config_reg(31 downto 16) <= i_data;
			end if;
		end if;
	end process; -- manage_regs
	
	w_rx_reg <= i_spi_rx_data;
	o_txreg <= w_tx_reg;
	o_config_reg <= w_config_reg;
end rtl;