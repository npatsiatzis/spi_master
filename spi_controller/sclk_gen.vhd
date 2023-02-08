library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sclk_gen is 
	generic (
			g_data_width : natural :=8);
	port (
			i_clk : in std_ulogic;
			i_arstn : in std_ulogic;
			i_dv : in std_ulogic;		--input bus data valid
			i_sclk_cycles : in std_ulogic_vector(7 downto 0);
			i_setup : in std_ulogic_vector(7 downto 0);
			i_hold : in std_ulogic_vector(7 downto 0);
			i_tx2tx : in std_ulogic_vector(7 downto 0);
			i_pol : in std_ulogic;
			o_ss_n : out std_ulogic;
			o_sclk : out std_ulogic);
end sclk_gen;

architecture rtl of sclk_gen is
	signal w_period_half_rate : unsigned(7 downto 0);
	signal cnt_sclk_period : unsigned(7 downto 0);
	signal w_sclk_pulse : std_ulogic;
	signal w_sclk_pulse_r : std_ulogic;

	type  t_state is (IDLE,SETUP,DATA_TX,HOLD,TX2TX);
	signal w_state : t_state; 

	signal w_sclk_start : std_ulogic; 
	signal w_cnt_delay_start : std_ulogic;
	signal w_cnt_falling_edges : std_ulogic;
	signal w_cnt_delay : unsigned(7 downto 0);
	signal w_setup_done : std_ulogic;
	signal w_hold_done : std_ulogic;
	signal w_tx2tx_done : std_ulogic;

	signal w_sclk_falling_edges : unsigned(7 downto 0);
	signal w_sclk_falling_edge : std_ulogic;

begin
	w_period_half_rate <= shift_right(unsigned(i_sclk_cycles),1);

	--Basic logic (excluding ipol) to build the serial clock (o_sclk)

	build_sclk_pulse : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			cnt_sclk_period <= (others => '0');
			w_sclk_pulse <= '0';
		elsif (rising_edge(i_clk)) then
			if(w_sclk_start = '1') then
				if(cnt_sclk_period < unsigned(i_sclk_cycles)-1) then 
					cnt_sclk_period <= cnt_sclk_period +1;
				else
					cnt_sclk_period <= (others => '0');
				end if;
			else
				cnt_sclk_period <= to_unsigned(1,cnt_sclk_period'length);
			end if;
			if(cnt_sclk_period < w_period_half_rate) then
				w_sclk_pulse <='1';
			else
				w_sclk_pulse <= '0';
			end if;
		end if;
	end process; -- build_sclk_pulse


	--register the sclk pulse because we need to use its falling edges to count trans. progress

	reg_sclk : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_sclk_pulse_r <= '0';
		elsif (rising_edge(i_clk)) then
			w_sclk_pulse_r <= w_sclk_pulse;
		end if;
	end process; -- reg_sclk

	--build o_sclk by taking into account the required clock polarity as well

	build_sclk : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			o_sclk <= '0';
		elsif (rising_edge(i_clk)) then
			--only start the serial clock during the tx phase
			if(w_state = DATA_TX) then
				if(i_pol = '1') then
					o_sclk <= not(w_sclk_pulse);
				else
					o_sclk <= w_sclk_pulse;
				end if;
			end if;
		end if;
	end process; -- build_sclk

	--based on the state of the transaction, manage the serial clock
	--start stop when we must and handle setup,hold and tx2tx requiredments for sclk

	mange_sclk : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_state <= IDLE;
			w_sclk_start <= '0';
			w_cnt_delay_start <= '0';
			w_cnt_falling_edges <= '0';
			o_ss_n <= '1';				--ss_start is active low
		elsif (rising_edge(i_clk)) then
			case w_state is 
				when IDLE =>
					if(i_dv = '1') then
						w_state <= SETUP;
						w_cnt_delay_start <= '1';
						o_ss_n <= '0';
					end if;
				when SETUP =>
						if(w_setup_done = '1') then
							w_state <= DATA_TX;
							w_sclk_start <= '1';
							w_cnt_delay_start <= '0';
							w_cnt_falling_edges <= '1';
						end if;
				when DATA_TX =>
					if(w_sclk_falling_edges = g_data_width) then
						w_state <= HOLD;
						w_cnt_delay_start <= '1';
						w_cnt_falling_edges <= '0';
					end if;
				when HOLD =>
					if(w_hold_done = '1') then
						w_state <= TX2TX;
						w_sclk_start <= '0';
						w_cnt_delay_start <= '0';
						o_ss_n <= '1';
					end if;
			 	when TX2TX =>
			 		if(w_tx2tx_done = '1') then
			 			w_state <= IDLE;
			 			w_cnt_delay_start <= '0';
			 		else
			 			w_cnt_delay_start <= '1';
			 		end if;
				when others =>
					w_state <= IDLE;
					w_sclk_start <= '0';
					w_cnt_delay_start <= '0';
					w_cnt_falling_edges <= '0';
					o_ss_n <= '1';			
			end case;
		end if;
	end process; -- mange_sclk

	--count and indicate when setup,hold,tx2tx time has expired

	cnt_delays : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_cnt_delay <= (others => '0');
		elsif (rising_edge(i_clk)) then
			if(w_cnt_delay_start = '0') then
				w_cnt_delay <= (others => '0');
			else
				w_cnt_delay <= w_cnt_delay +1;
			end if;
		end if;
	end process; -- cnt_delays

	w_setup_done <= '1' when w_cnt_delay = unsigned(i_setup) else '0';
	w_hold_done <= '1' when w_cnt_delay = unsigned(i_hold) else '0';
	w_tx2tx_done <= '1' when w_cnt_delay = unsigned(i_tx2tx) else '0';

	cnt_falling_edges : process(i_clk,i_arstn) is
	begin
		if(i_arstn = '0') then
			w_sclk_falling_edges <= (others => '0');
		elsif (rising_edge(i_clk)) then
				if(w_cnt_falling_edges = '0') then
					w_sclk_falling_edges <= (others => '0');
				elsif (w_sclk_falling_edge = '1') then
					w_sclk_falling_edges <= w_sclk_falling_edges +1;
				end if;
		end if;
	end process; -- cnt_falling_edges

	w_sclk_falling_edge <= '1' when w_sclk_pulse = '0' and w_sclk_pulse_r = '1' else '0';
end rtl;

