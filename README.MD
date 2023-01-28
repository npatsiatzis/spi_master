![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/regression.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/coverage.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/regression_pyuvm.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/coverage_pyuvm.yml/badge.svg)

### spi-master RTL implementation


- supports all four spi modes
- supports continuous transmission
- CoCoTB testbench for functional verification
    - $ make
- CoCoTB-test unit testing to exercise the CoCoTB tests across a range of values for the generic parameters
    - $  SIM=ghdl pytest -n auto -o log_cli=True --junitxml=test-results.xml --cocotbxml=test-cocotb.xml


