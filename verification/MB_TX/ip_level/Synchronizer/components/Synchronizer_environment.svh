`ifndef SYNCHRONIZER_ENVIRONMENT_SVH
`define SYNCHRONIZER_ENVIRONMENT_SVH

class Synchronizer_environment extends uvm_env;
  `uvm_component_utils(Synchronizer_environment)

  Synchronizer_agent agt;
  Synchronizer_scoreboard sb;
  Synchronizer_subscriber sub;

  Synchronizer_env_cfg_obj cfg;
  Synchronizer_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Synchronizer_sequence_item) Synchronizer_env_aport;

  function new(string name = "Synchronizer_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Synchronizer_env_aport = new("Synchronizer_env_aport", this);

    if (!uvm_config_db#(Synchronizer_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNCHRONIZER_ENV", "Synchronizer_env_cfg_obj not found in config_db for Synchronizer_environment")

    if (cfg.Synchronizer_has_agent) begin
      agt_cfg = Synchronizer_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Synchronizer_vif = cfg.Synchronizer_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Synchronizer"];

      uvm_config_db#(Synchronizer_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Synchronizer_has_agent)
      agt = Synchronizer_agent::type_id::create("agt", this);

    if (cfg.Synchronizer_has_scoreboard)
      sb = Synchronizer_scoreboard::type_id::create("sb", this);

    if (cfg.Synchronizer_has_subscriber)
      sub = Synchronizer_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Synchronizer_has_agent) begin
      if (cfg.Synchronizer_has_scoreboard)
        agt.agt_aport.connect(sb.exp);

      if (cfg.Synchronizer_has_subscriber)
        agt.agt_aport.connect(sub.exp);

      agt.agt_aport.connect(Synchronizer_env_aport);
    end
  endfunction
endclass

`endif // SYNCHRONIZER_ENVIRONMENT_SVH
