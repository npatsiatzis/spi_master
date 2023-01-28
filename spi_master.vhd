library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
	generic(
		g_sys_clk : natural := 50_000_000;		--system clock frequency in Hz
		g_clk_div_len : natural :=2;			--length of the clock divide input
		g_width : natural :=8;					--width of the word to transmit
		g_slaves : natural :=4);				--bit size for the ss_n input
	port(
		i_clk : in std_ulogic;					--system clock
		i_arst_n : in std_ulogic;				--asynchronous active low reset
		i_en : in std_ulogic;					--enable signal to latch configuration
		i_tx_data : in std_ulogic_vector(g_width -1 downto 0);		--data word to transmit
		i_cont : in std_ulogic;										--continuous mode flag
		i_addr : in integer	range 0 to g_slaves-1;					--slave address
		i_clk_div : in std_ulogic_vector(g_clk_div_len -1 downto 0);--f_sclk = f_clk/(2*i_clk_div)
		i_pol : in std_ulogic;										--spi clock polarity
		i_pha : in std_ulogic;										--spi clock phase
		i_miso : in std_ulogic;										--master in slave out
		o_mosi : out std_ulogic;									-- master out slave in
		o_busy : out std_ulogic;									--busy / data ready
		o_rx_data : out std_ulogic_vector(g_width -1 downto 0);		--data received from spi slave
		o_ss_n : out std_ulogic_vector(g_slaves -1 downto 0);		--spi clock
		o_sclk : out std_ulogic);
end spi_master;

architecture rtl of spi_master is
	type spi_master_state is (READY,EXECUTE);
	signal spi_state : spi_master_state := READY;

	signal cnt : integer range 0 to 2**g_clk_div_len :=0;		--counter for clk_div
	signal w_clk_div : std_ulogic_vector(g_clk_div_len -1 downto 0);
	signal tx_rx : std_ulogic;									--spi clock edge tx/rx indicator
	signal tx_buffer : std_ulogic_vector(g_width -1 downto 0) :=(others => '0');	--buffer holding mosi data
	signal rx_buffer : std_ulogic_vector(g_width -1 downto 0) :=(others => '0');	--buffer holding miso data
	signal clk_toggles : integer range 0 to 2*g_width + 1 :=0;	
	signal last_bit_rx : integer range 0 to 2*g_width :=0;			--clk_toggle value for last rx bit

	signal r_addr : integer range 0 to g_slaves-1;		   		--latch i_addr when en goes high
	signal continue : std_ulogic;      --flag to continue transaction
	
	--convert std_logic to integer
	function std_ulogic_to_integer (n : std_ulogic) return integer is 
	begin
		if(n = '1') then
			return 1;
		else 
			return 0;
		end if;
	end std_ulogic_to_integer;
begin

	w_clk_div <= std_ulogic_vector(to_unsigned(1,g_clk_div_len)) when (unsigned(i_clk_div) = 0) else i_clk_div;

	--spi master FSM
	spi_FSM : process(i_clk,i_arst_n)
	begin
		if(i_arst_n ='0') then
			o_busy <= '1';					--set busy / data ready
			o_rx_data <= (others => '0');	--clear receive data port
			rx_buffer <= (others => '0');	--initialize receive buffer
			o_ss_n <= (others => '1');		--set ss high for all slaves
			o_mosi <= 'Z';					--set mosi at high impedance
			spi_state <= READY;				--set state to READY
			tx_buffer <= (others => '0');
			rx_buffer <= (others => '0');
		elsif (rising_edge(i_clk)) then
			case spi_state is 
				when READY =>
					o_busy <= '0';			--set busy /data ready
					o_ss_n <= (others => '1');
					o_mosi <= 'Z';
					continue <= '0';		--flag to continue transaction set low
					o_sclk <= i_pol;		--set idle sclk level at clock polarity
					if(i_en = '1') then		--if en latch configuration
						o_busy <= '1';								--set busy/data ready to high
						r_addr <= i_addr;							--latch the address of the slave

						spi_state <= EXECUTE;						--set state to EXECUTE
						cnt <= to_integer(unsigned(w_clk_div));		--set cnt to clk_div to transition next
						tx_rx <= not i_pha;							--set tx/rx indicator at no clock phase
						tx_buffer <= i_tx_data;						--latch data to transmit
						clk_toggles <= 0;							--set clock toggle of cur. transaction to low
						last_bit_rx <= 2*g_width + std_ulogic_to_integer(i_pha) -1;		--set index of last rx bit
																						--based on configuration
					else 
						spi_state <= READY;							--if en is low the state is READY
					end if;
				when EXECUTE =>												
					o_busy <= '1';
					o_ss_n(r_addr) <= '0';							--set to low the slave based on addr
					if(cnt >= to_integer(unsigned(w_clk_div))) then  --if cnt reached new sclk edge ###!!!!#####@@@@@@@ (= -> >=)
						cnt <= 0;									--re-initialize cnt
						tx_rx <= not tx_rx;							--toggle between rx/tx

						if(clk_toggles = 2*g_width + 1) then		--if sclk reached max toggles for transaction
							clk_toggles <= 0;						--re-initialize clk toggle counter
						else
							clk_toggles <= clk_toggles + 1;			--else incremenet clk toggles
						end if;

						if(clk_toggles <= 2*g_width) then			--if clk toggles within range, toggle sclk
							o_sclk <= not o_sclk;					--analyse as VHDL08, out port can be read as well
						end if;

						if(tx_rx <= '0' and clk_toggles <= last_bit_rx) then   --receive spi (MSB first)
							rx_buffer <= rx_buffer(g_width-2 downto 0) & i_miso;
						end if;

						if(tx_rx = '1' and clk_toggles < last_bit_rx) then		--transmit spi (MSB first)
							tx_buffer <= tx_buffer(g_width-2 downto 0) & '0';
							o_mosi <= tx_buffer(g_width-1);
						end if;

						if(clk_toggles = last_bit_rx and i_cont = '1')then		--if transaction end and cont. mode
							tx_buffer <= i_tx_data;								--latch in new data to transmit
							continue <= '1';									--raise continue flag
							clk_toggles <= last_bit_rx - 2*g_width +1;			--reset clk toggles
						end if;

						if(continue = '1')	then								--if continue after transaction
							o_busy <= '0';										--set busy / ready to low
							o_rx_data <= rx_buffer;								--set continue to low
							continue <= '0';
						end if;

						if(clk_toggles = 2*g_width+1) then		--if transaction over and not cont. mode
							o_busy <= '0';										--set busy low
							o_rx_data <= rx_buffer;								--send receive data to rx output port
							o_ss_n <= (others => '1');							--deselect slave 
							o_mosi <= 'Z';										--set mosi line to high impedance
							spi_state <= READY;									--set state to READY	
						else
							spi_state <= EXECUTE;
						end if;
					else
 						cnt <= cnt + 1;
						spi_state <= EXECUTE;
					end if;
			end case;
		end if;
	end process; -- spi_FSM
end rtl;