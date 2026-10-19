`ifndef DEMUX_ENVIRONMENT_SVH
`define DEMUX_ENVIRONMENT_SVH

class demux_environment extends uvm_env;
  `uvm_component_utils(demux_environment)

  demux_agent agt;
  demux_scoreboard sb;
  demux_subscriber sub;

  demux_env_cfg_obj cfg;
  demux_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(demux_sequence_item) demux_env_aport;

  function new(string name = "demux_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    demux_env_aport = new("demux_env_aport", this);

    if (!uvm_config_db#(demux_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_ENV", "demux_env_cfg_obj not found in config_db for demux_environment")

    if (cfg.demux_has_agent) begin
      agt_cfg = demux_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.demux_vif = cfg.demux_vif;
      agt_cfg.is_active = cfg.active_passive_agents["demux"];

      uvm_config_db#(demux_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.demux_has_agent)
      agt = demux_agent::type_id::create("agt", this);

    if (cfg.demux_has_scoreboard)
      sb = demux_scoreboard::type_id::create("sb", this);

    if (cfg.demux_has_subscriber)
      sub = demux_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.demux_has_agent) begin
      if (cfg.demux_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.demux_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(demux_env_aport);
    end
  endfunction
endclass

`endif // DEMUX_ENVIRONMENT_SVH
