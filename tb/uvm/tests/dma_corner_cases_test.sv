class dma_corner_cases_test extends dma_base_test;
  `uvm_component_utils(dma_corner_cases_test)

  function new(string name = "dma_corner_cases_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    dma_base_seq seq;

    phase.raise_objection(this);

    // caso 1: mínimo, burst único
    seq = dma_base_seq::type_id::create("seq_min");
    seq.src_addr  = 32'h0010_0000;
    seq.dst_addr  = 32'h0011_0000;
    seq.len_bytes = 32'd4;
    seq.max_beats = 1;
    seq.seed      = 32'hE000_0000;
    seq.start(env.vsqr);

    // caso 2: maximum with many burst
    seq = dma_base_seq::type_id::create("seq_max_many");
    seq.src_addr  = 32'h0012_0000;
    seq.dst_addr  = 32'h0013_0000;
    seq.len_bytes = 32'd256;
    seq.max_beats = 1;
    seq.seed      = 32'hE100_0000;
    seq.start(env.vsqr);

    // caso 3: maximum with large burst
    seq = dma_base_seq::type_id::create("seq_max_burst16");
    seq.src_addr  = 32'h0014_0000;
    seq.dst_addr  = 32'h0015_0000;
    seq.len_bytes = 32'd256;
    seq.max_beats = 16;
    seq.seed      = 32'hE200_0000;
    seq.start(env.vsqr);

    // case 4: last partial burst
    seq = dma_base_seq::type_id::create("seq_partial_last");
    seq.src_addr  = 32'h0016_0000;
    seq.dst_addr  = 32'h0017_0000;
    seq.len_bytes = 32'd100;
    seq.max_beats = 8;
    seq.seed      = 32'hE300_0000;
    seq.start(env.vsqr);

    phase.drop_objection(this);
  endtask
endclass