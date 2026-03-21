class dma_error_injection_test extends dma_base_test;
  `uvm_component_utils(dma_error_injection_test)

  function new(string name = "dma_error_injection_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_base_seq seq;
    phase.raise_objection(this);
    env.mem_vif.inject_bresp_err = 1'b1;
    seq = dma_base_seq::type_id::create("seq");
    seq.src_addr  = 32'h0001_3000;
    seq.dst_addr  = 32'h0002_3000;
    seq.len_bytes = 32'd16;
    seq.max_beats = 4;
    seq.seed      = 32'hD000_0000;
    // Expected to error/fatal in the sequence due to status[2] or AXI response.
    seq.start(env.vsqr);
    env.mem_vif.inject_bresp_err = 1'b0;
    phase.drop_objection(this);
  endtask
endclass
