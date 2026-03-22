class dma_backpressure_test extends dma_base_test;
  `uvm_component_utils(dma_backpressure_test)

  function new(string name = "dma_backpressure_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_base_seq seq;

    phase.raise_objection(this);

    env.mem_vif.ar_delay_cycles = 3;
    env.mem_vif.aw_delay_cycles = 4;
    env.mem_vif.r_delay_cycles  = 2;
    env.mem_vif.b_delay_cycles  = 3;

    seq = dma_base_seq::type_id::create("seq");
    seq.src_addr  = 32'h0003_0000;
    seq.dst_addr  = 32'h0004_0000;
    seq.len_bytes = 32'd128;
    seq.max_beats = 4;
    seq.seed      = 32'hB000_0000;
    seq.start(env.vsqr);

 
    env.mem_vif.ar_delay_cycles = 0;
    env.mem_vif.aw_delay_cycles = 0;
    env.mem_vif.r_delay_cycles  = 0;
    env.mem_vif.b_delay_cycles  = 0;

    phase.drop_objection(this);
  endtask
endclass