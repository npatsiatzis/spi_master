
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
        self.dut.i_we.value = 0
        self.dut.i_data.value = 0
        self.dut.i_miso .value = 0
        await ClockCycles(self.dut.i_clk,5)
        self.dut.i_arstn.value = 1
        await RisingEdge(self.dut.i_clk)

    async def driver_bfm(self):

        while True:
            await RisingEdge(self.dut.i_clk)
            self.dut.i_miso.value = self.dut.o_mosi.value
            try:
                (i_we,i_stb,i_addr,i_data) = self.driver_queue.get_nowait()
                self.dut.i_we.value = i_we
                self.dut.i_stb.value = i_stb
                self.dut.i_addr.value = i_addr
                self.dut.i_data.value = i_data

            except QueueEmpty:
                pass

    async def data_mon_bfm(self):
        while True:
            await RisingEdge(self.dut.o_stall)
            # await RisingEdge(self.dut.o_tx_ready)
            i_we = self.dut.i_we.value 
            i_stb = self.dut.i_stb.value 
            i_addr = self.dut.i_addr.value
            i_data = self.dut.i_data.value 

            data = (i_we,i_stb,i_addr,i_data)
            self.data_mon_queue.put_nowait(data)


    async def result_mon_bfm(self):
        while True:
            await RisingEdge(self.dut.o_rx_ready)    #rx done interrupt
            await RisingEdge(self.dut.o_ack)         #wait for ack of transaction
            self.result_mon_queue.put_nowait(self.dut.o_data.value)


    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())