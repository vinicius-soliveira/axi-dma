class dma_smoke_test extends dma_base_test;
  `uvm_component_utils(dma_smoke_test)

  function new(string name = "dma_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_smoke_seq seq;

    phase.raise_objection(this);

    wait (env.axil_ag.drv.vif.ARESETn === 1'b1);
    repeat (2) @(env.axil_ag.drv.vif.drv_cb);

    env.mem_vif.fill_pattern(32'h0001_0000, 8, 32'hA000_0000);

    seq = dma_smoke_seq::type_id::create("seq");
    seq.start(env.vsqr);

    phase.drop_objection(this);
  endtask
endclass