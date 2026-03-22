class dma_cov_item extends uvm_object;
  `uvm_object_utils(dma_cov_item)

  rand bit [31:0] src_addr;
  rand bit [31:0] dst_addr;
  rand bit [31:0] len_bytes;
  rand bit [7:0]  max_beats;

  int unsigned num_bursts;
  bit          is_done;
  bit          is_error;
  bit          is_single;

  function new(string name = "dma_cov_item");
    super.new(name);
  endfunction

  function void post_randomize();
    is_single = (num_bursts == 1);
  endfunction
endclass