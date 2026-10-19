`ifndef MUX_SBTX_ENVIRONMENT_SVH
`define MUX_SBTX_ENVIRONMENT_SVH

class mux_sbtx_environment extends uvm_env;
  `uvm_component_utils(mux_sbtx_environment)

  mux_sbtx_agent agt;
  mux_sbtx_scoreboard sb;
  mux_sbtx_subscriber sub;

  mux_sbtx_env_cfg_obj cfg;
  mux_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(mux_sbtx_sequence_item) mux_sbtx_env_aport;

  function new(string name = "mux_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    mux_sbtx_env_aport = new("mux_sbtx_env_aport", this);

    if (!uvm_config_db#(mux_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBTX_ENV", "mux_sbtx_env_cfg_obj not found in config_db for mux_sbtx_environment")

    if (cfg.mux_sbtx_has_agent) begin
      agt_cfg = mux_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.mux_sbtx_vif = cfg.mux_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["mux_sbtx"];

      uvm_config_db#(mux_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.mux_sbtx_has_agent)
      agt = mux_sbtx_agent::type_id::create("agt", this);

    if (cfg.mux_sbtx_has_scoreboard)
      sb = mux_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.mux_sbtx_has_subscriber)
      sub = mux_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.mux_sbtx_has_agent) begin
      if (cfg.mux_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.mux_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(mux_sbtx_env_aport);
    end
  endfunction
endclass

`endif // MUX_SBTX_ENVIRONMENT_SVH
