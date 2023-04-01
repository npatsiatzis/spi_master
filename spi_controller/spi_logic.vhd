library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_logic is
	generic (
	 	g_data_width : natural :=8); 
	port (
			i_clk : in std_ulogic;
			i_arstn : in std_ulogic;
			i_pol : in std_ulogic;
			i_pha : in std_ulogic;
			i_lsb_first : in std_ulogic;

			--wishbone b4(slave) interface
			i_data : in std_ulogic_vector(15 downto 0);
			i_wr : in std_ulogic;
			i_stb : in std_ulogic;
			o_ack : out std_ulogic;
			o_data : out std_ulogic_vector(15 downto 0);


			o_tx_rdy : out std_ulogic;
			o_rx_rdy : out std_ulogic;

			i_ss_n : in std_ulogic;						--active low
			i_sclk : in std_ulogic;
			i_miso : in std_ulogic;
			o_mosi : out std_ulogic);
end spi_logic;

architecture rtl of spi_logic is 
	signal w_data_to_tx : std_ulogic_vector(g_data_width -1 downto 0);

	signal w_rx_data : std_ulogic_vector(g_data_width -1 downto 0);
	signal w_sr_rx_pos_sclk : std_ulogic_vector(g_data_width -1 downto 0);
	signal w_sr_rx_neg_sclk : std_ulogic_vector(g_data_width -1 downto 0);
	signal w_rx_fifo_data_in : std_ulogic_vector(15 downto 0);
	signal w_tx_data : std_ulogic_vector(g_data_width -1 downto 0);

	signal w_cnt_rx_pos : unsigned(4 downto 0);
	signal w_cnt_rx_neg : unsigned(4 downto 0);
	signal w_rx_done_pos : std_ulogic;
	signal w_rx_done_neg : std_ulogic;

	signal w_rx_done, w_rx_done_r, w_rx_done_rr : std_ulogic;
	signal w_rx_rdy, w_rx_rdy_r, w_rx_rdy_rr: std_ulogic;

	signal w_mosi_pos_01, w_mosi_pos_10 : std_ulogic;
	signal w_mosi_neg_00, w_mosi_neg_11 : std_ulogic;
	signal w_cnt_tx_pos : unsigned(4 downto 0);
	signal w_cnt_tx_neg : unsigned(4 downto 0);
	signal w_tx_done_pos : std_ulogic;
	signal w_tx_done_neg : std_ulogic;

	signal w_tx_done, w_tx_done_r, w_tx_done_rr : std_ulogic;
	signal w_tx_rdy : std_ulogic;
	
