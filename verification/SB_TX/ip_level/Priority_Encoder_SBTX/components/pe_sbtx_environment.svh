`ifndef PE_SBTX_ENVIRONMENT_SVH
`define PE_SBTX_ENVIRONMENT_SVH

class pe_sbtx_environment extends uvm_env;
  `uvm_component_utils(pe_sbtx_environment)

  pe_sbtx_D2D_agent  D2D_agt;
  pe_sbtx_PHY_agent  PHY_agt;
  pe_sbtx_FIFO_agent FIFO_agt;
  pe_sbtx_scoreboard sb;
  pe_sbtx_coverage   cov;
  pe_sbtx_vseqr      vseqr;

  pe_sbtx_env_cfg_obj       cfg;
  pe_sbtx_D2D_agt_cfg_obj   D2D_agt_cfg;
  pe_sbtx_PHY_agt_cfg_obj   PHY_agt_cfg;
  pe_sbtx_FIFO_agt_cfg_obj  FIFO_agt_cfg;

  function new(string name = "pe_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(pe_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PE_SBTX_ENV", "pe_sbtx_env_cfg_obj not found in config_db for pe_sbtx_environment")

    // ---- D2D Agent ----
    if (cfg.pe_sbtx_has_D2D_agent) begin
      D2D_agt_cfg = pe_sbtx_D2D_agt_cfg_obj::type_id::create("D2D_agt_cfg");
      D2D_agt_cfg.pe_sbtx_vif = cfg.d2d_vif;
      D2D_agt_cfg.is_active = cfg.active_passive_agents["D2D"];
      D2D_agt_cfg.pe_sbtx_D2D_has_monitor = 1;

      uvm_config_db#(pe_sbtx_D2D_agt_cfg_obj)::set(this, "D2D_agt", "cfg", D2D_agt_cfg);
      D2D_agt = pe_sbtx_D2D_agent::type_id::create("D2D_agt", this);
    end

    // ---- PHY Agent ----
    if (cfg.pe_sbtx_has_PHY_agent) begin
      PHY_agt_cfg = pe_sbtx_PHY_agt_cfg_obj::type_id::create("PHY_agt_cfg");
      PHY_agt_cfg.pe_sbtx_vif = cfg.phy_vif;
      PHY_agt_cfg.is_active = cfg.active_passive_agents["PHY"];
      PHY_agt_cfg.pe_sbtx_PHY_has_monitor = 1;

      uvm_config_db#(pe_sbtx_PHY_agt_cfg_obj)::set(this, "PHY_agt", "cfg", PHY_agt_cfg);
      PHY_agt = pe_sbtx_PHY_agent::type_id::create("PHY_agt", this);
    end

    // ---- FIFO Agent ----
    if (cfg.pe_sbtx_has_FIFO_agent) begin
      FIFO_agt_cfg = pe_sbtx_FIFO_agt_cfg_obj::type_id::create("FIFO_agt_cfg");
      FIFO_agt_cfg.pe_sbtx_vif = cfg.fifo_vif;
      FIFO_agt_cfg.is_active = cfg.active_passive_agents["FIFO"];
      FIFO_agt_cfg.pe_sbtx_FIFO_has_monitor = 1;

      uvm_config_db#(pe_sbtx_FIFO_agt_cfg_obj)::set(this, "FIFO_agt", "cfg", FIFO_agt_cfg);
      FIFO_agt = pe_sbtx_FIFO_agent::type_id::create("FIFO_agt", this);
    end

    // ---- Scoreboard ----
    if (cfg.pe_sbtx_has_scoreboard)
      sb = pe_sbtx_scoreboard::type_id::create("sb", this);

    // ---- Coverage Collector ----
    if (cfg.pe_sbtx_has_subscriber)
      cov = pe_sbtx_coverage::type_id::create("cov", this);

    // ---- Virtual Sequencer ----
    vseqr = pe_sbtx_vseqr::type_id::create("vseqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect virtual sequencer handles
    if (cfg.pe_sbtx_has_D2D_agent && cfg.active_passive_agents["D2D"] == UVM_ACTIVE)
      vseqr.D2D_seqr = D2D_agt.seqr;

    if (cfg.pe_sbtx_has_PHY_agent && cfg.active_passive_agents["PHY"] == UVM_ACTIVE)
      vseqr.PHY_seqr = PHY_agt.seqr;

    // Connect agents to scoreboard
    if (cfg.pe_sbtx_has_scoreboard) begin
      if (cfg.pe_sbtx_has_D2D_agent)
        D2D_agt.agt_aport.connect(sb.sb_d2d_aexport);
      if (cfg.pe_sbtx_has_PHY_agent)
        PHY_agt.agt_aport.connect(sb.sb_phy_aexport);
      if (cfg.pe_sbtx_has_FIFO_agent)
        FIFO_agt.agt_aport.connect(sb.sb_fifo_aexport);
    end

    // Connect agents to coverage collector
    if (cfg.pe_sbtx_has_subscriber) begin
      if (cfg.pe_sbtx_has_D2D_agent)
        D2D_agt.agt_aport.connect(cov.d2d_imp);
      if (cfg.pe_sbtx_has_PHY_agent)
        PHY_agt.agt_aport.connect(cov.phy_imp);
    end
  endfunction
endclass

`endif // PE_SBTX_ENVIRONMENT_SVH
