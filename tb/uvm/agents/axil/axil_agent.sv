class axil_agent extends uvm_component;
  `uvm_component_utils(axil_agent)

  axil_agent_cfg cfg;
  axil_driver    drv;
  axil_monitor   mon;
  axil_sequencer sqr;

  function new(string name = "axil_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(axil_agent_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = axil_agent_cfg::type_id::create("cfg");
      if (!uvm_config_db#(virtual axil_if)::get(this, "", "vif", cfg.vif))
        `uvm_fatal("NOVIF", "axil_agent could not get virtual interface")
    end

    uvm_config_db#(virtual axil_if)::set(this, "mon", "vif", cfg.vif);
    mon = axil_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin
      uvm_config_db#(virtual axil_if)::set(this, "drv", "vif", cfg.vif);
      drv = axil_driver::type_id::create("drv", this);
      sqr = axil_sequencer::type_id::create("sqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
