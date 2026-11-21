`ifndef MUX_SBRX_ENVIRONMENT_SVH
`define MUX_SBRX_ENVIRONMENT_SVH

class mux_sbrx_environment extends uvm_env;
  `uvm_component_utils(mux_sbrx_environment)

  mux_sbrx_agent agt;
  mux_sbrx_scoreboard sb;
  mux_sbrx_subscriber sub;

  mux_sbrx_env_cfg_obj cfg;
  mux_sbrx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(mux_sbrx_sequence_item) mux_sbrx_env_aport;

  function new(string name = "mux_sbrx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    mux_sbrx_env_aport = new("mux_sbrx_env_aport", this);

    if (!uvm_config_db#(mux_sbrx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MUX_SBRX_ENV", "mux_sbrx_env_cfg_obj not found in config_db for mux_sbrx_environment")

    if (cfg.mux_sbrx_has_agent) begin
      agt_cfg = mux_sbrx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.mux_sbrx_vif = cfg.mux_sbrx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["mux_sbrx"];

      uvm_config_db#(mux_sbrx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.mux_sbrx_has_agent)
      agt = mux_sbrx_agent::type_id::create("agt", this);

    if (cfg.mux_sbrx_has_scoreboard)
      sb = mux_sbrx_scoreboard::type_id::create("sb", this);

    if (cfg.mux_sbrx_has_subscriber)
      sub = mux_sbrx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.mux_sbrx_has_agent) begin
      if (cfg.mux_sbrx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.mux_sbrx_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(mux_sbrx_env_aport);
    end
  endfunction
endclass

`endif // MUX_SBRX_ENVIRONMENT_SVH
