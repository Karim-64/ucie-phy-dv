`ifndef BIT_SYNC_SBTX_ENVIRONMENT_SVH
`define BIT_SYNC_SBTX_ENVIRONMENT_SVH

class BIT_SYNC_SBTX_environment extends uvm_env;
  `uvm_component_utils(BIT_SYNC_SBTX_environment)

  BIT_SYNC_SBTX_agent agt;
  BIT_SYNC_SBTX_scoreboard sb;
  BIT_SYNC_SBTX_subscriber sub;

  BIT_SYNC_SBTX_env_cfg_obj cfg;
  BIT_SYNC_SBTX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(BIT_SYNC_SBTX_sequence_item) BIT_SYNC_SBTX_env_aport;

  function new(string name = "BIT_SYNC_SBTX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    BIT_SYNC_SBTX_env_aport = new("BIT_SYNC_SBTX_env_aport", this);

    if (!uvm_config_db#(BIT_SYNC_SBTX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("BIT_SYNC_SBTX_ENV", "BIT_SYNC_SBTX_env_cfg_obj not found in config_db for BIT_SYNC_SBTX_environment")

    if (cfg.BIT_SYNC_SBTX_has_agent) begin
      agt_cfg = BIT_SYNC_SBTX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.BIT_SYNC_SBTX_vif = cfg.BIT_SYNC_SBTX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["BIT_SYNC_SBTX"];

      uvm_config_db#(BIT_SYNC_SBTX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.BIT_SYNC_SBTX_has_agent)
      agt = BIT_SYNC_SBTX_agent::type_id::create("agt", this);

    if (cfg.BIT_SYNC_SBTX_has_scoreboard)
      sb = BIT_SYNC_SBTX_scoreboard::type_id::create("sb", this);

    if (cfg.BIT_SYNC_SBTX_has_subscriber)
      sub = BIT_SYNC_SBTX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.BIT_SYNC_SBTX_has_agent) begin
      if (cfg.BIT_SYNC_SBTX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.BIT_SYNC_SBTX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(BIT_SYNC_SBTX_env_aport);
    end
  endfunction
endclass

`endif // BIT_SYNC_SBTX_ENVIRONMENT_SVH
