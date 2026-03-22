class dma_scoreboard extends uvm_component;
  `uvm_component_utils(dma_scoreboard)

  uvm_analysis_imp  #(axil_seq_item, dma_scoreboard) imp;
  uvm_analysis_port #(dma_cov_item)                  cov_ap;

  virtual axi_mem_model mem_vif;

  bit [31:0] src_addr;
  bit [31:0] dst_addr;
  bit [31:0] len_bytes;
  bit [7:0]  max_beats;

  bit saw_done;
  bit saw_error;

  function new(string name = "dma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    imp    = new("imp", this);
    cov_ap = new("cov_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_mem_model)::get(this, "", "mem_vif", mem_vif))
      `uvm_fatal("NOMEMVIF", "dma_scoreboard could not get mem_vif")
  endfunction

  function int unsigned calc_num_bursts(bit [31:0] len_b, bit [7:0] beats_cfg);
    int unsigned words_total;
    int unsigned beats_per_burst;
    int unsigned nbursts;

    if (beats_cfg == 0)
      return 0;

    words_total      = len_b >> 2;
    beats_per_burst  = beats_cfg;
    nbursts          = (words_total + beats_per_burst - 1) / beats_per_burst;
    return nbursts;
  endfunction

  function void publish_cov(bit is_done, bit is_error, bit [31:0] status);
    dma_cov_item citem;

    citem = dma_cov_item::type_id::create("citem");
    citem.src_addr   = src_addr;
    citem.dst_addr   = dst_addr;
    citem.len_bytes  = len_bytes;
    citem.max_beats  = max_beats;
    citem.num_bursts = calc_num_bursts(len_bytes, max_beats);
    citem.is_done    = is_done;
    citem.is_error   = is_error;
    citem.is_single  = (citem.num_bursts == 1);

    cov_ap.write(citem);

    `uvm_info(
      "SB",
      $sformatf(
        "coverage publish: src=%08h dst=%08h len=%0d max_beats=%0d num_bursts=%0d status=%08h done=%0b error=%0b",
        src_addr, dst_addr, len_bytes, max_beats, citem.num_bursts, status, is_done, is_error
      ),
      UVM_LOW
    )
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
    end
    else if (tr.addr[7:0] == dma_pkg::CSR_STATUS_OFF) begin
      if (tr.rdata[2]) begin
        saw_error = 1'b1;
        publish_cov(1'b0, 1'b1, tr.rdata);
        `uvm_info(
          "SB",
          $sformatf(
            "DMA error observed: src=%08h dst=%08h len=%0d max_beats=%0d status=%08h",
            src_addr, dst_addr, len_bytes, max_beats, tr.rdata
          ),
          UVM_LOW
        )
      end

      if (tr.rdata[1]) begin
        saw_done = 1'b1;
        publish_cov(1'b1, 1'b0, tr.rdata);

        if (!mem_vif.check_copy(src_addr, dst_addr, len_bytes/4, bad_idx, exp, got)) begin
          `uvm_error(
            "SB",
            $sformatf(
              "Copy mismatch idx=%0d exp=%08h got=%08h src=%08h dst=%08h len=%0d max_beats=%0d",
              bad_idx, exp, got, src_addr, dst_addr, len_bytes, max_beats
            )
          )
        end
        else begin
          `uvm_info(
            "SB",
            $sformatf(
              "DMA copy check passed: src=%08h dst=%08h len=%0d max_beats=%0d",
              src_addr, dst_addr, len_bytes, max_beats
            ),
            UVM_LOW
          )
        end
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    if (!saw_done && !saw_error)
      `uvm_warning("SB", "DMA done/error was not observed by scoreboard")
  endfunction
endclass