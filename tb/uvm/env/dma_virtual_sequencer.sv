class dma_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);
  `uvm_component_utils(dma_virtual_sequencer)

  axil_sequencer      axil_sqr;
  virtual axi_mem_model mem_vif;

  function new(string name = "dma_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
