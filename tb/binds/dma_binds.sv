bind dma_axi_top axil_sva #(
  .ADDR_W(32),
  .DATA_W(32)
) u_axil_sva (
  .ACLK    (ACLK),
  .ARESETn (ARESETn),

  .AWADDR  (S_AXI_AWADDR),
  .AWVALID (S_AXI_AWVALID),
  .AWREADY (S_AXI_AWREADY),
  .WDATA   (S_AXI_WDATA),
  .WSTRB   (S_AXI_WSTRB),
  .WVALID  (S_AXI_WVALID),
  .WREADY  (S_AXI_WREADY),
  .BRESP   (S_AXI_BRESP),
  .BVALID  (S_AXI_BVALID),
  .BREADY  (S_AXI_BREADY),

  .ARADDR  (S_AXI_ARADDR),
  .ARVALID (S_AXI_ARVALID),
  .ARREADY (S_AXI_ARREADY),
  .RDATA   (S_AXI_RDATA),
  .RRESP   (S_AXI_RRESP),
  .RVALID  (S_AXI_RVALID),
  .RREADY  (S_AXI_RREADY)
);

bind dma_axi_top dma_ctrl_sva u_dma_ctrl_sva (
  .ACLK       (ACLK),
  .ARESETn    (ARESETn),
  .start_pulse(start_pulse),
  .busy       (core_busy),
  .done       (core_done_pulse),
  .error      (core_err_pulse),
  .src_addr   (src_addr),
  .dst_addr   (dst_addr),
  .len_bytes  (len_bytes)
);

bind dma_axi_top dma_axi_read_sva #(
  .ADDR_W(32),
  .DATA_W(32)
) u_dma_axi_read_sva (
  .ACLK    (ACLK),
  .ARESETn (ARESETn),

  .ARADDR  (M_AXI_ARADDR),
  .ARLEN   (M_AXI_ARLEN),
  .ARSIZE  (M_AXI_ARSIZE),
  .ARBURST (M_AXI_ARBURST),
  .ARVALID (M_AXI_ARVALID),
  .ARREADY (M_AXI_ARREADY),

  .RDATA   (M_AXI_RDATA),
  .RRESP   (M_AXI_RRESP),
  .RLAST   (M_AXI_RLAST),
  .RVALID  (M_AXI_RVALID),
  .RREADY  (M_AXI_RREADY)
);

bind dma_axi_top dma_axi_write_sva #(
  .ADDR_W(32),
  .DATA_W(32),
  .STRB_W(4)
) u_dma_axi_write_sva (
  .ACLK    (ACLK),
  .ARESETn (ARESETn),

  .AWADDR  (M_AXI_AWADDR),
  .AWLEN   (M_AXI_AWLEN),
  .AWSIZE  (M_AXI_AWSIZE),
  .AWBURST (M_AXI_AWBURST),
  .AWVALID (M_AXI_AWVALID),
  .AWREADY (M_AXI_AWREADY),

  .WDATA   (M_AXI_WDATA),
  .WSTRB   (M_AXI_WSTRB),
  .WLAST   (M_AXI_WLAST),
  .WVALID  (M_AXI_WVALID),
  .WREADY  (M_AXI_WREADY),

  .BRESP   (M_AXI_BRESP),
  .BVALID  (M_AXI_BVALID),
  .BREADY  (M_AXI_BREADY)
);