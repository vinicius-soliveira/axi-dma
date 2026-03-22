class dma_factory_override_test extends dma_base_test;
  `uvm_component_utils(dma_factory_override_test)

  function new(string name = "dma_factory_override_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    dma_base_seq::type_id::set_type_override(dma_random_seq::get_type());

    `uvm_info(
      "FACTORY",
      "Applied factory override: dma_base_seq -> dma_random_seq",
      UVM_LOW
    )
  endfunction

  task run_phase(uvm_phase phase);
    dma_base_seq seq;

    phase.raise_objection(this);

    seq = dma_base_seq::type_id::create("seq");
    seq.start(env.vsqr);

    phase.drop_objection(this);
  endtask
endclass