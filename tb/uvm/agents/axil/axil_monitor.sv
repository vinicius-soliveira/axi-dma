class axil_monitor extends uvm_component;
  `uvm_component_utils(axil_monitor)

  virtual axil_if vif;
  uvm_analysis_port #(axil_seq_item) ap;

  function new(string name = "axil_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axil_monitor could not get virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_writes();
      monitor_reads();
    join
  endtask

  task monitor_writes();
    axil_seq_item tr;
    bit [31:0] awaddr_q;
    bit [31:0] wdata_q;
    forever begin
      do @(vif.mon_cb); while (!(vif.mon_cb.AWVALID && vif.mon_cb.AWREADY));
      awaddr_q = vif.mon_cb.AWADDR;
      do @(vif.mon_cb); while (!(vif.mon_cb.WVALID && vif.mon_cb.WREADY));
      wdata_q = vif.mon_cb.WDATA;
      do @(vif.mon_cb); while (!(vif.mon_cb.BVALID && vif.mon_cb.BREADY));
      tr = axil_seq_item::type_id::create("wr_tr");
      tr.is_write = 1;
      tr.addr     = awaddr_q;
      tr.data     = wdata_q;
      tr.resp     = vif.mon_cb.BRESP;
      ap.write(tr);
    end
  endtask

  task monitor_reads();
    axil_seq_item tr;
    bit [31:0] araddr_q;
    forever begin
      do @(vif.mon_cb); while (!(vif.mon_cb.ARVALID && vif.mon_cb.ARREADY));
      araddr_q = vif.mon_cb.ARADDR;
      do @(vif.mon_cb); while (!(vif.mon_cb.RVALID && vif.mon_cb.RREADY));
      tr = axil_seq_item::type_id::create("rd_tr");
      tr.is_write = 0;
      tr.addr     = araddr_q;
      tr.rdata    = vif.mon_cb.RDATA;
      tr.resp     = vif.mon_cb.RRESP;
      ap.write(tr);
    end
  endtask
endclass
