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
@CoverPoint("top.i_data",xf = lambda x : x.i_data.value, bins = list(range(2**g_word_width)), at_least=1)
def number_cover(dut):
	covered_valued.append(int(dut.i_data.value))

async def reset(dut,cycles=1):
	dut.i_arstn.value = 0
	dut.i_we.value = 0
	dut.i_data.value = 0
	dut.i_miso .value = 0
	await ClockCycles(dut.i_clk,cycles)
	dut.i_arstn.value = 1
	await RisingEdge(dut.i_clk)
	dut._log.info("the core was reset")

async def connect_mosi_miso(dut):
	while full != True:
		await RisingEdge(dut.i_clk)
		dut.i_miso.value = dut.o_mosi.value 		#loopback


@cocotb.test()
async def test(dut):
	"""Check results and coverage for spi controller"""

	cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
	await reset(dut,5)	
	cocotb.start_soon(connect_mosi_miso(dut))

	
	
	expected_value = 0

	dut.i_addr.value = 2
	dut.i_stb.value = 1
	dut.i_we.value = 1
	dut.i_data.value = 5120   #0x1400

	await RisingEdge(dut.o_ack)

	dut.i_addr.value = 3
	dut.i_stb.value = 1
	dut.i_we.value = 1
	dut.i_data.value = 580

	await RisingEdge(dut.i_clk)
	dut.i_stb.value = 0
	dut.i_we.value = 0
	await FallingEdge(dut.o_ack)

	while(full != True):
		
		data = random.randint(0,2**8-1)		#too costly to achieve 100% coverage with width= 16
		while(data in covered_valued):		#change according to teting capabilities
			data = random.randint(0,2**8-1)
		expected_value = data

		dut.i_addr.value = 0 				#write data to txreg
		dut.i_data.value = data
		dut.i_we.value = 1
		dut.i_stb.value = 1
		await RisingEdge(dut.i_clk)
		await RisingEdge(dut.o_stall)
		dut.i_stb.value = 0
		dut.i_we.value = 0
		await RisingEdge(dut.o_rx_ready) 	#rx done interrupt
		dut.i_addr.value = 1 				#read data from rxreg
		dut.i_we.value = 0
		dut.i_stb.value = 1
		await RisingEdge(dut.o_ack) 		#wait for ack of transaction
		assert not (expected_value != int(dut.o_data.value)),"Different expected to actual data on Master RX"
		coverage_db["top.i_data"].add_threshold_callback(notify, 100)
		number_cover(dut)

		await FallingEdge(dut.o_stall)

	# coverage_db.report_coverage(cocotb.log.info,bins=True)
	coverage_db.export_to_xml(filename="coverage.xml")


