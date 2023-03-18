from cocotb_test.simulator import run
from cocotb.binary import BinaryValue
import pytest
import os

vhdl_compile_args = "--std=08"
sim_args = "--wave=wave.ghw"


tests_dir = os.path.abspath(os.path.dirname(__file__)) #gives the path to the test(current) directory in which this test.py file is placed
rtl_dir = tests_dir                                    #path to hdl folder where .vhdd files are placed


      
#run tests with generic values for length
@pytest.mark.parametrize("g_data_width", [str(8),str(16)])
def test_uart(g_data_width):

    module = "testbench_w_slave"
    toplevel = "spi_top_w_slave"   
    vhdl_sources = [
        os.path.join(rtl_dir, "sclk_gen.vhd"),
        os.path.join(rtl_dir, "spi_logic.vhd"),
        os.path.join(rtl_dir, "spi_slave.vhd"),
        os.path.join(rtl_dir, "synchronous_fifo.vhd"),
        os.path.join(rtl_dir, "spi_top_w_slave.vhd"),
        ]

    parameter = {}
    parameter['g_data_width'] = g_data_width


    run(
        python_search=[tests_dir],                         #where to search for all the python test files
        vhdl_sources=vhdl_sources,
        toplevel=toplevel,
        module=module,

        vhdl_compile_args=[vhdl_compile_args],
        toplevel_lang="vhdl",
        parameters=parameter,                              #parameter dictionary
        extra_env=parameter,
        sim_build="sim_build/"
        + "_".join(("{}={}".format(*i) for i in parameter.items())),
    )
