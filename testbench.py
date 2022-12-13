# Functional test for spi_master
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
from cocotb_coverage import crv 

g_sys_clk = int(cocotb.top.g_sys_clk)
period_ns = 10**9 / g_sys_clk
g_clk_div_len = int(cocotb.top.g_clk_div_len)
g_width = int(cocotb.top.g_width)


class crv_inputs(crv.Randomized):
	def __init__(self,data,pol,pha,clk_div):
		crv.Randomized.__init__(self)
		self.data = data
		self.pol = pol
		self.pha = pha 
		self.clk_div = clk_div 
		self.add_rand("data",list(range(2**g_width)))
		self.add_rand("pol",list(range(0,2)))
		self.add_rand("pha",list(range(0,2)))
		self.add_rand("clk_div",list(range(2,2**g_clk_div_len)))


covered_value = []

full = False
# #Callback function to capture the bin content showing
def notify_full():
	global full
	full = True

# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.o_rx_data",xf = lambda x : x.o_rx_data.value, bins = list(range(2**g_width)), at_least=1)
@CoverPoint("top.i_clk_div",xf = lambda x : x.i_clk_div.value,bins = list(range(2,2**g_clk_div_len)),at_least=1)
@CoverPoint("top.i_pol",xf = lambda x : x.i_pol.value == 1,bins = list(range(2**10)),at_least=1)
@CoverPoint("top.i_pha",xf = lambda x : x.i_pha.value == 1,bins = [True,False],at_least=1)
@CoverCross("top.data_X_clk_div", items = ["top.o_rx_data","top.i_clk_div"], at_least=1)
def number_cover(dut):
	covered_value.append(dut.o_rx_data.value)

async def reset(dut,cycles=1):
	dut.i_arst_n.value = 0

	dut.i_en.value = 0 
	dut.i_tx_data.value = 0
	dut.i_cont.value = 0
	dut.i_addr.value = 0
	dut.i_clk_div.value = 2 
	dut.i_pol.value = 0
	dut.i_pha.value = 0
	dut.i_miso.value = 0

	await ClockCycles(dut.i_clk,cycles)
	dut.i_arst_n.value = 1
	await RisingEdge(dut.i_clk)
	dut._log.info("the core was reset")

@cocotb.test()
async def test(dut):
	"""Check results and coverage for spi_master"""

	cocotb.start_soon(Clock(dut.i_clk, period_ns, units="ns").start())
	await reset(dut,5)	
	

	expected_value = 0
	rx_data = 0

	inputs = crv_inputs(0,0,0,0)
	inputs.randomize()


	dut.i_tx_data.value = inputs.data

	expected_value = inputs.data
	dut.i_en.value = 1

	while(full != True):
		await RisingEdge(dut.i_clk)
		dut.i_miso.value = dut.o_mosi.value
		old_rx_data = rx_data
		rx_data = dut.o_rx_data.value
		if(old_rx_data != rx_data):
			assert not (expected_value != int(dut.o_rx_data.value)),"Different expected to actual read data"
			number_cover(dut)
			coverage_db["top.o_rx_data"].add_threshold_callback(notify_full, 100)	
			
			inputs.randomize()
			data = inputs.data
			if(full == True):
				break
			else:
				while(data in covered_value):					
					inputs.randomize()
					data = inputs.data
				dut.i_tx_data.value = data
				expected_value = data
		
