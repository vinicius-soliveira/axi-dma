class dma_random_seq extends dma_base_seq;
  `uvm_object_utils(dma_random_seq)

  rand int unsigned num_transactions;

  constraint c_num_txn { num_transactions inside {[5:20]}; }

  function new(string name = "dma_random_seq");
    super.new(name);
    num_transactions = 10;
  endfunction

  task body();
    for (int i = 0; i < num_transactions; i++) begin
      if (!randomize())
        `uvm_fatal("RAND", "Failed to randomize dma_random_seq")
      super.body();
      repeat (5) @(posedge p_sequencer.mem_vif.ACLK);
    end
  endtask
endclass
