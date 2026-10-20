`ifndef DEMUX_ENVIRONMENT_SVH
`define DEMUX_ENVIRONMENT_SVH

class DEMUX_environment extends uvm_env;
  `uvm_component_utils(DEMUX_environment)

  DEMUX_agent agt;
  DEMUX_scoreboard sb;
  DEMUX_subscriber sub;

  DEMUX_env_cfg_obj cfg;
  DEMUX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(DEMUX_sequence_item) DEMUX_env_aport;

  function new(string name = "DEMUX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    DEMUX_env_aport = new("DEMUX_env_aport", this);

    if (!uvm_config_db#(DEMUX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_ENV", "DEMUX_env_cfg_obj not found in config_db for DEMUX_environment")

    if (cfg.DEMUX_has_agent) begin
      agt_cfg = DEMUX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.DEMUX_vif = cfg.DEMUX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["DEMUX"];

      uvm_config_db#(DEMUX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.DEMUX_has_agent)
      agt = DEMUX_agent::type_id::create("agt", this);

    if (cfg.DEMUX_has_scoreboard)
      sb = DEMUX_scoreboard::type_id::create("sb", this);

    if (cfg.DEMUX_has_subscriber)
      sub = DEMUX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.DEMUX_has_agent) begin
      if (cfg.DEMUX_has_scoreboard)
        // agt.agt_aport.connect(sb.sb_aimp);
        agt.agt_aport.connect(sb.scb_aexp);

      if (cfg.DEMUX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(DEMUX_env_aport);
    end
  endfunction
endclass

`endif // DEMUX_ENVIRONMENT_SVH
