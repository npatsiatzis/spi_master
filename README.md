![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/regression_controller.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/spi_master/actions/workflows/coverage_controller.yml/badge.svg)

### spi-controller RTL implementation


- supports all four spi modes
- CoCoTB testbench for functional verification
    - $ make
        - test based on simple spi slave model, the operation of which is controller via host interface. can be expanded to act as a memory(flash) or any other kind of spi-enabled device.
    - $ make test
        - test based on a loopback (cross coupling of miso,mosi lines of the spi master, no slave involed)


### Repo Structure

This is a short tabular description of the contents of each folder in the repo.

| Folder | Description |
| ------ | ------ |
| [rtl](https://github.com/npatsiatzis/spi_master/tree/main/rtl/VHDL) | VHDL RTL implementation files |
| [cocotb_sim](https://github.com/npatsiatzis/spi_master/tree/main/cocotb_sim) | Functional Verification with CoCoTB (Python-based) |
| [pyuvm_sim](https://github.com/npatsiatzis/spi_master/tree/main/pyuvm_sim) | Functional Verification with pyUVM (Python impl. of UVM standard) |


This is the tree view of the strcture of the repo.
<pre>
<font size = "2">
.
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/spi_master/tree/main/rtl">rtl</a></b> </font>
│   └── VHD files
├── <font size = "4"><b><a href="https://github.com/npatsiatzis/spi_master/tree/main/cocotb_sim">cocotb_sim</a></b></font>
│   ├── Makefile
│   └── python files
└── <font size = "4"><b><a 
 href="https://github.com/npatsiatzis/spi_master/tree/main/pyuvm_sim">pyuvm_sim</a></b></font>
    ├── Makefile
    └── python files
</pre>
