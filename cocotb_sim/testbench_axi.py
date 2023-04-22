# Functional test for uart module
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles,ReadWrite
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverPoint,coverage_db

covered_valued = []

g_word_width = int(cocotb.top.g_data_width)

full = False
def notify():
	global full
	full = True


# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.i_data",xf = lambda x : x, bins = list(range(2**8)), at_least=1)
def number_cover(data):
	covered_valued.append(int(data))

async def reset(dut,cycles=1):
	dut.S_AXI_ARESETN.value = 0
	dut.S_AXI_AWVALID.value = 0
	dut.S_AXI_AWADDR.value = 0
	dut.S_AXI_WVALID.value = 0
	dut.S_AXI_WDATA.value = 0
	dut.S_AXI_WSTRB.value = 15
	dut.S_AXI_BREADY.value = 0
	dut.S_AXI_ARVALID.value = 0
	dut.S_AXI_ARADDR.value = 0
	dut.S_AXI_RREADY.value = 0
	await ClockCycles(dut.S_AXI_ACLK,cycles)
	dut.S_AXI_ARESETN.value = 1
	await RisingEdge(dut.S_AXI_ACLK)
	dut._log.info("the core was reset")

async def connect_mosi_miso(dut):
	while full != True:
		await RisingEdge(dut.S_AXI_ACLK)
		dut.i_miso.value = dut.o_mosi.value 		#loopback


	# 					REGISTER MAP

	# 			Address 		| 		Functionality
	#			   0 			|	tx_reg (data to tx)
	#			   1 			|	rx_reg (data read)
	#			   2 			|	(15 downto 8) -> scl_cycles, (7 downto 3) -> X, 2->lsb_first, 1->pha, 0->pol
	#			   3 			|	(31 downto 28) -> X, (27 downto 24) -> idling, (23 downto 20) -> tailing, (19 donwto 16) -> leading


@cocotb.test()
async def test(dut):
	"""Check results and coverage for spi controller"""

	cocotb.start_soon(Clock(dut.S_AXI_ACLK, 10, units="ns").start())
	await reset(dut,5)	
	cocotb.start_soon(connect_mosi_miso(dut))

	
	expected_value = 0

	dut.S_AXI_AWVALID.value = 1
	dut.S_AXI_AWADDR.value = 2
	dut.S_AXI_WVALID.value = 1
	dut.S_AXI_WDATA.value = 5120   #0x1400
	dut.S_AXI_BREADY.value = 1
	await RisingEdge(dut.S_AXI_ACLK)
	await RisingEdge(dut.S_AXI_BVALID)
	dut.S_AXI_AWVALID.value = 0
	dut.S_AXI_WVALID.value = 0

	await RisingEdge(dut.S_AXI_ACLK)

	dut.S_AXI_AWVALID.value = 1
	dut.S_AXI_AWADDR.value = 3
	dut.S_AXI_WVALID.value = 1
	dut.S_AXI_WDATA.value = 580
	dut.S_AXI_BREADY.value = 1
	await RisingEdge(dut.S_AXI_ACLK)
	await RisingEdge(dut.S_AXI_BVALID)
	dut.S_AXI_AWVALID.value = 0
	dut.S_AXI_WVALID.value = 0
	await RisingEdge(dut.S_AXI_ACLK)


	while(full != True):
		
		data = random.randint(0,2**8-1)		#too costly to achieve 100% coverage with width= 16
		while(data in covered_valued):		#change according to teting capabilities
			data = random.randint(0,2**8-1)
		expected_value = data

		dut.S_AXI_AWVALID.value = 1
		dut.S_AXI_AWADDR.value = 0
		dut.S_AXI_WVALID.value = 1
		dut.S_AXI_WDATA.value = data
		dut.S_AXI_BREADY.value = 1
		await RisingEdge(dut.S_AXI_ACLK)
		await RisingEdge(dut.S_AXI_BVALID)
		dut.S_AXI_AWVALID.value = 0
		dut.S_AXI_WVALID.value = 0

		await RisingEdge(dut.o_rx_ready) 	#rx done interrupt


		dut.S_AXI_ARVALID.value = 1
		dut.S_AXI_ARADDR.value = 1
		dut.S_AXI_RREADY.value = 1
		await FallingEdge(dut.S_AXI_RVALID)
		dut.S_AXI_ARVALID.value = 0
		await RisingEdge(dut.S_AXI_ACLK)
		
		assert not (expected_value != int(dut.o_data.value)),"Different expected to actual data on Master RX"
		coverage_db["top.i_data"].add_threshold_callback(notify, 100)
		number_cover(data)

		await FallingEdge(dut.o_stall)

	# coverage_db.report_coverage(cocotb.log.info,bins=True)
	coverage_db.export_to_xml(filename="coverage.xml")


