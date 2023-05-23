# Makefile

# defaults
SIM ?= ghdl
TOPLEVEL_LANG ?= vhdl
EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/../rtl/intf_registers.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_slave.vhd
VHDL_SOURCES += $(PWD)/../rtl/synchronous_fifo.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_logic.vhd
VHDL_SOURCES += $(PWD)/../rtl/sclk_gen.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_top.vhd
VHDL_SOURCES += $(PWD)/../rtl/spi_top_w_slave.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file
test_w_slave:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench_w_slave TOPLEVEL=spi_top_w_slave	

test:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench TOPLEVEL=spi_top	

clean_dir:
		rm -f wave.*
		rm -f *.o 
		rm -f *.xml
		find . -maxdepth 1 -type f -executable -exec rm {} +
		find -mindepth 1 -maxdepth 1 -type d -print0 | xargs -r0 rm -R
# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim