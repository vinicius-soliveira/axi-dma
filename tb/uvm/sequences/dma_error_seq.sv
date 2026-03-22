class dma_error_seq extends dma_base_seq;
  `uvm_object_utils(dma_error_seq)

  function new(string name = "dma_error_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] status;
    int watchdog;

    check_handles();

    p_sequencer.mem_vif.fill_pattern(src_addr, len_bytes/4, seed);

    program_dma();

    watchdog = 0;
    forever begin
      do_read(dma_pkg::CSR_STATUS_OFF, status);

      if (status[2]) begin
        `uvm_info("DMAERR_EXP",
          $sformatf("Expected DMA error observed status=%08h src=%08h dst=%08h len=%0d max_beats=%0d",
                    status, src_addr, dst_addr, len_bytes, max_beats),
          UVM_LOW)
        return;
      end

      if (status[1]) begin
        `uvm_fatal("UNEXP_DONE",
          $sformatf("DMA completed successfully but error was expected. status=%08h", status))
      end

      repeat (20) @(posedge p_sequencer.mem_vif.ACLK);
      watchdog++;
      if (watchdog > 300)
        `uvm_fatal("TIMEOUT", "Timeout waiting expected DMA error")
    end
  endtask
endclass