class dma_random_test extends dma_base_test;
  `uvm_component_utils(dma_random_test)

  function new(string name = "dma_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_random_seq seq;
    phase.raise_objection(this);
    seq = dma_random_seq::type_id::create("seq");
    void'(seq.randomize() with { num_transactions == 10; });
    seq.start(env.vsqr);
    phase.drop_objection(this);
  endtask
endclass
