class dma_cov_collector extends uvm_component;
  `uvm_component_utils(dma_cov_collector)

  uvm_analysis_imp #(dma_cov_item, dma_cov_collector) imp;
  dma_cov_item item;

  covergroup dma_cg;
    option.per_instance = 1;

    cp_len : coverpoint item.len_bytes {
      bins len_small = {[4:16]};
      bins len_mid   = {[20:64]};
      bins len_large = {[68:256]};
    }

    cp_max_beats : coverpoint item.max_beats {
      bins beats_1  = {1};
      bins beats_2  = {2};
      bins beats_4  = {4};
      bins beats_8  = {8};
      bins beats_16 = {16};
    }

    cp_num_bursts : coverpoint item.num_bursts {
      bins burst_single = {1};
      bins burst_few    = {[2:4]};
      bins burst_many   = {[5:64]};
    }

    cp_outcome : coverpoint {item.is_done, item.is_error} {
      bins outcome_done  = {2'b10};
      bins outcome_error = {2'b01};
    }

    cp_single_multi : coverpoint item.is_single {
      bins single_burst = {1};
      bins multi_burst  = {0};
    }

    cross_len_x_beats      : cross cp_len, cp_max_beats;
    cross_single_x_outcome : cross cp_single_multi, cp_outcome;
  endgroup

  function new(string name = "dma_cov_collector", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
    dma_cg = new();
  endfunction

  function void write(dma_cov_item t);
    item = t;
    dma_cg.sample();

    `uvm_info(
      "COV",
      $sformatf("sampled len=%0d max_beats=%0d num_bursts=%0d done=%0b error=%0b single=%0b",
                item.len_bytes, item.max_beats, item.num_bursts,
                item.is_done, item.is_error, item.is_single),
      UVM_HIGH
    )
  endfunction

endclass