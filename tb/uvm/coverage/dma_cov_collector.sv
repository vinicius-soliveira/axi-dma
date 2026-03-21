class dma_cov_collector extends uvm_component;
  `uvm_component_utils(dma_cov_collector)

  uvm_analysis_imp #(axil_seq_item, dma_cov_collector) imp;

  bit [31:0] len_bytes;
  bit [7:0]  max_beats;
  bit        done_seen;
  bit        err_seen;

  covergroup dma_cg;
    option.per_instance = 1;
    cp_len: coverpoint len_bytes {
      bins short_t  = {[4:16]};
      bins medium_t = {[20:64]};
      bins long_t   = {[68:256]};
    }
    cp_beats: coverpoint max_beats {
      bins b1  = {1};
      bins b2  = {2};
      bins b4  = {4};
      bins b8  = {8};
      bins b16 = {16};
    }
    cp_done: coverpoint done_seen { bins yes = {1}; }
    cp_err : coverpoint err_seen  { bins no = {0}; bins yes = {1}; }
    x_len_beats: cross cp_len, cp_beats;
  endgroup

  function new(string name = "dma_cov_collector", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
    dma_cg = new();
  endfunction

  function void write(axil_seq_item tr);
    if (tr.is_write) begin
      case (tr.addr[7:0])
        dma_pkg::CSR_LEN_BYTES_OFF:  len_bytes = tr.data;
        dma_pkg::CSR_BURST_CFG_OFF:  max_beats = tr.data[7:0];
        default: ;
      endcase
    end else if (tr.addr[7:0] == dma_pkg::CSR_STATUS_OFF) begin
      done_seen = tr.rdata[1];
      err_seen  = tr.rdata[2];
      if (done_seen || err_seen) dma_cg.sample();
    end
  endfunction
endclass
