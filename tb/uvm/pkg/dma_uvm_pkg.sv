package dma_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_pkg::*;

  `include "axil_seq_item.sv"
  `include "axil_agent_cfg.sv"
  `include "axil_sequencer.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"
  `include "axil_agent.sv"

  `include "dma_cov_item.sv"

  `include "dma_virtual_sequencer.sv"
  `include "dma_scoreboard.sv"
  `include "dma_cov_collector.sv"
  `include "dma_env.sv"

  `include "dma_base_seq.sv"
  `include "dma_random_seq.sv"
  `include "dma_smoke_seq.sv"
  `include "dma_error_seq.sv"

  `include "dma_base_test.sv"
  `include "dma_smoke_test.sv"
  `include "dma_random_test.sv"
  `include "dma_error_injection_test.sv"
  `include "dma_factory_override_test.sv"
  `include "dma_backpressure_test.sv"
  `include "dma_read_error_injection_test.sv"
  `include "dma_reset_mid_transfer_test.sv"
  `include "dma_corner_cases_test.sv"
endpackage