`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import dma_pkg::*;
  import dma_uvm_pkg::*;

  localparam int unsigned ADDR_W = 32;
  localparam int unsigned DATA_W = 32;
  localparam int unsigned FIFO_D = 16;
  localparam int unsigned CLK_NS = 10;

  logic ACLK = 0;
  logic ARESETn = 0;
  logic IRQ;

  always #(CLK_NS/2) ACLK = ~ACLK;

  axil_if      #(ADDR_W, 32)    axil_vif(ACLK);
  axi_mem_model#(ADDR_W, DATA_W) mem_vif(ACLK);

  dma_axi_top #(
    .ADDR_WIDTH      (ADDR_W),
    .DATA_WIDTH      (DATA_W),
    .AXIL_DATA_WIDTH (32),
    .FIFO_DEPTH      (FIFO_D)
  ) dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),

    .S_AXI_AWADDR (axil_vif.AWADDR),
    .S_AXI_AWVALID(axil_vif.AWVALID),
    .S_AXI_AWREADY(axil_vif.AWREADY),
    .S_AXI_WDATA  (axil_vif.WDATA),
    .S_AXI_WSTRB  (axil_vif.WSTRB),
    .S_AXI_WVALID (axil_vif.WVALID),
    .S_AXI_WREADY (axil_vif.WREADY),
    .S_AXI_BRESP  (axil_vif.BRESP),
    .S_AXI_BVALID (axil_vif.BVALID),
    .S_AXI_BREADY (axil_vif.BREADY),
    .S_AXI_ARADDR (axil_vif.ARADDR),
    .S_AXI_ARVALID(axil_vif.ARVALID),
    .S_AXI_ARREADY(axil_vif.ARREADY),
    .S_AXI_RDATA  (axil_vif.RDATA),
    .S_AXI_RRESP  (axil_vif.RRESP),
    .S_AXI_RVALID (axil_vif.RVALID),
    .S_AXI_RREADY (axil_vif.RREADY),

    .M_AXI_ARADDR (mem_vif.ARADDR),
    .M_AXI_ARLEN  (mem_vif.ARLEN),
    .M_AXI_ARSIZE (mem_vif.ARSIZE),
    .M_AXI_ARBURST(mem_vif.ARBURST),
    .M_AXI_ARVALID(mem_vif.ARVALID),
    .M_AXI_ARREADY(mem_vif.ARREADY),
    .M_AXI_RDATA  (mem_vif.RDATA),
    .M_AXI_RRESP  (mem_vif.RRESP),
    .M_AXI_RLAST  (mem_vif.RLAST),
    .M_AXI_RVALID (mem_vif.RVALID),
    .M_AXI_RREADY (mem_vif.RREADY),

    .M_AXI_AWADDR (mem_vif.AWADDR),
    .M_AXI_AWLEN  (mem_vif.AWLEN),
    .M_AXI_AWSIZE (mem_vif.AWSIZE),
    .M_AXI_AWBURST(mem_vif.AWBURST),
    .M_AXI_AWVALID(mem_vif.AWVALID),
    .M_AXI_AWREADY(mem_vif.AWREADY),
    .M_AXI_WDATA  (mem_vif.WDATA),
    .M_AXI_WSTRB  (mem_vif.WSTRB),
    .M_AXI_WLAST  (mem_vif.WLAST),
    .M_AXI_WVALID (mem_vif.WVALID),
    .M_AXI_WREADY (mem_vif.WREADY),
    .M_AXI_BRESP  (mem_vif.BRESP),
    .M_AXI_BVALID (mem_vif.BVALID),
    .M_AXI_BREADY (mem_vif.BREADY),

    .IRQ(IRQ)
  );
  
    initial begin
    ARESETn          = 0;
    axil_vif.ARESETn = 0;
    mem_vif.ARESETn  = 0;

    axil_vif.AWADDR  = '0;
    axil_vif.AWVALID = 0;
    axil_vif.WDATA   = '0;
    axil_vif.WSTRB   = '0;
    axil_vif.WVALID  = 0;
    axil_vif.BREADY  = 0;
    axil_vif.ARADDR  = '0;
    axil_vif.ARVALID = 0;
    axil_vif.RREADY  = 0;

    repeat (5) @(posedge ACLK);
    ARESETn          = 1;
    axil_vif.ARESETn = 1;
    mem_vif.ARESETn  = 1;
  end

  initial begin
    uvm_config_db#(virtual axil_if)::set(null, "*", "axil_vif", axil_vif);
    uvm_config_db#(virtual axil_if)::set(null, "*", "vif", axil_vif);
    uvm_config_db#(virtual axi_mem_model)::set(null, "*", "mem_vif", mem_vif);
    uvm_top.set_timeout(1ms, 1);
    run_test();
  end
endmodule
