class dma_base_seq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(dma_base_seq)
  `uvm_declare_p_sequencer(dma_virtual_sequencer)

  rand bit [31:0] src_addr;
  rand bit [31:0] dst_addr;
  rand bit [31:0] len_bytes;
  rand bit [7:0]  max_beats;
  rand bit [31:0] seed;

  constraint c_default {
    src_addr[1:0] == 2'b00;
    dst_addr[1:0] == 2'b00;
    len_bytes inside {[4:256]};
    len_bytes[1:0] == 2'b00;
    max_beats inside {1,2,4,8,16};
    ((dst_addr >= src_addr + len_bytes) || (src_addr >= dst_addr + len_bytes));
  }

  function new(string name = "dma_base_seq");
    super.new(name);
    src_addr  = 32'h0001_0000;
    dst_addr  = 32'h0002_0000;
    len_bytes = 32'd32;
    max_beats = 8;
    seed      = 32'hA000_0000;
  endfunction

  task body();
    axil_seq_item tr;
    bit [31:0] status;
    int watchdog;
    int unsigned bad_idx;
    logic [31:0] exp, got;

    if (p_sequencer == null)
      `uvm_fatal("NOVSQR", "dma_base_seq requires dma_virtual_sequencer")
    if (p_sequencer.axil_sqr == null)
      `uvm_fatal("NOAXILSQR", "axil_sqr is null")
    if (p_sequencer.mem_vif == null)
      `uvm_fatal("NOMEMVIF", "mem_vif is null")

    p_sequencer.mem_vif.fill_pattern(src_addr, len_bytes/4, seed);

    do_write(dma_pkg::CSR_SRC_ADDR_OFF,  src_addr);
    do_write(dma_pkg::CSR_DST_ADDR_OFF,  dst_addr);
    do_write(dma_pkg::CSR_LEN_BYTES_OFF, len_bytes);
    do_write(dma_pkg::CSR_BURST_CFG_OFF, {24'd0, max_beats});
    do_write(dma_pkg::CSR_CTRL_OFF,      32'h0000_0003);

    watchdog = 0;
    forever begin
      do_read(dma_pkg::CSR_STATUS_OFF, status);
      if (status[2])
        `uvm_fatal("DMAERR", $sformatf("DMA error status=%08h", status))
      if (status[1]) begin
        if (!p_sequencer.mem_vif.check_copy(src_addr, dst_addr, len_bytes/4, bad_idx, exp, got)) begin
          `uvm_fatal("COPYCHK", $sformatf("Copy mismatch idx=%0d exp=%08h got=%08h", bad_idx, exp, got))
        end
        break;
      end
      repeat (20) @(posedge p_sequencer.mem_vif.ACLK);
      watchdog++;
      if (watchdog > 300)
        `uvm_fatal("TIMEOUT", "Timeout waiting DMA done")
    end

    do_write(dma_pkg::CSR_STATUS_OFF, 32'h0000_0002);
  endtask

  task do_write(bit [31:0] addr, bit [31:0] data);
    axil_seq_item tr;
    tr = axil_seq_item::type_id::create("wr_tr");
    tr.is_write = 1;
    tr.addr     = addr;
    tr.data     = data;
    start_item_on_axil(tr);
    if (tr.resp != 2'b00)
      `uvm_fatal("AXILWR", $sformatf("AXI-Lite write failed addr=%08h resp=%0b", addr, tr.resp))
  endtask

  task do_read(bit [31:0] addr, output bit [31:0] data);
    axil_seq_item tr;
    tr = axil_seq_item::type_id::create("rd_tr");
    tr.is_write = 0;
    tr.addr     = addr;
    start_item_on_axil(tr);
    if (tr.resp != 2'b00)
      `uvm_fatal("AXILRD", $sformatf("AXI-Lite read failed addr=%08h resp=%0b", addr, tr.resp))
    data = tr.rdata;
  endtask

  task start_item_on_axil(axil_seq_item tr);
    `uvm_do_on_with(tr, p_sequencer.axil_sqr, {})
  endtask
endclass
