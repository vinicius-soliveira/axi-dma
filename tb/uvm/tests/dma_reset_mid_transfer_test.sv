class dma_reset_mid_transfer_test extends dma_base_test;
  `uvm_component_utils(dma_reset_mid_transfer_test)

  function new(string name = "dma_reset_mid_transfer_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_base_seq seq;

    phase.raise_objection(this);

    // adiciona atrasos para aumentar chance de reset pegar transação em andamento
    env.mem_vif.aw_delay_cycles = 3;
    env.mem_vif.ar_delay_cycles = 3;
    env.mem_vif.r_delay_cycles  = 2;
    env.mem_vif.b_delay_cycles  = 2;

    seq = dma_base_seq::type_id::create("seq");
    seq.src_addr  = 32'h0007_0000;
    seq.dst_addr  = 32'h0008_0000;
    seq.len_bytes = 32'd256;
    seq.max_beats = 8;
    seq.seed      = 32'hD100_0000;

    fork
      begin
        seq.start(env.vsqr);
      end
      begin
        wait (env.mem_vif.AWVALID || env.mem_vif.ARVALID || env.mem_vif.WVALID || env.mem_vif.RVALID);
        repeat (3) @(posedge env.mem_vif.ACLK);

        `uvm_info("RSTMID", "Asserting reset during DMA activity", UVM_LOW)

        env.axil_vif.ARESETn = 1'b0;
        env.mem_vif.ARESETn  = 1'b0;

        repeat (5) @(posedge env.mem_vif.ACLK);

        env.axil_vif.ARESETn = 1'b1;
        env.mem_vif.ARESETn  = 1'b1;

        `uvm_info("RSTMID", "Releasing reset", UVM_LOW)
      end
    join

    env.mem_vif.aw_delay_cycles = 0;
    env.mem_vif.ar_delay_cycles = 0;
    env.mem_vif.r_delay_cycles  = 0;
    env.mem_vif.b_delay_cycles  = 0;

    phase.drop_objection(this);
  endtask
endclass