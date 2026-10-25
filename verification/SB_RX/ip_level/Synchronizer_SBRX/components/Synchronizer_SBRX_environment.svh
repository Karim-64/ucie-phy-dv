`ifndef SYNCHRONIZER_SBRX_ENVIRONMENT_SVH
`define SYNCHRONIZER_SBRX_ENVIRONMENT_SVH

class Synchronizer_SBRX_environment extends uvm_env;
  `uvm_component_utils(Synchronizer_SBRX_environment)

  Synchronizer_SBRX_agent agt;
  Synchronizer_SBRX_scoreboard sb;
  Synchronizer_SBRX_subscriber sub;

  Synchronizer_SBRX_env_cfg_obj cfg;
  Synchronizer_SBRX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Synchronizer_SBRX_sequence_item) Synchronizer_SBRX_env_aport;

  function new(string name = "Synchronizer_SBRX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Synchronizer_SBRX_env_aport = new("Synchronizer_SBRX_env_aport", this);

    if (!uvm_config_db#(Synchronizer_SBRX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNCHRONIZER_SBRX_ENV", "Synchronizer_SBRX_env_cfg_obj not found in config_db for Synchronizer_SBRX_environment")

    if (cfg.Synchronizer_SBRX_has_agent) begin
      agt_cfg = Synchronizer_SBRX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Synchronizer_SBRX_vif = cfg.Synchronizer_SBRX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Synchronizer_SBRX"];

      uvm_config_db#(Synchronizer_SBRX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Synchronizer_SBRX_has_agent)
      agt = Synchronizer_SBRX_agent::type_id::create("agt", this);

    if (cfg.Synchronizer_SBRX_has_scoreboard)
      sb = Synchronizer_SBRX_scoreboard::type_id::create("sb", this);

    if (cfg.Synchronizer_SBRX_has_subscriber)
      sub = Synchronizer_SBRX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Synchronizer_SBRX_has_agent) begin
      if (cfg.Synchronizer_SBRX_has_scoreboard)
        agt.agt_aport.connect(sb.Synchronizer_SBRX_analysis_export);

      if (cfg.Synchronizer_SBRX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Synchronizer_SBRX_env_aport);
    end
  endfunction
endclass

`endif // SYNCHRONIZER_SBRX_ENVIRONMENT_SVH
