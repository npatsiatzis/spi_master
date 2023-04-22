# Makefile

# defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/../rtl/axil_regs.vhd
VHDL_SOURCES += $(PWD)/../rtl/intf_registers.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_slave.vhd
VHDL_SOURCES += $(PWD)/../rtl/synchronous_fifo.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_logic.vhd
VHDL_SOURCES += $(PWD)/../rtl/sclk_gen.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_top.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_top_axi.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_top_w_slave.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_top_w_slave_axi.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file
test_w_slave:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_w_slave TOPLEVEL=spi_top_w_slave	

test_w_slave_axi:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_w_slave_axi TOPLEVEL=spi_top_w_slave_axi	

test:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench TOPLEVEL=spi_top	

test_axi:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_axi TOPLEVEL=spi_top_axi
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim