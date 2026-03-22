class axil_sequencer extends uvm_sequencer #(axil_seq_item);
  `uvm_component_utils(axil_sequencer)

  function new(string name = "axil_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass
