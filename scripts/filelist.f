# RTL
rtl/dma_pkg.sv
rtl/dma_fifo.sv
rtl/dma_csr.sv
rtl/dma_fsm.sv
rtl/dma_axi_master_rd.sv
rtl/dma_axi_master_wr.sv
rtl/dma_axi_top.sv

# Assertions
tb/assertions/axil_sva.sv
tb/assertions/dma_ctrl_sva.sv
tb/assertions/dma_axi_read_sva.sv
tb/assertions/dma_axi_write_sva.sv

# Bind
tb/binds/dma_binds.sv

# TB infrastructure
tb/uvm/top/axil_if.sv
tb/uvm/models/axi_mem_model.sv

# UVM package
tb/uvm/pkg/dma_uvm_pkg.sv

# Top
tb/uvm/top/tb_top.sv
