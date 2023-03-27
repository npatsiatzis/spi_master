# Makefile

# defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/spi_slave.vhd
VHDL_SOURCES += $(PWD)/spi_logic.vhd
VHDL_SOURCES += $(PWD)/sclk_gen.vhd
VHDL_SOURCES += $(PWD)/spi_top.vhd
VHDL_SOURCES += $(PWD)/spi_top_w_slave.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file
# test_w_slave:
# 		rm -rf sim_build
# 		$(MAKE) sim MODULE=testbench_w_slave TOPLEVEL=spi_top_w_slave	

test:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_pyuvm TOPLEVEL=spi_top	
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim