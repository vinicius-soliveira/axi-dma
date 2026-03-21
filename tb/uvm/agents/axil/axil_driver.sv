class axil_driver extends uvm_driver #(axil_seq_item);
  `uvm_component_utils(axil_driver)

  virtual axil_if vif;

  function new(string name = "axil_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axil_driver could not get virtual interface")
  endfunction

  task reset_signals();
    vif.drv_cb.AWADDR  <= '0;
    vif.drv_cb.AWVALID <= 0;
    vif.drv_cb.WDATA   <= '0;
    vif.drv_cb.WSTRB   <= '0;
    vif.drv_cb.WVALID  <= 0;
    vif.drv_cb.BREADY  <= 0;
    vif.drv_cb.ARADDR  <= '0;
    vif.drv_cb.ARVALID <= 0;
    vif.drv_cb.RREADY  <= 0;
  endtask

  task run_phase(uvm_phase phase);
    axil_seq_item tr;
    reset_signals();
    forever begin
      seq_item_port.get_next_item(tr);
      if (tr.is_write) drive_write(tr);
      else             drive_read(tr);
      seq_item_port.item_done();
    end
  endtask

  task drive_write(ref axil_seq_item tr);
    bit aw_done, w_done;
    aw_done = 0;
    w_done  = 0;

    @(negedge vif.ACLK);
    vif.drv_cb.AWADDR  <= tr.addr;
    vif.drv_cb.AWVALID <= 1;
    vif.drv_cb.WDATA   <= tr.data;
    vif.drv_cb.WSTRB   <= '1;
    vif.drv_cb.WVALID  <= 1;
    vif.drv_cb.BREADY  <= 0;

    fork
      begin
        while (!aw_done) begin
          @(vif.drv_cb);
          if (vif.drv_cb.AWVALID && vif.drv_cb.AWREADY) begin
            aw_done = 1;
            @(negedge vif.ACLK);
            vif.drv_cb.AWVALID <= 0;
          end
        end
      end
      begin
        while (!w_done) begin
          @(vif.drv_cb);
          if (vif.drv_cb.WVALID && vif.drv_cb.WREADY) begin
            w_done = 1;
            @(negedge vif.ACLK);
            vif.drv_cb.WVALID <= 0;
          end
        end
      end
    join

    @(negedge vif.ACLK);
    vif.drv_cb.BREADY <= 1;
    do @(vif.drv_cb); while (!(vif.drv_cb.BVALID && vif.drv_cb.BREADY));
    tr.resp = vif.drv_cb.BRESP;
    @(negedge vif.ACLK);
    vif.drv_cb.BREADY <= 0;
  endtask

  task drive_read(ref axil_seq_item tr);
    @(negedge vif.ACLK);
    vif.drv_cb.ARADDR  <= tr.addr;
    vif.drv_cb.ARVALID <= 1;
    vif.drv_cb.RREADY  <= 0;

    do @(vif.drv_cb); while (!(vif.drv_cb.ARVALID && vif.drv_cb.ARREADY));
    @(negedge vif.ACLK);
    vif.drv_cb.ARVALID <= 0;

    @(negedge vif.ACLK);
    vif.drv_cb.RREADY <= 1;
    do @(vif.drv_cb); while (!(vif.drv_cb.RVALID && vif.drv_cb.RREADY));
    tr.rdata = vif.drv_cb.RDATA;
    tr.resp  = vif.drv_cb.RRESP;
    @(negedge vif.ACLK);
    vif.drv_cb.RREADY <= 0;
  endtask
endclass
