# ============================================================
# SDC Constraints - dma_axi_top (AXI DMA)
# ============================================================

# ------------------------------------------------------------
# Clock
# ------------------------------------------------------------
create_clock -name ACLK -period 10.000 [get_ports ACLK]

# Clock uncertainty
set_clock_uncertainty 0.200 [get_clocks ACLK]

# ------------------------------------------------------------
# Input delays (exclude clock and reset)
# ------------------------------------------------------------
set_input_delay 1.000 -clock ACLK [get_ports {
  S_AXI_AWADDR[*]
  S_AXI_AWVALID
  S_AXI_WDATA[*]
  S_AXI_WSTRB[*]
  S_AXI_WVALID
  S_AXI_BREADY
  S_AXI_ARADDR[*]
  S_AXI_ARVALID
  S_AXI_RREADY

  M_AXI_ARREADY
  M_AXI_RDATA[*]
  M_AXI_RRESP[*]
  M_AXI_RLAST
  M_AXI_RVALID

  M_AXI_AWREADY
  M_AXI_WREADY
  M_AXI_BRESP[*]
  M_AXI_BVALID
}]

# ------------------------------------------------------------
# Output delays
# ------------------------------------------------------------
set_output_delay 1.000 -clock ACLK [get_ports {
  S_AXI_AWREADY
  S_AXI_WREADY
  S_AXI_BRESP[*]
  S_AXI_BVALID
  S_AXI_ARREADY
  S_AXI_RDATA[*]
  S_AXI_RRESP[*]
  S_AXI_RVALID

  M_AXI_ARADDR[*]
  M_AXI_ARLEN[*]
  M_AXI_ARSIZE[*]
  M_AXI_ARBURST[*]
  M_AXI_ARVALID
  M_AXI_RREADY

  M_AXI_AWADDR[*]
  M_AXI_AWLEN[*]
  M_AXI_AWSIZE[*]
  M_AXI_AWBURST[*]
  M_AXI_AWVALID
  M_AXI_WDATA[*]
  M_AXI_WSTRB[*]
  M_AXI_WLAST
  M_AXI_WVALID
  M_AXI_BREADY

  IRQ
}]

# ------------------------------------------------------------
# Simple I/O modeling
# ------------------------------------------------------------
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 [get_ports {
  S_AXI_AWADDR[*]
  S_AXI_AWVALID
  S_AXI_WDATA[*]
  S_AXI_WSTRB[*]
  S_AXI_WVALID
  S_AXI_BREADY
  S_AXI_ARADDR[*]
  S_AXI_ARVALID
  S_AXI_RREADY

  M_AXI_ARREADY
  M_AXI_RDATA[*]
  M_AXI_RRESP[*]
  M_AXI_RLAST
  M_AXI_RVALID

  M_AXI_AWREADY
  M_AXI_WREADY
  M_AXI_BRESP[*]
  M_AXI_BVALID
}]

set_load 0.050 [get_ports {
  S_AXI_AWREADY
  S_AXI_WREADY
  S_AXI_BRESP[*]
  S_AXI_BVALID
  S_AXI_ARREADY
  S_AXI_RDATA[*]
  S_AXI_RRESP[*]
  S_AXI_RVALID

  M_AXI_ARADDR[*]
  M_AXI_ARLEN[*]
  M_AXI_ARSIZE[*]
  M_AXI_ARBURST[*]
  M_AXI_ARVALID
  M_AXI_RREADY

  M_AXI_AWADDR[*]
  M_AXI_AWLEN[*]
  M_AXI_AWSIZE[*]
  M_AXI_AWBURST[*]
  M_AXI_AWVALID
  M_AXI_WDATA[*]
  M_AXI_WSTRB[*]
  M_AXI_WLAST
  M_AXI_WVALID
  M_AXI_BREADY

  IRQ
}]
