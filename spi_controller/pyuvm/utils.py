
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles
from cocotb.clock import Clock
from cocotb.queue import QueueEmpty, Queue
import cocotb
import enum
import random
from cocotb_coverage import crv 
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
from pyuvm import utility_classes



class SpiBfm(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.driver_queue = Queue(maxsize=1)
        self.data_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

    async def send_data(self, data):
        await self.driver_queue.put(data)

    async def get_data(self):
        data = await self.data_mon_queue.get()
        return data

    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result

    async def reset(self):
        await RisingEdge(self.dut.i_clk)
        self.dut.i_arstn.value = 0
        self.dut.i_wr.value = 0
        self.dut.i_rd.value = 0
        self.dut.i_pol.value = 0
        self.dut.i_pha.value = 0
        self.dut.i_lsb_first.value = 0
        self.dut.i_sclk_cycles.value = 20
        self.dut.i_leading_cycles.value = 4
        self.dut.i_tailing_cycles.value = 4
        self.dut.i_iddling_cycles.value = 2
        self.dut.i_data.value = 0
        self.dut.i_miso .value = 0
        await ClockCycles(self.dut.i_clk,5)
        self.dut.i_arstn.value = 1


    async def driver_bfm(self):
        # self.dut.i_tx_en.value = 0
        # self.dut.i_rx.value = 1
        # self.dut.i_tx_data.value = 0

        while True:
            await RisingEdge(self.dut.i_clk)
            self.dut.i_miso.value = self.dut.o_mosi.value
            try:
                (i_wr,i_rd,i_data) = self.driver_queue.get_nowait()
                self.dut.i_wr.value = i_wr
                self.dut.i_rd.value = i_rd
                self.dut.i_data.value = i_data

            except QueueEmpty:
                pass

    async def data_mon_bfm(self):
        while True:
            await RisingEdge(self.dut.o_tx_ready)
            i_wr = self.dut.i_wr.value 
            i_rd = self.dut.i_rd.value 
            i_data = self.dut.i_data.value 

            data = (i_wr,i_rd,i_data)
            self.data_mon_queue.put_nowait(data)


    async def result_mon_bfm(self):
        while True:
            await RisingEdge(self.dut.o_rx_ready)
            self.result_mon_queue.put_nowait(self.dut.o_data.value)


    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())