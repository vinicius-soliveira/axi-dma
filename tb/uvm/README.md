# UVM scaffold for DMA AXI project

This directory contains a starter UVM environment aligned to the current DMA RTL.

## Main pieces
- `top/axil_if.sv`: AXI-Lite virtual interface used by the agent.
- `models/axi_mem_model.sv`: AXI memory responder with helper methods for fill/check.
- `agents/axil/*`: active AXI-Lite agent.
- `env/*`: environment, scoreboard, coverage, virtual sequencer.
- `sequences/*`: base and random DMA programming sequences.
- `tests/*`: smoke, random and error-injection tests.
- `pkg/dma_uvm_pkg.sv`: package that includes all class files.

## Suggested compile order
1. RTL package and RTL modules
2. `tb/uvm/top/axil_if.sv`
3. `tb/uvm/models/axi_mem_model.sv`
4. `tb/uvm/pkg/dma_uvm_pkg.sv`
5. `tb/uvm/top/tb_top.sv`

## Suggested first run
Use `+UVM_TESTNAME=dma_smoke_test`.

## Notes
This is a coherent starter scaffold meant to bootstrap the UVM environment quickly.
Depending on your simulator and filelist conventions, you may want to adjust include paths or split the package includes into filelist entries.
