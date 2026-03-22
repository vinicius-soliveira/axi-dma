class dma_smoke_seq extends dma_base_seq;
  `uvm_object_utils(dma_smoke_seq)

  function new(string name = "dma_smoke_seq");
    super.new(name);
  endfunction

  task body();
    src_addr  = 32'h0001_0000;
    dst_addr  = 32'h0002_0000;
    len_bytes = 32'd32;
    max_beats = 8;

    super.body();
  endtask
endclass