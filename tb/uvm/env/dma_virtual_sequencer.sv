class dma_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(dma_virtual_sequencer)

  axil_sequencer axil_sqr;
  virtual axi_mem_model mem_vif;

  uvm_analysis_port #(dma_cov_item) cov_ap;

  function new(string name = "dma_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
    cov_ap = new("cov_ap", this);
  endfunction
endclass