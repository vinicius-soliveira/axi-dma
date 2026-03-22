class axil_agent_cfg extends uvm_object;
  `uvm_object_utils(axil_agent_cfg)

  virtual axil_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "axil_agent_cfg");
    super.new(name);
  endfunction
endclass
