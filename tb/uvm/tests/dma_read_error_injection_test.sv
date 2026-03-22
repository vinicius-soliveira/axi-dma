class dma_read_error_injection_test extends dma_base_test;
  `uvm_component_utils(dma_read_error_injection_test)

  function new(string name = "dma_read_error_injection_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_error_seq seq;

    phase.raise_objection(this);

    env.mem_vif.inject_rresp_err = 1'b1;

    seq = dma_error_seq::type_id::create("seq");
    seq.src_addr  = 32'h0005_0000;
    seq.dst_addr  = 32'h0006_0000;
    seq.len_bytes = 32'd32;
    seq.max_beats = 4;
    seq.seed      = 32'hC000_0000;
    seq.start(env.vsqr);

    env.mem_vif.inject_rresp_err = 1'b0;

    phase.drop_objection(this);
  endtask
endclass