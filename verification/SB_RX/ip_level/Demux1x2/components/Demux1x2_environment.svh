`ifndef DEMUX1X2_ENVIRONMENT_SVH
`define DEMUX1X2_ENVIRONMENT_SVH

class Demux1x2_environment extends uvm_env;
  `uvm_component_utils(Demux1x2_environment)

  Demux1x2_agent agt;
  Demux1x2_scoreboard sb;
  Demux1x2_subscriber sub;

  Demux1x2_env_cfg_obj cfg;
  Demux1x2_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Demux1x2_sequence_item) Demux1x2_env_aport;

  function new(string name = "Demux1x2_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Demux1x2_env_aport = new("Demux1x2_env_aport", this);

    if (!uvm_config_db#(Demux1x2_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX1X2_ENV", "Demux1x2_env_cfg_obj not found in config_db for Demux1x2_environment")

    if (cfg.Demux1x2_has_agent) begin
      agt_cfg = Demux1x2_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Demux1x2_vif = cfg.Demux1x2_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Demux1x2"];

      uvm_config_db#(Demux1x2_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Demux1x2_has_agent)
      agt = Demux1x2_agent::type_id::create("agt", this);

    if (cfg.Demux1x2_has_scoreboard)
      sb = Demux1x2_scoreboard::type_id::create("sb", this);

    if (cfg.Demux1x2_has_subscriber)
      sub = Demux1x2_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Demux1x2_has_agent) begin
      if (cfg.Demux1x2_has_scoreboard)
        agt.agt_aport.connect(sb.Demux1x2_analysis_export);

      if (cfg.Demux1x2_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Demux1x2_env_aport);
    end
  endfunction
endclass

`endif // DEMUX1X2_ENVIRONMENT_SVH
