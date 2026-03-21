class dma_scoreboard extends uvm_component;
  `uvm_component_utils(dma_scoreboard)

  uvm_analysis_imp #(axil_seq_item, dma_scoreboard) imp;
  virtual axi_mem_model mem_vif;

  bit [31:0] src_addr;
  bit [31:0] dst_addr;
  bit [31:0] len_bytes;
  bit [7:0]  max_beats;

  function new(string name = "dma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_mem_model)::get(this, "", "mem_vif", mem_vif))
      `uvm_fatal("NOMEMVIF", "dma_scoreboard could not get mem_vif")
  endfunction

  function void write(axil_seq_item tr);
    int unsigned bad_idx;
    logic [31:0] exp, got;

    if (tr.is_write) begin
      case (tr.addr[7:0])
        dma_pkg::CSR_SRC_ADDR_OFF:   src_addr  = tr.data;
        dma_pkg::CSR_DST_ADDR_OFF:   dst_addr  = tr.data;
        dma_pkg::CSR_LEN_BYTES_OFF:  len_bytes = tr.data;
        dma_pkg::CSR_BURST_CFG_OFF:  max_beats = tr.data[7:0];
        default: ;
      endcase
    end else if (tr.addr[7:0] == dma_pkg::CSR_STATUS_OFF) begin
      if (tr.rdata[1]) begin
        if (!mem_vif.check_copy(src_addr, dst_addr, len_bytes/4, bad_idx, exp, got)) begin
          `uvm_error("SB", $sformatf("Copy mismatch idx=%0d exp=%08h got=%08h", bad_idx, exp, got))
        end else begin
          `uvm_info("SB", $sformatf("DMA copy check passed: src=%08h dst=%08h len=%0d", src_addr, dst_addr, len_bytes), UVM_LOW)
        end
      end
    end
  endfunction
endclass
