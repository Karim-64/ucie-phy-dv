`ifndef DEMUX_SBTX_ENVIRONMENT_SVH
`define DEMUX_SBTX_ENVIRONMENT_SVH

class demux_SBTX_environment extends uvm_env;
  `uvm_component_utils(demux_SBTX_environment)

  demux_SBTX_agent agt;
  demux_SBTX_scoreboard sb;
  demux_SBTX_subscriber sub;

  demux_SBTX_env_cfg_obj cfg;
  demux_SBTX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(demux_SBTX_sequence_item) demux_SBTX_env_aport;

  function new(string name = "demux_SBTX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    demux_SBTX_env_aport = new("demux_SBTX_env_aport", this);

    if (!uvm_config_db#(demux_SBTX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_SBTX_ENV", "demux_SBTX_env_cfg_obj not found in config_db for demux_SBTX_environment")

    if (cfg.demux_SBTX_has_agent) begin
      agt_cfg = demux_SBTX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.demux_SBTX_vif = cfg.demux_SBTX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["demux_SBTX"];

      uvm_config_db#(demux_SBTX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.demux_SBTX_has_agent)
      agt = demux_SBTX_agent::type_id::create("agt", this);

    if (cfg.demux_SBTX_has_scoreboard)
      sb = demux_SBTX_scoreboard::type_id::create("sb", this);

    if (cfg.demux_SBTX_has_subscriber)
      sub = demux_SBTX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.demux_SBTX_has_agent) begin
      if (cfg.demux_SBTX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.demux_SBTX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(demux_SBTX_env_aport);
    end
  endfunction
endclass

`endif // DEMUX_SBTX_ENVIRONMENT_SVH
