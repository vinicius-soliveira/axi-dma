class dma_smoke_test extends dma_base_test;
  `uvm_component_utils(dma_smoke_test)

  function new(string name = "dma_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_base_seq seq;
    phase.raise_objection(this);
    seq = dma_base_seq::type_id::create("seq");
    seq.src_addr  = 32'h0001_0000;
    seq.dst_addr  = 32'h0002_0000;
    seq.len_bytes = 32'd32;
    seq.max_beats = 8;
    seq.seed      = 32'hA000_0000;
    seq.start(env.vsqr);
    phase.drop_objection(this);
  endtask
endclass
