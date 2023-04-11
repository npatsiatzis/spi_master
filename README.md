![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/regression_controller.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/coverage_controller.yml/badge.svg)

### spi-controller RTL implementation


- supports all four spi modes
- CoCoTB testbench for functional verification
    - $ make
        - test based on simple spi slave model, the operation of which is controller via host interface. can be expanded to act as a memory(flash) or any other kind of spi-enabled device.
    - $ make test
        - test based on a loopback (cross coupling of miso,mosi lines of the spi master, no slave involed)


