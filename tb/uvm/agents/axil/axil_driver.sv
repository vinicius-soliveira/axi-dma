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
    wait_reset_release();

    `uvm_info("AXIL_DRV", "run_phase started", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(tr);
      `uvm_info("AXIL_DRV",
                $sformatf("got item is_write=%0b addr=%08h data=%08h",
                          tr.is_write, tr.addr, tr.data),
                UVM_LOW)

      if (tr.is_write) drive_write(tr);
      else             drive_read(tr);

      seq_item_port.item_done();
  end
endtask
    
  task wait_reset_release();
  	do @(vif.drv_cb); while (vif.ARESETn !== 1'b0);
  	do @(vif.drv_cb); while (vif.ARESETn !== 1'b1);
  	@(vif.drv_cb);
  endtask 
    
  task drive_write(ref axil_seq_item tr);
  bit aw_done, w_done;

  aw_done = 0;
  w_done  = 0;

  // Apresenta endereço e dados
  @(vif.drv_cb);
  vif.drv_cb.AWADDR  <= tr.addr;
  vif.drv_cb.AWVALID <= 1'b1;
  vif.drv_cb.WDATA   <= tr.data;
  vif.drv_cb.WSTRB   <= '1;
  vif.drv_cb.WVALID  <= 1'b1;
  vif.drv_cb.BREADY  <= 1'b0;

  // Espera os dois handshakes independentemente
  while (!(aw_done && w_done)) begin
    @(vif.mon_cb);

    if (!aw_done && vif.mon_cb.AWREADY) begin
      aw_done = 1;
      vif.drv_cb.AWVALID <= 1'b0;
      `uvm_info("AXIL_DRV", $sformatf("AW handshake addr=%08h", tr.addr), UVM_HIGH)
    end

    if (!w_done && vif.mon_cb.WREADY) begin
      w_done = 1;
      vif.drv_cb.WVALID <= 1'b0;
      `uvm_info("AXIL_DRV", $sformatf("W handshake data=%08h", tr.data), UVM_HIGH)
    end
  end

  // Espera resposta
  @(vif.drv_cb);
  vif.drv_cb.BREADY <= 1'b1;

  do @(vif.mon_cb); while (!vif.mon_cb.BVALID);

  tr.resp = vif.mon_cb.BRESP;
  `uvm_info("AXIL_DRV", $sformatf("B handshake resp=%0d", tr.resp), UVM_HIGH)

  @(vif.drv_cb);
  vif.drv_cb.BREADY <= 1'b0;
endtask

  task drive_read(ref axil_seq_item tr);
  @(vif.drv_cb);
  vif.drv_cb.ARADDR  <= tr.addr;
  vif.drv_cb.ARVALID <= 1'b1;
  vif.drv_cb.RREADY  <= 1'b0;

  do @(vif.mon_cb); while (!vif.mon_cb.ARREADY);

  vif.drv_cb.ARVALID <= 1'b0;
  `uvm_info("AXIL_DRV", $sformatf("AR handshake addr=%08h", tr.addr), UVM_HIGH)

  @(vif.drv_cb);
  vif.drv_cb.RREADY <= 1'b1;

  do @(vif.mon_cb); while (!vif.mon_cb.RVALID);

  tr.rdata = vif.mon_cb.RDATA;
  tr.resp  = vif.mon_cb.RRESP;
  `uvm_info("AXIL_DRV", $sformatf("R handshake data=%08h resp=%0d", tr.rdata, tr.resp), UVM_HIGH)

  @(vif.drv_cb);
  vif.drv_cb.RREADY <= 1'b0;
 endtask
endclass