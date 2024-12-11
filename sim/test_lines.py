import os
import sys
import cocotb
import random
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from cocotb.runner import get_runner
import datetime

@cocotb.test()
async def test_convolution(dut):
    """Testbench for the convolution module."""
    
    # Start clock
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    
    # Reset
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5)
    dut.rst_in.value = 0



    kernel_0_output = []

    # Initialize inputs
    dut.data_valid_in.value = 0
    hcount = 0
    vcount = 0

    # Load input data into the module
    for row in input_data:
        for pixel in row:
            dut.data_in.value = pixel
            dut.hcount_in.value = hcount
            dut.vcount_in.value = vcount
            dut.data_valid_in.value = 1

            

            hcount += 1
            if hcount >= 3:
                hcount = 0
                vcount += 1

            await ClockCycles(dut.clk_in, 4)
            dut._log.info(f"Line buffer output: {dut.line_out}")
            dut._log.info(f"hcount output: {dut.hcount_out}")
            dut._log.info(f"vcount output: {dut.vcount_out}")

        await ClockCycles(dut.clk_in, 2)

    # Wait for convolution operation to complete
    await ClockCycles(dut.clk_in, 10)


def is_runner():
    """line_buffer Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))

    sources = [proj_path / "hdl" / "top_level.sv", proj_path / "hdl" / "image_sprite2.sv", proj_path / "hdl" / "before_sprite.sv",
               proj_path / "hdl" / "video_sig_gen.sv", proj_path / "hdl" / "xilinx_single_port_ram_read_first.v", 
               ]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="convolution",  
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=('1ns', '1ps'),
        waves=True
    )

    run_test_args = []
    test_result = runner.test(
        hdl_toplevel="convolution",
        test_module="test_convolution",  
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()