begin

		o_data_proc : process(all) is
		begin
			if(g_data_width = 8) then
				o_data(15 downto 8) <= (others => '0');
				o_data(7 downto 0) <= w_rx_data;
				
			elsif (g_data_width = 16) then
				o_data <= w_rx_data;
			end if;
		end process; -- o_data_proc

	latch_data_to_tx : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_data_to_tx <= (others => '0');
		elsif (rising_edge(i_clk)) then
			if(i_stb = '1' and i_wr = '1') then
			--if(i_wr = '1' and w_tx_rdy = '1') then
				if(g_data_width = 8) then
					w_data_to_tx <= i_data(7 downto 0);
				elsif (g_data_width = 16) then
					w_data_to_tx <= i_data;
				end if;
			end if;
		end if;
	end process; -- latch_data_to_tx

	--RX data register conditioned on which edge of the serial clock
	--the data should be read according to clock polarity and phase

	rx_data_reg : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then	
			w_rx_data <= (others => '0');
			o_ack <= '0';
		elsif(rising_edge(i_clk)) then
			o_ack <= '0';
			if(w_rx_done = '1' and w_rx_done_r = '0') then
				o_ack <= '1';
				if((i_pol = '0' and i_pha = '0') or (i_pol = '1' and i_pha = '1')) then
					w_rx_data <= w_sr_rx_pos_sclk;
				else
					w_rx_data <= w_sr_rx_neg_sclk;
				end if;
			 end if;
		end if;
	end process; -- rx_data_reg

	--re-register data for TX

		tx_data_reg_fifo : process(i_clk,i_arstn) is
		begin
			if(i_arstn = '0') then
				w_tx_data <= (others => '0');
			elsif (rising_edge(i_clk)) then
				w_tx_data <= w_data_to_tx;
			end if;
		end process; -- tx_data_reg_fifo

	--Receive End. Group that samples the serial line at the posedge of the serial clock

	pos_sample_miso : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
				w_sr_rx_pos_sclk <= (others => '0');
		elsif (rising_edge(i_sclk)) then
			if(i_ss_n = '0' and ((i_pol = '0' and i_pha = '0') or (i_pol = '1' and i_pha = '1'))) then
				if(i_lsb_first = '1') then
					w_sr_rx_pos_sclk <= i_miso & w_sr_rx_pos_sclk(g_data_width-1 downto 1);
				else
					w_sr_rx_pos_sclk <= w_sr_rx_pos_sclk(g_data_width -2 downto 0) & i_miso;
				end if;
			end if;
		end if;
	end process; -- pos_sample_miso

	--count bits receive on the posedge of the serial clock

	cnt_bits_rx_pos : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_cnt_rx_pos <= (others => '0');
			w_rx_done_pos <= '0';
		elsif (rising_edge(i_sclk)) then
			if(i_ss_n = '0' and ((i_pol = '0' and i_pha = '0') or (i_pol = '1' and i_pha = '1'))) then
				if(w_cnt_rx_pos = g_data_width -1) then
					w_cnt_rx_pos <= (others => '0');
					w_rx_done_pos <= '1';
				else
					w_cnt_rx_pos <= w_cnt_rx_pos +1;
					w_rx_done_pos <= '0';
				end if;
			end if;
		end if;
	end process; -- cnt_bits_rx_pos


	--Receive End. Group that samples the serial line at the negedge of the serial clock

	neg_sample_miso : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
				w_sr_rx_neg_sclk <= (others => '0');
		elsif (falling_edge(i_sclk)) then
			if(i_ss_n = '0' and ((i_pol = '1' and i_pha = '0') or (i_pol = '0' and i_pha = '1'))) then
				if(i_lsb_first = '1') then
					w_sr_rx_neg_sclk <= i_miso & w_sr_rx_neg_sclk(g_data_width-1 downto 1);
				else
					w_sr_rx_neg_sclk <= w_sr_rx_neg_sclk(g_data_width -2 downto 0) & i_miso;
				end if;
			end if;
		end if;
	end process; -- neg_sample_miso

	--count bits receive on the negedge of the serial clock

	cnt_bits_rx_neg : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_cnt_rx_neg <= (others => '0');
			w_rx_done_neg <= '0';
		elsif (falling_edge(i_sclk)) then
			if(i_ss_n = '0' and ((i_pol = '1' and i_pha = '0') or (i_pol = '0' and i_pha = '1'))) then
				if(w_cnt_rx_neg = g_data_width -1) then
					w_cnt_rx_neg <= (others => '0');
					w_rx_done_neg <= '1';
				else
					w_cnt_rx_neg <= w_cnt_rx_neg +1;
					w_rx_done_neg <= '0';
					end if;
				end if;
		end if;
	end process; -- cnt_bits_rx_neg

	--generate rx_done indicators 

	gen_rx_done : process(i_clk,i_arstn) is
		begin
			if(i_arstn = '0') then
				w_rx_done <= '0';
				w_rx_done_r <= '0';
				w_rx_done_rr <= '0';
			elsif (rising_edge(i_clk)) then
				if(i_ss_n = '0' and ((i_pol = '0' and i_pha = '0') or (i_pol = '1' and i_pha = '1'))) then
					w_rx_done <= w_rx_done_pos;
				elsif(i_ss_n = '0' and ((i_pol = '1' and i_pha = '0') or (i_pol = '0' and i_pha = '1'))) then
					w_rx_done <= w_rx_done_neg;
				end if;
			w_rx_done_r <= w_rx_done;
			w_rx_done_rr <= w_rx_done_r;
			end if;
		end process; -- gen_rx_done	

	--generate rx ready for new transactions

	rx_rdy : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_rx_rdy <= '0';
		elsif (rising_edge(i_clk)) then
			if(w_rx_done = '1' and w_rx_done_r = '0') then
				w_rx_rdy <= '1';
			else
				w_rx_rdy <= '0';
			end if;
		end if;
	end process; -- rx_rdy

	--Transmiter End. Group that drives the serial line at the posedge of the serial clock

	mosi_pos_10 : process(all) is
	begin
		if(i_lsb_first = '1') then
			w_mosi_pos_10 <= w_tx_data(to_integer(w_cnt_tx_pos));
		else
			w_mosi_pos_10 <= w_tx_data(to_integer((g_data_width - w_cnt_tx_pos -1)));
		end if;
	end process; -- mosi_pos_10

	mosi_pos_01 : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_mosi_pos_01 <= '1';
		elsif (rising_edge(i_sclk)) then
			if(i_lsb_first = '1') then
				w_mosi_pos_01 <= w_tx_data(to_integer(w_cnt_tx_pos));
			else
				w_mosi_pos_01 <= w_tx_data(to_integer((g_data_width - w_cnt_tx_pos -1)));
			end if;
		end if;
	end process; -- mosi_pos_01

	--Transmiter End. Group that drives the serial line at the negedge of the serial clock

	mosi_neg_00 : process(all) is
	begin
		if(i_lsb_first = '1') then
			w_mosi_neg_00 <= w_tx_data(to_integer(w_cnt_tx_neg));
		else
			w_mosi_neg_00 <= w_tx_data(to_integer((g_data_width - w_cnt_tx_neg -1)));
		end if;
	end process; -- mosi_neg_00

	mosi_neg_11 : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_mosi_neg_11 <= '1';
		elsif (falling_edge(i_sclk)) then
			if(i_lsb_first = '1') then
				w_mosi_neg_11 <= w_tx_data(to_integer(w_cnt_tx_neg));
			else
				w_mosi_neg_11 <= w_tx_data(to_integer((g_data_width - w_cnt_tx_neg -1)));
			end if;
		end if;
	end process; -- mosi_neg_11

	--count tx bits of rising edge of sclk

	tx_cnt_pos : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_cnt_tx_pos <= (others => '0');
			w_tx_done_pos <= '0';
		elsif (rising_edge(i_sclk)) then
			if(i_ss_n = '0' and ((i_pol = '0' and i_pha = '0') or (i_pol = '1' and i_pha = '1'))) then
				if(w_cnt_tx_pos = g_data_width -1) then
					w_cnt_tx_pos <= (others => '0');
					w_tx_done_pos <= '1';
				else
					w_cnt_tx_pos <= w_cnt_tx_pos +1;
					w_tx_done_pos <= '0';
				end if;
			end if;
		end if;	
	end process; -- tx_cnt_pos

	--count tx bits on falling edge of sclk

	tx_cnt_neg : process(i_sclk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_cnt_tx_neg <= (others => '0');
			w_tx_done_neg <= '0';
		elsif (falling_edge(i_sclk)) then
			if(i_ss_n = '0' and (i_pol = '1' and i_pha = '1')) then
				if(w_cnt_tx_neg = g_data_width -1) then
					w_cnt_tx_neg <= (others => '0');
					w_tx_done_neg <= '1';
				else
					w_cnt_tx_neg <= w_cnt_tx_neg +1;
					w_tx_done_neg <= '0';
				end if;
			elsif(i_ss_n = '0' and (i_pol = '0' and i_pha = '0')) then
				w_tx_done_neg <= '0';
				w_cnt_tx_neg <= w_cnt_tx_neg +1;
				if(w_cnt_tx_neg = g_data_width -2) then
					w_tx_done_neg <= '1';
				elsif(w_cnt_tx_neg = g_data_width-1) then
					w_cnt_tx_neg <= (others => '0');
				end if;
			end if;
		end if;	
	end process; -- tx_cntnegs

	--drive o_mosi based on the mode

	drive_mosi : process(all) is
	begin
		--drive mosi after ss has be deasserted
		if(i_ss_n = '0') then
			if(i_pol = '0' and i_pha = '0') then
				o_mosi <= w_mosi_neg_00;
			elsif (i_pol = '1' and i_pha = '1') then
				o_mosi <= w_mosi_neg_11;
			elsif(i_pol = '0' and i_pha = '1') then
				o_mosi <= w_mosi_pos_01;
			else
				o_mosi <= w_mosi_pos_10;			
			end if;
		else
			o_mosi <= '0';
		end if;
	end process; -- drive_mosi

	--generate tx_done indicators 

	gen_tx_done : process(i_clk,i_arstn) is
		begin
			if(i_arstn = '0') then
				w_tx_done <= '0';
				w_tx_done_r <= '0';
				w_tx_done_rr <= '0';
			elsif (rising_edge(i_clk)) then
				if(i_ss_n = '0' and ((i_pol = '0' and i_pha = '0') or (i_pol = '1' and i_pha = '1'))) then
					w_tx_done <= w_tx_done_neg;
				elsif(i_ss_n = '0' and ((i_pol = '1' and i_pha = '0') or (i_pol = '0' and i_pha = '1'))) then
					w_tx_done <= w_tx_done_pos;
				end if;
			w_tx_done_r <= w_tx_done;
			w_tx_done_rr <= w_tx_done_r;
			end if;
		end process; -- gen_tx_done	


	--generate tx ready for new transactions

	tx_rdy : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_tx_rdy <= '0';
		elsif (rising_edge(i_clk)) then
			--if(i_dv = '1') then
				--w_tx_rdy <= '0';
			if(w_tx_done = '1' and w_tx_done_r = '0') then
			--elsif(w_tx_done = '1' and w_tx_done_r = '0') then
				w_tx_rdy <= '1';
			else
				w_tx_rdy <= '0';
			end if;
		end if;
	end process; -- tx_rdy

	o_tx_rdy <= w_tx_rdy;
	o_rx_rdy <= w_rx_rdy;

end rtl;