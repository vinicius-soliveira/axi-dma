package dma_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_pkg::*;

  `include "tb/uvm/agents/axil/axil_seq_item.sv"
  `include "tb/uvm/agents/axil/axil_agent_cfg.sv"
  `include "tb/uvm/agents/axil/axil_sequencer.sv"
  `include "tb/uvm/agents/axil/axil_driver.sv"
  `include "tb/uvm/agents/axil/axil_monitor.sv"
  `include "tb/uvm/agents/axil/axil_agent.sv"

  `include "tb/uvm/env/dma_virtual_sequencer.sv"
  `include "tb/uvm/env/dma_scoreboard.sv"
  `include "tb/uvm/coverage/dma_cov_collector.sv"
  `include "tb/uvm/env/dma_env.sv"

  `include "tb/uvm/sequences/dma_base_seq.sv"
  `include "tb/uvm/sequences/dma_random_seq.sv"

  `include "tb/uvm/tests/dma_base_test.sv"
  `include "tb/uvm/tests/dma_smoke_test.sv"
  `include "tb/uvm/tests/dma_random_test.sv"
  `include "tb/uvm/tests/dma_error_injection_test.sv"
endpackage
