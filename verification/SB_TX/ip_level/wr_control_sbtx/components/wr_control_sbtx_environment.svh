`ifndef WR_CONTROL_SBTX_ENVIRONMENT_SVH
`define WR_CONTROL_SBTX_ENVIRONMENT_SVH

class wr_control_sbtx_environment extends uvm_env;
  `uvm_component_utils(wr_control_sbtx_environment)

  wr_control_sbtx_agent agt;
  wr_control_sbtx_scoreboard sb;
  wr_control_sbtx_subscriber sub;

  wr_control_sbtx_env_cfg_obj cfg;
  wr_control_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(wr_control_sbtx_sequence_item) wr_control_sbtx_env_aport;

  function new(string name = "wr_control_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    wr_control_sbtx_env_aport = new("wr_control_sbtx_env_aport", this);

    if (!uvm_config_db#(wr_control_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("WR_CONTROL_SBTX_ENV", "wr_control_sbtx_env_cfg_obj not found in config_db for wr_control_sbtx_environment")

    if (cfg.wr_control_sbtx_has_agent) begin
      agt_cfg = wr_control_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.wr_control_sbtx_vif = cfg.wr_control_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["wr_control_sbtx"];

      uvm_config_db#(wr_control_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.wr_control_sbtx_has_agent)
      agt = wr_control_sbtx_agent::type_id::create("agt", this);

    if (cfg.wr_control_sbtx_has_scoreboard)
      sb = wr_control_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.wr_control_sbtx_has_subscriber)
      sub = wr_control_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.wr_control_sbtx_has_agent) begin
      if (cfg.wr_control_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.wr_control_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(wr_control_sbtx_env_aport);
    end
  endfunction
endclass

`endif // WR_CONTROL_SBTX_ENVIRONMENT_SVH
