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
    axil_seq_item wr_tr, rd_tr;
    bit have_aw, have_w;

    bit [31:0] awaddr_q;
    bit [31:0] wdata_q;
    bit [3:0]  wstrb_q;

    have_aw = 0;
    have_w  = 0;

    forever begin
      @(vif.mon_cb);

      if (!vif.ARESETn) begin
        have_aw = 0;
        have_w  = 0;
        continue;
      end

      // Capture AW
      if (vif.mon_cb.AWVALID && vif.mon_cb.AWREADY) begin
        awaddr_q = vif.mon_cb.AWADDR;
        have_aw  = 1;
      end

      // Capture W
      if (vif.mon_cb.WVALID && vif.mon_cb.WREADY) begin
        wdata_q = vif.mon_cb.WDATA;
        wstrb_q = vif.mon_cb.WSTRB;
        have_w  = 1;
      end

      // Publish write only after response, with matched AW+W
      if (have_aw && have_w && vif.mon_cb.BVALID && vif.mon_cb.BREADY) begin
        wr_tr = axil_seq_item::type_id::create("wr_tr");
        wr_tr.is_write = 1;
        wr_tr.addr     = awaddr_q;
        wr_tr.data     = wdata_q;
        wr_tr.resp     = vif.mon_cb.BRESP;
        ap.write(wr_tr);

        have_aw = 0;
        have_w  = 0;
      end

      // Read path
      if (vif.mon_cb.ARVALID && vif.mon_cb.ARREADY) begin
        rd_tr = axil_seq_item::type_id::create("rd_tr");
        rd_tr.is_write = 0;
        rd_tr.addr     = vif.mon_cb.ARADDR;

        do @(vif.mon_cb); while (!(vif.mon_cb.RVALID && vif.mon_cb.RREADY));

        rd_tr.rdata = vif.mon_cb.RDATA;
        rd_tr.resp  = vif.mon_cb.RRESP;
        ap.write(rd_tr);
      end
    end
  endtask
endclass