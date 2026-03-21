class dma_env extends uvm_component;
  `uvm_component_utils(dma_env)

  axil_agent           axil_ag;
  dma_virtual_sequencer vsqr;
  dma_scoreboard       sb;
  dma_cov_collector    cov;

  axil_agent_cfg       axil_cfg;
  virtual axil_if      axil_vif;
  virtual axi_mem_model mem_vif;

  function new(string name = "dma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual axil_if)::get(this, "", "axil_vif", axil_vif))
      `uvm_fatal("NOVIF", "dma_env could not get axil_vif")
    if (!uvm_config_db#(virtual axi_mem_model)::get(this, "", "mem_vif", mem_vif))
      `uvm_fatal("NOMEMVIF", "dma_env could not get mem_vif")

    axil_cfg = axil_agent_cfg::type_id::create("axil_cfg");
    axil_cfg.vif = axil_vif;
    axil_cfg.is_active = UVM_ACTIVE;

    uvm_config_db#(axil_agent_cfg)::set(this, "axil_ag", "cfg", axil_cfg);
    uvm_config_db#(virtual axil_if)::set(this, "axil_ag", "vif", axil_vif);
    uvm_config_db#(virtual axi_mem_model)::set(this, "sb", "mem_vif", mem_vif);

    axil_ag = axil_agent::type_id::create("axil_ag", this);
    vsqr    = dma_virtual_sequencer::type_id::create("vsqr", this);
    sb      = dma_scoreboard::type_id::create("sb", this);
    cov     = dma_cov_collector::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vsqr.axil_sqr = axil_ag.sqr;
    vsqr.mem_vif  = mem_vif;
    axil_ag.mon.ap.connect(sb.imp);
    axil_ag.mon.ap.connect(cov.imp);
  endfunction
endclass
