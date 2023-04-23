library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_regs is
	generic(
		C_S_AXI_DATA_WIDTH : natural := 32;
		C_S_AXI_ADDR_WIDTH : natural :=4);
	port (
			--AXI4-Lite interface
			i_clk : in std_ulogic;
			i_arst : in std_ulogic;
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

			--data read from sdram
			i_spi_rd_data : in std_ulogic_vector(15 downto 0);

			--ports for write regs to hierarchy
			o_wr : out std_ulogic;
			o_config_reg : out std_ulogic_vector(31 downto 0);
			o_tx_reg : out std_ulogic_vector(15 downto 0)); 
end axil_regs;

architecture rtl of axil_regs is
	constant ADDR_LSB : natural := (C_S_AXI_DATA_WIDTH/32) +1;
	constant OPT_MEM_ADDR_BITS : natural := 1;


	--signal reg0, reg1, reg2, reg3 : std_ulogic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
	signal axil_awready, axil_bvalid, axil_arready : std_ulogic;
	signal axil_read_ready, axil_read_valid , axil_write_ready : std_ulogic;

	signal axil_wdata, axil_rdata : std_ulogic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
	--signal axil_waddr, axil_raddr : std_ulogic_vector(C_S_AXI_ADDR_WIDTH -1 downto ADDR_LSB);
	signal axil_waddr, axil_raddr : std_ulogic_vector(C_S_AXI_ADDR_WIDTH -1 downto 0);
	signal axil_wstrb : std_ulogic_vector(C_S_AXI_DATA_WIDTH/8 -1 downto 0);

	signal f_is_data_to_tx : std_ulogic;
	signal w_tx_reg : std_ulogic_vector(15 downto 0);
	signal w_config_reg : std_ulogic_vector(31 downto 0);
begin

	manage_w_channel : process(i_clk,i_arst) is
	begin
		if(i_arst = '1') then
			axil_awready <= '0';
		elsif (rising_edge(i_clk)) then
			if(axil_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and (S_AXI_BVALID = '0' or S_AXI_BREADY = '1')) then
				axil_awready <= '1';
			else
				axil_awready <= '0';
			end if;
		end if;
	end process; -- manage_w_channel

	S_AXI_AWREADY <= axil_awready;
	S_AXI_WREADY <= axil_awready;
	axil_write_ready <= axil_awready;
	axil_wdata <= S_AXI_WDATA;
	--axil_waddr <= S_AXI_AWADDR(S_AXI_AWADDR'high downto ADDR_LSB);
	axil_waddr <= S_AXI_AWADDR(S_AXI_AWADDR'high downto 0);
	axil_wstrb <= S_AXI_WSTRB;

	manage_b_channel : process(i_clk,i_arst) is
	begin
		if(i_arst = '1') then
			axil_bvalid <= '0';
		elsif (rising_edge(i_clk)) then
			if(axil_write_ready = '1') then
				axil_bvalid <= '1';
			end if;
		elsif (S_AXI_BREADY = '1') then
			axil_bvalid <= '0';
		end if;
	end process; -- manage_b_channel

	S_AXI_BVALID <= axil_bvalid;
	S_AXI_BRESP <= "00";


	axil_arready <= not S_AXI_RVALID;
	S_AXI_ARREADY <= axil_arready;
	axil_read_ready <= S_AXI_ARVALID and S_AXI_ARREADY;
	--axil_raddr <= S_AXI_ARADDR(S_AXI_ARADDR'high downto ADDR_LSB);
	axil_raddr <= S_AXI_ARADDR(S_AXI_ARADDR'high downto 0);

	manage_r_channel : process(i_clk,i_arst) is
	begin
		if(i_arst = '1') then
			axil_read_valid <= '0';
		elsif (rising_edge(i_clk)) then
			if(axil_read_ready = '1') then
				axil_read_valid <= '1';
			elsif (S_AXI_RREADY = '1') then
				axil_read_valid <= '0';
			end if;
		end if; 
	end process; -- manage_r_channel

	S_AXI_RVALID <= axil_read_valid;
	S_AXI_RDATA <= axil_rdata; 	
	S_AXI_RRESP <= "00";



	-- 			Address 		| 		Functionality
	--			   0 			|	tx_reg (data to tx)
	--			   1 			|	rx_reg (data read)
	--			   2 			|	(15 downto 8) -> scl_cycles, (7 downto 3) -> X, 2->lsb_first, 1->pha, 0->pol
	--			   3 			|	(31 downto 28) -> X, (27 downto 24) -> idling, (23 downto 20) -> tailing, (19 donwto 16) -> leading

	f_is_data_to_tx <= '1' when (S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and unsigned(S_AXI_AWADDR) = 0) else '0';

	manage_write_regs : process(i_clk,i_arst) is
		variable loc_addr : std_ulogic_vector(1 downto 0);
	begin
		if(i_arst = '1') then
			w_tx_reg <= (others => '0');
			o_wr <= '0';
		elsif (rising_edge(i_clk)) then
			o_wr <= '0';
			loc_addr := axil_waddr(1 downto 0);
			if(axil_write_ready = '1') then
				case loc_addr is 
					when "00" =>
						w_tx_reg <= axil_wdata(15 downto 0);	
						o_wr <= '1';
					when "10" =>
						w_config_reg(15 downto 0) <= axil_wdata(15 downto 0);	
					when "11" =>
						w_config_reg(31 downto 16) <= axil_wdata(15 downto 0);
					when others => 
						null;
				end case;
			end if;
		end if;
	end process; -- manage_write_regs

	manage_read_regs : process(i_clk,i_arst) is
		variable loc_addr : std_ulogic_vector(1 downto 0);
	begin
		if(i_arst = '1') then
			axil_rdata <= (others => '0');
		elsif (rising_edge(i_clk)) then
			loc_addr := axil_raddr(1 downto 0);
			if(S_AXI_RREADY = '1' and S_AXI_RVALID = '0' and loc_addr = "01") then
				axil_rdata(15 downto 0) <= i_spi_rd_data;
			end if;
		end if;
	end process; -- manage_read_regs

	o_config_reg <= w_config_reg;
	o_tx_reg <= w_tx_reg;
end rtl;